---
name: github-integration
description: Work with GitHub issues, pull requests and Projects boards through the user's AutoByteus GitHub connection. Use when a task needs to list, read, create or comment on issues, read or open pull requests, push a branch, or move an item on a Projects board.
---

# GitHub Integration

You reach GitHub through AutoByteus. The user connected GitHub once in
AutoByteus; your run's shell has an address, `AUTOBYTEUS_GITHUB_API_URL`, and
AutoByteus adds the user's token on its side. You never see or need the token.

The scripts are in the `scripts/` folder next to this file. Below, `$S` stands
for that folder's full path:

```bash
S=<this skill's folder>/scripts
```

## Check access first

```bash
$S/check-access.sh
```

- `GitHub access: connected as @login`: go ahead.
- Anything else says what is missing (exit code 3). Tell the user exactly that
  and stop; do not look for another way in.

You need a shell: a terminal tool on the AutoByteus runtime, or, on Codex, a
sandbox other than `read-only` (the `read-only` sandbox can't reach the
AutoByteus address).

## Commands

References are `OWNER/REPO#N` for one issue or pull request, `OWNER/REPO` for
a repository. Long text (bodies, comments) comes from a file, or from stdin
with `-`, never as an argument.

| Task | Command |
| --- | --- |
| List issues | `$S/issues.sh list OWNER/REPO [--state open\|closed\|all] [--limit N]` |
| Read an issue | `$S/issues.sh read OWNER/REPO#N [--comments N]` (last 5 comments by default) |
| Create an issue | `$S/issues.sh create OWNER/REPO --title TEXT --body-file FILE\|-` |
| Comment on an issue or PR | `$S/issues.sh comment OWNER/REPO#N --body-file FILE\|-` |
| List pull requests | `$S/pulls.sh list OWNER/REPO [--state open\|closed\|all] [--limit N]` |
| Read a pull request | `$S/pulls.sh read OWNER/REPO#N` |
| Open a pull request | `$S/pulls.sh open OWNER/REPO --head BRANCH --base BRANCH --title TEXT --body-file FILE\|- [--draft]` |
| List a board's items | `$S/board.sh items --owner LOGIN --number P [--status NAME]` |
| Move a board item | `$S/board.sh move OWNER/REPO#N --owner LOGIN --number P --status NAME` |

`--owner` is the user or organisation that owns the board and `--number` the
board's number (in its URL: `github.com/orgs/LOGIN/projects/P`). Status names
match regardless of case. `move` adds the issue or pull request to the board
first when it is not on it, and says so.

Examples:

```bash
$S/issues.sh list AutoByteus/autobyteus-integrations-test
printf 'Done in commit abc123.\n' | $S/issues.sh comment AutoByteus/autobyteus-integrations-test#3 --body-file -
$S/board.sh move AutoByteus/autobyteus-integrations-test#3 --owner AutoByteus --number 1 --status "In Progress"
```

### Pushing a branch and opening a pull request

Push with plain `git` and the `https://github.com/OWNER/REPO.git` URL;
AutoByteus redirects it. An SSH remote (`git@github.com:…`) does not go through
AutoByteus and will not work.

```bash
git remote set-url origin https://github.com/OWNER/REPO.git   # only if origin is SSH
git push -u origin fix/readme
$S/pulls.sh open OWNER/REPO --head fix/readme --base main --title "Fix README" --body-file notes.md
```

### Anything else

Call GitHub's REST or GraphQL API with `curl` on the same address, where you
would use `https://api.github.com`:

```bash
curl -s "$AUTOBYTEUS_GITHUB_API_URL/repos/OWNER/REPO/labels"
curl -s -X POST "$AUTOBYTEUS_GITHUB_API_URL/graphql" -d '{"query":"{ viewer { login } }"}'
```

`gh api` with the full address works too; `gh` needs some token value, any
value, and AutoByteus replaces it: `GH_TOKEN=unused gh api
"$AUTOBYTEUS_GITHUB_API_URL/user"`. `gh`'s own commands (`gh issue list`,
`gh pr create`) do not work.

## Rules

- **Never a token.** Do not ask for, read, print or store a GitHub token. Do
  not use `gh auth`, `gh auth token`, or any login `gh` or git may already
  have on this machine. Do not call `https://api.github.com` directly. If the
  access check fails, tell the user what it said and stop.
- **Never print the address.** `AUTOBYTEUS_GITHUB_API_URL` holds your run's
  pass; do not echo it or write it into files, issues or comments.
- **Write only what the task asks for.** Comments, issues, pull requests and
  board moves are visible to other people.

## Working across nodes

Project Task Managers on different AutoByteus nodes share work through GitHub
items:

- The shared identity of a work item is its GitHub reference,
  `OWNER/REPO#N`. Put it in every delegated task description and in every
  record of the work.
- Local Task keys (such as `autobyteus-42`) belong to one node. Never write
  them to GitHub as the item's identity and never send them to another node as
  one.
- Each node uses its own GitHub connection; the other node's agents act as
  their own user.

Example of a delegated task description:

```text
Work on AutoByteus/autobyteus-integrations-test#3 ("Fix README links").
Read it with issues.sh read, move it to In Progress on board AutoByteus #1,
comment on AutoByteus/autobyteus-integrations-test#3 when done, then move it
to Done.
```

## What a refusal means

| Exit | Meaning | What to do |
| --- | --- | --- |
| 0 | Done | — |
| 2 | Wrong usage, or an unknown board status (the valid ones are listed) | Fix the command |
| 3 | No access: GitHub not connected, this agent not given the integration, the run's address no longer valid, or the token rejected | Tell the user the message's next step |
| 4 | Refused: the call is outside what the integration allows, or GitHub said no (403, 404, 422, or a GraphQL error) | Usually the token lacks a permission or the repository is not in its list; tell the user |
| 5 | Unreachable or failed: GitHub or AutoByteus could not be reached, a GitHub server error, or a needed tool (`curl`, `jq`) is missing | Try again later, or install the named tool |

Every refusal prints what happened and a `Next:` line with what to do.
