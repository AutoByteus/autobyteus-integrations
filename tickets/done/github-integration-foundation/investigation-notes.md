# Investigation Notes — Integrations foundation and the GitHub integration

## Investigation Meta

- Package identifier: `github-integration-foundation`
- Request / ticket: Project Task `autobyteus-integrations-1` (Project `project_39227406-f32b-4eab-a1cd-bfe27a8e8580`)
- Workspace root: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation` (the integrations repository)
- Repository mode: Git
- Task worktree / branch: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation`, branch `codex/github-integration-foundation`
- Resolved base remote / branch / revision: `origin/main` @ `6fa9bbc` (`AutoByteus/autobyteus-integrations`, fetched 2026-10-30)
- Finalization target remote / branch: `origin/main` of `AutoByteus/autobyteus-integrations`
- App source read from: detached read-only worktree `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation-app-read` at `origin/personal` @ `8760c83788` (fetched 2026-10-30). No app change is made there; it is removed at the end.
- Bootstrap result: OK. Ticket folder `tickets/in-progress/github-integration-foundation/` follows the sibling repositories (`autobyteus-agents`, `autobyteus-skills` keep `tickets/` in the repository). The PM's untracked `task-plans/` folder is not touched.
- Bootstrap blocker: none
- Current solution revision ID: `SR-001`
- Authorities read (requirements gate, 2026-10-30): `references/requirements-engineering.md`, `references/finding-the-cause.md`, `references/ticket-scope.md`; also the project `DESIGN.md` (vocabulary rule) and `GLOSSARY.md` (MCP Secrets section)
- Investigation status: requirements investigation complete; architecture investigation pending approval

## Initial Request And Clarifications

- Original request: the Task text (foundation: definition and install path; the GitHub integration through `gh` with the vault credential; report which of the three app behaviours exist; propose the smallest app change; done when an agent with the vault credential lists and comments on an issue of a test repository, installed the way a teammate would).
- Clarifications in the Task comments: start now; keep the foundation general (a teammate installs it); the Task moved from the Agent Package Creator to this team.
- User-supplied constraints: no secret committed anywhere; no licence file; DESIGN.md vocabulary (an integration is a connection to an outside service, not a plugin).
- Initial ambiguity: the Task says beta.10 delivered "the platform supplies [a credential] only when a command runs". Verified below: not so (F-A2).

## Source Log

| Date | Type | Source | Why | Finding |
| --- | --- | --- | --- | --- |
| 2026-10-30 | Doc | `tickets/done/secrets-and-integrations-design/requirements-doc.md` (`origin/personal`) | What autobyteus-244 approved and built | Scope narrowed (SR-004) to **MCP server secrets in the vault** (MREQ-001…008). Skill/CLI credential use (UC-003) became follow-up FU-001 (credential proxy). DEC-002, DEC-005…DEC-008, DEC-010 still `Needs user` |
| 2026-10-30 | Doc | same ticket, `follow-ups.md`, `solution-validation.md` | The command path | FU-001 "Skill scripts and CLIs have no way to use an integration without holding its secret" (not built). V4: env injection is readable by a same-user shell; V6: a broker-run `gh` needs a subcommand allow-list, else `gh auth token` leaks |
| 2026-10-30 | Command | `git tag --contains 9eda0fdb75` | Which release has 244 | first tag `v1.5.9-beta.10` (the "beta.10" of the Task); also in stable `v1.5.10` |
| 2026-10-30 | Code | `autobyteus-server-ts/src/secret-management/**` (file list), `docs/modules/secret_management.md` | Vault consumers today | Consumers: provider credentials, managed Claude credentials, MCP secrets (`{kind:"mcpServer", vaultSecretId:"mcp.<uuid>"}`). No consumer for a skill, a command or a shell |
| 2026-10-30 | Doc | `autobyteus-server-ts/docs/modules/mcp_server_management.md` §Secret Values, §Supported Transports | How a credential reaches an MCP server | Remote server: the `token` / `Authorization` header (always secret) resolved from the vault at connect into request headers, in server memory. Stdio: into that child's env (readable by `ps -E`, accepted MDEC-003). Bulk import of an entry without the token works; the user then enters the token, stored as `mcp.<uuid>` |
| 2026-10-30 | Code | `tests/e2e/mcp/mcp-github-remote-live.e2e.test.ts` | Proof of the GitHub route | Live check: GitHub remote MCP (`https://api.githubcopilot.com/mcp/`) with the `Authorization` header in the vault reads issue #1 of `ryan-zheng-teki/autobyteus-mcp-test`; the token is in no response, output or file |
| 2026-10-30 | Doc+Code | `docs/modules/skills.md` §Managed GitHub source lifecycle; `src/skills/services/skill-source-service.ts`, `skill-discovery.ts` (`inspectGitHubSkillRepository`), `src/integrations/github/github-repository-source.ts` (`parseGitHubSkillRepository`) | Install from GitHub | **GitHub skill sources** exist: import a public `https://github.com/<owner>/<repo>` (repository root only, "no branch or subfolder"); skills found as a root `SKILL.md`, or direct child folders with `SKILL.md`, plus nested `skills/` chains. Background update checks and notifications, confirmed Update, Remove. Scripts are never executed at install; file modes kept (`& 0o777`) |
| 2026-10-30 | Code | `src/agent-packages/utils/package-root-summary.ts:55-80` (`validatePackageRoot`), `installers/github-agent-package-installer.ts`, `services/github-agent-package-updates.ts` | Can integrations use the agent-package path? | No: an agent package must contain `agents/`, `agent-teams/` or `applications/`. Both installers share the GitHub transport `src/integrations/github/` |
| 2026-10-30 | Code | `git grep -i integration origin/personal -- autobyteus-server-ts/src` | Listing integrations | No integration catalog, definition reader or menu. (`src/integrations/github/` is the shared GitHub download transport, not this concept.) |
| 2026-10-30 | Doc | `skills.md` §Import validation | Install risk | A skill name already present in tiers 1–3 rejects the whole source import (`SKILL_NAME_CONFLICT`) |
| 2026-10-30 | Command | `gh --version; gh auth status` (token masked) | What an agent shell has today on this node | `gh` 2.86.0 installed, logged in as `ryan-zheng-teki` from the keyring with a broad token (scopes `repo`, `workflow`, `read:org`, `gist`). An agent shell on this node can already run `gh` with that token, and `gh auth token` would print it (V6) |
| 2026-10-30 | Web | github/github-mcp-server `README.md`, `docs/remote-server.md` | Capabilities | Default toolsets `context, repos, issues, pull_requests, users`; `projects` must be selected (`/x/projects` path or `X-MCP-Toolsets` header; `X-MCP-Readonly` for read-only). Remote server not available for GitHub Enterprise Server |
| 2026-10-30 | Web | GitHub docs "Managing your personal access tokens"; community discussion #36441 | Board access | Fine-grained tokens can't access Projects owned by a **user account**; organisation Projects use the org permission "Projects". Classic tokens with `project` scope reach user Projects |
| 2026-10-30 | Web | GitHub docs "Set up the GitHub MCP server" | Who can use the remote server | Pages disagree whether Copilot access is a prerequisite; PAT via `Authorization` header is documented |

## Runtime, Probe, Or Reproduction Findings

Probes in `/tmp/gh-int-probe/` (disposable, outside every repository), using the existing **read-only** test token `autobyteus-mcp-test` (only `ryan-zheng-teki/autobyteus-mcp-test`, expires 2026-11-25) read from `~/.autobyteus-test/secrets/github-mcp-test.env` into a shell variable. The token was never printed; each probe checks that no output contains it.

| ID | Method | Observation | Established | Implication |
| --- | --- | --- | --- | --- |
| P-1 | `probe.sh "issues,pull_requests,projects"`: MCP `initialize` + `tools/list` on `https://api.githubcopilot.com/mcp/` with `X-MCP-Toolsets` | HTTP 200; 23 tools incl. `list_issues`, `issue_read`, `issue_write`, `add_issue_comment`, `pull_request_read`, `list_pull_requests`, `create_pull_request`, `projects_list`, `projects_get`, `projects_write` (`update_project_item` sets a field such as Status). Token occurrences in output: 0 | Measured | Every capability the Task lists exists on GitHub's MCP server, selectable by a plain header |
| P-2 | `call.sh issues list_issues ryan-zheng-teki/autobyteus-mcp-test` | Returned issue #1 "MCP live check: test issue". Token occurrences: 0 | Measured | Listing works with a fine-grained token |
| P-3 | `call.sh projects projects_list list_projects owner=ryan-zheng-teki owner_type=user` | `403 Resource not accessible by personal access token` | Measured | Board moves on a **user-owned** board can't work with a fine-grained token; need an organisation board (fine-grained token with org Projects permission) or a classic token |

- Not measured: writing (comment, create issue, open PR, board move): no token with write access exists. Organisation board access with a fine-grained token: no such token.
- Temporary diagnostics: none in any repository. Probes stay in `/tmp/gh-int-probe/` and are deleted at the end.

## Findings: the three app behaviours today

| ID | Behaviour | Exists? | Evidence |
| --- | --- | --- | --- |
| F-A1 | Install (and update) an integration from GitHub | **Yes, through GitHub skill sources** (not agent packages). Constraint: the whole public repository is one source; integrations must be top-level folders (or under `skills/`); a skill-name clash rejects the whole import | `skill-source-service.ts`, `skill-discovery.ts:200-212`, `github-repository-source.ts` `parseGitHubSkillRepository`; `package-root-summary.ts:55-80` |
| F-A2 | Hand a declared vault credential to a command (`gh`, a script) | **No.** Only to an MCP server: remote header in server memory, or stdio child env. 244 left the command path as FU-001 (credential proxy) | 244 `requirements-doc.md` SR-004, `follow-ups.md` FU-001; `secret_management.md` consumers |
| F-A3 | List integrations | **No.** No definition reader or catalog; autobyteus-311 | `git grep` above |
| F-A4 | A GitHub route that uses the vault credential without the agent holding it | **Yes, today: GitHub's remote MCP server** with the `Authorization` header (or `token`) stored as an MCP secret | live e2e test; P-1, P-2 |

## Stakeholder And User Evidence

| Source | Need | Strength | Implication |
| --- | --- | --- | --- |
| User via Task, 2026-10-30 | A teammate can install it; foundation general, not specific to this machine; installing very easy | Direct direction | Install from the public repository with app features any node has; nothing tied to this node's paths or tokens |
| User in 244 DEC-001 (approved) | "An agent may use a credential, never hold it" | Approved design | Rules out handing `GH_TOKEN` to the agent's shell |
| User in 244 DEC-010 (partial) | Third-party integration installs "quite dangerous" | User words | The official repository only; no third-party catalog here |
| Findings note F-5, F-6, F-3 | Cross-node work: external reference in the description; local keys not shared | Read | Skill conventions for the Project Task Manager |

## External Contracts And Dependencies

| Dependency | Constraint | Evidence | Risk |
| --- | --- | --- | --- |
| GitHub remote MCP server | PAT in `Authorization: Bearer`; toolsets by `X-MCP-Toolsets`; github.com only | P-1, docs | Whether a teammate needs Copilot access is unclear in GitHub's docs (RSK-001); local `github-mcp-server` (stdio, env token) is the fallback |
| GitHub fine-grained PAT | One resource owner per token; no user-owned Projects | docs, P-3 | Test board must be an organisation board, or a classic token |
| GitHub token creation | Only in GitHub's web UI (no API) | 244 MDEC-005 | The user creates the write-capable test token |

## Assumptions, Unknowns, And Risks

| ID | Type | Description | Resolution / Owner | Status |
| --- | --- | --- | --- | --- |
| RSK-001 | Risk | Remote GitHub MCP may require Copilot access for some accounts | Document the local stdio fallback entry; verify with the test account | Open |
| RSK-002 | Risk | Agents on a node where `gh` is logged in can use that broad token anyway (pre-existing) | Skill forbids the ambient `gh` login; follow-up FU-001 | Open |
| UNK-001 | Unknown | Write calls (comment, create, PR, board move) with a fine-grained token through the remote server | Measure with the write-capable test token (DEC-002) | Open |

## Supplemental Artifact Inventory

| Artifact | Owner | Purpose | Status |
| --- | --- | --- | --- |
| `/Users/normy/.autobyteus/server-data/projects/project_39227406-f32b-4eab-a1cd-bfe27a8e8580/tasks/project_task_94e47ec1-d32f-400a-bf01-19bc38496ff1/context/ctx_15f7b6e9e5b6__shared-projects-findings-20261026.md` | Solution Designer (302) | F-1…F-9 cross-node facts | Input, read-only |
| `.../context/ctx_a6a94aecf26d__handover.md` | Agent Package Creator | Handover (decided nothing) | Input, read-only |
| `integration-manifest-contract.md` (this folder) | Solution Designer, decided with the user | The integration manifest contract: folder conventions, `integration.json` fields, field validation (REQ-002, AC-002) | **Behavior-defining**, current at SR-006; approval: the user's words in SR-004…SR-006 |
| `handoff-prerequisite-credential-proxy.md` (this folder) | Solution Designer | PRE-001 request (credential proxy) | Delivered as autobyteus-311 step 1; historical |
| `handoff-prerequisite-integrations-page.md` (this folder) | Solution Designer | PRE-002 request (Integrations page) | Task autobyteus-337, not dispatched; AC-009 waits for it |
| `pause-note.md` (this folder) | Solution Designer | Where the ticket stopped while 311 ran | Historical |

## Requirement Implications

- The Task's premise "the platform supplies the credential when a command runs" is false today (F-A2). "Through `gh`, with the vault credential" needs a new app capability: the 244 credential proxy (FU-001) or a broker-run `gh` (V6). Neither is small.
- The same outcome (list, read, create and comment on issues; read and open PRs; move board items; vault credential the agent never holds) is reachable now with no app change through GitHub's remote MCP server (F-A4, P-1). This is a change to how the Task asked for it, so it needs the user (DEC-001).
- Install: GitHub skill sources fit; agent packages do not (F-A1).
- Board moves need an organisation board with a fine-grained token, or a classic token (P-3): the test target is a user decision (DEC-002).

## Resumed 2026-10-30: the proxy is delivered (autobyteus-311 step 1)

- Paused and resumed: see `pause-note.md`. Base of this repository unchanged (`origin/main` `6fa9bbc`, fetched 2026-10-30). App read at `origin/personal` `1a4453e553` (tag `v1.5.11-beta.4`) with `git show`, no app worktree.
- Authorities read (architecture gate, 2026-10-30): `references/architecture-design.md`, `references/design-principles.md`, `DESIGN.md` (app repository; this repository has none), `TESTING.md` (app; validation rules for isolated instances and the test vault).

| ID | Source | Finding | Established |
| --- | --- | --- | --- |
| F-B1 | `autobyteus-server-ts/docs/modules/credential_proxy.md`; `src/credential-proxy/integration-definitions.ts`; `src/api/graphql/types/github-integration.ts` (`githubIntegration`, `connectGitHubIntegration(token)`, `testGitHubIntegration`, `disconnectGitHubIntegration`, `setGitHubIntegrationAgentAccess(agentDefinitionIds)`); `delivery-records/credential-proxy-311-20261030/*` | GitHub card in Settings → Server Settings → Basics; per-agent tick; run pass per run; shell gets `AUTOBYTEUS_GITHUB_API_URL=http://127.0.0.1:<port>/r/<pass>/github/api`, `GIT_CONFIG_*` (`insteadOf https://github.com/`), `GIT_TERMINAL_PROMPT=0`. API route: GET/POST/PATCH/PUT/DELETE any path incl. `/graphql`; git: smart HTTP. Not supported: `gh` own commands, `uploads.github.com`, LFS; Codex `read-only` sandbox can't connect. Refusals are JSON `{"error","message"}` with codes `RUN_PASS_INVALID`, `INTEGRATION_NOT_ALLOWED`, `INTEGRATION_NOT_CONNECTED`, `PATH_NOT_ALLOWED`, `UPSTREAM_REJECTED_TOKEN` (git), `NOT_LOOPBACK`, `UPSTREAM_UNREACHABLE` (502), `PROXY_FAILED` (500). Hosts are app-owned ("An installed skill can't add or change a definition") | Read |
| F-B2 | 311 live check used the read-only `test.github.token`; residual: live push not covered | The write paths through the proxy are not yet proven against GitHub | Read (receipt) |
| F-B3 | `docker run --rm --entrypoint sh autobyteus/autobyteus-server:beta -c 'command -v …'`; `which jq curl git` on this Mac (macOS 26.5.2) | Docker image: bash, curl, git, jq, python3, node, gh present. Mac: `/usr/bin/jq`, curl, git present | Measured |
| F-B4 | `TESTING.md` §Test vault, §Isolated desktop instances | An instance on the test vault can't save settings (`SECRET_VAULT_READ_ONLY`), so the GitHub card needs the instance's own vault; of the CLI homes only `CODEX_HOME` passes into an isolated instance | Read |
| H-1 | 311 handover probe (`/tmp/gh-int-probe/ghproxy/`) | `gh` with `GH_HOST` insists on HTTPS; `gh api <full http URL>` works | Measured |

- Implication: the GitHub integration needs no app change. The live verification needs a write-capable token on a test target with a board (UP-001).
