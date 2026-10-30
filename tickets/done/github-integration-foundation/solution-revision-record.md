# Solution Revision Record — github-integration-foundation (autobyteus-integrations-1)

## Revision Index

| Revision ID | Phase | Trigger | Prior Status | Current Status | Affected IDs | Result |
| --- | --- | --- | --- | --- | --- | --- |
| SR-001 | Requirements | First investigation; the user's direction (proxy) | N/A | Draft, waiting for PRE-001 | DEC-001…DEC-003, PRE-001 | Prerequisite sent to the PM; ticket paused |
| SR-002 | Mixed | PRE-001 delivered (autobyteus-311 step 1, `v1.5.11-beta.4`) | Draft | Requirements Approved; Design Ready for the user's approval | REQ-001…REQ-010, AC-001…AC-008, DEC-004…DEC-006, UP-001 | Requirements and design rebuilt on the proxy contract |

## Revision Entries

### SR-001 — First baseline and the prerequisite

- Classification: Initial Baseline. Trigger: investigation showed 244 built MCP secrets only (F-A2); the user's direction 2026-10-30: integration = "skill plus authentication", credentials through a proxy service.
- Status: requirements Draft; no design. Intended behavior: proxy delivery (user decision).
- Handoff: `handoff-prerequisite-credential-proxy.md` to `/project_task_manager`; the PM gave the proxy Task (autobyteus-311) to another team copy; this ticket paused (`pause-note.md`).

### SR-002 — Rebuilt on the delivered proxy

- Classification: Refinement after a delivered prerequisite. Trigger: PM message 2026-10-30 ("CONTINUE autobyteus-integrations-1"); evidence F-B1…F-B4.
- Requirements: REQ-001…REQ-010, AC-001…AC-008 written; "through `gh`" realised as `curl` + `gh api`-compatible proxy calls + `git` (DEC-004), because the proxy does not support `gh`'s own commands.
- Approval: Solution Designer within the direction (user informed, 2026-10-30, with the design). The user's approval of the design is requested before building.
- Design: `design-spec.md` written. Classification `Medium` / `High` (new public contract; first credential-backed writes).
- User prerequisite UP-001 (test repository, board and token) asked.
- Next: the user's answer; then the configured handoff.

### SR-003 — Integrations page direction

- Classification: Requirement Gap, resolved by the user's own direction (quotes in `requirements-doc.md` § SR-003). Intended behavior changed: install and configure from an Integrations page; agent access follows the skill; GitHub card leaves Server Settings.
- Approval: the user's words in the Solution Designer conversation, 2026-10-30.
- Design impact: the repository part (`github/`, `integration.json`, docs) unchanged; the README install steps and the teammate-way check (AC-001, AC-008) move to the Integrations page and wait for PRE-002 = autobyteus-337.
- Handoff: `handoff-prerequisite-integrations-page.md` to `/project_task_manager`; Task autobyteus-337 created, not dispatched.
- Next: the user's answer (build the repository part now or wait).

### SR-004 — The integration manifest contract

- Classification: Refinement (design contract, with the user). Trigger: the user asked to design the data model first ("I think we need a contract file … better to first design the data model"); answer on the name: "If you think the integration file is better, then let's call it integration."
- Changed: `integration-manifest-contract.md` added as the contract authority; REQ-002 re-worded to it; design-spec example replaced by a pointer. Fields: `id`, `name`, `description`, `icon`, `service`, `skill`, `connection` (`kind`, `label`, `help`, `createUrl`, `permissions`), `prerequisites`. Removed from the earlier draft: `credential.setup` (the page does that), `install` (the reader knows the source), `requires` (README).
- Open: `connection.routes` (who decides where a token may go), for autobyteus-337 with the user.
- Next: the user's go to build the repository part.

### SR-005 — Manifest fields validated

- Trigger: the user, 2026-10-30: "validate by yourself whether you have redundant fields … what are necessary, what are not necessary".
- Removed as repeated or derivable: `id` (folder name), `skill` (`SKILL.md` name), `icon` (convention `icon.svg`), `connection.label` (from `name` + `kind`), `kind: "none"` (no `connection`), `prerequisites[].check` (`command -v`). Removed for having no reader: `service`. `prerequisites` became a tool → install-link map. Kept with reasons: `name`, `description` (user-facing, distinct from the agent-facing `SKILL.md` description), `connection.kind/help/createUrl/permissions`. Table in `integration-manifest-contract.md` § Field validation.
- REQ-002 and AC-002 re-worded. Open: `connection.routes` (autobyteus-337).

### SR-006 — Manifest trimmed to what is needed now

- Trigger: the user, 2026-10-30: "only keep the one we really need".
- `connection` (kind, help, createUrl, permissions) became `token` (help); `prerequisites` became a list of tool names. Final fields: `name`, `description`, `token.help`, `prerequisites`. Table in `integration-manifest-contract.md` § Second pass.
- The user also asked whether integrations need their own page: answered in the conversation (yes, autobyteus-337).

### SR-007 — Test target ready; design approved for building

- The user chose the organisation board ("it can be tested like end to end") and approved building ("Go ahead now, I think if the requirements are enough, then you can go ahead"), 2026-10-30.
- Done in the user's browser session and `gh` login: the existing token `autobyteus-mcp-test` got Contents/Issues/Pull requests write; private repository `AutoByteus/autobyteus-integrations-test`; board AutoByteus Project #1; token `autobyteus-integrations-test` (generated and saved by the user). Verified without printing it (repository read, board read and rename).
- Design status Ready and approved; classification unchanged (`Medium` / `High`). Next: the configured handoff (`handoff-architecture-design-complete.md`).

- Handoff (SR-007): Architecture Design Complete, Medium/High → `/software_engineering_team/architecture_reviewer` per `get_handoff_rules`; file `handoff-architecture-design-complete.md`.

### SR-008 — Architecture review ARCH-REV-001 resolved

- Trigger: architecture review Fail at ARCH-REV-001 (`design-review-report.md`): AR-001…AR-005 blocking, AR-006…AR-009 non-blocking. Classification confirmed Medium/High.
- AR-001: design spec aligned with the contract (folder name = ID; token routing as an addition under `token`; prerequisite message from the script's own wording; "What Remains" rewritten for autobyteus-337 and BEH-006…BEH-009; `check-access.sh` in the Ownership Map).
- AR-002: requirements desired outcome, UC-006, SCN-006 and § SR-003 aligned with REQ-002/SR-006; contract Status names the open part consistently; SR-005 table marked partly superseded. No new approval needed (the user's decisions already recorded).
- AR-003: headers say SR-008 and name the contract as the behavior-defining supplement; investigation-notes inventory lists the contract and handoffs.
- AR-004: DEC-007 (Solution Designer within the PM's direction): today's journey for AC-001/AC-008 now; Integrations-page journey and README rewrite in this ticket's final round (new AC-009) after autobyteus-337. Change Sequence step 5–6 and the README row aligned. The PM is told in the next report.
- AR-005: § Error Rules added (proxy vs GitHub discriminator, every proxy code placed, REST 401 → reconnect, GraphQL 200 + `errors` = refusal, matching stand-in tests).
- AR-006…AR-009: § Implementation Notes From Review; status example now "In Progress".
- Intended behavior changed: AC-009 added (the PM's own direction); no other change. Design status Ready; classification unchanged (Medium/High). Next: re-review by the architecture reviewer, scoped to these passages.

- Architecture re-review ARCH-REV-002 (SR-008): **Pass**, Medium/High confirmed; the reviewer routed to `/software_engineering_team/implementation_engineer` (informational to the Solution Designer; no duplicate forwarding). Non-blocking AR-010 (stale wording: "311", "SR-002" baselines, § SR-003 line, handoff Current SR and scope note) fixed the same day.
