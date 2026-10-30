# Implementation Handoff — github-integration-foundation (autobyteus-integrations-1)

## Upstream Artifact Package

All paths are in the ticket folder
`/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation/tickets/in-progress/github-integration-foundation/`.

- Upstream review applicability and handoff-rule result: architecture review selected (Medium / High) and passed at `ARCH-REV-002`; the architecture reviewer sent the package for implementation.
- Requirements doc: `requirements-doc.md` (SR-008)
- Investigation notes: `investigation-notes.md`
- Solution revision record: `solution-revision-record.md` (SR-008)
- Design spec (required on every route): `design-spec.md` (SR-008)
- Supplemental task artifacts: `integration-manifest-contract.md` (behavior-defining, SR-006; the authority for `integration.json` and the folder rules); `follow-ups.md` (FU-001)
- Design review report: `design-review-report.md` (ARCH-REV-002, Pass; AR-010 non-blocking)
- Architecture review revision record: `architecture-review-revision-record.md`
- Triggering rework report, revision record, or evidence: N/A (initial)
- Which text governs (AR-010): the AC table (AC-001, AC-008, AC-009), DEC-007 and design Change Sequence steps 5–6. `handoff-architecture-design-complete.md` § Scope notes ("AC-001/AC-008 wait for 337") is superseded. "(311)" at `design-spec.md:26` and `:204` means the Integrations page, autobyteus-337.

## Current Implementation Summary

The repository now holds the documented integration definition, a repository check, and the first integration, `github/`. No app change.

- `docs/integration-manifest.md`: the folder layout, every `integration.json` field, the rules for scripts and how to add an integration, written from `integration-manifest-contract.md`. The contract's validation history (SR-005/SR-006 tables) stays in the ticket, not in the doc.
- `tools/check-integrations.sh`: the AC-002 checks for every top-level folder.
- `github/integration.json`: the contract's example, unchanged.
- `github/SKILL.md`: `name: github-integration`; checking access first; the commands; pushing with the `https://` URL; plain `curl` and `GH_TOKEN=unused gh api` for other calls (DEC-004); the rules (no token, no `gh auth`, do not print the address); working across nodes with `OWNER/REPO#N` and an example description (REQ-009, AC-007); what each exit code means.
- `github/scripts/lib.sh`: the only request path, and it owns Error Rules 1–4. Its parts: the tool and access checks; `gh_request` (one `curl` call to `$AUTOBYTEUS_GITHUB_API_URL`); `gh_graphql`; `gh_get_list` (REST pages); reference and body-file parsing.
- `github/scripts/check-access.sh`, `issues.sh`, `pulls.sh`, `board.sh`: one subject each, as in the design's Interface Boundary Mapping.
- `tests/github/fake-api.py`, `tests/github/run-tests.sh`: 24 deterministic cases against a local stand-in for the proxy. There is one case per error rule (Rule 5); every proxy code is covered.
- `README.md`: the whole 244-era "What an integration is" and "Status" paragraphs are replaced. The README now covers what an integration is; the available integrations; today's install journey with the terminal-tool/sandbox note and the `https://` push note; the app version; that the journey moves to the Integrations page with autobyteus-337; the repository checks. The licence note is kept.

- Implementation cycle: `Initial`
- Implementation revision record: `implementation-revision-record.md`
- Current implementation revision ID: `IR-001`
- Related solution revision IDs: `SR-008`
- Related architecture-review revision IDs: `ARCH-REV-002`
- Related code-review revision IDs: `N/A`
- Related API/E2E revision IDs: `N/A`
- Related delivery revision IDs: `N/A`
- Triggering finding IDs: `N/A`
- Branch `codex/github-integration-foundation`, worktree `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation`. Code commit `3192aec` (on `a0b5d50`, base `origin/main` `6fa9bbc`); this handoff and the evidence are in the next commit on the branch. Not pushed.

## Routing Classification (Mandatory)

- Task size: `Medium`
- Architecture risk: `High`
- Design classification section / evidence reference: `design-spec.md` § Task Size And Architectural Risk
- Classification confirmed or changed: `Confirmed`
- Evidence and rationale: 13 new or changed files in one new repository, one capability area, no app code (Medium). The change creates the public `integration.json` / folder contract, and the first credential-backed write path (comments, issues, PRs, board moves) through the proxy (High). Nothing found during implementation changes either.
- Selected route: `Code Review`
- Lightweight implementation self-review completed for the direct route: `Not Applicable` (High risk goes to the Code Reviewer)
- New design impact or escalation trigger: `None`. No app or proxy-contract change was needed.

## Reviewed Behavior Implementation Trace

| Behavior ID | Approved Change / Preserved Outcome | Implemented Production Path / Key Files | Result / Notes |
| --- | --- | --- | --- |
| BEH-001 (REQ-001, AC-001) | Repository installs as one GitHub skill source | `github/SKILL.md` is the only top-level `SKILL.md`; `docs/`, `tools/`, `tests/`, `tickets/` have none; skill name `github-integration` | Shape done; AC-001 runs at delivery (DEC-007) |
| BEH-002 (REQ-004…008, AC-003…006) | Scripts on the proxy contract only | DS-002: `issues.sh`/`pulls.sh`/`board.sh`/`check-access.sh` → `lib.sh gh_request` → `curl "$AUTOBYTEUS_GITHUB_API_URL$path"` → status/body → Error Rules 1–4 → short line or refusal with `Next:`. DS-003: plain `git push` to the `https://github.com/` URL (SKILL.md, README) | Deterministic: IMP-01, IMP-04. Live (AC-003…006) not run here |
| BEH-002 / REQ-008 | Never a token; unset variable → how to give access, stop | `lib.sh gh_require_access` (exit 3); no token variable, `gh auth`, `api.github.com` or `Authorization` in script code; scripts send no `Authorization` | Cases "no AUTOBYTEUS_GITHUB_API_URL", "no request carried a token…", "the scripts name no token variable…" |
| BEH-004 (REQ-002, REQ-010, AC-002) | `integration.json` + documented contract | `github/integration.json`; `docs/integration-manifest.md`; `tools/check-integrations.sh` (required fields, unknown fields incl. `token.*`, ID pattern, half-folder rule, secret-looking values, `SKILL.md` name) | IMP-02: repository passes; 11 broken fixtures each fail with their rule |
| BEH-005 (REQ-009, AC-007) | Cross-node rules in the skill | `github/SKILL.md` § Working across nodes, with an example description carrying `OWNER/REPO#N` | Review item (AC-007) |
| BEH-003 | README describes the integrations | `README.md` | 244-era paragraphs replaced |

- Changes stayed within the requirements doc's Scope Guardrail: `Yes`

## Key Files Or Areas

| File | Lines (non-empty) | Notes |
| --- | --- | --- |
| `github/scripts/lib.sh` | 237 | Error Rules 1–4 are in `gh_request`, `gh_check_graphql_errors`, `gh_explain_refusal` |
| `github/scripts/issues.sh` | 155 | PR filter: `gh_get_list … 'has("pull_request") | not'`; the limit applies after the filter |
| `github/scripts/pulls.sh` | 110 | |
| `github/scripts/board.sh` | 182 | Five GraphQL documents. The board is found through `repositoryOwner` with `Organization`/`User` fragments, so no guess is needed for the owner kind. The item is found through `issueOrPullRequest.projectItems` and is added when absent |
| `github/scripts/check-access.sh` | 13 | |
| `tools/check-integrations.sh` | 119 | `[REPOSITORY_ROOT]` argument (used for the fixtures) |
| `tests/github/run-tests.sh`, `fake-api.py` | test | Stand-in serves `/r/rp_test/github/api/…`, matches GraphQL calls by a body substring, logs every request |

## Important Assumptions

Implementation decisions inside the design's room, for the reviewer to judge:

1. **Missing tool → exit 5.** The design's exit table has no slot for a missing tool. 5 ("failed") was chosen; the message is "jq is needed; install it, then run again". SKILL.md lists it under 5.
2. **Unknown board status → exit 2 (usage)**, listing the board's statuses (`board.sh move` and `items --status`). Nothing is changed.
3. Defaults the design left open: `--limit` 30 (1–1000); `issues.sh read --comments` 5 (0 hides comments, max 100).
4. `issues.sh create` and `pulls.sh open` require `--body-file`, as the design's syntax shows (no brackets).
5. `lib.sh` also holds the shared argument helpers: `OWNER/REPO` and `OWNER/REPO#N` parsing (strict pattern; `.`/`..` refused), number checks, and reading `--body-file`. These are reference formats every subject shares, not subject logic. `gh_get_list` takes the caller's jq `select` filter, so the issues-without-PRs rule stays in `issues.sh`.
6. **No leak of the run pass.** Refusal messages name the method and the path without the query, never `AUTOBYTEUS_GITHUB_API_URL`. A curl failure prints only curl's exit code. SKILL.md tells agents not to print the address: `credential_proxy.md` § Security Limits calls the pass a bearer capability. This is a rule in the spirit of REQ-008, not new behavior.
7. Request headers: `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`, User-Agent `autobyteus-github-integration`, `--connect-timeout 10`. Redirects are not followed.
8. `board.sh items` leaves out archived items. Items the token can't see print as `(hidden)`, and drafts print as `(draft)`.
9. A proxy code the scripts don't know (for example `UPSTREAM_REJECTED_TOKEN`, which is git-only) gets the proxy's message, with exit 5 for a 5xx status and 4 otherwise.
10. The scripts are bash-3.2 compatible (macOS `/bin/bash`), checked on macOS and on bash 5.2 in the server image.

## Known Risks

- R-1/R-2 (design): the GraphQL documents, the REST field names, and the write paths through the real proxy are proven only against the stand-in. The schema and field names were checked by reading GitHub's API; a mistake shows only in the live check.
- `pulls.sh open --draft` on a private repository needs a GitHub plan that allows draft PRs there. GitHub answers 422 otherwise, and the scripts explain that answer.
- FU-001 (ambient `gh` login on this node) is unchanged and stays with the Solution Designer.
- The ticket folder is committed and will be public. It names local paths and the secrets file path, but holds no secret value: a scan for GitHub token patterns found only the tests' fake sentinel `ghp_SENTINEL…`.

## Task Design Health Assessment Implementation Check

- Reviewed change posture: Feature (new content in a new repository)
- Reviewed root-cause classification: No Design Issue Found
- Reviewed refactor decision: `No Refactor Needed`
- Implementation matched the reviewed assessment: `Yes`
- If challenged, routed as `Design Impact`: `N/A`
- Evidence / notes: the request, error and output handling shared by the three subject scripts lives once, in `lib.sh` (Principle 13). No subject script calls `curl` itself.

## Legacy / Compatibility Removal Check

- Backward-compatibility mechanisms introduced: `None` (no `gh` login fallback, no version field)
- Legacy old-behavior retained in scope: `No`. The README's 244-era text ("platform supplies them only when a command runs", "may also carry its MCP server entry", "No integration is published yet") is removed.
- Dead code in the touched files and modules removed: `Yes` (new files; nothing unused. Shellcheck is clean)
- Dead code found elsewhere, added to `follow-ups.md`: None
- Shared structures remain tight: `Yes` (`integration.json` has exactly the contract's fields)
- Canonical shared design guidance was reapplied during implementation: `Yes`
- Changed source files within size guardrails: `Yes` (largest is `lib.sh`, 237 non-empty lines)
- Notes: —

## Persisted Data Transition Check (When Applicable)

- Approved decision: `Not Affected` (`design-spec.md` § Persisted Data / State Transition Decision); no stored data.

## Environment Or Dependency Notes

- This repository has no `TESTING.md` or `DESIGN.md`. Commands come from the design's Verification Intent and the README.
- Local tools: macOS 26.5, `/bin/bash` 3.2.57, curl 8.x, jq 1.7.1, Python 3.9.6, shellcheck 0.11.0. Server image `autobyteus/autobyteus-server:beta` (ab4a15444f52): bash 5.2.21, jq 1.7, curl 8.5.0, Python 3.13.

## Checks Run

Evidence is in `tickets/in-progress/github-integration-foundation/evidence/`.

| Check ID | Command Or Steps | Commit Tested | Environment | Code It Exercises | Behavior / Criteria IDs | Result | Evidence Files | Look For |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IMP-01 | `tests/github/run-tests.sh` | `3192aec` | macOS 26.5, bash 3.2.57 | `github/scripts/*`, `tests/github/*` | BEH-002, REQ-004…008, Error Rules 1–5, review notes AR-006…AR-009 | Pass | `IMP-01-run-tests-macos.log` | `24 passed, 0 failed` |
| IMP-02 | `tools/check-integrations.sh` on the repository and on 13 fixture folders (one per broken rule) | `3192aec` | macOS 26.5 | `tools/check-integrations.sh`, `github/integration.json`, `github/SKILL.md` | AC-002, REQ-002, half-folder rule | Pass | `IMP-02-check-integrations.log` | `all 1 integration folder(s) pass`; fixtures `11 problem(s) in 13 integration folder(s)`, one `FAIL` line per broken folder |
| IMP-03 | `shellcheck -x -P SCRIPTDIR -s bash github/scripts/*.sh tools/check-integrations.sh tests/github/run-tests.sh` | `3192aec` | shellcheck 0.11.0 | all shell files | — | Pass | `IMP-03-shellcheck.log` | `exit 0` with no findings |
| IMP-04 | `docker run --rm --network none … autobyteus/autobyteus-server:beta`: `run-tests.sh` and `check-integrations.sh` | `3192aec` | Linux server image, bash 5.2.21, no network | same as IMP-01, IMP-02 | REQ-003 (tools present in the released image) | Pass | `IMP-04-run-tests-linux-image.log` | `24 passed, 0 failed`; `all 1 integration folder(s) pass` |
| IMP-05 | `run-tests.sh` against copies of `github/` with one deliberate defect each (6 defects) | `3192aec` | macOS 26.5 | the tests themselves | Error Rules 1, 2, 4; PR filter; add-then-move; no token | Pass (each defect caught) | `IMP-05-tests-catch-defects.log` | each block ends `23 passed, 1 failed` (token defect: `21 passed, 3 failed`) |

- Not run, and why:
  - The live check through a real app proxy (Change Sequence step 4: AC-003…AC-006 live, R-1/R-2, the token scan of AC-006). It needs an isolated `v1.5.11-beta.4` instance with its own vault, the test token sent once, and an agent run. That environment and its sign-off belong to API/E2E.
  - AC-001 and AC-008: delivery, after finalization on `main` (DEC-007).
  - AC-007: a review item.
  - AC-009: this ticket's final round, after autobyteus-337.

## Frontend Rendered-Result Check (When Applicable)

`Not Applicable`: no app or UI change. The repository holds shell scripts and Markdown.

## Downstream Coverage Hints / Suggested Scenarios

Live target: `AutoByteus/autobyteus-integrations-test`, board `--owner AutoByteus --number 1` (Todo, In Progress, Done). The token is in `~/.autobyteus-test/secrets/github-integration-test.env`, key `GITHUB_INTEGRATION_TEST_TOKEN`; send it once with `connectGitHubIntegration`, never print it. Use this worktree's folder as a local skill source, tick the agent and give it `github-integration`.

1. `check-access.sh` → `GitHub access: connected as @<token owner>`.
2. `issues.sh list` (an open PR must not appear), `read --comments 2`, `create` (body with quotes and newlines), `comment` with `--body-file -`.
3. Push a branch with the `https://github.com/AutoByteus/autobyteus-integrations-test.git` URL, then `pulls.sh open` → `OWNER/REPO#N`, then `pulls.sh read` (files, mergeable). Then `pulls.sh open --head does-not-exist` → exit 4 with GitHub's 422 and its `errors` (AC-004 failure outcome).
4. `board.sh move` on a new issue not on the board → `added … to the board; moved to In Progress`. Then `move` again with another case spelling (`done`). Then `board.sh items --status "in progress"`. Then an unknown status → exit 2 with the list (AC-005). This is the first real check of the organisation board with a fine-grained token (R-1, UNK-001).
5. Refusals through the real proxy: untick the agent while the run is live → `INTEGRATION_NOT_ALLOWED`, exit 3; a run without the tick has no variable → exit 3 "No GitHub access in this run".
6. AC-006: scan the run's outputs, run files, server log and `integrations/activity.jsonl` for the token value by script, printing counts only. The activity log should show each call's method, path and status.
7. Optional: a Codex `read-only` run cannot reach the proxy; expect curl's exit 5 message.

## API / E2E / Executable Coverage Investigation And Execution Still Required

- AC-003, AC-004, AC-005, AC-006 live through the real proxy (Change Sequence step 4), with the R-1/R-2 risks above.
- Whether to keep `tests/github/run-tests.sh` as the durable deterministic suite or extend it is API/E2E's call.
