#!/usr/bin/env bash
# GitHub pull requests through AutoByteus: list, read, open.
# Push the branch first with git, using the https://github.com/OWNER/REPO.git
# URL (AutoByteus redirects it); an SSH remote does not go through AutoByteus.
set -euo pipefail
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

GH_USAGE="usage:
  pulls.sh list OWNER/REPO [--state open|closed|all] [--limit N]
  pulls.sh read OWNER/REPO#N
  pulls.sh open OWNER/REPO --head BRANCH --base BRANCH --title TEXT --body-file FILE|- [--draft]"

# The head branch as GitHub shows it: OWNER:BRANCH when it is in a fork.
PULL_HEAD='(if .head.repo != null and .head.repo.full_name == .base.repo.full_name then .head.ref else .head.label end)'
PULL_STATE='(if .merged_at != null then "merged" else .state end) + (if .draft then ", draft" else "" end)'

pulls_list() {
  local state=open limit=30 pulls
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

  pulls="$(gh_get_list "/repos/$GH_OWNER/$GH_REPO/pulls?state=$state" "$limit")" || exit $?
  printf '%s' "$pulls" | jq -r --arg repo "$GH_OWNER/$GH_REPO" --arg state "$state" "
    if length == 0 then \"no \(if \$state == \"all\" then \"\" else \$state + \" \" end)pull requests in \(\$repo)\"
    else .[] | \"\(\$repo)#\(.number) [\($PULL_STATE)] \(.title) (\($PULL_HEAD) → \(.base.ref))\"
    end"
}

pulls_read() {
  local pull files
  [ "$#" -eq 1 ] || gh_usage_error "read needs exactly OWNER/REPO#N"
  gh_parse_item "$1"
  gh_require_tools curl jq
  gh_require_access

  pull="$(gh_request GET "/repos/$GH_OWNER/$GH_REPO/pulls/$GH_NUMBER")" || exit $?
  files="$(gh_get_list "/repos/$GH_OWNER/$GH_REPO/pulls/$GH_NUMBER/files" 3000)" || exit $?
  printf '%s\n%s' "$pull" "$files" | jq -r -s --arg ref "$GH_OWNER/$GH_REPO#$GH_NUMBER" "
    .[0] as \$pull | .[1] as \$files | \$pull |
    \"\(\$ref) [\($PULL_STATE)] \(.title)\",
    \"author: @\(.user.login)\",
    \"branches: \($PULL_HEAD) → \(.base.ref)\",
    \"mergeable: \(if .mergeable == null then \"unknown (GitHub is still checking; read again shortly)\" else .mergeable end)\",
    \"url: \(.html_url)\",
    \"\",
    \"changed files (\(\$files | length)):\",
    (\$files[] | \"  +\(.additions) -\(.deletions) \(.filename)\"),
    \"\",
    (if (.body // \"\") == \"\" then \"(no description)\" else .body end)"
}

pulls_open() {
  local head="" base="" title="" body_file="" draft=false body payload created
  [ "$#" -ge 1 ] || gh_usage_error "open needs OWNER/REPO"
  gh_parse_repo "$1"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --head | --base | --title | --body-file)
        [ "$#" -ge 2 ] || gh_usage_error "$1 needs a value"
        case "$1" in
          --head) head="$2" ;;
          --base) base="$2" ;;
          --title) title="$2" ;;
          --body-file) body_file="$2" ;;
        esac
        shift 2
        ;;
      --draft)
        draft=true
        shift
        ;;
      *) gh_usage_error "unknown option for open: $1" ;;
    esac
  done
  [ -n "$head" ] || gh_usage_error "open needs --head BRANCH"
  [ -n "$base" ] || gh_usage_error "open needs --base BRANCH"
  [ -n "$title" ] || gh_usage_error "open needs --title"
  [ -n "$body_file" ] || gh_usage_error "open needs --body-file FILE or -"
  gh_require_tools curl jq
  gh_require_access

  body="$(gh_read_body_file "$body_file")" || exit $?
  payload="$(jq -n --arg head "$head" --arg base "$base" --arg title "$title" --arg body "$body" \
    --argjson draft "$draft" '{title: $title, head: $head, base: $base, body: $body, draft: $draft}')"
  created="$(gh_request POST "/repos/$GH_OWNER/$GH_REPO/pulls" "$payload")" || exit $?
  printf '%s' "$created" | jq -r --arg repo "$GH_OWNER/$GH_REPO" '"\($repo)#\(.number) \(.html_url)"'
}

[ "$#" -ge 1 ] || gh_usage_error "a command is needed"
command="$1"
shift
case "$command" in
  list) pulls_list "$@" ;;
  read) pulls_read "$@" ;;
  open) pulls_open "$@" ;;
  -h | --help | help) printf '%s\n' "$GH_USAGE" ;;
  *) gh_usage_error "unknown command: $command" ;;
esac
