# Prerequisite request — the Integrations page (from autobyteus-integrations-1)

- From: Solution Designer (run `solution_designer_60f98864f3454354b938e1c03887ef02`), 2026-10-30
- To: `/project_task_manager`
- Ticket: `autobyteus-integrations-1` (package `github-integration-foundation`), worktree `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation`, branch `codex/github-integration-foundation` (nothing committed)
- Documents: `requirements-doc.md` (section SR-003), `design-spec.md`, `investigation-notes.md`, `solution-revision-record.md` in `tickets/in-progress/github-integration-foundation/`

## The user's direction (2026-10-30, in my conversation, after seeing the design)

- "Why does the user have to go to a server setting to do the GitHub thing? … Each integration should handle their own configuration."
- "each integration has their own card … when we install the integration the integration will ask the user to … log in GitHub or … provide some kind of token … it's basically a skill … if it's integration it's just a nicer way of configuring things and also install the skill … then the user can basically go to any agent like how they do now and install that skill. This is how I imagined."

## What the app needs (autobyteus-311, its Integrations-page step)

1. An **Integrations page** (its own menu item, not Server Settings): one card per integration, with name and description read from the integration's `integration.json` (in the official repository `AutoByteus/autobyteus-integrations`, one folder per integration) and its state (not installed / needs token / connected as @login).
2. **Install from the card**: installs the integration's skill (today the official repository installs as one GitHub skill source; update checks exist), then asks for what the integration needs: a token now (vault, never shown again, Test, Remove), a sign-in later.
3. **Agent access follows the skill**: an agent whose configured skills include the integration's skill gets the integration in its runs (the proxy's run pass and shell variables). This replaces the per-agent tick of `setGitHubIntegrationAgentAccess` and `connections.json` agent lists.
4. The GitHub card moves from Server Settings → Basics to the Integrations page (clean cut).

## Open questions for the page's designer to ask the user

- Who decides where a token may be sent: (a) the app, with a code definition per integration (today; each new integration needs an app release), or (b) the integration's own `integration.json` (hosts and auth format shown to the user when connecting; only from the official repository). I recommended (b); the user has not chosen.
- Agents with "all installed skills": I recommend they do not get integration access automatically; only an explicitly configured skill grants it.

## Suggested Task

Title: Integrations page: one card per integration (install, connect, agent access through the skill), GitHub first. Design first.

Description: the user's direction above. Build on autobyteus-311 step 1 (credential proxy, `v1.5.11-beta.4`). Replace the GitHub card in Server Settings → Basics with an Integrations page: cards from the official integrations repository's `integration.json` files; Install (the skill source) and connect (token in the vault) from the card; agent access granted by configuring the integration's skill on the agent, replacing the per-agent tick. Ask the user the two open questions above. Done when: on an isolated instance, a user opens Integrations, installs GitHub, pastes a token, adds the skill to an agent, and that agent's shell reaches GitHub through the proxy; the token appears in no output or log. Unblocks the teammate-way check of autobyteus-integrations-1.

## This ticket meanwhile

The repository content (the `github/` skill, scripts, `integration.json`, docs) does not depend on the page and works today with the existing GitHub card. I asked the user whether to build it now or wait. The teammate-way install demo waits for the page.
