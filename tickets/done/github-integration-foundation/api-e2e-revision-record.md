# API/E2E Revision Record — github-integration-foundation (autobyteus-integrations-1)

## Revision Index

| Revision ID | Triggering Role / Report / Round | Related Upstream Revision IDs | Prior Result / Confidence | Current Result / Confidence |
| --- | --- | --- | --- | --- |
| API-REV-001 | Code reviewer, `code-review-report.md` CRR-001 (Pass), round 1 | SR-008, ARCH-REV-002, IR-001, CRR-001 | N/A | Pass / 95% |

## Revision Entries

### API-REV-001 — Live check through a real app proxy (Change Sequence step 4)

- Triggering role, report path, and round: code reviewer, `code-review-report.md` (CRR-001), round 1
- Triggering finding or case IDs: none (pass); code-review hold CG-08 measured in API-14
- Related revision IDs: SR-008, ARCH-REV-002, IR-001, CRR-001
- Why this baseline was recorded: first API/E2E validation. AC-003…AC-006 and R-1/R-2 had been proven only against the local stand-in
- Coverage decisions or durable test paths changed: none. `tests/github/run-tests.sh` stays the durable deterministic suite; the live probes are kept as evidence (`evidence/API-live-*.{mjs,sh}`, `evidence/API-scan-token.mjs`)
- Cases added, changed, removed, or rechecked: API-01…03 reused (IMP-01…05); API-10…API-18 live in ENV-2
- Commands, environment, fixture, or broader-validation delta: isolated AutoByteus 1.5.11-beta.5 with its own vault, Codex runtime, worktree as local skill source; CG-08 fixture by issue transfer (the planned direct add was impossible)

#### Prior Failure Resolution

None.

- Canonical artifacts and sections updated: `api-e2e-coverage-investigation.md` (created), `api-e2e-execution-coverage-report.md` (created), `api-e2e-test-progress.md`, `evidence/API-*`
- Prior result and confidence: N/A
- Current result and confidence: Pass, 95% (post-repository 65%)
- New or remaining failure IDs: none
- Recommended owner: code reviewer (successful-output route); CG-08 measurement for its hold
- Remaining risks, blocked evidence, or untested scope: AC-001/AC-008 (delivery, DEC-007), AC-009 (final round); CG-08 outcome: GitHub omits items outside the token's list (no `errors`, no `(hidden)` line); listing lag after an add; `RUN_PASS_INVALID`/5xx/curl failure stand-in only
