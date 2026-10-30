# The Integration Manifest

An integration connects AutoByteus agents to one outside service. It is a
**skill plus authentication**: a skill folder (instructions and scripts) that
an agent reads, and an integration manifest, `integration.json`, that tells the
user and the app what the integration is and what it asks for.

This document is the contract for every integration in this repository.
Readers: people adding an integration, `tools/check-integrations.sh`, and the
AutoByteus Integrations page.

## The integration folder

An integration is one top-level folder of this repository. Conventions carry
the facts a field would only repeat:

```text
github/              the folder name is the integration's ID
  integration.json   the integration manifest: what the Integrations page reads
  SKILL.md           what an agent reads; its `name` is the integration's skill
  scripts/           the operations, when the integration needs any
  icon.svg           optional: the card's icon (found by name, no field)
```

- **ID.** The folder name is the integration's ID. The app stores the user's
  connection under it, so the folder of the GitHub integration is `github`. An
  ID matches `^[a-z][a-z0-9-]*$`.
- **Skill.** The `name` in the `SKILL.md` front matter is the skill an agent is
  given to use the integration (for GitHub: `github-integration`). Pick a name
  that does not clash with common skill names: AutoByteus refuses a whole
  skill source when one of its skill names is already installed.
- **Icon.** `icon.svg` in the folder, when present.
- **Not integrations.** Top-level folders with neither `SKILL.md` nor
  `integration.json` (`docs/`, `tools/`, `tests/`, `tickets/`) are not
  integrations. A top-level folder with only one of the two is an error.

## `integration.json`

Only what the Integrations page needs and nothing else holds.

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `name` | string | yes | Display name on the card |
| `description` | string, one sentence | yes | What it lets agents do, written for the user |
| `token` | object | no: absent when the integration asks the user for nothing | The integration asks the user for a token when it is installed |
| `token.help` | string (may contain a link) | yes, when `token` is present | How to create the token and what to grant it |
| `prerequisites` | array of tool names | no: absent when nothing beyond a shell is needed | Tools the scripts need; each is checked with `command -v <tool>`; AutoByteus never installs them |

Rules:

- **No secret, ever**: no token, password, key, or a value that looks like one.
  The user's token is stored in the AutoByteus vault, never in this repository.
- **No version field.** The repository's commit identifies the revision. The
  app version an integration needs is written in the README.
- **No unknown fields.** `tools/check-integrations.sh` refuses them, so a typo
  can't pass silently.
- A later need gets its own explicit field when it exists, never a meaning by
  absence. For example, a sign-in would be a `signIn` object beside `token`.

`SKILL.md` has its own `description`, written for agents ("use when …"). The
manifest's `description` is written for the user. They are different texts for
different readers.

### Example: `github/integration.json`

```json
{
  "name": "GitHub",
  "description": "Work with GitHub issues, pull requests and Projects boards. Your token stays in AutoByteus.",
  "token": {
    "help": "Create a fine-grained token at https://github.com/settings/personal-access-tokens/new, limited to the repositories your agents work on, with Issues, Pull requests and Contents read and write (and the organisation's Projects read and write for a board). A board owned by a personal account needs a classic token with the repo and project scopes."
  },
  "prerequisites": ["curl", "jq", "git"]
}
```

## Rules for scripts

- **Through AutoByteus only.** A script reaches the service only through the
  address AutoByteus gives the run (for GitHub, `AUTOBYTEUS_GITHUB_API_URL`, and
  git's redirection of `https://github.com/`). AutoByteus adds the user's token
  on its side; the agent never sees it.
- **Never a token.** A script never asks for, reads, prints or stores a token,
  never reads token variables (`GH_TOKEN`, `GITHUB_TOKEN`), never uses a tool's
  own stored login (`gh auth`), and never calls the service's public address
  directly.
- **When access is missing**, the script says how to give it and stops.
- **Prerequisites declared.** Every tool a script uses beyond a shell is listed
  in `prerequisites`. The script checks for it with `command -v` and, when it is
  missing, says which tool to install and stops. Nothing installs tools for the
  user.
- **No binaries.** Scripts are plain text the user can read; nothing is
  downloaded or compiled.
- **Short answers.** A result is a few readable lines; a refusal says what
  happened and what to do next.

## Adding an integration

1. Make sure AutoByteus can deliver the service's credential to a run. Where a
   token may be sent is decided by the app, not by the integration, so a new
   service needs its connection in AutoByteus first.
2. Create the top-level folder; its name is the ID (for example `jira`).
3. Write `integration.json` with the fields above.
4. Write `SKILL.md`: front matter with `name` and `description`, then when to
   use the integration, how to check access first, the commands, and the rules.
5. Add the scripts under `scripts/`, following the rules for scripts. Keep
   tests outside the integration folder (under `tests/<id>/`), so the installed
   skill stays small.
6. Run `tools/check-integrations.sh` and the integration's tests.
7. Add the integration to the README's list.
