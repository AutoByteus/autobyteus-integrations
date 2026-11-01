# AutoByteus Integrations

Integrations connect AutoByteus agents to outside services, such as GitHub, Jira and SSH.

**What an integration is.** A skill plus authentication: a skill folder (instructions and scripts) that an agent reads, and an integration manifest, `integration.json`, that names the integration, says what it is for, which token the user provides and which tools it needs. An integration never contains a secret. The user stores the token once in AutoByteus; when an agent's scripts call the service, AutoByteus adds the token on its side, so the agent never holds it. The folder layout and every manifest field are described in [docs/integration-manifest.md](docs/integration-manifest.md), which also says how to add an integration.

**What it is not.** It is not a plugin that extends the AutoByteus application itself. "Integration" means a connection to an outside service; this repository uses the word with that one meaning.

## Available integrations

| Folder | Skill | What it does |
| --- | --- | --- |
| [`github/`](github/) | `github-integration` | Issues (list, read, create, comment), pull requests (list, read, open), Projects boards (list items, move an item) |

## Installing

Needs an AutoByteus version that has the **Integrations** page (main menu → Integrations; `v1.5.11-beta.9` and earlier don't have it), and on the machine running the agents: `curl`, `jq` and `git`.

1. **Import this repository.** In AutoByteus: Integrations → **Import** → paste `https://github.com/AutoByteus/autobyteus-integrations` (or the path of a local copy of this repository) → Import. Each integration in it appears as a card, and its skill joins your skills. AutoByteus checks a GitHub import for updates; **Manage sources** updates or removes it.
2. **Connect GitHub.** On the GitHub card: **Connect** → paste a GitHub token (the card says what to grant it; a fine-grained token limited to the repositories your agents work on is recommended) → Connect. AutoByteus checks the token with GitHub and keeps it in its vault.
3. **Give the skill to an agent.** Add `github-integration` to the agent's skills, as with any skill (an agent set to all installed skills already has it). Only agents with the skill can use GitHub.
4. **Give the agent a shell.** The agent needs a terminal tool (AutoByteus runtime), or on Codex a sandbox other than `read-only`.

Start a new run of the agent; it can then check its access with the skill's `check-access.sh`. To push branches, use the `https://github.com/OWNER/REPO.git` URL: an SSH remote does not go through AutoByteus.

Removing this source (Manage sources → Remove, or on the Skills page) also removes your GitHub connection.

## Repository checks

- `tools/check-integrations.sh` checks every integration folder against the manifest rules.
- `tests/github/run-tests.sh` tests the GitHub scripts against a local stand-in (needs `python3`; no network, no token).

**Licence.** Not yet decided. Until a licence file is added, no licence is granted.
