# Code Review Report — github-integration-foundation (autobyteus-integrations-1)

## Review Round Meta

- Review Entry Point: `Implementation Review`
- Requirements Doc Reviewed As Context: `requirements-doc.md` (SR-008)
- Investigation Notes Reviewed As Context: `investigation-notes.md` (as referenced by the requirements and design; F-A1, F-B1…F-B3)
- Solution Revision Record Reviewed As Context: `solution-revision-record.md` (SR-008)
- Design Spec Reviewed As Context: `design-spec.md` (SR-008)
- Supplemental Task Artifacts Reviewed As Context: `integration-manifest-contract.md` (SR-006, behavior-defining); `follow-ups.md` (FU-001)
- Relevant Solution Revision IDs: `SR-008`
- Design Review Report Reviewed As Context: `design-review-report.md` (ARCH-REV-002, Pass; AR-005…AR-010)
- Architecture Review Revision Record Reviewed As Context: `architecture-review-revision-record.md`
- Relevant Architecture Review Revision IDs: `ARCH-REV-002`
- Implementation Handoff Reviewed As Context: `implementation-handoff.md`
- Implementation Revision Record Reviewed As Context: `implementation-revision-record.md`
- Relevant Implementation Revision IDs: `IR-001`
- Code Review Revision Record: `code-review-revision-record.md`
- Current Code Review Revision ID: `CRR-001`
- Current Review Round: `1`
- Review Scope: `Full Review`
- Review Scope Evidence (round >1): N/A
- Trigger: implementation ready for source review (Medium / High)
- Prior Review Round Reviewed: N/A
- Latest Authoritative Round: `1`
- Coverage Investigation / Execution Coverage / API/E2E Revision Record: N/A (implementation review)
- Delivery Revision Record: N/A
- Failing Scenario IDs / Commands / Evidence: N/A

## Routing Classification Review

- Task size: `Medium`
- Architectural risk: `High`
- Selected route: `Implementation Review`
- Independent source review required by the classification: `Yes`
- Classification evidence or correction required: Confirmed. Six small shell files plus docs and tests in one new repository (Medium). A new public contract (`integration.json`, the folder layout) and the first credential-backed write path through the proxy (High). No correction.

## Review Scope

- Changed implementation and behavior reviewed: commits `a0b5d50`, `3192aec` on base `6fa9bbc` (`git diff 6fa9bbc..3192aec`): `README.md`, `docs/integration-manifest.md`, `tools/check-integrations.sh`, `github/` (SKILL.md, integration.json, scripts/lib.sh, check-access.sh, issues.sh, pulls.sh, board.sh), `tests/github/` (fake-api.py, run-tests.sh).
- Files / areas reviewed: all of the above, read in full; evidence logs IMP-01…IMP-05.
- Explicit exclusions: the ticket documents (`f9d7f02`), except as context. No check was rerun: none of the exercised code changed after IMP-01…IMP-05 ran on `3192aec`, and no finding needed a new check.
- Project guidance: this repository has no `DESIGN.md` or `TESTING.md` (`No project DESIGN.md found`, as the design spec records).

## Upstream Behavior And Production-Path Basis Confirmation

- Approved requirements basis understood: Yes (REQ-001…REQ-010, AC-001…AC-009; DEC-004, DEC-006, DEC-007).
- Design-spec behavior map verified against the implementation: Yes.
- Design review report and round confirmed: ARCH-REV-002 Pass; review notes AR-005…AR-009 are implemented (below).
- Behavior-basis status: `Confirmed`
- Changed or newly discovered behavior: None.
- Remaining material ambiguity: None for source review. The live shapes (GraphQL, REST fields, write paths) are R-1/R-2 and belong to the live check.

| Behavior ID | Current Status | Current Implementation Path And Lifecycle Evidence | Contradicting / New Evidence |
| --- | --- | --- | --- |
| BEH-001 (REQ-001, AC-001) | Confirmed | `github/SKILL.md` is the only top-level `SKILL.md`; `docs/`, `tools/`, `tests/`, `tickets/` have none; skill name `github-integration` | — |
| BEH-002 (REQ-004…REQ-008) | Confirmed | DS-002: subject script → `lib.sh gh_request` (`lib.sh:105-137`, the only `curl`) → `$AUTOBYTEUS_GITHUB_API_URL$path` → 2xx (GraphQL errors check `lib.sh:141-152`) or `gh_explain_refusal` (`lib.sh:155-228`, Rules 1–3). No `Authorization`, token variable, `gh auth` or `api.github.com` in script code (test "the scripts name no token variable…") | — |
| BEH-002 / REQ-008 | Confirmed | `gh_require_access` (`lib.sh:47-53`) exit 3 with the next step; refusal texts use `$method ${path%%\?*}`, never the address; curl runs with `-s`, so it prints no URL (`lib.sh:108-123`) | — |
| BEH-004 (REQ-002, REQ-010, AC-002) | Confirmed | `github/integration.json` equals the contract's example; `tools/check-integrations.sh` enforces required fields, unknown fields (incl. `token.*`), ID pattern, half-folder rule (AR-009), secret-looking values, `SKILL.md` name; `docs/integration-manifest.md` matches `integration-manifest-contract.md` § fields and rules | — |
| BEH-005 (REQ-009, AC-007) | Confirmed | `SKILL.md` § Working across nodes: `OWNER/REPO#N` as shared identity, local Task keys never sent as identity, each node's own connection, example description with `OWNER/REPO#N`. AC-007 (review item) satisfied | — |
| BEH-003 (REQ-010) | Confirmed | README: definition, available integrations, today's journey (DEC-007) with the terminal/sandbox and `https://` push notes (AR-007), app version, move to the Integrations page, checks; 244-era text removed | — |

Review notes from the architecture review: AR-005 (Error Rules 1–5 owned by `lib.sh`, one test per rule) — done. AR-006 (issues list leaves out PRs, limit after filter, `issues.sh:39-40`, `lib.sh:242-256`) — done, tested across pages. AR-007 — done (SKILL.md, README). AR-008 (add-then-move message, case-insensitive status, unknown lists valid names, `board.sh:108-117,173-189`) — done, tested. AR-009 (half-folder rule, `check-integrations.sh:87-94`) — done, fixtures in IMP-02.

## Supported Product Scenario And Reachability Gate (Mandatory)

| Scenario ID | Related IDs | Kind | Actor | Goal / Event | Entry Surface | Shape | Forward Path | Expected Outcome | Evidence | Validity | Use |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SCN-001 | BEH-001, REQ-001 | User | User/teammate | Install from GitHub | Skill sources | Normal | DS-001 | Skill listed | requirements, F-A1 | Supported Normal Scenario | Use |
| SCN-002 | BEH-002, REQ-004/007/008 | User/agent | Agent in a ticked run | Work on issues | `issues.sh` | Normal | DS-002 | Result or refusal with `Next:` | requirements, design | Supported Normal Scenario | Use |
| SCN-003 | REQ-005 | User/agent | Agent | Open a PR | `git push`, `pulls.sh open` | Normal | DS-003, DS-002 | `OWNER/REPO#N` | requirements | Supported Normal Scenario | Use |
| SCN-004 | REQ-006 | User/agent | PM | Keep the board current | `board.sh` | Normal | DS-002 (GraphQL) | Item moved / listed | requirements, AR-008 | Supported Normal Scenario | Use |
| SCN-005 | REQ-009 | System | Two PMs | Share one board | delegation text | Normal | DS-005 | Same item on both nodes | requirements F-3/F-5/F-6 | Supported Normal Scenario | Use |
| SCN-006 | REQ-002 | Contract | Reader / page / check | Show the integration | `integration.json` + folder | Normal | DS-004 | Fields read | manifest contract | Supported Normal Scenario | Use |

### Candidate Finding And Mechanism Gate

| Candidate ID | Observation Or Mechanism | Scenario / Contract | Independent Trigger | Forward Path / Consequence | Evidence | Disposition | Scope | Reason / Response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CG-01 | Missing tool exits 5 (handoff assumption 1) | Design exit table (lib.sh contract) | Agent runs a script on a node without `jq` | `gh_require_tools` → exit 5 "jq is needed; install it, then run again" | `lib.sh:37-44`; SKILL.md exit table lists it under 5; test "a missing tool…" | Reject (accepted decision) | — | The table has no slot for it; 3 (access) and 4 (refused) would mislead; 5 "failed" fits and is documented. Accepted |
| CG-02 | Unknown board status exits 2 with the valid names (assumption 2) | AC-005 failure outcome; AR-008 | Agent passes a status the board lacks | `board_option` → `gh_usage_error` before any mutation | `board.sh:108-117`; test (only the board query is sent) | Reject (accepted decision) | — | The wrong value is the caller's argument: usage is the right class; AC-005 requires only the listed names. Accepted |
| CG-03 | Defaults `--limit 30` (1–1000), `--comments 5` (0 hides, max 100) (assumption 3) | REQ-004/005 "short and readable" (REQ-007) | Agent lists or reads | Bounded output | `issues.sh:14,50`, `pulls.sh:19` | Reject (accepted decision) | — | Matches GitHub's own default page size; keeps output short. Accepted |
| CG-04 | `lib.sh` holds `OWNER/REPO`, `OWNER/REPO#N` parsing and `--body-file` reading (assumption 5) | Design: "`lib.sh` knows no subject"; Principle 11/13 | Every subject script parses references | One owner for the shared reference format and the stdin/file rule | `lib.sh:56-94`; used by all three subject scripts | Reject (accepted decision) | — | The reference format is the design's shared interface rule ("References are always…", "Long text comes from a file or `-`"), not issue/PR/board logic. Putting it once in `lib.sh` is the Principle 13 answer. Accepted |
| CG-05 | `gh_get_list` takes the caller's jq filter (assumption 5) | Design: subject rules stay in subject scripts | `issues.sh list` | PR exclusion stays in `issues.sh:39-40`; paging/limit in `lib.sh` | `lib.sh:242-256` | Reject (accepted decision) | — | Keeps `lib.sh` subject-free while the limit-after-filter rule (AR-006) holds; filter is a caller constant, not input. Accepted |
| CG-06 | Refusals never print `AUTOBYTEUS_GITHUB_API_URL`; SKILL.md forbids printing it (assumption 6) | REQ-008 spirit; `credential_proxy.md` § Security Limits (pass is a bearer capability) | Any refusal or curl failure | Messages carry method + path without query; curl `-s`; test asserts `rp_test` absent on curl failure | `lib.sh:120-122,195-225`; SKILL.md Rules | Reject (accepted decision) | — | A sound, proportionate rule that adds no behaviour. Accepted |
| CG-07 | `board.sh move` reads `issueOrPullRequest.projectItems`; when the issue is also on a board the token cannot see, GitHub returns 200 with `nodes: [null]` and a `FORBIDDEN` error, and Rule 4 refuses the move | SCN-004 | Would need the target issue to also sit on another owner's board the token can't see | `board.sh:48-55,167` → Rule 4 exit 4 with the permission hint; no wrong success | Response shape measured in [cli/cli#13281](https://github.com/cli/cli/pull/13281) | Reject | — | No requirement or scenario has an issue on a second, inaccessible board (SCN-004/005 use one shared board). The failure is a clear refusal, not a silent wrong result. Recorded as a residual risk only |
| CG-08 | `board.sh items` prints `(hidden)` for items whose content is null. GitHub documents that items a token may not view come back `REDACTED`; if that answer also carries a GraphQL `errors` entry, Rule 4 refuses the whole listing for an org board that holds items from repositories outside a repo-limited token's list | SCN-004; `token.help` recommends repo-limited tokens | Org board spanning more repositories than the token covers | `board.sh:27-45,132` → `lib.sh:141-152` | [GitHub docs: "the item type will be returned as `REDACTED`"](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects); whether errors accompany it is not documented or measured | Hold for Evidence | — | The code follows both the approved Rule 4 and GitHub's documented behaviour, so no source conclusion depends on it. The missing evidence only the live check can produce (R-1, AC-005): API/E2E should put one item from a repository outside the token's list on the test board and run `board.sh items`. If the answer carries `errors`, it returns as a failure-origin review (Error Rule 4 is a design rule → Design Impact). Not scored |
| CG-09 | `curl` has `--connect-timeout 10` but no overall `--max-time` | DS-002 | Would need the local proxy to accept the connection and then never answer | Script waits | `lib.sh:108` | Reject | — | No supported scenario: the proxy owns upstream failure and answers `UPSTREAM_UNREACHABLE`; a slow legitimate answer (large list) must not be cut off |
| CG-10 | A GitHub 403 for a rate limit gets the permission hint | Rule 3 | Secondary rate limit | GitHub's own message is printed first, then the hint | `lib.sh:204-206` | Reject | — | Approved Rule 3; the agent sees GitHub's message. Not material |
| CG-11 | `lib.sh` is 237 non-empty lines (>220) | Size guardrail | — | — | line count | Reject | — | New file, one concern (the request path and its refusal rules, plus the shared reference format). A split would only scatter the Error Rules the design gives one owner |

## Structural / Design Checks

| Check | Result | Evidence | Required Action |
| --- | --- | --- | --- |
| Task design health assessment present and preserved | Pass | Feature, No Design Issue Found; capability reuse (skill sources, proxy); repeated coordination placed in `lib.sh` | — |
| Matches behavior-defining supplements | Pass | `integration.json` = contract example; check script and doc implement every contract rule (fields, `token.help` required when `token` present, ID regex, half-folder, no secret, unknown fields) | — |
| Data-flow spine inventory clarity | Pass | DS-002 is literal in code: subject script → `gh_request` → `$AUTOBYTEUS_GITHUB_API_URL` → status → Rules 1–4 → line or refusal | — |
| Ownership boundary preservation | Pass | Only `lib.sh` calls `curl`; subject scripts own parsing, calls and output for one subject | — |
| Off-spine concern clarity | Pass | Error explanation and prerequisite check live in `lib.sh` as the design's Off-Spine table says; scripts never read `integration.json` | — |
| Existing capability reuse | Pass | Install through skill sources; credential through the proxy; no new mechanism | — |
| Reusable owned structures | Pass | Reference parsing, count checks, body-file reading, paging are once in `lib.sh`; `PULL_HEAD`/`PULL_STATE` jq fragments shared within `pulls.sh` | — |
| Shared-structure tightness | Pass | `integration.json` has exactly the contract's fields; check refuses unknown ones | — |
| Repeated coordination ownership | Pass | Error Rules owned once (`gh_explain_refusal`, `gh_check_graphql_errors`) | — |
| Empty indirection | Pass | `gh_graphql` adds payload building and `.data` extraction; `check-access.sh` is the connection check the design names | — |
| Separation of concerns / file responsibility | Pass | One subject per script; `tools/` and `tests/` outside the skill folder | — |
| Ownership-driven dependency | Pass | Scripts → `lib.sh` → proxy only; forbidden shortcuts (token vars, `gh auth`, `api.github.com`) absent and tested | — |
| Authoritative Boundary Rule | Pass | No subject script calls `curl` or bypasses `gh_request` | — |
| File placement | Pass | Matches design § Target Folder / File Mapping | — |
| Flat-vs-over-split layout | Pass | Six small scripts, one lib; readable | — |
| Interface boundary clarity | Pass | Commands match design § Interface Boundary Mapping, explicit identity shapes (`OWNER/REPO`, `OWNER/REPO#N`, `--owner/--number`) | — |
| Naming / one vocabulary | Pass | `integration`, `integration manifest`, connection, `OWNER/REPO#N` used consistently across README, docs, SKILL.md, scripts | — |
| No unjustified duplication | Pass | Option loops repeat per command by design (different options per subject); no duplicated policy | — |
| Patch-on-patch complexity | Pass | Initial round | — |
| Dead code removed (Principle 7) | Pass | Shellcheck clean (IMP-03); every helper has callers. The `(hidden)` branch follows GitHub's documented `REDACTED` items (CG-08) | — |
| Test scenarios clear and requirement-aligned | Pass | 24 named cases mapped to REQ/AC/Rules; one case per Error Rule; IMP-05 shows the tests catch six seeded defects | — |
| Test fixtures/helpers reusable, structure coherent | Pass | `start/routes/run/expect_*`, `proxy_refusal`, shared `BOARD` fixture; stand-in records every request | — |
| No stale/duplicated/compat tests | Pass | New suite | — |
| API/E2E readiness | Pass | Live hints in handoff § Downstream Coverage Hints are concrete; plus CG-08 measurement below | — |

## Source File Size And Structure Audit

| Source File | Before | After | `>500` | `>220` Delta | SoC / Ownership | Placement | Classification | Action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `github/scripts/lib.sh` | 0 (new) | 237 | Pass | Over 220: justified (CG-11) | One owner: request path + Error Rules + shared reference format | Pass | OK | None |
| `github/scripts/board.sh` | 0 | 182 | Pass | Pass | Board subject only | Pass | OK | None |
| `github/scripts/issues.sh` | 0 | 155 | Pass | Pass | Issues subject only | Pass | OK | None |
| `github/scripts/pulls.sh` | 0 | 110 | Pass | Pass | PR subject only | Pass | OK | None |
| `github/scripts/check-access.sh` | 0 | 13 | Pass | Pass | Connection check | Pass | OK | None |
| `tools/check-integrations.sh` | 0 | 119 | Pass | Pass | AC-002 checks | Pass | OK | None |

## Legacy / Backward-Compatibility Verdict

| Check | Result | Notes |
| --- | --- | --- |
| No backward-compatibility mechanisms | Pass | No `gh` login fallback, no version field |
| No legacy old-behavior retention | Pass | README 244-era text removed |
| Dead code removed | Pass | — |
| Persisted-data decision followed | Pass | Not Affected |
| No dual reads/writes or old-shape fallback | Pass | — |
| Transition mechanics | Pass | N/A |

## Dead / Obsolete / Legacy Items Requiring Removal

None.

## Docs-Impact Verdict

- Docs impact: `Yes`, delivered in this change (README, `docs/integration-manifest.md`, `SKILL.md`). The README install steps are rewritten in the final round (AC-009, DEC-007).

## Additional Material Premise Validation

None new or reclassified. CG-07 and CG-08 are recorded in the candidate gate above.

## Review Scorecard (Mandatory)

- Overall score: `9.5/10` (simple average; not the decision rule)

| Priority | Category | Score | Why | Weak | Improve |
| --- | --- | --- | --- | --- | --- |
| 1 | Data-Flow Spine Inventory and Clarity | 9.6 | DS-002 is one visible path: script → `gh_request` → proxy → rules → line | — | — |
| 2 | Ownership Clarity and Boundary Encapsulation | 9.6 | `lib.sh` is the only request path and the only Error Rule owner; no bypass | — | — |
| 3 | API / Interface / Query / Command Clarity | 9.5 | Commands match the design table; explicit reference shapes; long text only from file/stdin | Exit 2 for an unknown status is a judgment call (CG-02), documented | — |
| 4 | Separation of Concerns and File Placement | 9.5 | One subject per script; tools/tests outside the skill folder | `lib.sh` holds the reference format too (CG-04): justified | — |
| 5 | Shared-Structure / Data-Model Tightness | 9.6 | Manifest has exactly the contract's fields; checker refuses extras | — | — |
| 6 | Naming Quality and Local Readability | 9.4 | Clear function names, comments state the rules; bash 3.2 safe | `pulls.sh` jq programs in double-quoted bash strings are dense to read | Acceptable as is |
| 7 | API/E2E Readiness | 9.4 | Deterministic suite strong; live hints concrete | GraphQL/REST shapes proven only against the stand-in (R-1/R-2), CG-08 unmeasured | Live check measures them |
| 8 | Runtime Correctness And Behavioral Fidelity | 9.3 | Exit-code propagation through subshells and `pipefail` traced; paging and last-N comments correct; JSON built only with `jq --arg` | Live GitHub shapes unproven (R-1/R-2, CG-08) | Live check |
| 9 | No Backward-Compatibility / No Legacy Retention | 9.8 | None | — | — |
| 10 | Cleanup Completeness | 9.6 | README fully replaced; shellcheck clean | — | — |

## Findings

None.

## Follow-ups

- Follow-ups this review added: None. FU-001 stays with the Solution Designer.

## Classification

N/A (Pass).

## Recommended Recipient

API/E2E (primary pass rule); implementation notified (informational).

## Residual Risks

- R-1/R-2: GraphQL documents, REST field names and write paths are proven only against the stand-in. The live check is the first real proof (organisation board with a fine-grained token).
- CG-08 (for API/E2E to measure): put one item from a repository outside the token's list on the test board (for example an issue of a public AutoByteus repository), then run `board.sh items`. Expected: that item prints `(hidden)` and the command exits 0. If the GraphQL answer carries `errors`, the listing is refused (exit 4). That is a failure for failure-origin review: Error Rule 4 is a design rule.
- CG-07: `board.sh move` refuses (exit 4, clear message) when the target issue also sits on a board the token cannot see. This is outside the supported scenarios.
- FU-001 (ambient `gh` login on this node) is unchanged.

## Latest Authoritative Result

- Review Decision: `Pass`
- Review Entry Point: `Implementation Review`
- Supported Product Scenario Gate: `Pass`
- Material-Premise Gate: `Pass` (CG-08 held for the live measurement; no source conclusion depends on it)
- Score Summary: 9.5/10 overall, every category ≥ 9.3
- Failure Origin: N/A
- Recommended Recipient: API/E2E
- Notes: All six assumptions in the handoff are accepted (CG-01…CG-06). AC-007 is satisfied by review. The checks were not rerun, because the code has not changed since IMP-01…IMP-05 ran.
