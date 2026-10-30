# Design Spec — Integrations foundation and the GitHub integration (autobyteus-integrations-1)

## Solution And Approval Basis

- Current solution revision ID: `SR-008`
- Approved requirements: `requirements-doc.md` at SR-008 (basis in its Document Status: the Solution Designer within the direction, and the user's own words for SR-003…SR-007)
- Behavior-defining supplements: `integration-manifest-contract.md` at SR-006 (decided with the user), the authority for `integration.json` and the folder conventions
- Design status: `Ready`; approved by the user for building, 2026-10-30 ("Go ahead now, I think if the requirements are enough, then you can go ahead"), with the manifest contract at SR-006
- Investigation notes: `investigation-notes.md` (this folder)
- Authorities read (2026-10-30): `references/architecture-design.md`, `references/design-principles.md`; project `DESIGN.md` of the app repository (`AutoByteus/autobyteus-workspace`, `origin/personal` `1a4453e553`), which this repository follows for vocabulary (an integration is a connection to an outside service); this repository has no `DESIGN.md` or glossary (`No project DESIGN.md found` here)
- Conflicts or discrepancies: none

## Current-State Read

- The repository holds a README only (`origin/main` `6fa9bbc`).
- The app side is complete for GitHub (F-B1): the user connects GitHub on the GitHub card and ticks agents; each ticked run's shell gets `AUTOBYTEUS_GITHUB_API_URL` and git's redirection; the app owns where the token may go.
- Install exists as GitHub skill sources (F-A1): the whole public repository is one source; a top-level folder with `SKILL.md` is a skill; extra folders without `SKILL.md` (`docs/`, `tickets/`, `tools/`, `tests/`) are ignored; a name clash refuses the whole import.

## Intended Change

Add to the integrations repository: the documented integration definition, a repository check, and the first integration `github/` (skill, definition, scripts, tests). No app change.

## Change Scope (Mandatory)

- In scope: UC-001…UC-006. Areas: repository docs (`README.md`, `docs/`), `github/`, `tools/check-integrations.sh`, `tests/github/`.
- Derived consumers: `integration.json` is a new structure; its readers are `tools/check-integrations.sh` now and the Integrations page later (autobyteus-337). `SKILL.md` is read by the app's skill catalog (name, description).
- Deliberately left alone: the app (proxy, card, catalog, importer); `task-plans/` (the PM's untracked notes); a licence.
- Follow-ups: FU-001 (the ambient `gh` login on this node).

## Relevant Behavior And Production-Path Map

| Behavior | Requirement / AC | Trigger | Existing | Change | Target path / spine |
| --- | --- | --- | --- | --- | --- |
| BEH-001 | REQ-001; AC-001 | User adds the source | skill sources (F-A1) | Repository shaped for it | DS-001 |
| BEH-002 | REQ-004…008; AC-003…006 | Agent runs a script | proxy contract (F-B1) | Scripts on that contract | DS-002, DS-003 |
| BEH-004 | REQ-002, REQ-010; AC-002 | A reader or menu | none | `integration.json` + docs | DS-004 |
| BEH-005 | REQ-009; AC-007 | PM delegates across nodes | findings F-3/F-5/F-6 | Skill rules | DS-005 |

## Task Design Health Assessment (Mandatory)

- Change posture: Feature (new content in a new repository).
- Current design issue found: No.
- Structural triggers: Capability-area reuse fires: install reuses GitHub skill sources, credential delivery reuses the proxy, no new mechanism. Repeated coordination: the three operation scripts share request, error and output handling, so it lives once in `scripts/lib.sh` (Principle 13). Vocabulary: `integration` keeps its one meaning; the integration's ID is its folder name (`github`), which is also the app's connection name: one name on both sides (Principle 15). Others (persistence, legacy, shared folder) don't apply: no app code, no stored data.
- Root cause classification: No Design Issue Found. Refactor needed now: No.

## Terminology

- **Integration**: a connection to an outside service: here, a folder with a skill and its definition. Its ID equals the app's integration ID when the app delivers its credential (`github`).
- **Integration definition**: `integration.json` in the integration folder.
- **Connection**: what the user sets up in the app for an integration (the GitHub card: token in the vault, ticked agents); `connections.json` on the app side.
- **External reference**: `OWNER/REPO#N`, the shared identity of a GitHub issue or pull request.

## Data-Flow Spine Inventory

| ID | Scope | Behaviors | Start | End | Owner | Why |
| --- | --- | --- | --- | --- | --- | --- |
| DS-001 | Primary | BEH-001 | User adds the repository URL | Skill in the catalog | App skill sources | Install and update |
| DS-002 | Primary | BEH-002 | Agent runs an issue/PR/board script | GitHub's answer printed short | `github/scripts/lib.sh` (request) via the app proxy | Every operation |
| DS-003 | Primary | BEH-002 | Agent pushes a branch | Branch on GitHub | git + proxy (`insteadOf`) | PRs need a pushed branch |
| DS-004 | Primary | BEH-004 | Reader / menu | Integration shown | `integration.json` | The foundation |
| DS-005 | Primary | BEH-005 | PM A delegates | PM B works the same item | `SKILL.md` rules | Shared board across nodes |

## Primary Execution Spines

- DS-001: `Settings → Skills (add GitHub source) → SkillSourceService import → catalog finds github/SKILL.md → agent's skills include github-integration`
- DS-002: `Agent (reads SKILL.md) → scripts/issues.sh comment → lib.sh gh_request → $AUTOBYTEUS_GITHUB_API_URL (run pass) → app proxy (checks, adds token) → api.github.com → lib.sh maps status/codes → short line to the agent`
- DS-003: `Agent → git push https://github.com/OWNER/REPO.git → git insteadOf → app proxy git route → github.com`
- DS-004: `Integrations page or tools/check-integrations.sh → <folder>/integration.json (+ folder name, SKILL.md name, icon.svg) → name, description, token help, prerequisites`
- DS-005: `PM A → delegate_task (description with OWNER/REPO#N) → PM B → board.sh / issues.sh on OWNER/REPO#N with B's own connection`

## Ownership Map

| Node | Owns |
| --- | --- |
| `SKILL.md` | When to use which script; rules (REQ-008, REQ-009); the prerequisite check; raw `curl` for other calls |
| `integration.json` | The facts a reader needs (REQ-002); nothing executable |
| `scripts/lib.sh` | The one request path: presence check of `AUTOBYTEUS_GITHUB_API_URL` and tools, `curl` call, the refusal rules (§ Error Rules), JSON building with `jq`, REST and GraphQL helpers |
| `scripts/check-access.sh` | The connection check: is the variable set, does `GET /user` answer; prints the login or what to do |
| `scripts/issues.sh`, `pulls.sh`, `board.sh` | One subject each: argument parsing, the calls for that subject, output format |
| `tools/check-integrations.sh` | Repository rule checks (AC-002) |
| App (not changed) | Install, the token, the hosts, the run pass, the activity log |

## Off-Spine Concerns

| Concern | Serves | Responsibility |
| --- | --- | --- |
| Error explanation (in `lib.sh`) | DS-002 | The refusal rules of § Error Rules: proxy code, GitHub status, GraphQL `errors` → a sentence, the next step and an exit code |
| Prerequisite check (in `lib.sh`) | DS-002 | `command -v` for each tool the script uses; message from the script's own wording ("jq is needed; install it, then run again"). Scripts never read `integration.json` |
| Deterministic test stand-in (`tests/github/fake-api.py`) | tests | A local HTTP server that records requests and answers like GitHub and like the proxy's refusals |

## Ownership Boundaries And Dependency Rules

- Scripts depend only on the proxy contract (`AUTOBYTEUS_GITHUB_API_URL`, git), `bash`, `curl`, `jq`, `git`. Forbidden: any token variable (`GH_TOKEN` with a real value, `GITHUB_TOKEN`), `gh auth`, `gh` own commands, `https://api.github.com` directly, writing tokens or responses with headers to files.
- `issues.sh`/`pulls.sh`/`board.sh` call GitHub only through `lib.sh`. `lib.sh` knows no subject.
- Nothing reads `integration.json` at runtime in this ticket (only the check script and later the menu); the scripts don't depend on it.

## Interface Boundary Mapping

References are always `OWNER/REPO#N` (issues and PRs) or `OWNER/REPO` (lists). Long text comes from a file or `-` (stdin), never an argument, so quoting can't break it.

| Command | Subject | Output |
| --- | --- | --- |
| `issues.sh list OWNER/REPO [--state open\|closed\|all] [--limit N]` | issues | one line each: `OWNER/REPO#N [state] title (labels)` |
| `issues.sh read OWNER/REPO#N [--comments N]` | one issue | title, state, author, labels, URL, body, last N comments |
| `issues.sh create OWNER/REPO --title TEXT --body-file FILE\|-` | issues | `OWNER/REPO#N <url>` |
| `issues.sh comment OWNER/REPO#N --body-file FILE\|-` | one issue | `commented on OWNER/REPO#N: <comment url>` |
| `pulls.sh list OWNER/REPO [--state …] [--limit N]` | PRs | one line each with head → base |
| `pulls.sh read OWNER/REPO#N` | one PR | title, state, draft, head → base, mergeable, changed files with +/−, body |
| `pulls.sh open OWNER/REPO --head BRANCH --base BRANCH --title TEXT --body-file FILE\|- [--draft]` | PRs | `OWNER/REPO#N <url>` |
| `board.sh items --owner LOGIN --number P [--status NAME]` | a board | `OWNER/REPO#N [Status] title` |
| `board.sh move OWNER/REPO#N --owner LOGIN --number P --status NAME` | one board item | `moved OWNER/REPO#N to NAME` |
| `check-access.sh` | the connection | `GitHub access: connected as @login` or what to do |

Exit codes: 0 done; 2 usage; 3 no access (variable unset, proxy `RUN_PASS_INVALID`, `INTEGRATION_NOT_ALLOWED`, `INTEGRATION_NOT_CONNECTED`, `NOT_LOOPBACK`, or GitHub's 401 on the API route); 4 refused (proxy `PATH_NOT_ALLOWED`; GitHub 403/404/422; a GraphQL answer with `errors`); 5 unreachable or failed (proxy `UPSTREAM_UNREACHABLE`, `PROXY_FAILED`, any 5xx, curl failure).

## Error Rules (owned by `lib.sh`; AR-005)

1. **Who answered.** A response whose JSON body has a string `error` field matching `^[A-Z_]+$` (one of the codes in `credential_proxy.md`) is the proxy's own refusal; anything else is GitHub's answer. GitHub's error bodies have `message`, never a top-level `error` code.
2. **Proxy refusals** → the proxy's `message` plus the next step: `INTEGRATION_NOT_CONNECTED` "connect GitHub in AutoByteus"; `INTEGRATION_NOT_ALLOWED` / `RUN_PASS_INVALID` "this agent has no GitHub access in this run: give the agent the integration, then start a new run"; `NOT_LOOPBACK` "run the script on the AutoByteus machine"; `PATH_NOT_ALLOWED` "this call is outside what the GitHub integration allows"; `UPSTREAM_UNREACHABLE`, `PROXY_FAILED` "GitHub could not be reached; try again".
3. **GitHub's status** (REST): 401 "the token was rejected (expired or revoked): reconnect GitHub in AutoByteus" (exit 3); 403/404 GitHub's `message` plus "the token may lack a permission or the repository is not in its list"; 422 GitHub's `message` and `errors` (for example a missing branch); 5xx exit 5.
4. **GraphQL** (`board.sh`, and any `/graphql` call): an HTTP 200 whose body has a non-empty `errors` array is a refusal (exit 4) with each `errors[].message` (and `type`, e.g. `FORBIDDEN`, `NOT_FOUND`, `INSUFFICIENT_SCOPES`) and the permission hint; it is never reported as success. HTTP 401 follows rule 3.
5. The deterministic tests (`tests/github/`) have one stand-in case per rule: each proxy code, REST 401/403/404/422, GraphQL 200 + `errors`, and a GitHub body that merely contains the word "error" (must not be taken for a proxy refusal).

`board.sh` uses GraphQL: find the project (`user` or `organization` by login, project number) with its Status field and options; find the item for the issue/PR in that project (add it if absent: `addProjectV2ItemById`); `updateProjectV2ItemFieldValue` with the option. An unknown status lists the valid ones.

## Concrete Examples

What the agent's shell has (from the app, nothing from us):

```bash
AUTOBYTEUS_GITHUB_API_URL=http://127.0.0.1:53114/r/rp_…/github/api   # a run pass, not the token
GIT_CONFIG_COUNT=1  GIT_CONFIG_KEY_0=url.http://127.0.0.1:53114/r/rp_…/github/git/.insteadOf  GIT_CONFIG_VALUE_0=https://github.com/
```

What an agent runs (skill folder path from the catalog):

```bash
S=<skill folder>/scripts
$S/issues.sh list AutoByteus/autobyteus-integrations-test
printf 'Done in commit abc123.\n' | $S/issues.sh comment AutoByteus/autobyteus-integrations-test#3 --body-file -
git push -u origin fix/readme && $S/pulls.sh open AutoByteus/autobyteus-integrations-test --head fix/readme --base main --title "Fix README" --body-file notes.md
$S/board.sh move AutoByteus/autobyteus-integrations-test#3 --owner AutoByteus --number 1 --status "In Progress"
# anything else, directly:
curl -s "$AUTOBYTEUS_GITHUB_API_URL/repos/OWNER/REPO/labels"
```

Who adds the token: the app's proxy, on its side, for that run only; the agent never sees it.

`github/integration.json` follows the **integration manifest contract**, `integration-manifest-contract.md` (this folder; SR-004), which is the authority for the fields. The GitHub example is there. The app version it needs (`v1.5.11-beta.4`, the proxy) is stated in the README, not in the manifest (DESIGN.md rule 9).

How Jira reuses it later (not built here): the app adds a Jira connection on the same proxy (311's "Adding An Integration"; or, if 337 decides the integration declares where its token goes, an addition under the manifest's `token`); this repository adds the folder `jira/` (its name is the ID) with `integration.json`, `SKILL.md` and its scripts on the same pattern.

Avoided shape: scripts that read `GH_TOKEN`/`gh auth token`, or that call `https://api.github.com` directly; an `integration.json` that lists hosts the token may go to (the app owns that).

## Removal / Decommission Plan

None (new content). README text "No integration is published yet" is replaced.

## Backward-Compatibility Rejection Log

| Candidate | Decision |
| --- | --- |
| A fallback to `gh`'s own login when the variable is unset | Rejected: it bypasses the proxy (REQ-008) |
| Version fields or checks in the definition | Rejected (DESIGN.md rules 8, 9) |

## Persisted Data / State Transition Decision

Not Affected: no stored data; the app's stores are unchanged.

## Target Folder / File Mapping

| Path | Kind | Responsibility | Must not contain |
| --- | --- | --- | --- |
| `README.md` | File | What an integration is; available integrations; today's install journey (skill source; GitHub card in Server Settings → Basics with the agent ticked; `github-integration` added to the agent; the agent needs a terminal tool, or for Codex a sandbox other than `read-only`), with a note that it moves to the Integrations page with autobyteus-337 (rewritten in this ticket's final round, DEC-007); the app version needed (`v1.5.11-beta.4` or later); link to `docs/integration-manifest.md`; licence note kept | secrets, licence grant |
| `docs/integration-manifest.md` | File | The integration manifest contract (from `integration-manifest-contract.md`): layout, every `integration.json` field, rules for scripts (proxy only, prerequisites declared, no binaries), how to add an integration | app internals |
| `github/SKILL.md` | File | `name: github-integration`; when to use; check access first; the commands; plain `curl` examples; rules (no token, no `gh auth`, cross-node `OWNER/REPO#N`); error meanings | tokens, examples with real tokens |
| `github/integration.json` | File | The integration manifest per `integration-manifest-contract.md` (SR-006: `name`, `description`, `token.help`, `prerequisites`) | secrets, unknown fields |
| `github/scripts/lib.sh` | File | Shared request, error and output helpers | subject logic |
| `github/scripts/check-access.sh`, `issues.sh`, `pulls.sh`, `board.sh` | Files | One subject each (executable) | direct GitHub URLs |
| `tools/check-integrations.sh` | File | AC-002 checks for every integration folder | — |
| `tests/github/fake-api.py`, `tests/github/run-tests.sh` | Files | Deterministic script tests against a local stand-in (Python 3 standard library, run with `-I`) | real tokens or network |
| `tickets/in-progress/github-integration-foundation/` | Folder | These documents (moved to `tickets/done/` at delivery) | secrets |

Placing `tools/` and `tests/` at the top keeps the installed skill folder lean and they are ignored by the catalog (no `SKILL.md`).

## Change Sequence

1. `docs/integration-manifest.md`, `tools/check-integrations.sh`.
2. `github/scripts/lib.sh`, then the subject scripts, with `tests/github/` against the stand-in.
3. `github/SKILL.md`, `github/integration.json`, README.
4. Live check through a real app proxy (isolated instance or built server of `v1.5.11-beta.4`, own vault; token sent once by a script from the owner-private file, never through chat), using the worktree's folder as a local skill source: AC-003…AC-006.
5. Finalize on `main`, then the teammate-way check on today's released journey (AC-001, AC-008; DEC-007).
6. Final round, when autobyteus-337 is delivered and the PM resumes this ticket: the Integrations-page journey with the unchanged folder, and the README install steps rewritten (AC-009).

## Verification Intent

- Deterministic: `tests/github/run-tests.sh` (requests built, outputs, error mapping, no token variable used); `tools/check-integrations.sh`.
- Live: one agent (Codex runtime with a throwaway `CODEX_HOME`, auto-execute or `workspace-write`, since `read-only` can't reach the proxy) in an isolated instance with its own vault; the token connected by `connectGitHubIntegration` from a script reading the file; the agent ticked; the run's outputs, run files, server log and `integrations/activity.jsonl` scanned for the token by a script that prints only counts.
- The activity log shows the calls (method, path, status), proving they went through the proxy.

## Key Tradeoffs

- Scripts vs plain `curl`: scripts cost a few files but make the common operations safe and short for agents; plain `curl` stays available.
- One repository source installs every integration in it: simple now; per-integration install is an Integrations-page concern (autobyteus-337).

## Risks

- R-1: organisation board with a fine-grained token not yet measured (UNK-001) → AC-005 depends on UP-001.
- R-2: write paths through the proxy not proven against GitHub (F-B2) → the live check covers them.
- R-3: the ambient `gh` login on a node (FU-001) is outside our control; the skill forbids it.

## What Remains For The Integrations Page (autobyteus-337)

Measured against the user's direction (BEH-006…BEH-009):

1. List integrations from `integration.json` (name, description) plus the folder (ID, `SKILL.md` name, `icon.svg`), for the official repository before install and for installed sources.
2. Install from the card: add the source (today one repository source installs all its integrations), then ask for the token using `token.help`; store it in the vault (Test, Remove).
3. Agent access follows the skill: an agent whose configured skills include the integration's skill gets the proxy in its runs; this replaces the per-agent tick of the GitHub card (`setGitHubIntegrationAgentAccess`).
4. Move the GitHub card from Server Settings → Basics to the page (clean cut).
5. Show the card's state (not installed / needs token / connected as @login) and each prerequisite's `command -v` result per node.
6. Settle with the user: who decides where a token may go (if the integration, an addition under `token`); whether "all installed skills" agents get integration access (recommended: no).
7. Optional later: install a single integration (the importer accepts a repository root only).

## Guidance For Implementation

- Reproduction to start from: none (new content). Never put a real token in a test; the stand-in checks that scripts send no `Authorization` of their own.
- Bash: `set -euo pipefail`; quote everything; build JSON only with `jq -n --arg`; never print request headers.

## Task Size And Architectural Risk (Mandatory)

- Task size: `Medium`: about 12 files in one new repository, one capability area, no app code.
- Architectural risk: `High`: it creates a new public contract (`integration.json` and the folder layout) that every later integration and the menu depend on, and it handles a credential-backed write path (comments, PRs, board moves) for the first time against GitHub.
- Escalation trigger: any need to change the app or the proxy contract → stop and return to the Solution Designer.

## Live Test Target (SR-007)

- Repository `AutoByteus/autobyteus-integrations-test` (private), board AutoByteus Project #1 "AutoByteus Integrations Test Board" (Status: Todo, In Progress, Done). Safe to change; tests create their own issues, branches and PRs there.
- Token: `~/.autobyteus-test/secrets/github-integration-test.env`, key `GITHUB_INTEGRATION_TEST_TOKEN` (owner-private; expires 2026-11-29). Read only by a test script and sent once to the test instance (`connectGitHubIntegration`); never printed, never in chat or commits.
- The older token `test.github.token` (`ryan-zheng-teki/autobyteus-mcp-test`, now also issues/PR/contents write, expires 2026-11-25) is not needed for this ticket.
- The manifest contract (`integration-manifest-contract.md`) governs `integration.json`; `docs/integration-manifest.md` is written from it (the design's earlier name `docs/integration-definition.md` is replaced).

## Implementation Notes From Review (SR-008, AR-006…AR-009)

- `issues.sh list` leaves out pull requests (REST items with `pull_request`), applying `--limit` after filtering; one stand-in test.
- `SKILL.md` and README: the agent needs a terminal tool (native runtime) or a Codex sandbox other than `read-only`; push with the `https://github.com/OWNER/REPO.git` URL (an SSH remote bypasses the proxy).
- `board.sh move`: when the item is not on the board it is added first (`addProjectV2ItemById`) and the output says so (`added OWNER/REPO#N to the board; moved to In Progress`). Status names match case-insensitively; the output uses the board's spelling; an unknown name lists the valid ones.
- `tools/check-integrations.sh` fails a top-level folder that has exactly one of `SKILL.md` and `integration.json`.
