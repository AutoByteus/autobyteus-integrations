# Handoff Summary — github-integration-foundation (autobyteus-integrations-1)

## What Was Delivered

The integrations repository `AutoByteus/autobyteus-integrations` now defines an integration as a skill plus authentication, and has its first one, GitHub:

- `docs/integration-manifest.md`: the contract. The folder name is the ID, `SKILL.md`'s `name` is the skill and `icon.svg` is the icon. `integration.json` holds `name`, `description`, `token.help` and `prerequisites`, with no secret, no version field and no unknown fields.
- `github/`: skill `github-integration` (`SKILL.md`, `integration.json`, `scripts/` with `check-access.sh`, `issues.sh`, `pulls.sh`, `board.sh`, `lib.sh`). It reaches GitHub only through the run's `AUTOBYTEUS_GITHUB_API_URL` (REST and GraphQL with `curl`) and git's `insteadOf` redirection. It never touches a token or `gh auth`.
- `tools/check-integrations.sh`: checks every integration folder against the manifest rules.
- `tests/github/run-tests.sh` + `fake-api.py`: 24 network-free cases against a local stand-in for the proxy.
- `README.md`: what an integration is, the available integrations, today's install journey (needs AutoByteus `v1.5.11-beta.4` or later), and the note that the steps move to the Integrations page with autobyteus-337.

Delivery added one sentence to `github/SKILL.md`: a board listing shows only the items the token can see (from CG-08, API-14).

## Classification And Route

- `task_size` `Medium`, `architectural_risk` `High`, route `Reviewed`: architecture review (ARCH-REV-001 and later), code review CRR-001 Pass 9.5/10, API/E2E API-REV-001 Pass at 95%, test review CRR-002 `Not Applicable` (no durable test changed). Delivery does not reclassify.

## Integration State

- Base: `origin/main` `6fa9bbc`, fetched at delivery start. The ticket branch `codex/github-integration-foundation` already contained it, so nothing was integrated (`Already current`).
- Checks on the delivery state (2026-10-30, macOS 26.5, bash 3.2.57): `tools/check-integrations.sh` → `all 1 integration folder(s) pass`; `tests/github/run-tests.sh` → `24 passed, 0 failed`; `shellcheck -x -P SCRIPTDIR -s bash …` → exit 0. Run both before and after the SKILL.md edit.

## Acceptance Status

| AC | Status | By |
| --- | --- | --- |
| AC-002 | Proven | IMP-02 / API-02 |
| AC-003, AC-004, AC-005, AC-006 | Proven live through the real proxy on released 1.5.11-beta.5 | API-10…API-18 |
| AC-007 | Proven (review) | CRR-001 |
| AC-001, AC-008 | Delivery, after finalization on `main` (DEC-007) | See `release-deployment-report.md` |
| AC-009 | This ticket's final round, after autobyteus-337 | Not this round |

## Open Items

- AC-009: the Integrations-page journey with the unchanged `github/` folder and the README install steps rewritten. The ticket stays open for that round (DEC-007). The Solution Designer re-opens it when the PM resumes the ticket.
- FU-001 (`follow-ups.md`): the host's ambient `gh` login can be used by any agent shell. It stays with the Solution Designer.
- Residual observations, none of them a failure (execution report, Latest Authoritative Result): board list lag right after an add; the board's own auto-close workflow; `mergeable: unknown` right after `open`; the conservative Rule 2 wording.

## Where Things Are

- Ticket folder: `tickets/done/github-integration-foundation/` after finalization (was `tickets/in-progress/…`).
- Delivery documents: `docs-sync-report.md`, `handoff-summary.md`, `release-deployment-report.md`, `delivery-revision-record.md`.
- Evidence: `evidence/` (IMP-*, API-*; AC-001/AC-008 files added by delivery as `DEL-*`).
