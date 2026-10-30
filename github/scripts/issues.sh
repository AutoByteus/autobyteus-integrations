#!/usr/bin/env bash
# GitHub issues through AutoByteus: list, read, create, comment.
set -euo pipefail
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

GH_USAGE="usage:
  issues.sh list OWNER/REPO [--state open|closed|all] [--limit N]
  issues.sh read OWNER/REPO#N [--comments N]
  issues.sh create OWNER/REPO --title TEXT --body-file FILE|-
  issues.sh comment OWNER/REPO#N --body-file FILE|-"

issues_list() {
  local state=open limit=30 issues
  [ "$#" -ge 1 ] || gh_usage_error "list needs OWNER/REPO"
  gh_parse_repo "$1"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --state)
        [ "$#" -ge 2 ] || gh_usage_error "--state needs a value"
        case "$2" in open | closed | all) state="$2" ;; *) gh_usage_error "--state is open, closed or all" ;; esac
        shift 2
        ;;
      --limit)
        [ "$#" -ge 2 ] || gh_usage_error "--limit needs a value"
        gh_require_count --limit "$2" 1000
        limit="$2"
        shift 2
        ;;
      *) gh_usage_error "unknown option for list: $1" ;;
    esac
  done
  gh_require_tools curl jq
  gh_require_access

  # GitHub's issues list also returns pull requests; they are left out, and
  # the limit applies after that.
  issues="$(gh_get_list "/repos/$GH_OWNER/$GH_REPO/issues?state=$state" "$limit" \
    'has("pull_request") | not')" || exit $?
  printf '%s' "$issues" | jq -r --arg repo "$GH_OWNER/$GH_REPO" --arg state "$state" '
    if length == 0 then "no \(if $state == "all" then "" else $state + " " end)issues in \($repo)"
    else .[]
      | "\($repo)#\(.number) [\(.state)] \(.title)"
        + (if (.labels | length) > 0 then " (" + ([.labels[].name] | join(", ")) + ")" else "" end)
    end'
}

issues_read() {
  local comments=5 issue total page batch shown
  [ "$#" -ge 1 ] || gh_usage_error "read needs OWNER/REPO#N"
  gh_parse_item "$1"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --comments)
        [ "$#" -ge 2 ] || gh_usage_error "--comments needs a value"
        if [ "$2" = "0" ]; then comments=0; else gh_require_count --comments "$2" 100; comments="$2"; fi
        shift 2
        ;;
      *) gh_usage_error "unknown option for read: $1" ;;
    esac
  done
  gh_require_tools curl jq
  gh_require_access

  issue="$(gh_request GET "/repos/$GH_OWNER/$GH_REPO/issues/$GH_NUMBER")" || exit $?
  printf '%s' "$issue" | jq -r --arg ref "$GH_OWNER/$GH_REPO#$GH_NUMBER" '
    "\($ref) [\(.state)] \(.title)",
    "author: @\(.user.login)"
      + (if (.labels | length) > 0 then "  labels: " + ([.labels[].name] | join(", ")) else "" end)
      + (if .pull_request then "  (this is a pull request; see pulls.sh read)" else "" end),
    "url: \(.html_url)",
    "",
    (if (.body // "") == "" then "(no description)" else .body end)'

  total="$(printf '%s' "$issue" | jq '.comments')"
  if [ "$comments" -eq 0 ] || [ "$total" -eq 0 ]; then
    return 0
  fi
  # The last N comments: the last page of 100, plus the page before it when
  # the last page holds fewer than N.
  page=$(((total + 99) / 100))
  batch="$(gh_request GET "/repos/$GH_OWNER/$GH_REPO/issues/$GH_NUMBER/comments?per_page=100&page=$page")" || exit $?
  if [ "$page" -gt 1 ] && [ "$(printf '%s' "$batch" | jq 'length')" -lt "$comments" ]; then
    batch="$(
      {
        gh_request GET "/repos/$GH_OWNER/$GH_REPO/issues/$GH_NUMBER/comments?per_page=100&page=$((page - 1))"
        printf '\n%s' "$batch"
      } | jq -s 'add'
    )" || exit $?
  fi
  shown="$(printf '%s' "$batch" | jq --argjson n "$comments" '.[-$n:]')"
  printf '%s' "$shown" | jq -r --argjson total "$total" '
    "",
    "--- comments (last \(length) of \($total)) ---",
    (.[] | "", "@\(.user.login) at \(.created_at):", .body)'
}

issues_create() {
  local title="" body_file="" body payload created
  [ "$#" -ge 1 ] || gh_usage_error "create needs OWNER/REPO"
  gh_parse_repo "$1"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --title)
        [ "$#" -ge 2 ] || gh_usage_error "--title needs a value"
        title="$2"
        shift 2
        ;;
      --body-file)
        [ "$#" -ge 2 ] || gh_usage_error "--body-file needs FILE or -"
        body_file="$2"
        shift 2
        ;;
      *) gh_usage_error "unknown option for create: $1" ;;
    esac
  done
  [ -n "$title" ] || gh_usage_error "create needs --title"
  [ -n "$body_file" ] || gh_usage_error "create needs --body-file FILE or -"
  gh_require_tools curl jq
  gh_require_access

  body="$(gh_read_body_file "$body_file")" || exit $?
  payload="$(jq -n --arg title "$title" --arg body "$body" '{title: $title, body: $body}')"
  created="$(gh_request POST "/repos/$GH_OWNER/$GH_REPO/issues" "$payload")" || exit $?
  printf '%s' "$created" | jq -r --arg repo "$GH_OWNER/$GH_REPO" '"\($repo)#\(.number) \(.html_url)"'
}

issues_comment() {
  local body_file="" body payload comment
  [ "$#" -ge 1 ] || gh_usage_error "comment needs OWNER/REPO#N"
  gh_parse_item "$1"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --body-file)
        [ "$#" -ge 2 ] || gh_usage_error "--body-file needs FILE or -"
        body_file="$2"
        shift 2
        ;;
      *) gh_usage_error "unknown option for comment: $1" ;;
    esac
  done
  [ -n "$body_file" ] || gh_usage_error "comment needs --body-file FILE or -"
  gh_require_tools curl jq
  gh_require_access

  body="$(gh_read_body_file "$body_file")" || exit $?
  payload="$(jq -n --arg body "$body" '{body: $body}')"
  comment="$(gh_request POST "/repos/$GH_OWNER/$GH_REPO/issues/$GH_NUMBER/comments" "$payload")" || exit $?
  printf '%s' "$comment" | jq -r --arg ref "$GH_OWNER/$GH_REPO#$GH_NUMBER" '"commented on \($ref): \(.html_url)"'
}

[ "$#" -ge 1 ] || gh_usage_error "a command is needed"
command="$1"
shift
case "$command" in
  list) issues_list "$@" ;;
  read) issues_read "$@" ;;
  create) issues_create "$@" ;;
  comment) issues_comment "$@" ;;
  -h | --help | help) printf '%s\n' "$GH_USAGE" ;;
  *) gh_usage_error "unknown command: $command" ;;
esac
