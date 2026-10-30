# Docs Sync Report — github-integration-foundation (autobyteus-integrations-1)

## Scope

- Ticket: `github-integration-foundation`, Project Task `autobyteus-integrations-1`. `task_size` `Medium`, `architectural_risk` `High`, route `Reviewed` (architecture review, code review CRR-001, API/E2E API-REV-001, test review CRR-002 `Not Applicable`)
- Trigger: code reviewer handoff "validated and ready for delivery" (CRR-001 Pass, API-REV-001 Pass at 95%, CRR-002 Not Applicable, CG-08 closed)
- Bootstrap base reference: `origin/main` `6fa9bbc` (AutoByteus/autobyteus-integrations)
- Integrated base reference used for docs sync: `origin/main` `6fa9bbc`, fetched at the start of delivery (2026-10-30). The branch already contained it (`git merge-base --is-ancestor origin/main HEAD`), so nothing was merged
- Post-integration verification reference: ticket branch `5c5690b` plus the SKILL.md docs edit below. Reran `tools/check-integrations.sh` (`all 1 integration folder(s) pass`, exit 0), `tests/github/run-tests.sh` (`24 passed, 0 failed`) and `shellcheck -x -P SCRIPTDIR -s bash github/scripts/*.sh tools/check-integrations.sh tests/github/run-tests.sh` (exit 0) before and after the edit

## Why Docs Were Updated

- Summary: one sentence added to `github/SKILL.md` saying that a board listing shows only the items the user's token can see. API-14 (CG-08) measured that GitHub leaves items from repositories outside a repository-limited token out of the list with no error and no mark. Before this change the skill did not tell the agent that a listing can be shorter than the board on GitHub.
- Why this should live in long-lived project docs: an agent reads `SKILL.md`, not the ticket. Without this sentence an agent on a shared organisation board could report an incomplete list as the whole board. This is how GitHub behaves, measured live, and it holds for every user of the integration.

## Long-Lived Docs Reviewed

| Doc Path | Why It Was Reviewed | Result (`Updated`/`No change`/`Needs follow-up`) | Notes |
| --- | --- | --- | --- |
| `github/SKILL.md` | What agents read; must match the scripts and the live behavior | Updated | Board-visibility sentence (above). Commands, options, exit codes, refusal texts, the push rule (HTTPS remote only) and the cross-node rules (AC-007) all match `github/scripts/*.sh` and the live evidence (API-10…API-17) |
| `README.md` | Install journey, app version, repository checks | No change | Documents today's journey (skill source; GitHub card in Server Settings → Basics with the agent ticked; `github-integration` on the agent; a shell), `v1.5.11-beta.4` or later (live run used 1.5.11-beta.5), and the note that the steps move to the Integrations page with autobyteus-337 (DEC-007). Rewriting it for the page is AC-009, this ticket's final round |
| `docs/integration-manifest.md` | The manifest contract (REQ-002, REQ-010) | No change | Fields, rules and the `github/integration.json` example match the file byte for byte and `tools/check-integrations.sh`'s rules (IMP-02 fixtures) |
| `github/integration.json` | User-facing token help | No change | The token help (fine-grained, repo-limited, Issues/PRs/Contents read and write, organisation Projects for a board; classic token for a personal-account board) matches what API-13 proved and probe P-3 found |

## Docs Updated

| Doc Path | Type Of Update | What Changed | Why |
| --- | --- | --- | --- |
| `github/SKILL.md` | Behavior note (3 lines after the board-command paragraph) | "A board listing shows only the items the user's token can see. With a token limited to some repositories, items from other repositories are left out without a mark, so the list may be shorter than the board on GitHub." | CG-08 measurement (`evidence/API-14-cg08-outside-item.log`: `"totalCount":2` with the outside item gone, no `"errors"`); suggested by the code reviewer as in-scope docs sync |

## Durable Design / Runtime Knowledge Promoted

| Topic | What Future Readers Need To Understand | Source Ticket Artifact(s) | Target Long-Lived Doc |
| --- | --- | --- | --- |
| Board visibility with a repository-limited token | GitHub omits items it will not show the token; the list is not the whole board | `api-e2e-execution-coverage-report.md` API-14; `code-review-report.md` CG-08 | `github/SKILL.md` |
| Integration definition, folder layout, manifest fields, adding an integration | Already promoted by implementation | `integration-manifest-contract.md`, `design-spec.md` | `docs/integration-manifest.md`, `README.md` (no change in delivery) |

## Removed / Replaced Components Recorded

| Old Component / Path / Concept | What Replaced It | Where The New Truth Is Documented |
| --- | --- | --- |
| None. The repository had only the README before this ticket | — | — |

## No-Impact Decision (Use Only If Truly No Docs Changes Are Needed)

- Not used: one doc was updated.

## Delivery Continuation

- Result: `Pass`
- Next delivery action: handoff summary, verification from the evidence, move the ticket to `tickets/done/`, finalize on `main`, then AC-001/AC-008 on today's released journey (DEC-007)
- Notes: the `(hidden)` line in `board.sh` (null content) stays as a guard for GitHub's documented REDACTED shape. It is code, not docs, and code review judged it acceptable; the SKILL.md sentence does not mention it. `implementation-handoff.md` item 8 says items the token can't see print as `(hidden)`; that is a ticket-local statement made before CG-08 was measured and is corrected by the execution report's API-14 row. It is not a long-lived doc.
