# Requirements Document — Integrations foundation and the GitHub integration (autobyteus-integrations-1)

## Document Status

- Status: `Approved` at SR-008. Basis: the Solution Designer within the direction (SR-002, user informed), the user's own words for SR-003 (Integrations page), SR-004…SR-006 (manifest) and SR-007 (go-ahead: "Go ahead now, I think if the requirements are enough, then you can go ahead"); SR-008 aligns the text after architecture review ARCH-REV-001 and settles the acceptance path (DEC-007) within the PM's direction
- Current solution revision ID: `SR-008`
- Package identifier: `github-integration-foundation`
- Request / ticket: Project Task `autobyteus-integrations-1`, Project `project_39227406-f32b-4eab-a1cd-bfe27a8e8580`
- Requested by: `/project_task_manager` (run `project_task_manager_7c8dce0c4a8b44f88e776a83809dee03`), on the user's direction of 2026-10-30
- Requirements owner: Solution Designer
- Date: 2026-10-30 (resumed after the prerequisite was delivered)
- Approved by and reference: see Status (SR-002 Solution Designer within the direction; SR-003…SR-007 the user's words; SR-008 alignment and DEC-007 within the PM's direction)
- Exact approved baseline: this document at SR-008
- Behavior-defining supplements: `integration-manifest-contract.md` at SR-006 (decided with the user; approval: his words in SR-004…SR-006). The app contract it builds on is `autobyteus-server-ts/docs/modules/credential_proxy.md` on `origin/personal` @ `1a4453e553` (released in `v1.5.11-beta.4`), owned by autobyteus-311

## The User's Direction

1. Task (2026-10-30): integrations connect agents to outside services; GitHub first, then Jira, then SSH; a teammate can install it too; this first integration is the foundation; a later Integrations menu lists integrations; installing must be very easy.
2. In this conversation (2026-10-30): an integration is "skill plus authentication"; "we do not install prerequisite for the user but in the integration we maybe mention those prerequisite"; "there should be a proxy service … proxy service will get those tokens from that vault".
3. The user's order (relayed by the PM, 2026-10-30): the proxy first (done, autobyteus-311 step 1, `v1.5.11-beta.4`), then this integration.

## Problem And Desired Outcome

- Problem: agents need to work with GitHub (issues, pull requests, a Projects board) with a credential they never hold, and a teammate must be able to install the same integration on their own node. No integration exists yet, and nothing defines what an integration is in a form a later menu can read.
- Desired outcome: the integrations repository defines an integration as a **skill plus authentication**: a skill folder (instructions and scripts) with an integration manifest (`integration.json`) that names the integration, says what it is for, what token the user must provide and which tools it needs; the folder itself gives its ID, skill and icon. The first integration, GitHub, works through the delivered credential proxy: the user connects GitHub once, and the agents that may use it reach GitHub through their run's proxy address. Today the connection is the GitHub card in Server Settings with per-agent ticks; with autobyteus-337 it becomes the Integrations page, where agent access follows the skill (SR-003).
- Observable definition of success: on a node with the released app, a teammate installs the integration from the public repository, connects their own token, ticks an agent, and that agent lists the issues of a test repository and comments on one; the token is in no chat, tool output or log.

## Relevant Current And Desired Behavior

| ID | Kind | Current (evidence: investigation notes) | Desired | Preserved |
| --- | --- | --- | --- | --- |
| BEH-001 | User | Install from GitHub exists as **GitHub skill sources** (public repository root, top-level skill folders, update checks and notifications) (F-A1) | The integrations repository installs through it unchanged | The skill-source lifecycle and its name-conflict rule |
| BEH-002 | Contract | Since `v1.5.11-beta.4` (F-B1): the GitHub card stores the token in the vault; a ticked agent's run shell has `AUTOBYTEUS_GITHUB_API_URL` and git's `insteadOf` redirection; `gh`'s own commands are not supported | The GitHub integration's scripts use exactly this contract: `curl` to `$AUTOBYTEUS_GITHUB_API_URL` (REST and GraphQL) and plain `git` | The proxy contract (owned by autobyteus-311) |
| BEH-003 | User | No integration in the repository; README describes the purpose only | A `github/` integration and the documented definition | README purpose and naming |
| BEH-004 | Contract | No readable integration manifest; no Integrations page (autobyteus-337) | Each integration carries an integration manifest (`integration.json`) the Integrations page can read without changing the integration | — |
| BEH-005 | System | Cross-node: a saved Task can't cross nodes, only the description travels; local Task keys are per node (findings F-3, F-5, F-6) | The skill makes the external reference (`OWNER/REPO#N`) the shared identity in delegated descriptions and records; local Task keys are never used across nodes; each node connects its own GitHub card | Remote delegation as it is |

## Scope Guardrail (Mandatory)

### In-Scope Use Cases

| ID | Use Case | Scenarios |
| --- | --- | --- |
| UC-001 | A user or teammate installs the integrations repository and updates it from GitHub | SCN-001 |
| UC-002 | An agent with GitHub access lists, reads, creates and comments on issues | SCN-002 |
| UC-003 | An agent reads and opens pull requests (the branch pushed with git) | SCN-003 |
| UC-004 | An agent lists a Projects board's items and moves an item to another status | SCN-004 |
| UC-005 | Project Task Managers on two nodes share work through GitHub items (external reference in the description) | SCN-005 |
| UC-006 | The Integrations page (autobyteus-337) or a reader learns an integration's name, description, the token it asks for and its prerequisites from `integration.json`, and its ID, skill and icon from the folder | SCN-006 |

### Out Of Scope

- Any app change (the proxy, the GitHub card, the Integrations menu, other integrations' app definitions). Anything found missing in the app is reported (REQ-010), not built.
- Jira and SSH integrations; a licence file; third-party integration repositories.
- `gh`'s own commands (`gh issue list`, `gh pr create`): not supported by the proxy (contract "Not supported").

### Non-Goals

Installing tools for the user or bundling binaries; code that runs inside the app; protection against a same-OS-user process (the proxy's stated limit).

### Preserved Behavior Boundary

BEH-001 and BEH-002 preserved columns. Nothing on the app side changes.

### Prerequisites

| ID | Finding | Blocks | Task | Status |
| --- | --- | --- | --- | --- |
| PRE-001 | Credential proxy for integrations | UC-002…UC-005 | autobyteus-311 step 1 | **Delivered** (`v1.5.11-beta.4`, `origin/personal` `1a4453e553`) |

### Review Authority

Standard (`ticket-scope.md`).

## Requirements

| ID | Requirement | Behaviors | Feasibility evidence | Source |
| --- | --- | --- | --- | --- |
| REQ-001 | The repository installs and updates as one GitHub skill source from its public URL. Each integration is a top-level folder whose `SKILL.md` makes it a skill; skill names do not clash with common names (a clash refuses the whole source) | BEH-001 | Read (F-A1) | Task step 1–2 |
| REQ-002 | Each integration folder has an **integration manifest**, `integration.json` (the user, 2026-10-30: "let's call it integration"), as defined in `integration-manifest-contract.md`: display name, short description, the token the user provides on install (`token.help`) and the tools it needs (`prerequisites`, tool names). Facts the folder already carries are not repeated: the folder name is the ID, `SKILL.md` names the skill, `icon.svg` is the icon. No secret, no version field, no install source (SR-004…SR-006) | BEH-004 | N/A | Task step 2; the user's direction 2; 311 comment 1; SR-004, SR-005 |
| REQ-003 | The integration needs no tool beyond those it declares; it installs nothing and ships no binary | — | Measured: Docker image has bash, curl, git, jq; macOS 26 has jq (F-B3) | the user's direction 2 |
| REQ-004 | Issues: list (state filter, limit), read (with comments), create, comment, through the proxy | BEH-002 | Read (contract REST examples); P-2 (listing) | Task step 3 |
| REQ-005 | Pull requests: list, read (state, branches, changed files), open (from a branch pushed with git) | BEH-002 | Read (contract: git push through `insteadOf`) | Task step 3 |
| REQ-006 | Projects board: list items with their status, and move an item (by its `OWNER/REPO#N`) to a named status | BEH-002 | Read: GraphQL `/graphql` allowed; P-3: a personal-account board refuses fine-grained tokens. **Unclear** for an organisation board until measured with a token that has organisation Projects access (UNK-001) | Task step 3 |
| REQ-007 | Each script result is short and readable; a refusal says what to do (connect GitHub, tick the agent, token lacks a permission, path not allowed), mapped from the proxy's error codes and GitHub's status | BEH-002 | Read (contract error table) | quality for agents |
| REQ-008 | The skill never asks for, reads, prints or stores a token; never uses the ambient `gh` login or `gh auth`; when `AUTOBYTEUS_GITHUB_API_URL` is unset it tells the user how to give access and stops | BEH-002 | Read (RSK-002) | 244 DEC-001 |
| REQ-009 | The skill's cross-node rules: the shared identity of a work item is `OWNER/REPO#N`; it goes into every delegated description; local Task keys are never written to GitHub or sent to another node as an identity; each node uses its own connection | BEH-005 | Read (F-3, F-5, F-6) | Task step 3 |
| REQ-010 | The repository documents the foundation (what an integration is, the folder layout, the manifest fields, how to install, how to add one); the report lists what the Integrations page (autobyteus-337) still needs | BEH-003, BEH-004 | N/A | Task step 4, Done when |

## Acceptance Criteria

| ID | REQ | Trigger | Expected outcome | Failure outcome | Verification |
| --- | --- | --- | --- | --- | --- |
| AC-001 | REQ-001 | A teammate's isolated app instance of the **current released app** (own vault) adds `https://github.com/AutoByteus/autobyteus-integrations` as a GitHub skill source (today's journey, DEC-007) | Import succeeds; the skill `github-integration` is listed; update check shows up to date | A clash or "no valid skills" fails the import | Delivery, after finalization on `main` (the importer reads the default branch) |
| AC-002 | REQ-002 | Read each `integration.json` | Parses; required fields present, no unknown field; folder name is a valid ID; the folder has `SKILL.md`; no secret-looking value | — | Repository check script |
| AC-003 | REQ-004, REQ-007 | A ticked agent runs the issue scripts on the test repository | List shows the open issues; read shows title, body, comments; create returns `OWNER/REPO#N`; comment returns the comment URL | Unticked agent: a clear "give access" message; token without Issues write: GitHub's 403 explained | Deterministic tests against a local stand-in for the proxy, then live through the real proxy |
| AC-004 | REQ-005 | A ticked agent pushes a branch with git and opens a PR | `pulls.sh open` returns `OWNER/REPO#N`; read shows it | Missing branch: GitHub's 422 explained | Live, test repository |
| AC-005 | REQ-006 | A ticked agent moves a test item on the test board | The item's status is the requested one; list shows it | Unknown status name: the valid names listed; no board access: explained | Live, when the test board exists (user prerequisite) |
| AC-006 | REQ-008 | The agent's run and the scripts | No token in the chat, tool outputs, run files, server log or the activity log; no `gh auth` call in the scripts | — | Scan the run's data and outputs for the token value (by a test script, never printed) |
| AC-007 | REQ-009 | Read `SKILL.md` | The cross-node rules are there, with an example description carrying `OWNER/REPO#N` | — | Review |
| AC-008 | Done when (first round) | After finalization, on today's journey (DEC-007): AC-001, connect the GitHub card, tick the agent, add `github-integration` to the agent; the agent lists the test repository's issues and comments on one | Comment visible on GitHub, made by the token's account; token in no output or log | — | Delivery, teammate-way install |
| AC-009 | Done when (final round, DEC-007) | autobyteus-337 is delivered and the PM resumes this ticket | The same journey through the Integrations page (install from the GitHub card, paste token, add the skill to an agent) works with the unchanged `github/` folder; the README's install steps are rewritten for the page | A manifest field the page needs but lacks is a Requirement Gap back to the Solution Designer | This ticket's final round (Solution Designer re-opens; implementation edits README; delivery runs the check) |

## Relevant Scenarios

| ID | Kind | Actor | Goal | Trigger | Steps | Outcome | Validity |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SCN-001 | User | User or teammate | Get the integrations | Today: Skills → Manage skill sources → GitHub URL; after autobyteus-337: the Integrations page (AC-009) | Today: add source; Server Settings → Basics → GitHub card: paste token, tick agents; add `github-integration` to those agents' skills. After 337: install and paste the token on the GitHub card; add the skill to agents | The agents can use GitHub | Supported Normal |
| SCN-002 | User/agent | Agent in a ticked run | Work on issues | The user asks, or a Task needs it | Agent reads `SKILL.md`, runs `scripts/issues.sh …` | Result or clear refusal | Supported Normal |
| SCN-003 | User/agent | Agent | Propose a change | Work done on a branch | `git push` (proxy), `pulls.sh open` | PR `OWNER/REPO#N` | Supported Normal |
| SCN-004 | User/agent | Project Task Manager | Keep the shared board current | A Task changes state | `board.sh move OWNER/REPO#N --status …` | Item moved | Supported Normal |
| SCN-005 | System | Two nodes' Project Task Managers | Share one board | PM A delegates to PM B | Description carries `OWNER/REPO#N`; B works and comments there with its own connection | Both see the same GitHub item | Supported Normal (findings) |
| SCN-006 | Contract | A reader or the Integrations page | Show the integration | Reads the folder | Reads `integration.json`, the folder name, the `SKILL.md` name and `icon.svg` | Name, description, token help, prerequisites; ID, skill, icon | Supported Normal |

## External Contracts And Dependencies

| Dependency | Constraint | Evidence |
| --- | --- | --- |
| Credential proxy (`credential_proxy.md`, `v1.5.11-beta.4`) | `AUTOBYTEUS_GITHUB_API_URL`; REST and `/graphql`; git smart HTTP; no `gh` own commands, no uploads host, no LFS; Codex `read-only` sandbox can't reach it | F-B1 |
| GitHub tokens | Fine-grained: one resource owner; no personal-account Projects (P-3) | F-B2 |
| Released app version | The integration needs `v1.5.11-beta.4` or later (stated in docs, not checked in code: DESIGN.md rule 9) | F-B1 |

## Assumptions And User Prerequisites

| ID | Item | Status |
| --- | --- | --- |
| UP-001 | **A write-capable test target**, created by the user (only GitHub's web UI makes tokens): recommended a private test repository and a Projects board under the AutoByteus organisation, and a fine-grained token limited to that repository (Issues, Pull requests, Contents: read/write; Metadata: read) with organisation Projects read/write, saved in an owner-private file under `~/.autobyteus-test/secrets/`. Needed for AC-003…AC-005 and AC-008 live; asked with the design | Partly done 2026-10-30: the existing fine-grained token `autobyteus-mcp-test` (only `ryan-zheng-teki/autobyteus-mcp-test`, expires 2026-11-25) now has Contents, Issues and Pull requests read and write, Metadata read; edited in the browser by the Solution Designer after the user signed in (GitHub: "Your personal access token has been updated"; token page: "Read and Write access to code, issues, and pull requests"). The token value is unchanged and was never displayed. **Board target done 2026-10-30** (the user chose the organisation board: "it can be tested like end to end"): private repository `AutoByteus/autobyteus-integrations-test` (created by the Solution Designer with the user's `gh` login, he is org admin), board AutoByteus Project #1 "AutoByteus Integrations Test Board" (Status: Todo, In Progress, Done), fine-grained token `autobyteus-integrations-test` (owner AutoByteus; only that repository: Contents, Issues, Pull requests read/write, Metadata read; organisation Projects read/write; expires 2026-11-29), generated by the user and saved by him in `~/.autobyteus-test/secrets/github-integration-test.env` (mode 600, key `GITHUB_INTEGRATION_TEST_TOKEN`). Verified without printing it: repository read HTTP 200, board read, board rename (write) succeeded; `/tmp/gh-int-probe/check-token.sh` |
| ASM-001 | The organisation allows fine-grained tokens | To confirm when the token is made |

## Decisions

| ID | Question | Reasoning And Recommendation | Owner | Status |
| --- | --- | --- | --- | --- |
| DEC-001 | Credential delivery | The credential proxy (the user's direction 2) | User | Decided by the user |
| DEC-002 | Install path | GitHub skill sources (exist, update checks); agent packages need `agents/`/`agent-teams/` | Solution Designer | Decided |
| DEC-003 | Tools | Declared by name in `prerequisites` (checked with `command -v`; SR-006); never installed or bundled (the user's direction 2) | Solution Designer with the user's direction | Decided |
| DEC-004 | "Through `gh`" (Task) | The proxy does not support `gh`'s own commands (measured in 311, H-1). The scripts use `curl` against `$AUTOBYTEUS_GITHUB_API_URL` and plain `git`; the skill tells agents that `GH_TOKEN=unused gh api "$AUTOBYTEUS_GITHUB_API_URL/…"` also works for one-off calls. Same capabilities, no new app work | Solution Designer, within the proxy direction | Decided |
| DEC-005 | Where the credential's hosts are defined | In the app (`IntegrationDefinition`, 311): an installed integration can't change where a token goes. The definition file only names the connection (`github`) | 311 (app contract) | Given |
| DEC-006 | Scripts or plain `curl` in `SKILL.md` | Scripts for the listed operations: they keep outputs short, escape text safely (jq), turn the board move's three GraphQL steps into one command and explain refusals the same way; `SKILL.md` also shows plain `curl` for anything else | Solution Designer | Decided |

## Readiness Check

- Content ready for approval: Yes. Approved basis ready for design: Yes (SR-008). UP-001 done (SR-007); AC-009 waits for autobyteus-337.

## SR-003 — The user's direction on installing and configuring (2026-10-30)

The user, in the Solution Designer conversation (after seeing the design):

- "Why does the user have to go to a server setting to do the GitHub thing? … Each integration should handle their own configuration."
- "each integration has their own card … when we install the integration the integration will ask the user to … log in GitHub or … provide some kind of token … it's basically a skill … if it's integration it's just a nicer way of configuring things and also install the skill … then the user can basically go to any agent like how they do now and install that skill. This is how I imagined."

Resulting intended behavior (this changes UC-001 and the install steps of SCN-001; renewed approval: the user's own words above):

| ID | Behavior |
| --- | --- |
| BEH-006 | An **Integrations page** in the app (not Server Settings) lists integrations, each with its own card (name, description from `integration.json`, state). |
| BEH-007 | **Installing** an integration from its card installs its skill and then asks the user for what the integration needs (a token today; a sign-in later), stored in the vault. |
| BEH-008 | **Agent access follows the skill:** the user adds the integration's skill to an agent the usual way (agent settings), and that agent's runs can use the integration. No separate per-agent tick on a settings card. |
| BEH-009 | The GitHub card leaves Server Settings → Basics (clean cut) and becomes the GitHub card of the Integrations page. |

- This is app work outside this repository, now Project Task autobyteus-337 (first framed as a step of autobyteus-311): prerequisite **PRE-002** (`handoff-prerequisite-integrations-page.md`).
- This repository's part is unchanged in kind: the `github/` folder (skill, scripts) and `integration.json`, which carries what the page's card asks the user for (`token.help`, per `integration-manifest-contract.md` at SR-006).
- Open for the page's design (not decided here): whether the app or the integration's `integration.json` decides where a token may be sent (options (a)/(b) shown to the user; he did not choose); whether agents with "all installed skills" get integration access automatically (Solution Designer's recommendation: no, only explicitly configured skills grant access).
- Status: requirements SR-003 Approved for this repository's part (the user's direction). Acceptance path: settled at SR-008 by DEC-007 (today's journey now, AC-001/AC-008; the Integrations-page journey and README rewrite in this ticket's final round, AC-009, after PRE-002).
- PRE-002 recorded as Project Task **autobyteus-337** (AutoByteus Project) by the PM, 2026-10-30; not yet dispatched (the PM asks the user to give it to the copy that built the proxy). The repository part waits only for the user's build-now-or-wait answer.

## SR-008 — Alignment after architecture review ARCH-REV-001

| ID | Question | Reasoning And Recommendation | Owner | Status |
| --- | --- | --- | --- | --- |
| DEC-007 | Which install journey counts toward this ticket's done-when, and who updates the README when 337 moves the card? (AR-004) | The PM set it: "Autobyteus-integrations-1 stays open and paused for the page part; the repository part … is yours to build … I will message you when the page is delivered." So: the repository part is finalized now and proven on today's released journey (AC-001, AC-008: skill source + GitHub card in Server Settings + skill on the agent); the README documents that journey and says it moves to the Integrations page with autobyteus-337. When 337 is delivered, this ticket's final round proves the page journey with the unchanged folder and rewrites the README install steps (AC-009). 337 itself changes no file in this repository. | Solution Designer within the PM's direction | Decided |
