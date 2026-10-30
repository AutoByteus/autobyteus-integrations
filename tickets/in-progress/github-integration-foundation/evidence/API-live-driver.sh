#!/usr/bin/env bash
# Temporary live driver for autobyteus-integrations-1 API/E2E (API-10…API-15).
# Runs INSIDE the AutoByteus agent run's shell (Codex), so the skill scripts see exactly the agent's environment:
# AUTOBYTEUS_GITHUB_API_URL and git's insteadOf redirection from the app's credential proxy. No token is used here.
# Every command's stdout, stderr and exit code go to <outdir>/steps.log; the run pass is masked (rp_<pass>).
# Usage: driver.sh <phase A|B|C> <outdir>
set -u
PHASE="$1"; OUT="$2"
S=/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation/github/scripts
REPO=AutoByteus/autobyteus-integrations-test
STATE=/tmp/gh-int-live/out/driver-state.env
mkdir -p "$OUT"; LOG="$OUT/steps.log"
mask() { sed -E 's/rp_[A-Za-z0-9_-]+/rp_<pass>/g'; }
# step NAME CMD... : run CMD, record it; sets $RC and $STDOUT
step() {
  local name="$1"; shift
  local o="$OUT/.o" e="$OUT/.e"
  "$@" >"$o" 2>"$e"; RC=$?
  STDOUT="$(cat "$o")"
  { echo "=== $name"; echo "\$ $*"; echo "--- exit: $RC"; echo "--- stdout:"; cat "$o"; echo "--- stderr:"; cat "$e"; echo; } | mask >>"$LOG"
}
# stdin_step NAME STDIN CMD...
stdin_step() {
  local name="$1" input="$2"; shift 2
  local o="$OUT/.o" e="$OUT/.e"
  printf '%s' "$input" | "$@" >"$o" 2>"$e"; RC=$?
  STDOUT="$(cat "$o")"
  { echo "=== $name"; echo "\$ printf '%s' <stdin below> | $*"; echo "--- stdin:"; printf '%s\n' "$input"; echo "--- exit: $RC"; echo "--- stdout:"; cat "$o"; echo "--- stderr:"; cat "$e"; echo; } | mask >>"$LOG"
}
num_of() { sed -nE 's/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+#([0-9]+).*/\1/p' | head -1; }
# Raw board read-back, independent of board.sh: every item with its content and Status, plus GraphQL errors as GitHub sent them.
raw_board() {
  local q='query { organization(login: "AutoByteus") { projectV2(number: 1) { title items(first: 100) { nodes { id type isArchived content { __typename ... on Issue { number title repository { nameWithOwner } } ... on PullRequest { number title repository { nameWithOwner } } } fieldValueByName(name: "Status") { ... on ProjectV2ItemFieldSingleSelectValue { name } } } } } } }'
  curl -sS -X POST -H 'Accept: application/vnd.github+json' -H 'Content-Type: application/json' \
    --data "$(jq -n --arg q "$q" '{query: $q}')" "$AUTOBYTEUS_GITHUB_API_URL/graphql"
}

{ echo "# driver phase $PHASE, $(date -u +%Y-%m-%dT%H:%M:%SZ), shell: bash $BASH_VERSION, $(uname -sm)";
  echo "# AUTOBYTEUS_GITHUB_API_URL=${AUTOBYTEUS_GITHUB_API_URL:-<unset>}"; echo "# GIT_CONFIG_COUNT=${GIT_CONFIG_COUNT:-<unset>} GIT_TERMINAL_PROMPT=${GIT_TERMINAL_PROMPT:-<unset>}";
  for i in $(seq 0 $(( ${GIT_CONFIG_COUNT:-0} - 1 ))); do k="GIT_CONFIG_KEY_$i"; v="GIT_CONFIG_VALUE_$i"; echo "# $k=${!k} $v=${!v}"; done
  echo; } | mask >"$LOG"

case "$PHASE" in
A)
  TAG="$(date -u +%Y%m%d%H%M%S)"
  echo "TAG=$TAG" >"$STATE"
  step "A01 check-access" "$S/check-access.sh"
  printf 'Line one with "double" and '"'"'single'"'"' quotes.\nLine two: $HOME `backticks` and a backslash \\ stay literal.\n\nCreated by the API/E2E live check %s.\n' "$TAG" >"$OUT/body-a.md"
  step "A02 issues create (quotes, newlines, from a file)" "$S/issues.sh" create "$REPO" --title "Live check $TAG: issue A \"quoted\"" --body-file "$OUT/body-a.md"
  A="$(printf '%s' "$STDOUT" | num_of)"; echo "A=$A" >>"$STATE"
  stdin_step "A03 issues comment --body-file -" "$(printf 'Comment one from stdin.\nSecond line "quoted" and $(not run).\n')" "$S/issues.sh" comment "$REPO#$A" --body-file -
  printf 'Comment two from a file (%s).\n' "$TAG" >"$OUT/comment-2.md"
  step "A04 issues comment --body-file FILE" "$S/issues.sh" comment "$REPO#$A" --body-file "$OUT/comment-2.md"
  printf 'Comment three (%s).\n' "$TAG" >"$OUT/comment-3.md"
  step "A05 issues comment (third)" "$S/issues.sh" comment "$REPO#$A" --body-file "$OUT/comment-3.md"
  step "A06 issues read --comments 2" "$S/issues.sh" read "$REPO#$A" --comments 2
  # DS-003: push with the https URL, through git's insteadOf to the proxy
  rm -rf "$OUT/clone"
  step "A07 git clone https URL" git clone -q "https://github.com/$REPO.git" "$OUT/clone"
  BR="live-check/$TAG"; echo "BR=$BR" >>"$STATE"
  ( cd "$OUT/clone" && git checkout -q -b "$BR" && printf 'live check %s\n' "$TAG" >"live-check-$TAG.txt" && git add . \
    && git -c user.name="AutoByteus API-E2E" -c user.email="api-e2e@autobyteus.invalid" commit -q -m "Live check $TAG" ) >>"$LOG" 2>&1
  step "A08 git remote (unchanged https URL)" git -C "$OUT/clone" remote get-url origin
  step "A09 git push -u origin BRANCH" git -C "$OUT/clone" push -u origin "$BR"
  printf 'PR body for the live check %s.\n\n- item "one"\n- item two\n' "$TAG" >"$OUT/pr.md"
  step "A10 pulls open" "$S/pulls.sh" open "$REPO" --head "$BR" --base main --title "Live check $TAG: PR" --body-file "$OUT/pr.md"
  P="$(printf '%s' "$STDOUT" | num_of)"; echo "P=$P" >>"$STATE"
  step "A11 pulls read" "$S/pulls.sh" read "$REPO#$P"
  step "A12 pulls list" "$S/pulls.sh" list "$REPO"
  step "A13 pulls open --head missing branch (expect 422, exit 4)" "$S/pulls.sh" open "$REPO" --head "does-not-exist-$TAG" --base main --title "Should fail" --body-file "$OUT/pr.md"
  stdin_step "A14 issues comment on the PR" "$(printf 'Comment on the PR (%s).\n' "$TAG")" "$S/issues.sh" comment "$REPO#$P" --body-file -
  step "A15 issues list (open; the open PR must not appear)" "$S/issues.sh" list "$REPO"
  step "A16 issues list --state all --limit 1" "$S/issues.sh" list "$REPO" --state all --limit 1
  printf 'Board item for the live check %s.\n' "$TAG" >"$OUT/body-b.md"
  step "A17 issues create (issue B, for the board)" "$S/issues.sh" create "$REPO" --title "Live check $TAG: issue B (board)" --body-file "$OUT/body-b.md"
  B="$(printf '%s' "$STDOUT" | num_of)"; echo "B=$B" >>"$STATE"
  step "A18 board move B (not on the board) In Progress" "$S/board.sh" move "$REPO#$B" --owner AutoByteus --number 1 --status "In Progress"
  step "A19 board items --status 'in progress'" "$S/board.sh" items --owner AutoByteus --number 1 --status "in progress"
  step "A20 board move B --status done (other spelling)" "$S/board.sh" move "$REPO#$B" --owner AutoByteus --number 1 --status done
  step "A21 board move PR --status todo" "$S/board.sh" move "$REPO#$P" --owner AutoByteus --number 1 --status todo
  step "A22 board items" "$S/board.sh" items --owner AutoByteus --number 1
  step "A23 board items --status DONE" "$S/board.sh" items --owner AutoByteus --number 1 --status DONE
  step "A24 board move unknown status (expect exit 2 with the names)" "$S/board.sh" move "$REPO#$B" --owner AutoByteus --number 1 --status Blocked
  step "A25 raw GraphQL board read-back (not board.sh)" raw_board
  ;;
B)
  # CG-08: the board holds an item from a repository outside the token's list
  step "B01 raw GraphQL board read-back (not board.sh)" raw_board
  step "B02 board items" "$S/board.sh" items --owner AutoByteus --number 1
  step "B03 board items --status todo" "$S/board.sh" items --owner AutoByteus --number 1 --status todo
  ;;
G)
  # CG-08 control: the same item, first inside the token's list (visible), before the host transfers it out again
  step "G01 board move AutoByteus/autobyteus-integrations-test#5 --status todo" "$S/board.sh" move "$REPO#5" --owner AutoByteus --number 1 --status todo
  sleep 30
  step "G02 board items (30 s later)" "$S/board.sh" items --owner AutoByteus --number 1
  q='query { organization(login: "AutoByteus") { projectV2(number: 1) { items(first: 100) { totalCount nodes { id type content { __typename ... on Issue { number repository { nameWithOwner } } ... on PullRequest { number } } } } } } }'
  step "G03 raw GraphQL items totalCount + nodes" curl -sS -X POST -H 'Content-Type: application/json' --data "$(jq -n --arg q "$q" '{query: $q}')" "$AUTOBYTEUS_GITHUB_API_URL/graphql"
  ;;
B2)
  # CG-08 recheck: totalCount next to the nodes, as the token sees them
  q='query { organization(login: "AutoByteus") { projectV2(number: 1) { items(first: 100) { totalCount nodes { id type content { __typename ... on Issue { number repository { nameWithOwner } } ... on PullRequest { number } } } } } } }'
  step "B2-01 raw GraphQL items totalCount + nodes" curl -sS -X POST -H 'Content-Type: application/json' --data "$(jq -n --arg q "$q" '{query: $q}')" "$AUTOBYTEUS_GITHUB_API_URL/graphql"
  step "B2-02 board items" "$S/board.sh" items --owner AutoByteus --number 1
  ;;
C)
  # Real refusals through the proxy
  step "C01 issues read, private repo outside the token's list (expect 404, exit 4)" "$S/issues.sh" read "AutoByteus/autobyteus-server#6"
  stdin_step "C02 issues comment, public repo outside the token's list (expect 403, exit 4)" "$(printf 'Should be refused.\n')" "$S/issues.sh" comment "AutoByteus/autobyteus-workspace#2" --body-file -
  step "C03 board items, user-owned board (expect GraphQL errors, exit 4)" "$S/board.sh" items --owner ryan-zheng-teki --number 1
  step "C04 board items, org board number that does not exist (expect exit 4)" "$S/board.sh" items --owner AutoByteus --number 999
  ;;
R)
  # Recheck of A22 (the PR item added in A21 was missing from the listing seconds later)
  step "R01 board items" "$S/board.sh" items --owner AutoByteus --number 1
  step "R02 board items --status todo" "$S/board.sh" items --owner AutoByteus --number 1 --status todo
  step "R03 raw GraphQL board read-back (not board.sh)" raw_board
  ;;
F)
  # Fixture for CG-08, not a skill call: add AutoByteus/autobyteus-server#6 (private, outside the token's list) by node ID
  pid_q='query { organization(login: "AutoByteus") { projectV2(number: 1) { id } } }'
  PROJECT="$(curl -sS -X POST -H 'Content-Type: application/json' --data "$(jq -n --arg q "$pid_q" '{query: $q}')" "$AUTOBYTEUS_GITHUB_API_URL/graphql" | jq -r '.data.organization.projectV2.id')"
  echo "PROJECT=$PROJECT" >>"$STATE"
  add_m='mutation($p: ID!, $c: ID!) { addProjectV2ItemById(input: {projectId: $p, contentId: $c}) { item { id type } } }'
  step "F01 add outside item by node ID (fixture, raw GraphQL)" curl -sS -X POST -H 'Content-Type: application/json' \
    --data "$(jq -n --arg q "$add_m" --arg p "$PROJECT" --arg c "I_kwDONPysk86kDgoP" '{query: $q, variables: {p: $p, c: $c}}')" "$AUTOBYTEUS_GITHUB_API_URL/graphql"
  ;;
F2)
  # Fixture for CG-08 (second way): issue C on the board; the host then transfers it to a private repository outside
  # the token's list (GitHub keeps transferred issues on organisation-wide boards).
  . "$STATE"
  printf 'CG-08 fixture for the live check %s; transferred out and back by the tester.\n' "$TAG" >"$OUT/body-c.md"
  step "F2-01 issues create (issue C)" "$S/issues.sh" create "$REPO" --title "Live check $TAG: issue C (CG-08 fixture)" --body-file "$OUT/body-c.md"
  C="$(printf '%s' "$STDOUT" | num_of)"; echo "C=$C" >>"$STATE"
  step "F2-02 board move C --status todo" "$S/board.sh" move "$REPO#$C" --owner AutoByteus --number 1 --status todo
  ;;
X)
  # Cleanup: remove every item from board #1 that this run put there (by item ID, raw GraphQL)
  . "$STATE"
  del_m='mutation($p: ID!, $i: ID!) { deleteProjectV2Item(input: {projectId: $p, itemId: $i}) { deletedItemId } }'
  for item in $(raw_board | jq -r '.data.organization.projectV2.items.nodes[].id'); do
    step "X delete board item $item" curl -sS -X POST -H 'Content-Type: application/json' \
      --data "$(jq -n --arg q "$del_m" --arg p "$PROJECT" --arg i "$item" '{query: $q, variables: {p: $p, i: $i}}')" "$AUTOBYTEUS_GITHUB_API_URL/graphql"
  done
  step "X raw GraphQL board read-back after cleanup" raw_board
  ;;
*) echo "unknown phase $PHASE" >&2; exit 2 ;;
esac
rm -f "$OUT/.o" "$OUT/.e"
echo "DRIVER PHASE $PHASE DONE: $(grep -c '^=== ' "$LOG") steps, log $LOG"
