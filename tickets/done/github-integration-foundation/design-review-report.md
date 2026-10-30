# Design Review Report — github-integration-foundation (autobyteus-integrations-1)

## Review Round Meta

- Upstream Requirements Doc: `/Users/normy/autobyteus_org/autobyteus-worktrees/github-integration-foundation/tickets/in-progress/github-integration-foundation/requirements-doc.md` (SR-008)
- Upstream Investigation Notes: `.../github-integration-foundation/investigation-notes.md`
- Upstream Solution Revision Record: `.../github-integration-foundation/solution-revision-record.md` (§ SR-008)
- Reviewed Design Spec: `.../github-integration-foundation/design-spec.md` (SR-008)
- Supplemental Task Artifacts Reviewed: `integration-manifest-contract.md` (behavior-defining, SR-006 + SR-008 folder rule); `handoff-architecture-design-complete.md` (incl. § Re-review request); `handoff-prerequisite-integrations-page.md`; `follow-ups.md`
- Relevant Solution Revision IDs: SR-002…SR-008
- Architecture Review Revision Record: `.../github-integration-foundation/architecture-review-revision-record.md`
- Current Architecture Review Revision ID: `ARCH-REV-002`
- Current Review Round: 2
- Trigger: Solution Designer re-review request after ARCH-REV-001 (SR-008), 2026-10-30
- Prior Review Round Reviewed: 1 (`ARCH-REV-001`, Fail)
- Latest Authoritative Round: 2
- Current-State Evidence Basis: unchanged from round 1 and still valid — integrations repository `origin/main` `6fa9bbc` (README only; worktree holds only the untracked ticket folder); app `1a4453e553` (`v1.5.11-beta.4`): `autobyteus-server-ts/docs/modules/credential_proxy.md`, `docs/modules/skills.md` § Runtime Consumption, `src/skills/services/skill-discovery.ts:199-212`, `src/agent-execution/backends/shared/workspace-skill-links.ts:103-106`, `DESIGN.md` rules 8, 9. Round 2 re-read every changed passage listed in the handoff's § Re-review request.

## Routing Classification Review

- Task size: `Medium`
- Architectural risk: `High`
- Classification rationale reviewed: unchanged — new public contract (`integration.json`, folder layout) and the first credential-backed GitHub writes through the proxy; about 12 files, one new repository, no app code.
- Independent Architecture Review required by the classification: `Yes`
- Classification evidence or correction required: none. SR-008 adds AC-009 (a later round of this ticket) without adding code surface now.

## Upstream Behavior And Production-Path Basis Confirmation

- Overall Basis Status: `Confirmed`
- Approved requirements / intended behavior understood: Yes (SR-008). Integration = skill + authentication; `github/` skill and scripts on the proxy contract; manifest `name`, `description`, `token.help`, `prerequisites`; folder name = ID, `SKILL.md` name = skill, `icon.svg`; a top-level folder with only one of `SKILL.md`/`integration.json` is an error; cross-node `OWNER/REPO#N`; no app change.
- Relevant existing behavior and evidence confirmed: Yes (round-1 evidence still valid; nothing in the app or repository changed).
- Scope guardrail confirmed: Yes (UC-001…UC-006; out of scope unchanged; preserved BEH-001/BEH-002; standard review authority).
- Approved change, preserved behavior, outside scope: understood. DEC-007 (Solution Designer within the PM's quoted direction): AC-001/AC-008 on today's released journey after finalization; Integrations-page journey and README rewrite in this ticket's final round (AC-009) after autobyteus-337.
- Every prospective blocking `Design Impact` finding is traceable: Yes (none remain).
- Remaining material ambiguity: none. Cosmetic stale references only (AR-010, non-blocking).
- Statements about existing code the design relies on: proxy refusal codes and statuses in § Error Rules match `credential_proxy.md` error table (all 403 except `UPSTREAM_UNREACHABLE` 502, `PROXY_FAILED` 500; API route passes GitHub's 401 through; `UPSTREAM_REJECTED_TOKEN` git-only, correctly not mapped by the scripts). Skill discovery and skill-path delivery as in round 1.

| Behavior ID | Kind | Design Alignment With Approved Intent | Approved Trigger / Contract And Current-State Evidence | Target Outcome / Path / Spine Coherence | Status | Required Action |
| --- | --- | --- | --- | --- | --- | --- |
| BEH-001 | User | Pass | Pass (F-A1, `skill-discovery.ts`) | Pass — AC-001/AC-008 today's journey; AC-009 later; Change Sequence 5–6 and README row aligned | Confirmed | — |
| BEH-002 | Contract | Pass | Pass (`credential_proxy.md`) | Pass — § Error Rules covers every proxy code, REST 401, GraphQL 200 + `errors` | Confirmed | — |
| BEH-003 | User | Pass | Pass | Pass | Confirmed | — |
| BEH-004 | Contract | Pass — UC-006, SCN-006, desired outcome, design text match the contract | Pass | Pass | Confirmed | — |
| BEH-005 | System | Pass | Pass | Pass (DS-005) | Confirmed | — |
| BEH-006…BEH-009 | User (app, 337) | Pass — § What Remains For The Integrations Page rewritten against them | Pass (SR-003) | Pass | Confirmed | — |

## Supplemental Artifact Coherence Verdict

| Artifact | Purpose And Scope Are Clear? | Linked To Relevant Core Artifacts? | Internally Complete? | Consistent With Related Core Artifacts? | Status And Approval Applicability Are Clear? | Required Action |
| --- | --- | --- | --- | --- | --- | --- |
| `integration-manifest-contract.md` | Pass | Pass (REQ-002; both headers; inventory) | Pass — open part named once ("an addition under `token`"); SR-005 table marked partly superseded | Pass | Pass (behavior-defining, current at SR-006; inventory row) | — |
| `handoff-prerequisite-integrations-page.md` | Pass | Pass (inventory) | Pass | Pass (AC-009 waits for it) | Pass | — |
| `handoff-architecture-design-complete.md` | Pass | Pass | Pass | Partly — § Scope notes still says AC-001/AC-008 wait for 337 and "Current SR: SR-007"; § Re-review request and DEC-007 supersede | Pass | AR-010 (non-blocking) |

## Task Design Health Assessment Verdict

| Assessment Area | Result | Evidence | Required Action |
| --- | --- | --- | --- |
| Assessment present | Pass | Feature, new content in a new repository | — |
| Root-cause classification evidence-backed | Pass | No Design Issue Found; README-only repository | — |
| Refactor decision explicit | Pass | No refactor | — |
| Refactor decision supported | Pass | Triggers recorded; vocabulary line now "ID is its folder name … one name on both sides" | — |

## Spine Inventory Verdict

| Spine ID | Scope | Readable? | Narrative Clear? | Facade Vs Governing Owner | Naming Clear? | One Owner Per Node, In Call Order? | Off-Spine Off Main Line? | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DS-001 install | Primary | Pass | Pass | N/A | Pass | Pass | Pass | Pass |
| DS-002 operation | Primary | Pass | Pass | Pass (subject script → `lib.sh` → proxy) | Pass | Pass; return path via § Error Rules | Pass | Pass |
| DS-003 git push | Primary | Pass | Pass | N/A | Pass | Pass | Pass | Pass |
| DS-004 manifest read | Primary | Pass | Pass | N/A | Pass | Pass | Pass | Pass |
| DS-005 cross-node | Primary | Pass | Pass | N/A | Pass | Pass | Pass | Pass |

## Boundary Encapsulation Verdict

| Boundary / Owner | Public Entry Clear? | Internals Stay Internal? | Bypass Controlled? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `lib.sh` (one request path, refusal rules) | Pass | Pass | Pass | Pass | Subject scripts call GitHub only through it; it knows no subject |
| App proxy (not changed) | Pass | Pass | Pass | Pass | Forbidden list explicit |
| `integration.json` | Pass | Pass | Pass | Pass | No runtime reader; prerequisite message now from the script's own wording |

## Dependency Direction / Forbidden Shortcut Verdict

| Owner / Boundary | Allowed Clear? | Forbidden Explicit? | Coherent? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `github/scripts/*` | Pass | Pass | Pass | Pass | bash, curl, jq, git, proxy contract |
| `tools/check-integrations.sh` | Pass | N/A | Pass | Pass | manifests + `SKILL.md` only |

## Interface Boundary Verdict

| Interface | Subject Clear? | Singular? | Identity Explicit? | Generic Risk | Verdict |
| --- | --- | --- | --- | --- | --- |
| `issues.sh list/read/create/comment` | Pass | Pass | Pass | Low | Pass (PRs filtered, limit after filter) |
| `pulls.sh list/read/open` | Pass | Pass | Pass | Low | Pass |
| `board.sh items/move` | Pass | Pass | Pass | Low | Pass (add-then-move reported; case-insensitive status, board's spelling in output) |
| `check-access.sh` | Pass | Pass | N/A | Low | Pass |
| Exit codes 0/2/3/4/5 + § Error Rules | Pass | Pass | Pass — discriminator (top-level `error` code = proxy), every proxy code placed, 401 → 3, GraphQL `errors` → 4 | Low | Pass |
| Long text from file / `-` | Pass | Pass | Pass | Low | Pass |

## Existing Capability / Subsystem Reuse Verdict

| Need | Checked? | Decision Sound? | New Piece Justified? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| Install / update | Pass | Pass — skill sources | N/A | Pass | |
| Credential delivery | Pass | Pass — proxy | N/A | Pass | |
| Request/error handling | Pass | Pass | Pass — one `lib.sh` | Pass | |
| Test stand-in | Pass | Pass | Pass | Pass | Python stdlib, `-I` |

## Subsystem / Capability-Area Allocation Verdict

| Area | Allocation Clear? | Decision Sound? | Supports Spine Owners? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `github/` (installed skill) | Pass | Pass | Pass | Pass | |
| `docs/`, `tools/`, `tests/` (repository) | Pass | Pass | Pass | Pass | ignored by the importer |

## Reusable Owned Structures Verdict

| Repeated Structure / Logic | Evaluated? | Shared File Sound? | Ownership Clear? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| Request, refusal rules, JSON building | Pass | Pass (`lib.sh`) | Pass | Pass | |

## Shared Structure / Data Model Tightness Verdict

| Structure | One Meaning Per Field? | Redundant Removed? | Overlap Controlled? | Core Vs Variant | Verdict | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `integration.json` | Pass | Pass | Pass | N/A | Pass | Design and requirements now describe only the contract's fields |

Derived consumers listed with a decision for each: `Pass` (`tools/check-integrations.sh` now; the Integrations page, autobyteus-337, later; `SKILL.md` read by the catalog).

One vocabulary: `Pass` — ID = folder name everywhere; token routing = "an addition under `token`" everywhere. Two leftover "(311)" labels for the page are wording drift, recorded under AR-010.

## File Responsibility Mapping Verdict

| File | Singular? | Matches Owner? | Re-Tightened? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `README.md` | Pass | Pass | N/A | Pass | today's journey, terminal-tool/sandbox note, app version, moves with 337 |
| `docs/integration-manifest.md` | Pass | Pass | N/A | Pass | |
| `github/SKILL.md` | Pass | Pass | N/A | Pass | |
| `github/integration.json` | Pass | Pass | N/A | Pass | |
| `github/scripts/lib.sh` | Pass | Pass | Pass | Pass | |
| `github/scripts/{check-access,issues,pulls,board}.sh` | Pass | Pass | Pass | Pass | |
| `tools/check-integrations.sh` | Pass | Pass | N/A | Pass | half-integration folder rule added |
| `tests/github/{fake-api.py,run-tests.sh}` | Pass | Pass | N/A | Pass | one case per error rule |

## Subsystem / Folder / File Placement Verdict

| Path | Placement Clear? | Matches Boundary? | Risk | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `github/` top level | Pass | Pass | Low | Pass | |
| `tools/`, `tests/github/`, `docs/` | Pass | Pass | Low | Pass | |

## Removal / Decommission Completeness Verdict

| Item | Named? | Replacement Clear? | Scope Explicit? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| README's 244-era text ("No integration is published yet", "platform supplies them only when a command runs", "may also carry its MCP server entry") | Pass | Pass (README row rewritten) | Pass | Pass | Implementation replaces the "What an integration is" and "Status" paragraphs, not only the one sentence |

## Legacy / Backward-Compatibility Verdict

| Area | Legacy Exists? | Clean-Cut Explicit? | Verdict | Notes |
| --- | --- | --- | --- | --- |
| `gh` login fallback; version fields | No | Pass | Pass | |

## Persisted-Data Transition Verdict

N/A — `Not Affected` (no stored data; app stores unchanged).

## Change / Refactor Safety Verdict

| Area | Sequence Realistic? | Seams Explicit? | Cleanup Explicit? | Verdict |
| --- | --- | --- | --- | --- |
| Steps 1–4 (build, deterministic tests, live check) | Pass | N/A | Pass | Pass |
| Step 5 (finalize; AC-001/AC-008 today's journey) | Pass | N/A | N/A | Pass |
| Step 6 (final round after 337; AC-009, README rewrite) | Pass | Pass — README's interim journey is the explicit temporary state, owned by this ticket's final round | Pass | Pass |

## Example Adequacy Verdict

| Topic | Needed? | Present And Clear? | Bad Shape Explained? | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| Shell environment and script calls | Yes | Pass (status now "In Progress") | Pass | Pass | |
| Manifest | Yes | Pass | Pass | Pass | |
| Jira reuse | Yes | Pass (folder `jira/` = ID; addition under `token`) | N/A | Pass | |
| Error rules | Yes | Pass (per-code messages, test cases incl. "a GitHub body that merely contains the word error") | N/A | Pass | |

## Material Premise Validation (Only When Needed)

Round-1 premises, rechecked:

- P-001 (GraphQL refusal = HTTP 200 + `errors`): `Reachable`; now handled by § Error Rules rule 4 and its stand-in case. Closed.
- P-002 (REST issues list includes PRs): `Reachable`; handled in § Implementation Notes From Review. Closed.
- P-003 (SSH remote bypasses the proxy): `Unclear`, non-blocking; `SKILL.md`/README now say to push with the `https://github.com/` URL. Closed as a docs note.

No new premise.

## Unresolved Approved-Behavior Or Current-State Gaps

None.

## Review Decision

- **`Pass`** — the behavior basis is confirmed, every blocking finding from ARCH-REV-001 is resolved in the current canonical artifacts, and no in-scope machinery depends on an unsupported premise. Ready for implementation per `design-spec.md` (SR-008).

## Findings

### AR-010 — Leftover stale references (non-blocking)

- Type: Design Impact (wording), Low. Non-blocking. Protects: clarity of REQ-010/DEC-007 for implementation and delivery.
- Scope status: Within Approved Scope. Changes approved behavior: No.
- Evidence:
  - `design-spec.md:26` "the Integrations menu later (311)" and `:204` "per-integration install is a menu concern (311)" — the page is autobyteus-337.
  - `design-spec.md` header "Approved requirements: `requirements-doc.md` at SR-002"; `requirements-doc.md` header "Approved by and reference … SR-002", "Exact approved baseline: this document at SR-002" and § Readiness "SR-002", while Status says "Approved at SR-008".
  - `requirements-doc.md:161` "app work owned by autobyteus-311 (its Integrations-page step)"; `:165` "waits only for the user's build-now-or-wait answer" (answered at SR-007).
  - `handoff-architecture-design-complete.md` "Current SR: `SR-007`" and § Scope notes "the teammate-way check through the page (AC-001, AC-008) waits for 337" — superseded by DEC-007 and the AC table.
- Authority if read in conflict: the AC table (AC-001, AC-008, AC-009), DEC-007 and design Change Sequence 5–6 govern.
- Update: fix on the Solution Designer's next touch of these files (e.g. at the AC-009 round or delivery); no re-review needed.
- Recipient: Solution Designer (informational); implementation engineer told which text governs.

Prior findings AR-001…AR-009: resolved; see `architecture-review-revision-record.md` § ARCH-REV-002.

## Classification

N/A for routing (Pass). AR-010 is a non-blocking wording note.

## Recommended Recipient

Implementation engineer (`/software_engineering_team/implementation_engineer`); informational pass notice to the Solution Designer.

## Residual Risks

- R-1/R-2: organisation-board item moves and write paths through the proxy are proven only by the live check (Change Sequence step 4).
- FU-001 (ambient `gh` login on this node, urgent security follow-up) stays with the Solution Designer to send when the ticket leaves the team.
- The ticket folder is published in a public repository; it names local paths and the secrets file path (no values). Delivery should confirm no secret value is committed.
- AC-009 depends on autobyteus-337, not yet dispatched; the ticket stays open by the PM's direction.

## Latest Authoritative Result

- Review Decision: `Pass`
- Material-Premise Gate: `Pass`
- Notes: Medium/High confirmed. AR-001…AR-009 resolved; AR-010 non-blocking.
