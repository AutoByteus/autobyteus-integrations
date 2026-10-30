# AutoByteus Integrations

Integrations connect AutoByteus agents to outside services, such as GitHub, Jira and SSH.

**What an integration is.** A skill plus authentication: a skill folder (instructions and scripts) that an agent reads, and an integration manifest, `integration.json`, that names the integration, says what it is for, which token the user provides and which tools it needs. An integration never contains a secret. The user stores the token once in AutoByteus; when an agent's scripts call the service, AutoByteus adds the token on its side, so the agent never holds it. The folder layout and every manifest field are described in [docs/integration-manifest.md](docs/integration-manifest.md), which also says how to add an integration.

**What it is not.** It is not a plugin that extends the AutoByteus application itself. "Integration" means a connection to an outside service; this repository uses the word with that one meaning.

## Available integrations

| Folder | Skill | What it does |
| --- | --- | --- |
| [`github/`](github/) | `github-integration` | Issues (list, read, create, comment), pull requests (list, read, open), Projects boards (list items, move an item) |

## Installing

Needs AutoByteus `v1.5.11-beta.4` or later, and on the machine running the agents: `curl`, `jq` and `git`.

1. **Add this repository as a skill source.** In AutoByteus: Skills → Manage skill sources → add `https://github.com/AutoByteus/autobyteus-integrations`. AutoByteus checks it for updates.
2. **Connect GitHub.** Settings → Server Settings → Basics → the GitHub card: paste a GitHub token (the card says what to grant it; a fine-grained token limited to the repositories your agents work on is recommended), then tick the agents that may use GitHub.
3. **Give the skill to those agents.** Add `github-integration` to each ticked agent's skills.
4. **Give the agent a shell.** The agent needs a terminal tool (AutoByteus runtime), or on Codex a sandbox other than `read-only`.

Start a new run of the agent; it can then check its access with the skill's `check-access.sh`. To push branches, use the `https://github.com/OWNER/REPO.git` URL: an SSH remote does not go through AutoByteus.

These steps will move to a coming Integrations page in AutoByteus (AutoByteus Task autobyteus-337), where each integration has its own card; this README will be updated then.

## Repository checks

- `tools/check-integrations.sh` checks every integration folder against the manifest rules.
- `tests/github/run-tests.sh` tests the GitHub scripts against a local stand-in (needs `python3`; no network, no token).

**Licence.** Not yet decided. Until a licence file is added, no licence is granted.
