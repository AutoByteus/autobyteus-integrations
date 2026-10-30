# API/E2E Coverage Investigation — github-integration-foundation (autobyteus-integrations-1)

The plan. Results, confidence and the broader-validation decision are in `api-e2e-execution-coverage-report.md`.

## Investigation Meta

All paths are in the ticket folder `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation/tickets/in-progress/github-integration-foundation/`.

- Requirements Doc: `requirements-doc.md` (SR-008)
- Investigation Notes: `investigation-notes.md`
- Solution Revision Record: `solution-revision-record.md` (SR-008)
- Design Spec (required on every route): `design-spec.md` (SR-008)
- Supplemental Task Artifacts: `integration-manifest-contract.md` (SR-006), `follow-ups.md` (FU-001)
- Design Review Report: `design-review-report.md` (ARCH-REV-002, Pass)
- Architecture Review Revision Record: `architecture-review-revision-record.md`
- Implementation Handoff: `implementation-handoff.md` (IR-001)
- Implementation Revision Record: `implementation-revision-record.md`
- Code Review Report: `code-review-report.md` (CRR-001, Pass, no findings; CG-07, CG-08)
- Code Review Revision Record: `code-review-revision-record.md`
- Delivery Revision Record (delivery re-entry only): N/A
- Relevant Delivery Revision IDs: N/A
- API/E2E Revision Record (created after the first completed result): `api-e2e-revision-record.md`
- Current API/E2E Revision ID: `API-REV-001`
- Current Investigation Round: 1
- Trigger: code review CRR-001 passed (Medium / High); design Change Sequence step 4 (live check through a real app proxy)
- Prior Investigation Reviewed: N/A (first round)
- Latest Authoritative Investigation: this file, round 1

## Current Requirement And Design Basis

- What must be proven here (step 4): AC-003 (issues: list, read with comments, create, comment; refusals: no access, GitHub 403/404 explained), AC-004 (push with git through the proxy, `pulls.sh open` returns `OWNER/REPO#N`, read shows it; missing branch: GitHub's 422 explained), AC-005 (board move to a named status, list shows it; unknown status lists the valid names; no board access explained), AC-006 (the token in no chat, tool output, run file, server log or activity log; no `gh auth` in the scripts) — all through a real app proxy and real GitHub, with R-1 (organisation board with a fine-grained token, UNK-001) and R-2 (write paths) as the risks the live run retires.
- Code review hold CG-08: an item from a repository outside the token's list on the test board; `board.sh items` must print `(hidden)` and exit 0. If GitHub's answer also carries `errors`, the listing is refused (exit 4) and the result is a failure for failure-origin review (Error Rule 4 is a design rule).
- Not in this round: AC-001 and AC-008 (delivery after finalization, DEC-007), AC-009 (final round after autobyteus-337), AC-002 and AC-007 (proven by IMP-02 and by code review).
- Error Rules 1–5, exit codes and output shapes: design § Interface Boundary Mapping and § Error Rules; proven against the stand-in by IMP-01/IMP-04/IMP-05.

## Supported Scenarios And Real Usage

- Designer scenarios covered (`SCN-*`): SCN-002 (agent works on issues), SCN-003 (push and open a PR), SCN-004 (keep the board current), SCN-005 only as the `OWNER/REPO#N` outputs the scripts give (the cross-node rules are AC-007, a review item); SCN-001 and SCN-006 are AC-001/AC-008 and AC-002, outside this round.
- Real-use scenarios added from investigating the implemented behavior, each with its real trigger:
  - SCN-API-1 — access withdrawn during a live run: the user unticks the agent on the GitHub card while the run is active (the proxy reads the tick on every call). Trigger: `setGitHubIntegrationAgentAccess` without the agent, then the agent runs a script.
  - SCN-API-2 — an agent that is not ticked has the skill and runs it. Trigger: an agent with `github-integration` but no tick.
  - SCN-API-3 — an organisation board that also holds items from repositories outside a repo-limited token's list (CG-08). Trigger: the board already has such an item when the agent lists it. A shared org board in real use holds items from many repositories, and `token.help` recommends repo-limited tokens.
  - SCN-API-4 — the agent names a board it has no access to (a user-owned board, which fine-grained tokens cannot reach, P-3). Trigger: `board.sh items --owner <user> --number 1`.
- Designer scenarios recorded as `Technically Possible but Unsupported/Contrived` (not tested): CG-07 (the target issue also on a second board the token cannot see), recorded by code review as a residual risk outside the supported scenarios.

## Changed Behavior Summary

| Behavior ID / Boundary | Change Type | Upstream Evidence | Coverage Consequence |
| --- | --- | --- | --- |
| BEH-002: scripts → `lib.sh gh_request` → app proxy → GitHub (REST, GraphQL) | Added | design DS-002, Error Rules; handoff R-1/R-2 | Live run through a real proxy and real GitHub: every subject script, its write paths and its refusals |
| BEH-002: `git push` with the `https://github.com/` URL through `insteadOf` (DS-003) | Added (documented use of the app's contract) | design DS-003; SKILL.md, README | Live push in the agent's shell, then `pulls.sh open` |
| BEH-002 / REQ-008: no token anywhere | Added | AC-006 | Scan of every output and data location for the token value, counts only |
| BEH-004 / AC-002, BEH-005 / AC-007, BEH-001 / AC-001 | Added | IMP-02; CRR-001; DEC-007 | Not this round (reused or owned by delivery) |

## Changed Surface And Boundary Classification

| Surface / Boundary | Affected? | Actual Changed Boundary | Repository Evidence Available | Material Risk Not Exercised By That Evidence | Candidate Broader Validation Mode |
| --- | --- | --- | --- | --- | --- |
| Domain / backend logic | No | — | — | — | — |
| API / transport / contract | Yes | Script ↔ proxy ↔ GitHub REST/GraphQL request and response shapes | IMP-01, IMP-04 (stand-in) | Real GitHub field names, GraphQL documents, paging, write paths (R-1, R-2) | Live API through a real proxy |
| Frontend component / state | No | — | — | — | — |
| Browser integration / user journey | No | (the GitHub card UI is the app's; AC-008 belongs to delivery) | — | — | — |
| Authentication / session / permissions | Yes | Run pass, agent tick, fine-grained token permissions, org board access | Stand-in proxy codes (IMP-01) | Real proxy refusals, the real token's reach (org Projects, repos outside its list) | Live run with tick/untick |
| Desktop renderer / web-equivalent UI | No | — | — | — | — |
| Desktop shell / Electron-specific integration | No | — | — | — | — |
| Process / lifecycle | Yes (light) | The agent's run shell with the proxy variables (Codex runtime) | None | Variables reach the Codex shell; scripts run there | Isolated desktop instance, Codex run |
| Persisted-data transition | No | `Not Affected` | — | — | — |
| Worker / queue / distributed coordination | No | — | — | — | — |
| External integration | Yes | GitHub (issues, PRs, Projects v2, git smart HTTP) | Stand-in only | Everything GitHub-specific | Live GitHub test target |

## Project Execution Discovery

- Assigned task worktree / workspace: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation` (branch `codex/github-integration-foundation`, `f9d7f02`; code last changed at `3192aec`)
- Project type and runtime stack: shell scripts (bash 3.2+, curl, jq, git) and Markdown; the app is the released AutoByteus desktop app.
- Project testing guideline path(s): `No project testing guideline found` in `AutoByteus/autobyteus-integrations`. The app's guideline `/Users/normy/autobyteus_org/autobyteus-workspace-superrepo/TESTING.md` governs the app instance used here (isolated instances, CLI homes, data safety).
- Conflicting, missing, or unclear project instructions: TESTING.md rule 1 ("test unreleased changes on a worktree build") concerns app changes; this ticket changes no app code and must run on the **released** app (requirements: `v1.5.11-beta.4` or later), so the installed release is the right target, not a worktree build.
- Required environment variables or secrets available: `Yes` — the test token file `~/.autobyteus-test/secrets/github-integration-test.env` (mode 600, key present; value never printed); the user's Codex login (`~/.codex/auth.json`, symlinked into a throwaway `CODEX_HOME`).

| Instruction / Configuration Path | Authority / Purpose | Commands, Setup, Or Constraints Learned |
| --- | --- | --- |
| `autobyteus-workspace-superrepo/TESTING.md` | App testing guideline | Isolated instance only, never the user's running app or data; only `CODEX_HOME` passes into an isolated instance; throwaway `CODEX_HOME` with `config.toml` and a symlink to `auth.json`; stop what you started |
| `autobyteus-workspace-superrepo/docs/isolated-app-instances.md` (`origin/personal`) | Isolated instance lifecycle | `pnpm --dir <repo> isolated-app start --app /Applications/AutoByteus.app`; keep `instanceId`; `stop <instanceId>`; installed releases after 1.4.91-beta.5 carry `isolated-launch.json` |
| `autobyteus-server-ts/docs/modules/credential_proxy.md` (`v1.5.11-beta.4`/`beta.5`) | The proxy contract | `connectGitHubIntegration(token)`, `setGitHubIntegrationAgentAccess(ids)`; Codex gets the variables through the thread config; `activity.jsonl` under `<app-data-dir>/integrations/`; Codex `read-only` cannot reach the proxy |
| `autobyteus-server-ts/tests/e2e/credential-proxy/github-credential-proxy-runtime-shells.e2e.test.ts` (`v1.5.11-beta.5`) | How a run is driven over the public API | `createAgentDefinition`, `createAgentRun` (`runtimeKind`, `autoExecuteTools`), WebSocket `/ws/agent/<runId>` `SEND_MESSAGE`, end on `TURN_COMPLETED` |
| `github/SKILL.md`, design § Live Test Target, handoff § Downstream Coverage Hints | The scenarios and the target | `AutoByteus/autobyteus-integrations-test`, board `--owner AutoByteus --number 1` (Todo, In Progress, Done) |

| Component / Dependency | Working Directory | Start / Setup Command | Runtime / Resource Notes | Readiness Check | Stop / Cleanup Method |
| --- | --- | --- | --- | --- | --- |
| Isolated AutoByteus 1.5.11-beta.5 (installed release) | superrepo | `CODEX_HOME=<tmp> pnpm --silent --dir <superrepo> isolated-app start --app /Applications/AutoByteus.app` | Own data root, own ports; the user's running app is untouched | `start` waits for `/rest/health` | `isolated-app stop <instanceId>` (auto data root removed after evidence is taken) |
| Codex runtime (codex-cli 0.166.0) | — | from the instance, throwaway `CODEX_HOME` | Spends the user's Codex plan (a few short turns) | run created, `TURN_COMPLETED` | throwaway home removed |
| Live harness (temporary) | `/tmp/gh-int-live/harness` | `node harness.mjs <step>` | Drives GraphQL and WebSocket; reads the token from the file into one request only | GraphQL answers | removed after the run; copies of the scripts kept as evidence |
| Live driver (temporary) | run in the agent's shell | `bash <evidence>/API-live-driver.sh <outdir>` | Runs the skill scripts exactly as an agent would, records stdout, stderr and exit codes | output files | — |

| Data / Fixture / Identity Need | Existing Project Mechanism Or Creation Method | Environment / Data-Safety Notes | Cleanup / Retention |
| --- | --- | --- | --- |
| GitHub connection with the test token | `connectGitHubIntegration` from the harness, token read from the owner-private file | Token only in that one request body; never printed or written | Instance data root removed at stop |
| Skill `github-integration` | `addSkillSource(<worktree root>)` (local source = the worktree, as the handoff says) | Read-only use of the worktree | Removed with the instance |
| Agent definitions (one ticked, one not) | `createAgentDefinition` with `skillNames: ["github-integration"]`, `skillScope: CONFIGURED`; tick by `setGitHubIntegrationAgentAccess` | Instance-owned | Removed with the instance |
| Issues, comments, a branch, a PR on `AutoByteus/autobyteus-integrations-test` | created by the scripts in the run | Test repository, "safe to change" (design § Live Test Target) | Issues and PR closed, branch deleted, board items of this run removed |
| Outside item for CG-08 | Planned: the closed issue `AutoByteus/autobyteus-server#6` added to board #1. **Revised during the run:** the token cannot add content it cannot see (`NOT_FOUND`) and the host login has no `project` scope, so a test issue is put on the board by the scripts and then transferred by the host login to the private `AutoByteus/autobyteus-server` (outside the token's list); organisation-board items survive a transfer. Control: back in (visible), out again | Timeline entries on the test issue only; nothing left in `autobyteus-server` | Transferred back, closed, item deleted from the board |
| Independent read-back | host `gh` (user login, `repo` scope; no `project` scope) for repository state; raw GraphQL through the proxy (not `board.sh`) for the board | Read-only, plus cleanup on the test repository | — |

## Existing Durable Coverage Inventory

| Path / Test | Current Assertion Or Intent | Related Requirement / AC / Design | Validity Decision | Evidence | Action |
| --- | --- | --- | --- | --- | --- |
| `tests/github/run-tests.sh` + `fake-api.py` (24 cases) | Request building, outputs, Error Rules 1–5, PR filter, add-then-move, no token, missing tool | REQ-004…008, AC-003…006 (deterministic part) | Still Valid | IMP-01, IMP-04, IMP-05 on `3192aec`; no code changed since (`git diff --name-only 3192aec f9d7f02` lists ticket files only) | Keep; reuse. Revisit if the live run shows a stand-in shape that differs from GitHub |
| `tools/check-integrations.sh` + fixtures | AC-002 | REQ-002 | Still Valid (out of this round's scope) | IMP-02 | Reuse |

## Planned Cases

| Case ID | Criteria | Boundary / Surface | Kind | Planned Command Or Steps | Why |
| --- | --- | --- | --- | --- | --- |
| API-01 | REQ-004…008, Error Rules 1–5 | scripts vs stand-in | Reused | IMP-01 (macOS) and IMP-04 (Linux image) | Ran on `3192aec`; no script or test changed since; evidence states `24 passed, 0 failed` |
| API-02 | AC-002 | repository check | Reused | IMP-02 | Same commit argument |
| API-03 | — (suite quality) | tests | Reused | IMP-05 | Same commit argument |
| API-10 | AC-003, REQ-007/008 | real proxy, run shell | Journey | Isolated instance, connect, skill source, ticked Codex agent; the agent runs `check-access.sh` | First real proof the variable reaches the shell and `GET /user` answers through the proxy |
| API-11 | AC-003 | issues REST (write + read) | Journey | In the agent's shell: `issues.sh create` (title, body with quotes and newlines from a file), `comment` twice (`--body-file -` and a file), `read --comments 2`, `list` (open PR must not appear, run after API-12), `list --state all --limit 1` | R-2 issues write paths and REST field shapes |
| API-12 | AC-004 | git smart HTTP + pulls REST | Journey | `git clone` and `git push -u origin <branch>` with the `https://github.com/…` URL, `pulls.sh open` → `OWNER/REPO#N`, `pulls.sh read`, `pulls.sh list`; `pulls.sh open --head does-not-exist` → exit 4 with GitHub's 422 and its `errors` | R-2 push and PR write path; AC-004 failure outcome |
| API-13 | AC-005, R-1 | Projects v2 GraphQL (org board, fine-grained token) | Journey | `board.sh move <new issue> --status "In Progress"` (added then moved), `move … --status done`, `items`, `items --status "in progress"` / `done`, unknown status → exit 2 with the names; independent read-back by raw GraphQL | R-1 / UNK-001: first real organisation-board check |
| API-14 | AC-005 (CG-08) | Projects v2 GraphQL, REDACTED items | Journey | Get an item from a repository outside the token's list onto board #1 (revised fixture: see Data / Fixture table); `board.sh items --owner AutoByteus --number 1` → expected that item `(hidden)`, exit 0; record whether GitHub's raw answer carries `errors`; control with the same item inside the list; remove the item | Code-review hold CG-08 |
| API-15 | AC-003 failure, AC-005 failure | GitHub 403/404 and GraphQL errors through the proxy | Journey | `issues.sh read` of a private repository outside the token's list (404 + hint, exit 4); `issues.sh comment` on a public repository outside the list (403 + hint, exit 4, nothing written); `board.sh items --owner ryan-zheng-teki --number 1` (user board: GraphQL errors, exit 4) | Real refusals for the "explained" failure outcomes |
| API-16 | AC-003 failure (unticked), REQ-007/008 | real proxy refusals | Journey | (a) untick the agent while its run is live → `check-access.sh` exit 3 `INTEGRATION_NOT_ALLOWED` with the next step; tick again → connected. (b) a second agent with the skill but no tick → exit 3 "No GitHub access in this run" | SCN-API-1, SCN-API-2 |
| API-17 | AC-003 (agent use) | agent reads SKILL.md, chooses commands | Journey | Natural request to the ticked agent: check access, list the open issues, comment on the run's issue; verify the comment on GitHub by host `gh` (author = token's account) | The real way an agent uses the skill, not only a fixed command |
| API-18 | AC-006 | outputs and data | Temporary Probe | Scan by script (counts only) for the token value: the run's wire messages, driver outputs, instance data root (db, run files, memory, `integrations/`), instance log, throwaway `CODEX_HOME`; check `activity.jsonl` has method, path, status for the calls; `grep` the scripts for `gh auth` | AC-006 scan; the activity log proves the calls went through the proxy |

- Test progress log needed: `Yes`

## Durable Coverage To Add

None. The live cases need an app instance, the owner-private token and a write-capable GitHub target; this repository's suite runs without network or secrets by design (`tests/github/` "real tokens or network" forbidden in design § Target Folder / File Mapping). The live driver and harness are kept in the evidence folder so a later round (AC-009) can rerun them.

## Durable Coverage To Update

None planned. If a live answer differs from the stand-in's shape, the stand-in must follow GitHub, and that change returns for test-code review.

## Durable Coverage To Remove

None.

## Live Environment And Fixture Plan

- Startup order and commands: throwaway `CODEX_HOME` (`config.toml` empty, `auth.json` symlink) → `isolated-app start --app /Applications/AutoByteus.app` → harness `setup` (connect, skill source, agents, tick) → `createAgentRun` (Codex, `autoExecuteTools: true`, model from the Codex catalog, low effort) → chat turns.
- Environment choices that materially affect the run: released app 1.5.11-beta.5 (≥ beta.4, the version the README states); Codex runtime with full access (the design's Verification Intent); the agent's skill from a local source pointing at this worktree.
- Health / readiness checks: `isolated-app start` readiness; `githubIntegration { connected login }`; `skills { name rootPath }` lists `github-integration`.
- Seed data / fixtures: none before the run; the run creates its own issues, branch and PR; CG-08 item added for API-14 only.
- Test identities: the test token's account (connected login), the user's Codex login (throwaway home), the user's `gh` login for read-back and cleanup only.
- Requirement-linked journeys: API-10…API-17.
- Evidence to capture: driver output files (stdout, stderr, exit code per command, the run pass masked), wire-message transcripts (masked), GitHub read-back, activity log excerpt, scan counts.
- Owned processes and temporary state to clean up: the isolated instance and its data root, the throwaway `CODEX_HOME`, `/tmp/gh-int-live`, the GitHub objects listed above.

## Not Tested / Infeasible / Deferred

| Behavior / Boundary | Reason | Risk | Only The User Can Check? | Required Follow-Up Or Escalation |
| --- | --- | --- | --- | --- |
| AC-001, AC-008 | Delivery after finalization on `main` (DEC-007) | — | No | Delivery |
| AC-009 | Final round after autobyteus-337 | — | No | Final round |
| Codex `read-only` run (handoff hint 7, optional) | The app's own contract (credential_proxy.md) already states and 311 measured it; the scripts' curl-failure mapping is IMP-01 | Low | No | None |
| CG-07 | Unsupported / contrived (code review) | Clear refusal, no wrong success | No | None |
| `pulls.sh open --draft` on a private repository | Depends on the org's GitHub plan; GitHub's 422 is explained by Rule 3 (IMP-01) | Low | No | None |

## Ambiguities Or Reroute Triggers

None at planning time. CG-08 becomes a failure for failure-origin review if the raw answer carries `errors` and the listing is refused.

## Investigation Decision

- Proceed To API/E2E Execution: `Yes`
- Repository-Resident Durable Coverage Will Be Added / Updated / Removed: `No` (revisit on a stand-in shape mismatch)
- Reroute Required Before Validation Execution: `No`
- Recommended Owner If Reroute Required: —
- Notes: The run pass is masked (`rp_<pass>`) in every saved file; the token is never printed.
