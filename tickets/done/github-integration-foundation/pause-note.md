# Pause note — autobyteus-integrations-1 (github-integration-foundation)

- Paused: 2026-10-30, at the user's direction (relayed by `/project_task_manager`). No further design, investigation or commits until the PM says continue.
- Waiting for: the credential proxy, autobyteus-311, delivered by the team copy that did autobyteus-244. Prerequisite PRE-001 in `requirements-doc.md`.

## Where it stopped

- Requirements investigation done (`investigation-notes.md`). Requirements `Draft` (`requirements-doc.md`); not presented for approval; no design spec; no SR entry yet.
- Decided so far: credential delivery through the credential proxy (the user, DEC-001); install through GitHub skill sources, not agent packages (DEC-002); prerequisite tools declared in the integration, never installed or bundled (DEC-003).
- Nothing committed. The worktree holds only this ticket folder (untracked).

## What remains when it resumes

1. Read what 311 delivered: how an integration declares and names its credential, how the user enters it, what the agent's shell gets, and whether `gh`'s own commands work through the proxy (311 handover H-1: a plain local proxy supports `curl`, `gh api <URL>` and git, not `gh issue …`).
2. Ask the user DEC-005: a write-capable test target; recommendation: a private test repository and Project board under the AutoByteus organisation, with a fine-grained token limited to them (a personal-account board is unreachable with a fine-grained token, probe P-3).
3. Complete requirements and approval, then the design: the integration definition (folder layout, `integration.json` with name, description, needed credential, prerequisites, install source), the GitHub skill and scripts.
4. Deliver on `main` of AutoByteus/autobyteus-integrations, with the demo: an agent lists and comments on an issue of the test repository, installed the way a teammate would.
5. Report separately what remains for the Integrations menu (autobyteus-311 later steps).

## Related

- 311 handover: `/Users/normy/autobyteus_org/autobyteus-delivery-records/github-integration-foundation-20261030/handover-311.md`
- Prerequisite request: `handoff-prerequisite-credential-proxy.md` (this folder)
