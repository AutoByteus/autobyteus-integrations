# API/E2E Execution Coverage Report — github-integration-foundation (autobyteus-integrations-1)

## Round

- Coverage investigation: `api-e2e-coverage-investigation.md` (round 1; lists the upstream documents)
- API/E2E revision record and current revision ID: `api-e2e-revision-record.md`, `API-REV-001`
- Test progress log: `api-e2e-test-progress.md`
- Round and trigger: round 1; code review CRR-001 passed; design Change Sequence step 4 (live check through a real app proxy)
- Prior round reviewed: N/A
- Deviations from the investigation's plan, and why:
  - API-14 (CG-08): the planned fixture (put `AutoByteus/autobyteus-server#6` on the board) was impossible: the test token cannot add content it cannot see (`NOT_FOUND`), and the host `gh` login has no `project` scope. Used instead: issue C created in the test repository and put on the board by the scripts, then **transferred** by the host `gh` login to the private `AutoByteus/autobyteus-server` (outside the token's list), with a control (back in, visible; out again, gone) and cleanup by transferring back. Organisation-board items survive a transfer (proven: the same item ID `…ExsGQ` was moved, not re-added, after the first round trip, and was deleted in cleanup).
  - A recheck phase R (API-13) and the control phase G (API-14) were added when results needed a second look.
- Evidence folder: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation/tickets/in-progress/github-integration-foundation/evidence/` (files `API-*`; the commit that holds it is given in the handoff message)

## Routing Classification

- Task size: `Medium`
- Architectural risk: `High`
- Input route: `Reviewed`
- Successful-output route: `Code Review`
- Proportional test-code review decision: `Not Applicable` — no durable test code was added, changed or removed this round (the live driver, harness and scanner are temporary probes kept as evidence)

## Tested Builds And Environments

| Env ID | Commit Tested | Platform / OS | Runtime, Browser, Or App Build | Other Settings That Matter |
| --- | --- | --- | --- | --- |
| ENV-1 | `3192aec` (IMP-01…IMP-05) | macOS 26.5 bash 3.2.57; server image bash 5.2.21 | local stand-in for the proxy | see implementation handoff § Checks Run |
| ENV-2 | `f9d7f02` (scripts identical to `3192aec`) | macOS 26.5 (arm64); the run shell was `/bin/bash -lc`, bash 3.2.57 | Installed release AutoByteus **1.5.11-beta.5** (`/Applications/AutoByteus.app`, has the proxy, ≥ the `v1.5.11-beta.4` the README states), started isolated: `CODEX_HOME=<throwaway> pnpm --silent isolated-app start --app /Applications/AutoByteus.app` → `iso-62788-45ad`, own data root and vault, backend `127.0.0.1:62789`; Codex runtime (codex-cli 0.166.0, `gpt-5.6-luna`, low effort, auto-execute) | GitHub connected once with the test token (`connectGitHubIntegration`, login `ryan-zheng-teki`); skill `github-integration` from a local skill source pointing at this worktree (Codex copies it into the workspace `.codex/skills/`); agent `gh-int-live-ticked-c8bf8b` ticked, agent `gh-int-live-unticked-dc5097` with the skill but never ticked; target `AutoByteus/autobyteus-integrations-test` (private) and board AutoByteus #1 (organisation, Todo/In Progress/Done), empty before the run; the user's `gh` login (scopes `repo`, `read:org`; no `project`) only for independent read-back, the CG-08 transfers and cleanup |

How ENV-2 drove the run (reproducible from the evidence): `API-live-harness.mjs` uses the instance's public GraphQL (`connectGitHubIntegration`, `addSkillSource`, `createAgentDefinition`, `setGitHubIntegrationAgentAccess`, `createAgentRun`, `terminateAgentRun`) and the run's WebSocket (`SEND_MESSAGE`, until `TURN_COMPLETED`). The systematic cases are one agent turn each: the agent runs `bash API-live-driver.sh <phase> <out>` in its own shell, so the skill scripts see exactly the agent's environment (`AUTOBYTEUS_GITHUB_API_URL`, git's `insteadOf`). The driver records each command, its exit code, stdout and stderr. API-17 is a plain request where the agent picks the commands itself.

## Cases

| Case ID | Criteria | Boundary / Surface | Command Or Steps | Env | Result | Evidence Files | Look For | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| API-01 | REQ-004…008, Error Rules 1–5 | scripts vs stand-in | Reused IMP-01, IMP-04 | ENV-1 | Pass | (implementation handoff) | `24 passed, 0 failed` | Still holds: `git diff --name-only 3192aec f9d7f02` lists ticket files only |
| API-02 | AC-002 | repository check | Reused IMP-02 | ENV-1 | Pass | (implementation handoff) | `all 1 integration folder(s) pass` | Same reason |
| API-03 | — | the tests catch defects | Reused IMP-05 | ENV-1 | Pass | (implementation handoff) | `23 passed, 1 failed` per seeded defect | Same reason |
| API-10 | AC-003, REQ-007/008 | variable in the Codex run shell, `GET /user` through the real proxy | Agent turn: `…/github/scripts/check-access.sh; echo "exit=$?"` | ENV-2 | Pass | `API-10-check-access-agent-turn.log` | `GitHub access: connected as @ryan-zheng-teki` and `exit=0` | The driver header in `API-11-12-13-phase-A-steps.log` shows the shell had `AUTOBYTEUS_GITHUB_API_URL=http://127.0.0.1:62846/r/rp_<pass>/github/api`, `GIT_CONFIG_KEY_0=url.http://127.0.0.1:62846/r/rp_<pass>/github/git/.insteadOf`, `GIT_TERMINAL_PROMPT=0` |
| API-11 | AC-003 | issues REST, write and read | Driver phase A: A02 `issues.sh create` (title with `"`, body file with quotes, `$HOME`, backticks, backslash, newlines), A03 `comment --body-file -`, A04/A05 `comment --body-file FILE`, A06 `read --comments 2`, A15 `list` (after the PR exists), A16 `list --state all --limit 1`, A14 `comment` on the PR; host read-back | ENV-2 | Pass | `API-11-12-13-phase-A-steps.log`; `API-11-17-host-readback.log` | `AutoByteus/autobyteus-integrations-test#1 https://github.com/AutoByteus/autobyteus-integrations-test/issues/1`; `commented on AutoByteus/autobyteus-integrations-test#1: https://github.com/…/issues/1#issuecomment-6523828322`; `--- comments (last 2 of 3) ---`; A15 prints only `…#1 [open] …` while PR #2 is open; read-back bodies byte-equal, `"user":"ryan-zheng-teki"` | R-2 issues write path proven. Text passed through unchanged (`$(not run)` stayed literal) |
| API-12 | AC-004 | git smart HTTP through `insteadOf`; pulls REST | Driver phase A: A07 `git clone https://github.com/AutoByteus/autobyteus-integrations-test.git`, commit, A09 `git push -u origin live-check/20261030132042`, A10 `pulls.sh open … --head <branch> --base main --body-file`, A11 `pulls.sh read`, A12 `pulls.sh list`, A13 `pulls.sh open --head does-not-exist-…` | ENV-2 | Pass | `API-11-12-13-phase-A-steps.log`; `API-11-17-host-readback.log` | A09 `* [new branch]      live-check/20261030132042 -> live-check/20261030132042`; A10 `AutoByteus/autobyteus-integrations-test#2 https://github.com/AutoByteus/autobyteus-integrations-test/pull/2`; A11 `branches: live-check/20261030132042 → main`, `changed files (1):`; A13 `--- exit: 4` and `GitHub answered HTTP 422 for POST /repos/AutoByteus/autobyteus-integrations-test/pulls: Validation Failed` / `- PullRequest head invalid` | R-2 push and PR write path proven. A11 printed `mergeable: unknown (GitHub is still checking; read again shortly)` one second after opening; the host read-back a few minutes later has `"mergeable":true`. A08 shows git reports the redirected remote URL (git's `insteadOf` rewrites what it displays); the push still names `https://github.com/…` in the clone command |
| API-13 | AC-005, R-1 / UNK-001 | Projects v2 GraphQL on an organisation board with a fine-grained token | Driver phase A: A18 `board.sh move …#3 --status "In Progress"` (not on the board), A19 `items --status "in progress"`, A20 `move …#3 --status done`, A21 `move …#2 --status todo` (the PR), A22 `items`, A23 `items --status DONE`, A24 `move …#3 --status Blocked`, A25 raw GraphQL read-back (not `board.sh`); phase R (recheck) | ENV-2 | Pass | `API-11-12-13-phase-A-steps.log`; `API-13-phase-R-board-recheck.log` | A18 `added AutoByteus/autobyteus-integrations-test#3 to the board; moved to In Progress`; A20 `moved AutoByteus/autobyteus-integrations-test#3 to Done`; A24 `--- exit: 2` and `unknown status "Blocked"; the board's statuses are: Todo, In Progress, Done`; R01 lists `…#3 [Done] …` and `…#2 [Todo] …`; A25 raw read-back `"fieldValueByName":{"name":"Done"}` and `{"name":"Todo"}` | UNK-001 settled: the organisation board works with the fine-grained token (read, add, set status). A22, run immediately after A21 added the PR, listed only #3; A25 seconds later and R01 list the PR. This is GitHub's item list catching up after an add, not the script (same query, same filter, correct a moment later). Moving #3 to Done also closed issue #3: the board's own "auto-close" workflow on GitHub, not the script (read-back `"state":"closed"`) |
| API-14 | AC-005 (CG-08) | Projects v2 GraphQL: an item whose issue is in a repository outside the token's list | F2: issue #4 on the board (Todo); host `gh issue transfer 4 AutoByteus/autobyteus-server` → `autobyteus-server#9`; phases B, B2 (45 s), B3 (1 min 47 s), B4 (6 min 5 s): raw GraphQL `items { totalCount nodes }` and `board.sh items`; control: transfer back (#5), G: `board.sh move #5 --status todo` and list (visible), transfer out again (`autobyteus-server#10`), B5 (91 s); cleanup: transfer back (#6), X deletes the item | ENV-2 | Pass | `API-14-cg08-outside-item.log` | Outside the list: `"totalCount":2` with nodes #3 and #2 only, no `"errors"`, no `REDACTED`, `board.sh items` `--- exit: 0` listing #3 and #2. Inside the list (G): `moved AutoByteus/autobyteus-integrations-test#5 to Todo` (moved, not added: the item stayed on the board), `"totalCount":3`, `…#5 [Todo] Live check 20261030132042: issue C (CG-08 fixture)`. Outside again (B5): `"totalCount":2`. X: `"deletedItemId":"PVTI_lADOB-mU1M4BpcaHzhExsGQ"` (the same item) | **CG-08 measured.** GitHub leaves such items out of the token's view entirely: no `errors` entry, so Error Rule 4 does not refuse the listing (the failure the reviewer asked about does not occur). It also sends no `REDACTED`/null-content node, so `board.sh` prints no `(hidden)` line: the item is simply absent. The `(hidden)` branch (`board.sh:144`) was not reached live and has no stand-in test either; reported to code review as information. Host count while outside: `autobyteus-server#9` `projectItems.totalCount: 1`. F01: the token cannot add the private outside issue (`Could not resolve to a node with the global id of 'I_kwDONPysk86kDgoP'.`) |
| API-15 | AC-003 failure, AC-005 failure | GitHub 403/404 and GraphQL errors through the proxy | Driver phase C: C01 `issues.sh read AutoByteus/autobyteus-server#6`; C02 `issues.sh comment AutoByteus/autobyteus-workspace#2 --body-file -`; C03 `board.sh items --owner ryan-zheng-teki --number 1`; C04 `board.sh items --owner AutoByteus --number 999` | ENV-2 | Pass | `API-15-phase-C-refusals.log`; `API-11-17-host-readback.log` | C01 `GitHub answered HTTP 404 for GET /repos/AutoByteus/autobyteus-server/issues/6: Not Found` + `Next: the token may lack a permission or the repository is not in its list.`, exit 4; C02 `GitHub answered HTTP 403 for POST /repos/AutoByteus/autobyteus-workspace/issues/2/comments: Resource not accessible by personal access token`, exit 4; C03 `GitHub refused the GraphQL request:` / `- Could not resolve to a ProjectV2 with the number 1. (NOT_FOUND)`, exit 4; C04 same for 999, exit 4; read-back: 0 comments `Should be refused` | Rule 3 (REST 403/404) and Rule 4 (GraphQL 200 + `errors`) proven against real answers |
| API-16 | AC-003 failure (no access), REQ-007/008; SCN-API-1/2 | real proxy refusals; no variable | (a) `setGitHubIntegrationAgentAccess([])` with the run live, agent runs `check-access.sh` and `issues.sh list`; (b) tick again, `check-access.sh`; (c) run of the never-ticked agent, `check-access.sh` | ENV-2 | Pass | `API-16-access-refusals-agent-turns.log`; `API-18-proxy-activity.jsonl` | (a) `AutoByteus refused GET /user (INTEGRATION_NOT_ALLOWED): This agent has no GitHub access. Allow it on the GitHub card in Settings.` + `Next: this agent has no GitHub access in this run: give the agent the integration, then start a new run.`, `exit=3` (twice); (b) `GitHub access: connected as @ryan-zheng-teki`, `exit=0`; (c) `No GitHub access in this run (AUTOBYTEUS_GITHUB_API_URL is not set).`, `exit=3` | (b) shows that re-ticking restores the same live run; the Rule 2 text's "start a new run" is conservative, not wrong (approved wording) |
| API-17 | AC-003 (agent use), SCN-002 | the agent reads SKILL.md and chooses the commands | Plain request: check access, list the open issues, comment on #1 with a given sentence | ENV-2 | Pass | `API-17-natural-agent-turn.log`; `API-11-17-host-readback.log` | The agent ran `cat …/.codex/skills/github-integration/SKILL.md`, `check-access.sh`, `issues.sh list AutoByteus/autobyteus-integrations-test --state open`, then `printf '%s\n' '…' \| …/issues.sh comment AutoByteus/autobyteus-integrations-test#1 --body-file -` → `commented on AutoByteus/autobyteus-integrations-test#1: https://github.com/…/issues/1#issuecomment-6523909235`; read-back `"body":"Natural-language live check by the agent (20261030132042).","id":6523909235,"user":"ryan-zheng-teki"` | The comment is made by the token's account, as AC-008 will require; the agent used no token, `gh` or other route |
| API-18 | AC-006 | outputs and data | `node API-scan-token.mjs` over: every agent-turn wire transcript and driver output (`/tmp/gh-int-live/out`), the instance data root (database, agents, memory, run files, `integrations/`, server logs, Electron data), the instance log, the throwaway `CODEX_HOME` (sessions, sqlite; the `auth.json` symlink skipped), both run workspaces, the worktree; positive control first; `grep` of `github/scripts`; activity-log summary | ENV-2 | Pass | `API-18-token-scan.log`; `API-18-proxy-activity.jsonl`; `API-agent-turns/` | `"files": 737`, `"filesWithToken": 0`; control `filesWithToken 1`; grep: only the comment `lib.sh:10:# stores a token, and nothing calls https://api.github.com directly.`; activity log `74 records` with `at,…,method,path,route,runId,status` (+ `error` on refusals), e.g. `43 api POST 200 -`, `3 git POST 200 -`, `2 api GET 403 INTEGRATION_NOT_ALLOWED`; `run pass in the instance log: 0 lines` | Every call went through the proxy (activity log). The scan also covers the Basic-auth form of the token. The committed evidence folder was scanned too: 0 files with the token, 0 unmasked run passes |

## Acceptance-Criteria Proof

| Acceptance-Criteria ID | Critical | Proven By Case IDs | Result | For A User-Only Part |
| --- | --- | --- | --- | --- |
| AC-003 | Yes | API-01, API-10, API-11, API-15, API-16, API-17 | Proven | — |
| AC-004 | Yes | API-12 | Proven | — |
| AC-005 | Yes | API-13, API-14, API-15 (C03/C04) | Proven | — |
| AC-006 | Yes | API-18 (and API-01 for "no `gh auth` in the scripts") | Proven | — |
| AC-002 | Yes | API-02 (reused IMP-02) | Proven | — |
| AC-007 | No | code review CRR-001 | Proven (review) | — |
| AC-001, AC-008 | Yes | — | Not Proven (not this round) | Delivery runs them after finalization on `main` (DEC-007); not a user-only part |
| AC-009 | Yes | — | Not Proven (not this round) | Final round after autobyteus-337 |

## Validation Confidence Scorecard (Mandatory)

| Confidence Category | Post-Repository Score | Final Score | What Supports It (Case IDs) | Residual Uncertainty | What Could Improve It |
| --- | --- | --- | --- | --- | --- |
| Requirement and acceptance-criteria proof | 50% | 95% | API-10…API-18 prove AC-003…AC-006 live; API-01/02 | AC-001/008/009 belong to later steps by design | Delivery's AC-001/AC-008 run |
| Changed-boundary execution directness | 75% | 95% | Scripts ran in a real agent run's shell against the real proxy and real GitHub (API-10…API-17); activity log (API-18) | — | — |
| Cross-boundary integration realism and mock gap | 50% | 95% | No stand-in in ENV-2; real GraphQL documents, REST field names and write paths (R-1, R-2); host read-back independent of the scripts | The stand-in's `(hidden)` shape is not what GitHub sent for CG-08 (but no test asserts it) | — |
| Environment, configuration, identity, and fixture fidelity | 50% | 95% | Released 1.5.11-beta.5, own vault; the recommended token kind (fine-grained, repo-limited, org Projects) on the organisation board; Codex runtime as the design names | Live run on macOS only; Docker nodes have the same tools (IMP-04) and the same HTTP path | — |
| Failure, edge-case, lifecycle, and recovery evidence | 75% | 95% | Live refusals: no variable, `INTEGRATION_NOT_ALLOWED` and recovery, 403, 404, 422, GraphQL `NOT_FOUND`, unknown status (exit 2); CG-08 with control; listing lag observed and explained | `RUN_PASS_INVALID`, 5xx and curl failure only against the stand-in (no supported scenario reaches them live without breaking the app) | — |
| User-surface, browser, and desktop-shell confidence | N/A | N/A | No UI change; the GitHub card journey is AC-008 (delivery) | — | — |
| Durable regression coverage quality and relevance | 90% | 95% | 24-case suite still valid; every live shape matched what the stand-in models (no mismatch to correct) | — | — |

- Overall post-repository confidence: 65%
- Overall final confidence: 95%
- Calculation method: simple average of the six applicable categories
- Every critical acceptance criterion directly proven, apart from parts only the user can check: `Yes` for this round's criteria (AC-003…AC-006); AC-001/AC-008/AC-009 are later steps, not user-only parts
- Any final applicable category below `90%`: `No`
- Default final confidence target of `95%` met: `Yes`
- Confidence-limiting residual risks: below (Latest Authoritative Result → Notes)

## Broader Validation Decision (Mandatory)

- Decision: `Required` (executed)
- Execution mode: `Live API` through `Project Desktop Validation` (isolated desktop instance of the released app, agent runs over its public API)
- Confidence gap it addresses: R-1 (organisation board with a fine-grained token), R-2 (write paths), the real proxy's refusals, AC-006 on real run data; the stand-in could prove none of them
- Browser validation needed: No. No UI changed; the instance was driven through its GraphQL and WebSocket API, which is what the UI uses. The card UI is AC-008's journey (delivery)
- If `Blocked`: N/A

## Compatibility / Legacy Scope Check

- Reviewed requirements/design introduce, tolerate, or ambiguously describe backward compatibility in scope: `No`
- Compatibility-only or legacy-retention behavior observed in implementation: `No`
- Durable coverage added or retained only for compatibility-only behavior: `No`
- Reroute classification: N/A; upstream recipient notified: N/A

## Durable Coverage Changed In The Codebase

- Repository-resident durable coverage added, updated, or removed this round: `No`

None. `tests/github/run-tests.sh` stays the durable deterministic suite: the live answers matched the shapes it models, so nothing needed correcting. The live cases need an app instance, the owner-private token and a write-capable GitHub target, which this repository's network-free suite must not depend on (design § Target Folder / File Mapping). The probes are kept, runnable, in the evidence folder (`API-live-harness.mjs`, `API-live-driver.sh`, `API-scan-token.mjs`) for the final round (AC-009).

- Added or updated paths attached for proportional test-code review: `Not Applicable`
- Diff or repository evidence supplied for removed paths: N/A

## Dependencies Mocked Or Emulated

| Dependency | Method | Why Real Dependency Was Not Used | Confidence Limitation |
| --- | --- | --- | --- |
| None in ENV-2 | — | — | — |
| A repository outside the token's list holding a board item (CG-08 fixture) | Issue transfer with the host login | The token cannot add such content and the host login has no `project` scope | None for the measured behavior (the item ID was shown to stay on the board) |

## Temporary Methods And Cleanup

| Item | Owned By This Run | Cleanup Action | Result |
| --- | --- | --- | --- |
| Isolated instance `iso-62788-45ad` and its data root | Yes | `pnpm --silent isolated-app stop iso-62788-45ad` | `"wasRunning": true`, `"dataRootRemoved": true`, both ports released; not in `isolated-app list`. The user's own AutoByteus (started 14:00) untouched |
| Throwaway `CODEX_HOME` (symlink to the user's `auth.json`), harness, driver, outputs, workspaces in `/tmp/gh-int-live` | Yes | `rm -rf /tmp/gh-int-live` after copying the evidence | Removed; `~/.codex/auth.json` unchanged |
| Issues #1, #3, #4→#5→#6 (CG-08 fixture), PR #2, branch `live-check/20261030132042` on the test repository | Yes | Closed with a cleanup comment; PR closed and branch deleted | All closed; branches `["main"]` |
| Board AutoByteus #1 items (#3, #2, the CG-08 item) | Yes | Driver phase X: `deleteProjectV2Item` for each | Read-back `"nodes":[]` (the board was empty before the run) |
| CG-08 fixture in `AutoByteus/autobyteus-server` (#9, #10) | Yes | Transferred back to the test repository each time | `autobyteus-server` lists only its own issues (#7, #6) |
| Timeline entries ("transferred", "added to project") on the closed test issues | Yes | Kept (GitHub records them; the test repository is "safe to change") | — |

## Latest Authoritative Result

- Result: `Pass`
- Criteria not proven, or parts only the user can check: `None` for this round. AC-001 and AC-008 are delivery's after finalization (DEC-007); AC-009 is the final round after autobyteus-337
- Preliminary classification and recommended owner: N/A
- Next recipient from `get_handoff_rules`: see the handoff message
- Notes (residual risks and observations, none of them a failure):
  - **CG-08 (for code review):** GitHub omits a board item whose issue is in a repository outside a repo-limited fine-grained token's list. It sends no `errors` entry and no REDACTED node, so `board.sh items` exits 0 without the item. The feared Rule 4 refusal does not happen. The `(hidden)` branch at `board.sh:144` (null content) was not reached live and no stand-in case asserts it. Whether it stays as a guard for GitHub's documented REDACTED shape (other token kinds) is code review's judgement. Real-use consequence: on a shared organisation board, the list shows only the items the connected token can see, and nothing marks the rest. SKILL.md does not claim otherwise.
  - Listing right after a change: GitHub's board item list can lag a few seconds behind `addProjectV2ItemById` (A22). `move`'s own output is authoritative. A list a moment later is correct.
  - Moving to Done closed issue #3 through the test board's own GitHub workflow (auto-close). Other boards may have other workflows; the script reports only the move.
  - `pulls.sh read` right after `open` shows `mergeable: unknown (GitHub is still checking; read again shortly)`, which is GitHub's normal answer while it computes the merge state. The script's message already says what to do.
  - Codex returned before the 30-second command in phase G finished, and the command still completed. This is runtime behavior for long commands and is outside this ticket.
  - The Rule 2 refusal text for `INTEGRATION_NOT_ALLOWED` says "then start a new run", but re-ticking also restores the running run (API-16 b). The approved wording is conservative and correct.
  - FU-001 is unchanged.
