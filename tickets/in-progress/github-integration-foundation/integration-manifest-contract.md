# Integration Manifest Contract (draft for `docs/integration-manifest.md`)

- Status: decided with the user, 2026-10-30 (SR-004, SR-005, SR-006): the file is `integration.json` ("If you think the integration file is better, then let's call it integration"). Each field validated for need, redundancy and name (SR-005, at the user's request: "validate by yourself whether you have redundant fields"). One part is open: who decides where a token may be sent; if autobyteus-337 and the user decide the integration declares it, it is an addition under `token`.
- Readers: the Integrations page (autobyteus-337), `tools/check-integrations.sh`, people.

## The integration folder

An integration is one top-level folder of the integrations repository. Conventions carry the facts a field would only repeat:

```text
github/              the folder name is the integration's ID (the app stores its connection under it)
  integration.json   the integration manifest: what the Integrations page reads
  SKILL.md           what an agent reads; its `name` is the integration's skill
  scripts/           the operations, when the integration needs any
  icon.svg           optional: the card's icon (found by name, no field)
```

Folders with neither `SKILL.md` nor `integration.json` (`docs/`, `tools/`, `tests/`, `tickets/`) are not integrations. A top-level folder with only one of the two is an error (`tools/check-integrations.sh` fails it). An ID matches `^[a-z][a-z0-9-]*$`.

## `integration.json`

Only what the Integrations page needs and nothing else holds (SR-006, the user: "only keep the one we really need").

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `name` | string | yes | Display name on the card |
| `description` | string, one sentence | yes | What it lets agents do, for the user |
| `token` | object | no: absent when the integration asks the user for nothing | The integration asks the user for a token when it is installed |
| `token.help` | string (may contain a link) | yes | How to create the token and what to grant it |
| `prerequisites` | array of tool names | no: absent when nothing beyond a shell is needed | Tools the scripts need; checked with `command -v <tool>`; the app never installs them |

Later needs get their own explicit field when they exist, never a meaning by absence: a sign-in would be a `signIn` object beside `token`; where a token may be sent, if autobyteus-337 decides the integration declares it, goes under `token`.

Rules:

- No secret, ever: no token, password, key or a value that looks like one.
- No version field; the repository's commit identifies the revision. The app version an integration needs is written in the README.
- Unknown fields are refused by `tools/check-integrations.sh`, so a typo can't pass silently.

## Example: `github/integration.json`

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

## Field validation (SR-005; partly superseded by § Second pass, SR-006)

This table is the first pass. Where § Second pass changed a decision (`connection` became `token`; `kind`, `createUrl`, `permissions` and the install links removed), the second pass is current.

Each field of the first draft (SR-004) was checked: who reads it, whether another place already holds the same fact, and whether its name says what it is.

| Draft field | Reader | Same fact elsewhere? | Decision |
| --- | --- | --- | --- |
| `id` | page, app connection | **Yes: the folder name.** Keeping both needs a check that they match | **Removed.** The folder name is the ID |
| `skill` | page | **Yes: `name` in `SKILL.md`** of the same folder | **Removed.** Read from `SKILL.md` |
| `icon` | page | **Yes: always `icon.svg`** in the folder | **Removed.** Convention, no field |
| `service` | nobody (no screen or check uses it) | `createUrl` gives the useful link | **Removed** (no reader) |
| `connection.label` | page | **Derivable**: "<name> token" from `name` + `kind` | **Removed** |
| `connection.kind: "none"` | page | Same as having no `connection` | **Removed.** `connection` is optional instead |
| `prerequisites[].check` | page | **Derivable**: `command -v <tool>` for every tool | **Removed**; `prerequisites` became a tool → link map |
| `prerequisites[].tool` | page | Became the map's key | Merged |
| `name` | page | Folder `github` can't give "GitHub" (casing, spaces such as "Jira Cloud") | **Kept** |
| `description` | page (for the user) | `SKILL.md` `description` is for agents ("use when …"): another reader and purpose | **Kept**; both written for their reader |
| `connection.kind`, `help`, `createUrl`, `permissions` | page (Install step) | Nowhere else | **Kept**; `permissions` can't be folded into `help` without losing the list form the card shows |
| name `connection` | — | The app already calls this `connection` (`integrations/connections.json`, "connect") | **Kept** (one word, one meaning) |
| name `prerequisites` | — | The user's word ("mention those prerequisite") | **Kept** |

## Second pass (SR-006)

The user: "only keep the one we really need … a lot of times … we put a lot of fields there and later we have to remove it."

| SR-005 field | Really needed now? | Decision |
| --- | --- | --- |
| `connection.kind` | No: only one value (`token`) exists; a field with one value is a dead option | **Removed.** The object is named for what it asks: `token` |
| `connection.createUrl` | No: the link fits in `help`, which the card shows | **Folded into `help`** |
| `connection.permissions` | No: the same text fits in `help` | **Folded into `help`** |
| `prerequisites` install links | No: the card only needs to know what to check; how to install a tool is general knowledge and the README | **Removed**; `prerequisites` is a list of tool names |
