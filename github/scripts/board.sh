#!/usr/bin/env bash
# The GraphQL documents below are single-quoted on purpose: $name is GraphQL.
# shellcheck disable=SC2016
# GitHub Projects boards through AutoByteus (GraphQL): list items, move an item.
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

GH_USAGE="usage:
  board.sh items --owner LOGIN --number P [--status NAME]
  board.sh move OWNER/REPO#N --owner LOGIN --number P --status NAME
LOGIN is the user or organisation that owns the board; P is the board's number."

# The board of a user or an organisation, with its Status field and options.
BOARD_QUERY='query($login: String!, $number: Int!) {
  repositoryOwner(login: $login) {
    ... on Organization { projectV2(number: $number) { ...Board } }
    ... on User { projectV2(number: $number) { ...Board } }
  }
}
fragment Board on ProjectV2 {
  id
  title
  field(name: "Status") { ... on ProjectV2SingleSelectField { id options { id name } } }
}'

ITEMS_QUERY='query($id: ID!, $after: String) {
  node(id: $id) {
    ... on ProjectV2 {
      items(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isArchived
          status: fieldValueByName(name: "Status") { ... on ProjectV2ItemFieldSingleSelectValue { name } }
          content {
            __typename
            ... on Issue { number title repository { nameWithOwner } }
            ... on PullRequest { number title repository { nameWithOwner } }
            ... on DraftIssue { title }
          }
        }
      }
    }
  }
}'

# The issue or pull request with the boards it is on.
CONTENT_QUERY='query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    issueOrPullRequest(number: $number) {
      ... on Issue { id projectItems(first: 100) { nodes { id project { id } } } }
      ... on PullRequest { id projectItems(first: 100) { nodes { id project { id } } } }
    }
  }
}'

ADD_ITEM_MUTATION='mutation($project: ID!, $content: ID!) {
  addProjectV2ItemById(input: { projectId: $project, contentId: $content }) { item { id } }
}'

SET_STATUS_MUTATION='mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $project, itemId: $item, fieldId: $field, value: { singleSelectOptionId: $option }
  }) { projectV2Item { id } }
}'

# board_parse_options ARG...: parses --owner, --number and --status into
# BOARD_OWNER, BOARD_NUMBER and BOARD_STATUS.
board_parse_options() {
  BOARD_OWNER=""
  BOARD_NUMBER=""
  BOARD_STATUS=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --owner | --number | --status)
        [ "$#" -ge 2 ] || gh_usage_error "$1 needs a value"
        case "$1" in
          --owner) BOARD_OWNER="$2" ;;
          --number) BOARD_NUMBER="$2" ;;
          --status) BOARD_STATUS="$2" ;;
        esac
        shift 2
        ;;
      *) gh_usage_error "unknown option: $1" ;;
    esac
  done
  [[ "$BOARD_OWNER" =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]] || gh_usage_error "--owner needs the LOGIN of the board's user or organisation"
  gh_require_count --number "$BOARD_NUMBER" 1000000
}

# board_load: reads the board into BOARD (JSON: id, title, field id, options).
board_load() {
  local variables data
  variables="$(jq -n --arg login "$BOARD_OWNER" --argjson number "$BOARD_NUMBER" \
    '{login: $login, number: $number}')"
  data="$(gh_graphql "$BOARD_QUERY" "$variables")" || exit $?
  BOARD="$(printf '%s' "$data" | jq '.repositoryOwner.projectV2 // empty')"
  if [ -z "$BOARD" ] || [ "$BOARD" = "null" ]; then
    gh_fail 4 "No board number $BOARD_NUMBER of $BOARD_OWNER was found." "Next: $GH_PERMISSION_HINT."
  fi
  if [ "$(printf '%s' "$BOARD" | jq '.field.id != null')" != "true" ]; then
    gh_fail 4 "The board \"$(printf '%s' "$BOARD" | jq -r '.title')\" has no single-select Status field."
  fi
}

# board_option NAME: prints the option {id, name} matching NAME case-insensitively;
# stops listing the valid names when none matches.
board_option() {
  local option
  option="$(printf '%s' "$BOARD" | jq -c --arg name "$1" \
    '[.field.options[] | select((.name | ascii_downcase) == ($name | ascii_downcase))][0] // empty')"
  if [ -z "$option" ]; then
    gh_usage_error "unknown status \"$1\"; the board's statuses are: $(printf '%s' "$BOARD" \
      | jq -r '[.field.options[].name] | join(", ")')"
  fi
  printf '%s' "$option"
}

board_items() {
  local filter="" after=null variables data page items='[]'
  board_parse_options "$@"
  gh_require_tools curl jq
  gh_require_access
  board_load
  if [ -n "$BOARD_STATUS" ]; then
    filter="$(board_option "$BOARD_STATUS" | jq -r '.name')" || exit $?
  fi

  while :; do
    variables="$(jq -n --arg id "$(printf '%s' "$BOARD" | jq -r '.id')" --argjson after "$after" \
      '{id: $id, after: $after}')"
    data="$(gh_graphql "$ITEMS_QUERY" "$variables")" || exit $?
    page="$(printf '%s' "$data" | jq '.node.items')"
    items="$(printf '%s\n%s' "$items" "$page" | jq -s '.[0] + .[1].nodes')"
    [ "$(printf '%s' "$page" | jq '.pageInfo.hasNextPage')" = "true" ] || break
    after="$(printf '%s' "$page" | jq '.pageInfo.endCursor')"
  done

  printf '%s' "$items" | jq -r --arg filter "$filter" --arg board "$(printf '%s' "$BOARD" | jq -r '.title')" '
    [.[] | select(.isArchived | not)
      | . + {statusName: (.status.name // "No status")}
      | select($filter == "" or .statusName == $filter)]
    | if length == 0 then "no items\(if $filter == "" then "" else " in " + $filter end) on \($board)"
      else .[] | (if .content == null then "(hidden)"
          elif .content.__typename == "DraftIssue" then "(draft)"
          else "\(.content.repository.nameWithOwner)#\(.content.number)" end)
        + " [\(.statusName)] \(.content.title // "(the token cannot see this item)")"
      end'
}

board_move() {
  local ref option variables data content item added=no project
  [ "$#" -ge 1 ] || gh_usage_error "move needs OWNER/REPO#N"
  gh_parse_item "$1"
  ref="$GH_OWNER/$GH_REPO#$GH_NUMBER"
  shift
  board_parse_options "$@"
  [ -n "$BOARD_STATUS" ] || gh_usage_error "move needs --status NAME"
  gh_require_tools curl jq
  gh_require_access
  board_load
  option="$(board_option "$BOARD_STATUS")" || exit $?
  project="$(printf '%s' "$BOARD" | jq -r '.id')"

  variables="$(jq -n --arg owner "$GH_OWNER" --arg name "$GH_REPO" --argjson number "$GH_NUMBER" \
    '{owner: $owner, name: $name, number: $number}')"
  data="$(gh_graphql "$CONTENT_QUERY" "$variables")" || exit $?
  content="$(printf '%s' "$data" | jq -r '.repository.issueOrPullRequest.id // empty')"
  [ -n "$content" ] || gh_fail 4 "No issue or pull request $ref was found." "Next: $GH_PERMISSION_HINT."
  item="$(printf '%s' "$data" | jq -r --arg project "$project" \
    '[.repository.issueOrPullRequest.projectItems.nodes[] | select(.project.id == $project) | .id][0] // empty')"

  if [ -z "$item" ]; then
    variables="$(jq -n --arg project "$project" --arg content "$content" '{project: $project, content: $content}')"
    data="$(gh_graphql "$ADD_ITEM_MUTATION" "$variables")" || exit $?
    item="$(printf '%s' "$data" | jq -r '.addProjectV2ItemById.item.id')"
    added=yes
  fi

  variables="$(printf '%s' "$option" | jq --arg project "$project" --arg item "$item" \
    --arg field "$(printf '%s' "$BOARD" | jq -r '.field.id')" \
    '{project: $project, item: $item, field: $field, option: .id}')"
  gh_graphql "$SET_STATUS_MUTATION" "$variables" >/dev/null || exit $?

  if [ "$added" = yes ]; then
    printf 'added %s to the board; moved to %s\n' "$ref" "$(printf '%s' "$option" | jq -r '.name')"
  else
    printf 'moved %s to %s\n' "$ref" "$(printf '%s' "$option" | jq -r '.name')"
  fi
}

[ "$#" -ge 1 ] || gh_usage_error "a command is needed"
command="$1"
shift
case "$command" in
  items) board_items "$@" ;;
  move) board_move "$@" ;;
  -h | --help | help) printf '%s\n' "$GH_USAGE" ;;
  *) gh_usage_error "unknown command: $command" ;;
esac
