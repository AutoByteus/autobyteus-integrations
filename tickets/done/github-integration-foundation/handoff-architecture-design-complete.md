# Handoff — Architecture Design Complete (autobyteus-integrations-1)

- From: Solution Designer (run `solution_designer_60f98864f3454354b938e1c03887ef02`), 2026-10-30
- Package: `github-integration-foundation`; Project Task `autobyteus-integrations-1` (Project `project_39227406-f32b-4eab-a1cd-bfe27a8e8580`), requested by `/project_task_manager`
- Classification: **Architecture Design Complete**, `task_size=Medium`, `architectural_risk=High` (new public contract: the integration manifest and folder layout every later integration and the Integrations page depend on; first credential-backed GitHub writes through the proxy)
- Current SR: `SR-008` (re-review ARCH-REV-002: Pass)
- Ticket folder: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation/tickets/in-progress/github-integration-foundation/`

## Workspace

- Repository: `AutoByteus/autobyteus-integrations` (public; licence undecided: add none)
- Worktree: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation`, branch `codex/github-integration-foundation`
- Base: `origin/main` @ `6fa9bbc`; finalization target: `origin/main`
- Nothing committed yet. The PM's untracked `task-plans/` in the main checkout is not part of this work.

## Original request and direction

- Task: make integrations real, GitHub first; a teammate can install it; foundation for all later integrations; settle the definition and install path; deliver the GitHub integration (issues list/read/create/comment, PRs read/open, Projects board moves) with the vault credential; report what the Integrations menu still needs.
- The user, 2026-10-30, in the Solution Designer conversation: integration = "skill plus authentication"; tokens through a proxy service (delivered as autobyteus-311 step 1, `v1.5.11-beta.4`); prerequisites mentioned, never installed; each integration owns its configuration on an Integrations page (prerequisite autobyteus-337, not dispatched yet); manifest named `integration.json`, fields validated twice and cut to what is needed ("only keep the one we really need"); test end to end on an organisation board; "Go ahead now".

## Approval basis

- Requirements `Approved` at SR-002…SR-007: Solution Designer within the direction, plus the user's own words for SR-003 (Integrations page), SR-004…SR-006 (manifest) and SR-007 (go-ahead). Quotes in `requirements-doc.md` and `solution-revision-record.md`.
- Behavior-defining supplement: `integration-manifest-contract.md` (SR-006), decided with the user. One part open by design: `token` routing (who decides where a token may go) belongs to autobyteus-337.

## What to review

- `design-spec.md`: spines DS-001…DS-005, ownership (`lib.sh` single request path; one subject per script), dependency rules (proxy contract only; no token variables, no `gh auth`, no `gh` own commands), interfaces (`OWNER/REPO#N` references, text from file/stdin, exit codes), file mapping, verification intent, what remains for the Integrations page.
- `integration-manifest-contract.md`: `name`, `description`, `token.help`, `prerequisites`; folder conventions (folder name = ID, `SKILL.md` name = skill, `icon.svg`).
- App contract it relies on (unchanged, owned by 311): `autobyteus-server-ts/docs/modules/credential_proxy.md` on `origin/personal` `1a4453e553`.

## Scope notes

- No app change. Install today: GitHub skill source + the existing GitHub card in Server Settings → Basics (interim, until autobyteus-337 moves it to the Integrations page). The README states today's steps. AC-001/AC-008 run on today's journey after finalization; the page journey and README rewrite are AC-009, this ticket's final round after 337 (DEC-007).
- Writing the skill and scripts stays with this team (the PM offered the Agent Package Creator; not needed).

## Live test target (user prerequisite, done)

- `AutoByteus/autobyteus-integrations-test` (private) and board AutoByteus Project #1 "AutoByteus Integrations Test Board" (Status: Todo, In Progress, Done).
- Token in `~/.autobyteus-test/secrets/github-integration-test.env` (`GITHUB_INTEGRATION_TEST_TOKEN`, owner-only, expires 2026-11-29); verified (repository read, board read and rename) without printing it. Never print it, put it in chat, commit it or copy it.

## Open risks

- R-1 organisation board writes measured only by the rename; item moves are proven in the live check.
- R-2 write paths through the proxy not yet proven against GitHub (311 covered reads).
- FU-001 (urgent, security): the ambient `gh` login on this node; sent to the PM when the ticket leaves the team.

## Next expected action

Independent architecture review of this package; on pass, implementation per `design-spec.md`.

## Re-review request (SR-008, after ARCH-REV-001)

- Resolved: AR-001…AR-005 (blocking) and AR-006…AR-009 (notes). Details per finding in `solution-revision-record.md` § SR-008.
- Changed passages: `design-spec.md` header, § Task Design Health (vocabulary line), § Ownership Map (`check-access.sh`), § Off-Spine Concerns, exit codes and the new § Error Rules, § Concrete Examples (status spelling, Jira), README row, Change Sequence 5–6, § What Remains For The Integrations Page (autobyteus-337), § Implementation Notes From Review; `requirements-doc.md` header, desired outcome, BEH-004, UC-006, SCN-001, SCN-006, REQ-010, AC-001, AC-008, new AC-009, DEC-003, § SR-003 text, new § SR-008 with DEC-007; `integration-manifest-contract.md` Status, folder rule, SR-005 table marked partly superseded; `investigation-notes.md` supplement inventory.
- AR-004 decision (DEC-007, within the PM's direction): today's journey for AC-001/AC-008 now; the Integrations-page journey and README rewrite in this ticket's final round (AC-009) after autobyteus-337. 337 changes no file in this repository.
