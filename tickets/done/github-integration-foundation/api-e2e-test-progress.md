# API/E2E Test Progress — github-integration-foundation

- Execution coverage report: `api-e2e-execution-coverage-report.md`
- Planned cases: `api-e2e-coverage-investigation.md` § Planned Cases (same case IDs)
- Scratch (temporary, outside the repository): `/tmp/gh-int-live` (harness, state, outputs, throwaway `CODEX_HOME`)

| Time | Case ID | Event | Result | Note |
| --- | --- | --- | --- | --- |
| 2026-10-30 14:20 | API-01…03 | Completed | Pass | Reused IMP-01…IMP-05 on `3192aec`; `git diff --name-only 3192aec f9d7f02` lists ticket files only |
| 2026-10-30 14:20 | ENV-2 | Started | — | Isolated instance of /Applications/AutoByteus.app (1.5.11-beta.5) with throwaway CODEX_HOME |
| 2026-10-30 14:19 | ENV-2 | Completed | Pass | iso-62788-45ad, backend 127.0.0.1:62789; connected as ryan-zheng-teki; skill github-integration from the worktree; agents gh-int-live-ticked-c8bf8b (ticked), gh-int-live-unticked-dc5097 |
| 2026-10-30 14:20 | API-10 | Started | — | Codex run gh_int_live_ticked_c8bf8b_1c71…, gpt-5.6-luna, auto-execute; check-access turn |
| 2026-10-30 14:21 | API-10 | Completed | Pass | `GitHub access: connected as @ryan-zheng-teki`, exit 0 (/tmp/gh-int-live/out/API-10-turn.jsonl) |
| 2026-10-30 14:22 | API-11…13 | Started | — | driver phase A in the agent's shell, out /tmp/gh-int-live/out/A |
| 2026-10-30 14:21 | API-11…13 | Completed | see report | phase A: 25 steps; A22 listing missed PR #2 seconds after it was added; A25 raw read-back shows it |
| 2026-10-30 14:22 | API-13 | Checkpoint | — | phase R: R01 board.sh items now lists #3 [Done] and #2 [Todo] → A22 was GitHub listing lag, not the script |
| 2026-10-30 14:22 | API-14 | Started | — | F01: token cannot add AutoByteus/autobyteus-server#6 (NOT_FOUND); F2: issue #4 created and put on the board (Todo); host transferred #4 → AutoByteus/autobyteus-server#9 at 13:22:40Z (private, outside the token's list) |
| 2026-10-30 14:23 | API-14 | Checkpoint | — | B, B2 (45 s after transfer): item absent from raw nodes and totalCount=2; board.sh items exit 0 without it. Host: issue #9 projectItems.totalCount=1. Recheck after a few minutes before concluding |
| 2026-10-30 14:24 | API-15 | Started | — | phase C refusals in the agent's shell |
| 2026-10-30 14:24 | API-15 | Completed | Pass | C01 404 exit 4, C02 403 exit 4 (nothing written), C03/C04 GraphQL NOT_FOUND exit 4 |
| 2026-10-30 14:25 | API-16 | Started | — | untick while live / re-tick / never-ticked agent run |
| 2026-10-30 14:26 | API-16 | Completed | Pass | INTEGRATION_NOT_ALLOWED exit 3 → re-tick connected → never-ticked "No GitHub access in this run" exit 3 |
| 2026-10-30 14:27 | API-17 | Started | — | plain request; agent chooses commands from SKILL.md |
| 2026-10-30 14:28 | API-17 | Completed | Pass | comment 6523909235 by ryan-zheng-teki (host read-back) |
| 2026-10-30 14:29 | API-14 | Checkpoint | — | B4 (6 min after transfer): still totalCount 2, no errors, exit 0; transfer back → #5; G control: #5 "moved" (item stayed on the board), listed, totalCount 3 |
| 2026-10-30 14:31 | API-14 | Completed | Pass | transfer out again → B5 totalCount 2, no errors, exit 0; GitHub omits the item (no REDACTED, no errors); transferred back → #6 |
| 2026-10-30 14:32 | cleanup | Completed | — | X deleted the 3 board items (board empty); host closed #1, #6, PR #2, deleted branch |
| 2026-10-30 14:33 | API-18 | Completed | Pass | scan 737 files, filesWithToken 0 (positive control 1); activity 74 records; instance log 0 run passes |
| 2026-10-30 14:34 | ENV-2 | Completed | — | isolated-app stop: dataRootRemoved true, ports released; /tmp/gh-int-live removed |
