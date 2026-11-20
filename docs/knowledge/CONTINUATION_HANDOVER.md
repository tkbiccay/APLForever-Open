# APLForever-Open — concise canonical continuation (20 November 2026)

> **Read this checkpoint first.** The complete pre-compaction ~70 KB continuation history is permanently preserved in [main at `cf64b166`](https://github.com/tkbiccay/APLForever-Open/blob/cf64b166889a9bacab87e5c3fdfa37dc8433cced/docs/knowledge/CONTINUATION_HANDOVER.md). PRs, source-pinned knowledge, every complete APL and their SHA-256 checksums remain individually accessible. Do not repeatedly load the historical full document unless investigating an earlier decision.

## Latest verified state and provenance

- **Repository:** [tkbiccay/APLForever-Open](https://github.com/tkbiccay/APLForever-Open), protected `main` head **`cf64b166889a9bacab87e5c3fdfa37dc8433cced`** *before* docs-only [AI Sprint 11 PR #51](https://github.com/tkbiccay/APLForever-Open/pull/51). [Validator run 44815198063](https://github.com/tkbiccay/APLForever-Open/actions/runs/44815198063) succeeded at that head. When resuming, read GitHub's **live** head, PR and current-head Actions result; this recorded SHA is not a future-state promise.
- **Upstream:** published Hekili Forever **v0.11.0**, `zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b` ([release record](engine/current-release.json)). WoWSims translated source `ab0f00e4fc83`. Reverify a new release only if GitHub now publishes one; current-release **all-role** native compatibility is still *unverified*.
- **Catalogue:** [roles.json](../../catalogue/roles.json) has **28 intended, 23 Supported, five blocked healer roles, 44 SHA-protected full revisions, zero Approved**. The catalogue defines selections, not filenames or latest revision numbers. **No in-game client has been run by this AI Sprint.**
- **Priorities:** Guardian/Feral Tank and Hunter BM **equal P0**, Feral DPS next; remaining roles according to risk. Original standalone custom APLs; preserve native off-switches, require no custom per-spec settings; shipped/default is a research comparator, not the design ceiling.

## Equal P0 role status / immutable rollback

| Role | Most recent candidate (unselected) | Protected Current / rollback | Decision |
| --- | --- | --- | --- |
| **Guardian Tank** | [v1.5 Draft](../../roles/Druid/Candidates/APL_Druid_Guardian_v1.5_Draft.txt), SHA256 `75de4388516e3e70cd77f292901c1205f1176dc3561ac9b54dac8fef6c2abcc2` | [v1.0 Reported Working / Needs Retest](../../roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt), SHA256 `f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786`; both preferred and last-working remain v1.0 | [Guardian native v0.11 pass](https://github.com/tkbiccay/APLForever-Open/actions/runs/44800584032); source-natural high-kit Rage floor never reached 35 in [Maul experiment](https://github.com/tkbiccay/APLForever-Open/actions/runs/44810733710); no v1.6 |
| **Hunter BM** | [v1.4 Draft](../../roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt), SHA256 `718182dca05bbb926652a8b824127a212651bcbdf930d820c5afd726b613aae5` | [v1.1 Current Draft](../../roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt), SHA256 `a9d752c5e6cdc11fc369fcb6627b73686cc52b5139ed2df4c6628db6c7826d96`; `preferred_apl=null`, no reported-working baseline | [10/10 source-native v1.4](https://github.com/tkbiccay/APLForever-Open/actions/runs/44812780314), Lone Wolf suppresses both Call and Revive, 6yd/12yd checks; no real pet arrival |
| **Feral DPS** | [v1.3 Draft](../../roles/Druid/Candidates/APL_Druid_Feral_v1.3_Draft.txt), SHA256 `f235f9c0512a8ceab0ec46daadc2de6b7b497e85de1ad116459aa874f93a9450` | [v1.0 Current Draft](../../roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt), selected development reference; not reported-working | [Scoped native pass](https://github.com/tkbiccay/APLForever-Open/actions/runs/44799502215); no game proof |

**Related latest Hunter result:** MM v1.1 and Survival v1.1 are separate unselected pet-recovery Drafts [PR #49](https://github.com/tkbiccay/APLForever-Open/pull/49); native stored-file [8/8 passed](https://github.com/tkbiccay/APLForever-Open/actions/runs/44814291357). Their original v1.0 Current files remain exact. The native source cannot prove real pet arrival, health, pet damage, DPS or player-facing repeated icons after accepted casts.

## Sprint 11 — compact continuity / test-target correctness

**[Docs-only PR #51](https://github.com/tkbiccay/APLForever-Open/pull/51)** corrects the [v0.11 live checklist](../Tests_P0_LIVE_ACCEPTANCE_V011.md) from stale BM v1.3 to tested **v1.4**, and explicitly checks Lone Wolf petless intent. Original v1.3 and all other APL candidates are unchanged. This canonical page now contains only the actionable restart; **full original historical text survives at the immutable commit link above**. Confirm PR #51 current-head CI and merge status, and only count it complete if genuinely merged green. This is **documentation**, not a combat improvement or an in-game validation.

## Next smallest worthwhile proof (not another speculative revision)

1. **Guardian:** in v0.11 client, safe grouped aggro with enough actual Rage: accepted Demoralising Roar, correct optional Barkskin toggle, next three legal actions; collect a natural high-Rage Maul queue/strike if available. No forced hazard or invented Rage.
2. **Hunter BM v1.4:** new test pack, Lone Wolf ON with naturally absent/dead pet → **neither Call nor Revive**; OFF with natural absence/death → real Call/Revive, pet arrival, then three legal subsequent casts. At safe 6–8yd Major ON/OFF validate Bestial Wrath and Hawk, compare Current/shipped, record `/hek snap` for a failure. Do not intentionally kill a pet.
3. **Feral DPS:** investigate only a specific unresolved native fallback/control or live observed failure. Don't build another Candidate merely for iteration count. Other tank Drafts: Warrior Protection v1.1 and Paladin Protection v1.1 remain source-native validated, unselected, game unproved.

For imports and exact test instructions use [v0.11 P0 live checklist](../Tests_P0_LIVE_ACCEPTANCE_V011.md). For transferable source-vs-fixture lessons, including DEMO-006 repeated Life Tap and final fallback, see [cross-APL transfer](lessons/CROSS_APL_TRANSFER.md). If live suggestions regress, restore the exact previous pack, capture `/hek snap`, and separate engine/API limitations from APL bugs. **0 Approved until repeatable real-client evidence and matched comparisons.**

## Restart / efficiency contract

1. Read [AGENTS.md](../../AGENTS.md), this **concise** checkpoint, [roles.json](../../catalogue/roles.json), current release record and latest relevant PR/CI. **Do not reread the entire historical handover by default**.
2. Verify main, open PRs, source pins and SHA-256; compare shipped/default **and** last-working without replacing either. Read full role APL only for the role being edited. Reuse verified fixtures and negative results; test the entire reachable final/repeated fallback before publishing.
3. One source-backed hypothesis → one small independent complete Draft if needed → targeted native tests → short-lived PR → green checks → merge only non-promotional safe work → update this page **in place**. Gameplay and approval remain human-only. No unlimited ongoing background work, no speculative mass loops, no unnecessary Codex delegation.
4. ChatGPT **Compact Mode:** user-facing sprint progress only reports **Done / Evidence / Blocker / Next**. Keep full code, explanations and detailed source evidence in GitHub; share complete APL code in chat when explicitly delivering a role. Compact messages do not remove ChatGPT context limits: start a fresh numbered chat using this GitHub checkpoint before running out.
