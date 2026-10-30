# Prerequisite request — credential proxy for integrations (from autobyteus-integrations-1)

- From: Solution Designer (Software Engineering Team, run `solution_designer_60f98864f3454354b938e1c03887ef02`), 2026-10-30
- To: `/project_task_manager` (run `project_task_manager_7c8dce0c4a8b44f88e776a83809dee03`)
- Ticket: `autobyteus-integrations-1`, package `github-integration-foundation`, status **Waiting For Prerequisite**
- Worktree: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation` (branch `codex/github-integration-foundation` from `origin/main` `6fa9bbc` of AutoByteus/autobyteus-integrations); nothing committed yet
- Documents: `tickets/in-progress/github-integration-foundation/requirements-doc.md` (Draft, PRE-001), `investigation-notes.md` (evidence)

## What blocks

The Task assumed beta.10 (autobyteus-244) lets the platform supply a vault credential "when a command runs". It does not: 244 built **MCP server secrets in the vault** only (its SR-004). The vault hands a credential to an MCP server, never to a script or command. The command/script path was left as 244's follow-up **FU-001**: "Integrations page and credential proxy … a local proxy for the GitHub API and git over HTTPS (run pass, allow-list, redaction, audit), per-agent grants, one skill using it". Evidence: 244 `requirements-doc.md` (SR-004), `follow-ups.md` FU-001, `solution-validation.md` V1/V1b; `autobyteus-server-ts/docs/modules/secret_management.md` (consumers: provider keys, MCP secrets only).

## The user's direction (2026-10-30, in the Solution Designer conversation)

- "I kinda feel like integration is just about skill plus authentication or something?"
- "There should be a proxy service or something. So that's for integrations. For integrations, the tokens are … [provided] into the proxy service. And proxy service will get those tokens from that vault."
- He asked me to ask you about it.

So the GitHub integration delivers its credential through the credential proxy, which does not exist yet. The proxy is app functionality outside this ticket (the integrations repository), so it is a **prerequisite**.

## What already works (for the proxy Task's context)

- Install and update from GitHub: GitHub skill sources (public repository root, top-level skill folders, update checks). No app change needed for installing.
- Listing integrations: does not exist (autobyteus-311, later).

## Suggested Task (please create it, or tell me if one already exists for 244 FU-001)

Title: Credential proxy for integrations (autobyteus-244 FU-001), design first

Description: Integrations (GitHub first) need their scripts to reach an outside service with a credential the agent never holds. Build the server-owned credential proxy designed and validated in autobyteus-244 (`tickets/done/secrets-and-integrations-design/solution-validation.md` §1–§5, V1 and V1b): the user stores an integration's token once in the node's vault; the proxy takes it from the vault and adds it to outbound requests (GitHub REST/GraphQL API, git over HTTPS), limited to the integration's allowed hosts and paths, redacting echoes and logging each use; an agent's shell gets only a proxy address that works for its own run. Include how the user enters the integration's token (a vault entry outside MCP), and settle whether `gh` itself can go through the proxy or the integration's scripts call the API directly. Per-agent grants and approval of risky actions (244 DEC-005) only as far as the user decides. Done when: a script in an agent's shell calls the GitHub API and clones a repository through the proxy with the vault token, and the token is in no shell environment, output or log. Unblocks autobyteus-integrations-1.

## Requested action

Create the Task (or point me to an existing one), give it to me first (same Solution Designer, which has the context), and tell me to continue autobyteus-integrations-1 when it is delivered. The integrations ticket waits until then.
