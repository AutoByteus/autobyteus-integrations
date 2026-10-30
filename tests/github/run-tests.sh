#!/usr/bin/env bash
# Deterministic tests of the GitHub integration's scripts against a local
# stand-in for the AutoByteus proxy (tests/github/fake-api.py). No network,
# no real token.
#
# Usage: tests/github/run-tests.sh
# Needs: bash, curl, jq, python3.

set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
scripts="$(cd "$here/../../github/scripts" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/github-integration-tests.XXXXXX")"
routes="$work/routes.json"
log="$work/requests.jsonl"
all_log="$work/all-requests.jsonl"
all_out="$work/all-output.txt"
echo '[]' >"$routes"
: >"$log"
: >"$all_log"
: >"$all_out"

python3 -I "$here/fake-api.py" --routes "$routes" --log "$log" --port-file "$work/port" &
fake_pid=$!
cleanup() {
  kill "$fake_pid" 2>/dev/null
  wait "$fake_pid" 2>/dev/null
  rm -rf "$work"
}
trap cleanup EXIT

for _ in $(seq 1 50); do
  [ -s "$work/port" ] && break
  sleep 0.1
done
if [ ! -s "$work/port" ]; then
  echo "the fake API did not start" >&2
  exit 1
fi
port="$(cat "$work/port")"
API_URL="http://127.0.0.1:$port/r/rp_test/github/api"

# A token that must never be used: the scripts may not read token variables.
SENTINEL="ghp_SENTINELshouldNEVERbeSENT0123456789"
export GH_TOKEN="$SENTINEL" GITHUB_TOKEN="$SENTINEL"
export AUTOBYTEUS_GITHUB_API_URL="$API_URL"

passed=0
failed=0
case_name=""
case_failed=0
OUT=""
ERR=""
CODE=0

start() {
  case_name="$1"
  case_failed=0
  : >"$log"
  echo '[]' >"$routes"
}

routes() {
  printf '%s' "$1" >"$routes"
}

# run CMD...: runs a script with no stdin, capturing stdout, stderr and the exit code.
run() {
  run_with_stdin /dev/null "$@"
}

run_with_stdin() {
  local input="$1"
  shift
  "$@" <"$input" >"$work/out" 2>"$work/err"
  CODE=$?
  OUT="$(cat "$work/out")"
  ERR="$(cat "$work/err")"
  cat "$work/out" "$work/err" >>"$all_out"
}

bad() {
  echo "  FAIL [$case_name] $1"
  case_failed=1
}

expect_exit() {
  [ "$CODE" -eq "$1" ] || bad "exit $CODE, expected $1 (stderr: $ERR)"
}

expect_out() {
  case "$OUT" in *"$1"*) ;; *) bad "stdout lacks: $1 (stdout: $OUT)" ;; esac
}

expect_out_exact() {
  [ "$OUT" = "$1" ] || bad "stdout is:
$OUT
expected:
$1"
}

expect_err() {
  case "$ERR" in *"$1"*) ;; *) bad "stderr lacks: $1 (stderr: $ERR)" ;; esac
}

expect_not_err() {
  case "$ERR" in *"$1"*) bad "stderr has: $1" ;; esac
}

expect_requests() {
  local got
  got="$(jq -r '"\(.method) \(.path)"' "$log")"
  [ "$got" = "$1" ] || bad "requests were:
$got
expected:
$1"
}

expect_no_requests() {
  [ ! -s "$log" ] || bad "expected no request, got: $(jq -r '"\(.method) \(.path)"' "$log")"
}

# expect_request_body N JQ_TEST: the JSON body of request N (1-based) passes the jq test.
expect_request_body() {
  local result
  result="$(sed -n "${1}p" "$log" | jq -r '.body | fromjson | '"$2" 2>&1)"
  [ "$result" = "true" ] || bad "request $1 body fails: $2 (got: $(sed -n "${1}p" "$log" | jq -r '.body'))"
}

finish() {
  cat "$log" >>"$all_log"
  if [ "$case_failed" -eq 0 ]; then
    echo "ok   $case_name"
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
}

proxy_refusal() {
  # proxy_refusal STATUS CODE: a routes file where GET /user gets the proxy's refusal.
  routes "$(jq -n --argjson status "$1" --arg code "$2" \
    '[{method: "GET", path: "/user", status: $status, body: {error: $code, message: "proxy says \($code)"}}]')"
}

BOARD='{"data":{"repositoryOwner":{"projectV2":{"id":"PVT_1","title":"Test Board","field":{"id":"PVTSSF_1","options":[{"id":"o_todo","name":"Todo"},{"id":"o_prog","name":"In Progress"},{"id":"o_done","name":"Done"}]}}}}}'

# ---------------------------------------------------------------- check-access

start "check-access prints the login and sends no Authorization of its own"
routes '[{"method":"GET","path":"/user","status":200,"body":{"login":"octo"}}]'
run "$scripts/check-access.sh"
expect_exit 0
expect_out_exact "GitHub access: connected as @octo"
expect_requests "GET /user"
[ "$(jq -r '.headers | has("authorization")' "$log")" = "false" ] || bad "an Authorization header was sent"
[ "$(jq -r '.prefixed' "$log")" = "true" ] || bad "the request did not use AUTOBYTEUS_GITHUB_API_URL"
finish

start "no AUTOBYTEUS_GITHUB_API_URL: says how to give access and stops (REQ-008)"
for script in check-access.sh "issues.sh list o/r" "pulls.sh read o/r#1" "board.sh items --owner o --number 1"; do
  # shellcheck disable=SC2086
  run env -u AUTOBYTEUS_GITHUB_API_URL $scripts/$script
  expect_exit 3
  expect_err "No GitHub access in this run"
  expect_err "give this agent the GitHub integration, then start a new run"
done
expect_no_requests
finish

start "a missing tool is named and the script stops"
nojq="$work/nojq-bin"
mkdir -p "$nojq"
for tool in bash dirname cat curl; do
  ln -sf "$(command -v "$tool")" "$nojq/$tool"
done
run env PATH="$nojq" "$scripts/check-access.sh"
expect_exit 5
expect_out_exact ""
expect_err "jq is needed; install it, then run again"
expect_no_requests
finish

start "curl cannot connect: unreachable (exit 5)"
run env AUTOBYTEUS_GITHUB_API_URL="http://127.0.0.1:9/r/rp_test/github/api" "$scripts/check-access.sh"
expect_exit 5
expect_err "GitHub could not be reached through AutoByteus"
expect_not_err "rp_test"
finish

# ---------------------------------------------------------------- issues

start "issues list leaves out pull requests and applies --limit after that, across pages"
page1="$(jq -n '[range(1; 100) | {number: (200 + .), title: "PR \(.)", state: "open", labels: [], pull_request: {}}]
  + [{number: 5, title: "Fix README", state: "open", labels: [{name: "bug"}, {name: "docs"}]}]')"
page2="$(jq -n '[{number: 4, title: "Second", state: "open", labels: []},
  {number: 3, title: "Third", state: "open", labels: []}, {number: 2, title: "Fourth", state: "open", labels: []}]')"
routes "$(jq -n --argjson p1 "$page1" --argjson p2 "$page2" '[
  {method: "GET", path: "/repos/o/r/issues?state=open&per_page=100&page=1", status: 200, body: $p1},
  {method: "GET", path: "/repos/o/r/issues?state=open&per_page=100&page=2", status: 200, body: $p2}]')"
run "$scripts/issues.sh" list o/r --limit 3
expect_exit 0
expect_out_exact "o/r#5 [open] Fix README (bug, docs)
o/r#4 [open] Second
o/r#3 [open] Third"
expect_requests "GET /repos/o/r/issues?state=open&per_page=100&page=1
GET /repos/o/r/issues?state=open&per_page=100&page=2"
finish

start "issues list with no issues says so"
routes '[{"method":"GET","path":"/repos/o/r/issues?state=closed&per_page=100&page=1","status":200,"body":[]}]'
run "$scripts/issues.sh" list o/r --state closed
expect_exit 0
expect_out_exact "no closed issues in o/r"
finish

start "issues read shows the issue and its last comments"
routes '[
  {"method":"GET","path":"/repos/o/r/issues/3","status":200,"body":{"number":3,"title":"Fix it","state":"open","user":{"login":"amy"},"labels":[{"name":"bug"}],"html_url":"https://github.com/o/r/issues/3","body":"Line one\nLine two","comments":3}},
  {"method":"GET","path":"/repos/o/r/issues/3/comments?per_page=100&page=1","status":200,"body":[
    {"user":{"login":"a"},"created_at":"2026-10-01T00:00:00Z","body":"first"},
    {"user":{"login":"b"},"created_at":"2026-10-02T00:00:00Z","body":"second"},
    {"user":{"login":"c"},"created_at":"2026-10-03T00:00:00Z","body":"third"}]}]'
run "$scripts/issues.sh" read o/r#3 --comments 2
expect_exit 0
expect_out_exact "o/r#3 [open] Fix it
author: @amy  labels: bug
url: https://github.com/o/r/issues/3

Line one
Line two

--- comments (last 2 of 3) ---

@b at 2026-10-02T00:00:00Z:
second

@c at 2026-10-03T00:00:00Z:
third"
finish

start "issues read takes the last comments across the last two pages"
c1="$(jq -n '[range(1; 101) | {user: {login: "u"}, created_at: "t", body: "c\(.)"}]')"
c2="$(jq -n '[range(101; 151) | {user: {login: "u"}, created_at: "t", body: "c\(.)"}]')"
routes "$(jq -n --argjson c1 "$c1" --argjson c2 "$c2" '[
  {method: "GET", path: "/repos/o/r/issues/9", status: 200,
   body: {number: 9, title: "Busy", state: "open", user: {login: "amy"}, labels: [], html_url: "u", body: "", comments: 150}},
  {method: "GET", path: "/repos/o/r/issues/9/comments?per_page=100&page=2", status: 200, body: $c2},
  {method: "GET", path: "/repos/o/r/issues/9/comments?per_page=100&page=1", status: 200, body: $c1}]')"
run "$scripts/issues.sh" read o/r#9 --comments 60
expect_exit 0
expect_out "(no description)"
expect_out "--- comments (last 60 of 150) ---"
[ "$(printf '%s\n' "$OUT" | grep -c '^c[0-9]')" = "60" ] || bad "expected 60 comments"
[ "$(printf '%s\n' "$OUT" | grep '^c[0-9]' | head -1)" = "c91" ] || bad "the first comment shown should be c91"
[ "$(printf '%s\n' "$OUT" | grep '^c[0-9]' | tail -1)" = "c150" ] || bad "the last comment shown should be c150"
finish

start "issues create sends title and body as JSON, text kept exactly"
printf 'He said "hi" & left.\n$(rm -rf /) `x` \\ tab\there ü\n\nlast line' >"$work/body.md"
routes '[{"method":"POST","path":"/repos/o/r/issues","status":201,"body":{"number":7,"html_url":"https://github.com/o/r/issues/7"}}]'
run "$scripts/issues.sh" create o/r --title 'A "quoted" title' --body-file "$work/body.md"
expect_exit 0
expect_out_exact "o/r#7 https://github.com/o/r/issues/7"
expect_requests "POST /repos/o/r/issues"
expect_request_body 1 '. == {title: "A \"quoted\" title", body: "He said \"hi\" & left.\n$(rm -rf /) `x` \\ tab\there ü\n\nlast line"}'
[ "$(jq -r '.headers["content-type"]' "$log")" = "application/json" ] || bad "content type is not JSON"
finish

start "issues comment reads the body from stdin"
printf 'Done in commit abc123.\n' >"$work/comment.md"
routes '[{"method":"POST","path":"/repos/o/r/issues/3/comments","status":201,"body":{"html_url":"https://github.com/o/r/issues/3#issuecomment-1"}}]'
run_with_stdin "$work/comment.md" "$scripts/issues.sh" comment o/r#3 --body-file -
expect_exit 0
expect_out_exact "commented on o/r#3: https://github.com/o/r/issues/3#issuecomment-1"
expect_request_body 1 '. == {body: "Done in commit abc123."}'
finish

start "usage errors exit 2 and send nothing"
run "$scripts/issues.sh"
expect_exit 2
run "$scripts/issues.sh" read o/r
expect_exit 2
expect_err "expected OWNER/REPO#N, got: o/r"
run "$scripts/issues.sh" list o/../r
expect_exit 2
run "$scripts/issues.sh" list o/r --limit abc
expect_exit 2
run "$scripts/issues.sh" comment o/r#1
expect_exit 2
expect_err "comment needs --body-file FILE or -"
run "$scripts/issues.sh" create o/r --title T --body-file "$work/missing.md"
expect_exit 2
expect_err "cannot read the body file"
run "$scripts/board.sh" move o/r#1 --owner o --number 1
expect_exit 2
expect_no_requests
finish

# ---------------------------------------------------------------- pulls

start "pulls list shows state and head -> base"
routes '[{"method":"GET","path":"/repos/o/r/pulls?state=all&per_page=100&page=1","status":200,"body":[
  {"number":12,"title":"Fix README","state":"open","draft":true,"merged_at":null,"head":{"ref":"fix/readme","label":"o:fix/readme","repo":{"full_name":"o/r"}},"base":{"ref":"main","repo":{"full_name":"o/r"}}},
  {"number":11,"title":"From a fork","state":"closed","draft":false,"merged_at":"2026-10-01T00:00:00Z","head":{"ref":"feat","label":"amy:feat","repo":{"full_name":"amy/r"}},"base":{"ref":"main","repo":{"full_name":"o/r"}}}]}]'
run "$scripts/pulls.sh" list o/r --state all
expect_exit 0
expect_out_exact "o/r#12 [open, draft] Fix README (fix/readme → main)
o/r#11 [merged] From a fork (amy:feat → main)"
finish

start "pulls read shows branches, mergeable and changed files"
routes '[
  {"method":"GET","path":"/repos/o/r/pulls/12","status":200,"body":{"number":12,"title":"Fix README","state":"open","draft":false,"merged_at":null,"mergeable":null,"user":{"login":"amy"},"html_url":"https://github.com/o/r/pull/12","body":"Why.","head":{"ref":"fix/readme","label":"o:fix/readme","repo":{"full_name":"o/r"}},"base":{"ref":"main","repo":{"full_name":"o/r"}}}},
  {"method":"GET","path":"/repos/o/r/pulls/12/files?per_page=100&page=1","status":200,"body":[{"filename":"README.md","additions":3,"deletions":1}]}]'
run "$scripts/pulls.sh" read o/r#12
expect_exit 0
expect_out_exact "o/r#12 [open] Fix README
author: @amy
branches: fix/readme → main
mergeable: unknown (GitHub is still checking; read again shortly)
url: https://github.com/o/r/pull/12

changed files (1):
  +3 -1 README.md

Why."
finish

start "pulls open sends head, base, title, body and draft"
printf 'Notes.\n' >"$work/notes.md"
routes '[{"method":"POST","path":"/repos/o/r/pulls","status":201,"body":{"number":13,"html_url":"https://github.com/o/r/pull/13"}}]'
run "$scripts/pulls.sh" open o/r --head fix/readme --base main --title "Fix README" --body-file "$work/notes.md" --draft
expect_exit 0
expect_out_exact "o/r#13 https://github.com/o/r/pull/13"
expect_request_body 1 '. == {title: "Fix README", head: "fix/readme", base: "main", body: "Notes.", draft: true}'
finish

# ---------------------------------------------------------------- board

start "board items lists items with their status; --status matches case-insensitively"
routes "$(jq -n --argjson board "$BOARD" '[
  {method: "POST", path: "/graphql", match: "repositoryOwner", status: 200, body: $board},
  {method: "POST", path: "/graphql", match: "items(first", status: 200, body: {data: {node: {items: {
    pageInfo: {hasNextPage: false, endCursor: null},
    nodes: [
      {isArchived: false, status: {name: "In Progress"}, content: {__typename: "Issue", number: 3, title: "Fix it", repository: {nameWithOwner: "o/r"}}},
      {isArchived: false, status: {name: "Todo"}, content: {__typename: "PullRequest", number: 12, title: "PR", repository: {nameWithOwner: "o/r"}}},
      {isArchived: true, status: {name: "In Progress"}, content: {__typename: "Issue", number: 1, title: "Old", repository: {nameWithOwner: "o/r"}}}]}}}}}]')"
run "$scripts/board.sh" items --owner o --number 1
expect_exit 0
expect_out_exact "o/r#3 [In Progress] Fix it
o/r#12 [Todo] PR"
expect_request_body 1 '.variables == {login: "o", number: 1}'
run "$scripts/board.sh" items --owner o --number 1 --status "in progress"
expect_exit 0
expect_out_exact "o/r#3 [In Progress] Fix it"
finish

start "board move: item already on the board"
routes "$(jq -n --argjson board "$BOARD" '[
  {method: "POST", path: "/graphql", match: "repositoryOwner", status: 200, body: $board},
  {method: "POST", path: "/graphql", match: "issueOrPullRequest", status: 200, body: {data: {repository: {issueOrPullRequest: {
    id: "I_3", projectItems: {nodes: [{id: "PVTI_other", project: {id: "PVT_9"}}, {id: "PVTI_3", project: {id: "PVT_1"}}]}}}}}},
  {method: "POST", path: "/graphql", match: "updateProjectV2ItemFieldValue", status: 200,
   body: {data: {updateProjectV2ItemFieldValue: {projectV2Item: {id: "PVTI_3"}}}}}]')"
run "$scripts/board.sh" move o/r#3 --owner o --number 1 --status "in PROGRESS"
expect_exit 0
expect_out_exact "moved o/r#3 to In Progress"
[ "$(wc -l <"$log" | tr -d ' ')" = "3" ] || bad "expected 3 GraphQL requests"
expect_request_body 2 '.variables == {owner: "o", name: "r", number: 3}'
expect_request_body 3 '.variables == {project: "PVT_1", item: "PVTI_3", field: "PVTSSF_1", option: "o_prog"}'
finish

start "board move: item not on the board is added first, and the output says so"
routes "$(jq -n --argjson board "$BOARD" '[
  {method: "POST", path: "/graphql", match: "repositoryOwner", status: 200, body: $board},
  {method: "POST", path: "/graphql", match: "issueOrPullRequest", status: 200, body: {data: {repository: {issueOrPullRequest: {
    id: "I_4", projectItems: {nodes: []}}}}}},
  {method: "POST", path: "/graphql", match: "addProjectV2ItemById", status: 200,
   body: {data: {addProjectV2ItemById: {item: {id: "PVTI_new"}}}}},
  {method: "POST", path: "/graphql", match: "updateProjectV2ItemFieldValue", status: 200,
   body: {data: {updateProjectV2ItemFieldValue: {projectV2Item: {id: "PVTI_new"}}}}}]')"
run "$scripts/board.sh" move o/r#4 --owner o --number 1 --status done
expect_exit 0
expect_out_exact "added o/r#4 to the board; moved to Done"
expect_request_body 3 '.variables == {project: "PVT_1", content: "I_4"}'
expect_request_body 4 '.variables == {project: "PVT_1", item: "PVTI_new", field: "PVTSSF_1", option: "o_done"}'
finish

start "board move: an unknown status lists the valid ones and changes nothing"
routes "$(jq -n --argjson board "$BOARD" '[{method: "POST", path: "/graphql", match: "repositoryOwner", status: 200, body: $board}]')"
run "$scripts/board.sh" move o/r#3 --owner o --number 1 --status Blocked
expect_exit 2
expect_err 'unknown status "Blocked"; the board'"'"'s statuses are: Todo, In Progress, Done'
[ "$(wc -l <"$log" | tr -d ' ')" = "1" ] || bad "expected only the board query"
finish

# ---------------------------------------------------------------- Error Rules

start "Rule 1: a GitHub body that merely contains the word error is GitHub's answer"
routes '[{"method":"GET","path":"/user","status":404,"body":{"message":"error: Not Found","documentation_url":"https://docs.github.com"}}]'
run "$scripts/check-access.sh"
expect_exit 4
expect_err "GitHub answered HTTP 404 for GET /user: error: Not Found"
expect_not_err "AutoByteus refused"
routes '[{"method":"GET","path":"/user","status":403,"body":{"message":"Forbidden","error":"Some error"}}]'
run "$scripts/check-access.sh"
expect_exit 4
expect_err "GitHub answered HTTP 403 for GET /user: Forbidden"
expect_not_err "AutoByteus refused"
finish

start "Rule 2: each proxy refusal gives its next step and exit code"
check_proxy() {
  proxy_refusal "$1" "$2"
  run "$scripts/check-access.sh"
  expect_exit "$3"
  expect_err "AutoByteus refused GET /user ($2): proxy says $2"
  expect_err "Next: $4"
}
check_proxy 403 INTEGRATION_NOT_CONNECTED 3 "connect GitHub in AutoByteus."
check_proxy 403 INTEGRATION_NOT_ALLOWED 3 "this agent has no GitHub access in this run: give the agent the integration, then start a new run."
check_proxy 403 RUN_PASS_INVALID 3 "this agent has no GitHub access in this run: give the agent the integration, then start a new run."
check_proxy 403 NOT_LOOPBACK 3 "run the script on the AutoByteus machine."
check_proxy 403 PATH_NOT_ALLOWED 4 "this call is outside what the GitHub integration allows."
check_proxy 502 UPSTREAM_UNREACHABLE 5 "GitHub could not be reached; try again."
check_proxy 500 PROXY_FAILED 5 "GitHub could not be reached; try again."
finish

start "Rule 3: GitHub's REST status 401 / 403 / 404 / 422 / 5xx"
routes '[{"method":"GET","path":"/user","status":401,"body":{"message":"Bad credentials"}}]'
run "$scripts/check-access.sh"
expect_exit 3
expect_err "GitHub answered HTTP 401 for GET /user: Bad credentials"
expect_err "Next: the token was rejected (expired or revoked): reconnect GitHub in AutoByteus."
routes '[{"method":"POST","path":"/repos/o/r/issues/3/comments","status":403,"body":{"message":"Resource not accessible by personal access token"}}]'
run "$scripts/issues.sh" comment o/r#3 --body-file "$work/comment.md"
expect_exit 4
expect_err "GitHub answered HTTP 403 for POST /repos/o/r/issues/3/comments: Resource not accessible by personal access token"
expect_err "Next: the token may lack a permission or the repository is not in its list."
expect_out_exact ""
routes '[{"method":"GET","path":"/repos/o/r/issues/99","status":404,"body":{"message":"Not Found"}}]'
run "$scripts/issues.sh" read o/r#99
expect_exit 4
expect_err "GitHub answered HTTP 404 for GET /repos/o/r/issues/99: Not Found"
expect_err "Next: the token may lack a permission or the repository is not in its list."
routes '[{"method":"POST","path":"/repos/o/r/pulls","status":422,"body":{"message":"Validation Failed","errors":[{"resource":"PullRequest","field":"head","code":"invalid"},{"message":"No commits between main and nope"}]}}]'
run "$scripts/pulls.sh" open o/r --head nope --base main --title T --body-file "$work/notes.md"
expect_exit 4
expect_err "GitHub answered HTTP 422 for POST /repos/o/r/pulls: Validation Failed"
expect_err "- PullRequest head invalid"
expect_err "- No commits between main and nope"
routes '[{"method":"GET","path":"/user","status":500,"body":{"message":"Server Error"}}]'
run "$scripts/check-access.sh"
expect_exit 5
expect_err "GitHub answered HTTP 500 for GET /user: Server Error"
routes '[{"method":"GET","path":"/user","status":503,"text":"<html>Unicorn</html>"}]'
run "$scripts/check-access.sh"
expect_exit 5
expect_err "GitHub answered HTTP 503 for GET /user: no message"
finish

start "Rule 4: a GraphQL 200 with errors is a refusal, never a success; GraphQL 401 follows rule 3"
routes '[{"method":"POST","path":"/graphql","status":200,"body":{"data":{"repositoryOwner":null},"errors":[{"type":"FORBIDDEN","message":"Resource not accessible by personal access token"},{"message":"second problem"}]}}]'
run "$scripts/board.sh" move o/r#3 --owner o --number 1 --status Done
expect_exit 4
expect_err "GitHub refused the GraphQL request:"
expect_err "- Resource not accessible by personal access token (FORBIDDEN)"
expect_err "- second problem"
expect_err "Next: the token may lack a permission or the repository is not in its list."
expect_out_exact ""
[ "$(wc -l <"$log" | tr -d ' ')" = "1" ] || bad "nothing may follow a refused GraphQL request"
routes '[{"method":"POST","path":"/graphql","status":401,"body":{"message":"Bad credentials"}}]'
run "$scripts/board.sh" items --owner o --number 1
expect_exit 3
expect_err "reconnect GitHub in AutoByteus"
finish

# ---------------------------------------------------------------- the token

start "no request carried a token or an Authorization header; no output shows the sentinel"
[ "$(jq -s 'map(select(.headers | has("authorization"))) | length' "$all_log")" = "0" ] \
  || bad "a request carried an Authorization header"
if grep -q "$SENTINEL" "$all_log"; then bad "a request carried the token variable's value"; fi
if grep -q "$SENTINEL" "$all_out"; then bad "an output showed the token variable's value"; fi
[ "$(jq -s 'map(select(.prefixed | not)) | length' "$all_log")" = "0" ] \
  || bad "a request did not go through AUTOBYTEUS_GITHUB_API_URL"
finish

start "the scripts name no token variable, no gh login and no direct GitHub address"
code_lines="$(grep -v '^[[:space:]]*#' "$scripts"/*.sh)"
for forbidden in GH_TOKEN GITHUB_TOKEN "gh auth" "api.github.com" "Authorization"; do
  case "$code_lines" in *"$forbidden"*) bad "the scripts use: $forbidden" ;; esac
done
finish

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
