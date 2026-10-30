# shellcheck shell=bash
# GH_OWNER, GH_REPO and GH_NUMBER are set here for the sourcing scripts.
# shellcheck disable=SC2034
# Shared request path of the GitHub integration's scripts. Sourced by the
# scripts in this folder, never run on its own.
#
# Every call to GitHub goes through gh_request, which reaches GitHub only
# through the run's AutoByteus address, $AUTOBYTEUS_GITHUB_API_URL. AutoByteus adds
# the user's token on its side, so nothing here asks for, reads, prints or
# stores a token, and nothing calls https://api.github.com directly.
#
# Exit codes: 0 done; 2 usage; 3 no access; 4 refused; 5 unreachable or failed.
# Messages for the agent go to stderr; results go to stdout.
#
# Bash 3.2 compatible (macOS /bin/bash).

GH_PERMISSION_HINT="the token may lack a permission or the repository is not in its list"

# gh_fail EXIT_CODE LINE...: prints the lines to stderr and exits.
gh_fail() {
  local code="$1"
  shift
  printf '%s\n' "$@" >&2
  exit "$code"
}

# gh_usage_error MESSAGE: prints the message and the script's GH_USAGE, exits 2.
gh_usage_error() {
  printf '%s\n' "$1" >&2
  if [ -n "${GH_USAGE:-}" ]; then
    printf '%s\n' "$GH_USAGE" >&2
  fi
  exit 2
}

# gh_require_tools TOOL...: stops when a tool the script uses is missing.
gh_require_tools() {
  local tool
  for tool in "$@"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      gh_fail 5 "$tool is needed; install it, then run again"
    fi
  done
}

# gh_require_access: stops when this run has no GitHub access.
gh_require_access() {
  if [ -z "${AUTOBYTEUS_GITHUB_API_URL:-}" ]; then
    gh_fail 3 \
      "No GitHub access in this run (AUTOBYTEUS_GITHUB_API_URL is not set)." \
      "Next: connect GitHub in AutoByteus and give this agent the GitHub integration, then start a new run. Do not use a token or gh's own login instead."
  fi
}

# gh_parse_repo OWNER/REPO: sets GH_OWNER and GH_REPO.
gh_parse_repo() {
  local re='^([A-Za-z0-9][A-Za-z0-9-]*)/([A-Za-z0-9._-]+)$'
  if [[ "$1" =~ $re ]] && [ "${BASH_REMATCH[2]}" != "." ] && [ "${BASH_REMATCH[2]}" != ".." ]; then
    GH_OWNER="${BASH_REMATCH[1]}"
    GH_REPO="${BASH_REMATCH[2]}"
  else
    gh_usage_error "expected OWNER/REPO, got: $1"
  fi
}

# gh_parse_item OWNER/REPO#N: sets GH_OWNER, GH_REPO and GH_NUMBER.
gh_parse_item() {
  local re='^([A-Za-z0-9][A-Za-z0-9-]*)/([A-Za-z0-9._-]+)#([1-9][0-9]*)$'
  if [[ "$1" =~ $re ]] && [ "${BASH_REMATCH[2]}" != "." ] && [ "${BASH_REMATCH[2]}" != ".." ]; then
    GH_OWNER="${BASH_REMATCH[1]}"
    GH_REPO="${BASH_REMATCH[2]}"
    GH_NUMBER="${BASH_REMATCH[3]}"
  else
    gh_usage_error "expected OWNER/REPO#N, got: $1"
  fi
}

# gh_require_count OPTION VALUE MAX: stops unless VALUE is a whole number 1..MAX.
gh_require_count() {
  if ! [[ "$2" =~ ^[1-9][0-9]*$ ]] || [ "$2" -gt "$3" ]; then
    gh_usage_error "$1 needs a number from 1 to $3, got: $2"
  fi
}

# gh_read_body_file FILE|-: prints the text of FILE, or of stdin for "-".
gh_read_body_file() {
  if [ "$1" = "-" ]; then
    cat
  elif [ -f "$1" ] && [ -r "$1" ]; then
    cat -- "$1"
  else
    gh_usage_error "cannot read the body file: $1"
  fi
}

# gh_json_value JQ_FILTER: applies the filter to the JSON on stdin; prints
# nothing when the input is not JSON.
gh_json_value() {
  jq -r "$1" 2>/dev/null || true
}

# gh_request METHOD PATH [JSON_BODY]: calls GitHub through AutoByteus and prints
# GitHub's answer body. On a refusal it explains it (Error Rules 1-4) and exits.
# PATH starts with "/" (for example /repos/OWNER/REPO/issues?state=open).
gh_request() {
  local method="$1" path="$2" out rc=0 status body
  local -a args
  args=(-s --connect-timeout 10 -X "$method"
    -A "autobyteus-github-integration"
    -H "Accept: application/vnd.github+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
    -w '\n%{http_code}')
  if [ "$#" -ge 3 ]; then
    args+=(-H "Content-Type: application/json" --data-binary @-)
    out="$(printf '%s' "$3" | curl "${args[@]}" "${AUTOBYTEUS_GITHUB_API_URL}${path}")" || rc=$?
  else
    out="$(curl "${args[@]}" "${AUTOBYTEUS_GITHUB_API_URL}${path}" </dev/null)" || rc=$?
  fi
  if [ "$rc" -ne 0 ]; then
    gh_fail 5 \
      "GitHub could not be reached through AutoByteus (curl exit $rc) for $method ${path%%\?*}." \
      "Next: check that AutoByteus is running on this machine, then try again."
  fi

  status="${out##*$'\n'}"
  body="${out%$'\n'*}"
  case "$status" in
    2??)
      if [ "${path%%\?*}" = "/graphql" ]; then
        gh_check_graphql_errors "$body"
      fi
      printf '%s' "$body"
      return 0
      ;;
  esac
  gh_explain_refusal "$method" "${path%%\?*}" "$status" "$body"
}

# Error Rule 4: an HTTP 200 GraphQL answer with a non-empty "errors" array is
# a refusal, never a success.
gh_check_graphql_errors() {
  local errors
  errors="$(printf '%s' "$1" | gh_json_value '
    if type == "object" and (.errors | type) == "array" and (.errors | length) > 0
    then .errors[]
      | "- " + ((.message // "no message") | tostring)
        + (if .type then " (" + (.type | tostring) + ")" else "" end)
    else empty end')"
  if [ -n "$errors" ]; then
    gh_fail 4 "GitHub refused the GraphQL request:" "$errors" "Next: $GH_PERMISSION_HINT."
  fi
}

# gh_explain_refusal METHOD PATH STATUS BODY: Error Rules 1-3; always exits.
gh_explain_refusal() {
  local method="$1" path="$2" status="$3" body="$4" code message next exit_code details

  # Rule 1: a top-level string "error" code is the AutoByteus proxy's own
  # refusal; anything else is GitHub's answer.
  code="$(printf '%s' "$body" | gh_json_value '
    if type == "object" and (.error | type) == "string" and (.error | test("^[A-Z_]+$"))
    then .error else empty end')"
  message="$(printf '%s' "$body" | gh_json_value '
    if type == "object" and (.message | type) == "string" then .message else empty end')"
  message="${message:-no message}"

  # Rule 2: the proxy's refusals.
  if [ -n "$code" ]; then
    case "$code" in
      INTEGRATION_NOT_CONNECTED)
        exit_code=3
        next="connect GitHub in AutoByteus"
        ;;
      INTEGRATION_NOT_ALLOWED | RUN_PASS_INVALID)
        exit_code=3
        next="this agent has no GitHub access in this run: give the agent the integration, then start a new run"
        ;;
      NOT_LOOPBACK)
        exit_code=3
        next="run the script on the AutoByteus machine"
        ;;
      PATH_NOT_ALLOWED)
        exit_code=4
        next="this call is outside what the GitHub integration allows"
        ;;
      UPSTREAM_UNREACHABLE | PROXY_FAILED)
        exit_code=5
        next="GitHub could not be reached; try again"
        ;;
      *)
        case "$status" in 5??) exit_code=5 ;; *) exit_code=4 ;; esac
        next="see the message above"
        ;;
    esac
    gh_fail "$exit_code" "AutoByteus refused $method $path ($code): $message" "Next: $next."
  fi

  # Rule 3: GitHub's own status.
  case "$status" in
    401)
      gh_fail 3 "GitHub answered HTTP 401 for $method $path: $message" \
        "Next: the token was rejected (expired or revoked): reconnect GitHub in AutoByteus."
      ;;
    403 | 404)
      gh_fail 4 "GitHub answered HTTP $status for $method $path: $message" \
        "Next: $GH_PERMISSION_HINT."
      ;;
    422)
      details="$(printf '%s' "$body" | gh_json_value '
        (.errors // [])[]
        | if type == "string" then "- " + .
          elif type == "object" then
            "- " + (.message // ([.resource, .field, .code] | map(select(. != null) | tostring) | join(" ")))
          else "- " + tojson end')"
      if [ -n "$details" ]; then
        gh_fail 4 "GitHub answered HTTP 422 for $method $path: $message" "$details"
      fi
      gh_fail 4 "GitHub answered HTTP 422 for $method $path: $message"
      ;;
    5??)
      gh_fail 5 "GitHub answered HTTP $status for $method $path: $message" \
        "Next: GitHub could not complete the request; try again."
      ;;
    *)
      gh_fail 4 "GitHub answered HTTP $status for $method $path: $message"
      ;;
  esac
}

# gh_graphql QUERY VARIABLES_JSON: runs a GraphQL request and prints its "data".
gh_graphql() {
  local payload response
  payload="$(jq -n --arg query "$1" --argjson variables "$2" \
    '{query: $query, variables: $variables}')" || exit 5
  response="$(gh_request POST /graphql "$payload")" || exit $?
  printf '%s' "$response" | jq '.data'
}

# gh_get_list PATH LIMIT [SELECT]: GETs a REST list page by page (100 per
# page) and prints a JSON array of at most LIMIT items that pass the jq filter
# SELECT (default: every item). The limit applies after the filter.
gh_get_list() {
  local path="$1" limit="$2" select="${3:-true}" sep="?" page=1 items='[]' batch count
  case "$path" in *\?*) sep="&" ;; esac
  while :; do
    batch="$(gh_request GET "${path}${sep}per_page=100&page=${page}")" || exit $?
    count="$(printf '%s' "$batch" | jq 'length')" || exit 5
    items="$(printf '%s\n%s' "$items" "$batch" \
      | jq -s --argjson limit "$limit" ".[0] + [.[1][] | select($select)] | .[:\$limit]")" || exit 5
    if [ "$count" -lt 100 ] || [ "$(printf '%s' "$items" | jq 'length')" -ge "$limit" ]; then
      break
    fi
    page=$((page + 1))
  done
  printf '%s' "$items"
}
