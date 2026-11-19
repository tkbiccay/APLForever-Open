# APLForever — source-pinned, reusable class mechanics

**Project-wide rule: Research once → Preserve → Reuse.**

Search existing pinned research, protected working evidence, tests and cross-spec lessons before rediscovering an issue. Preserve its *exact version, source, limitation, failure and verification grade*. Reuse mechanics or testing patterns only when the new class/spec/role and released engine permit them. No magic AI-generated facts, no duplicate silo, no shared runtime APL dependency.

## Canonical storage

- `knowledge/classes/Hunter.json` and `Druid.json` hold **one copy per class**, not separate contradictory copies for BM/Marksmanship/Survival or Guardian/Feral.
- Talent records include the **complete v0.9.0 class registry** (key, tree, rank-one spell ID, maximum rank and source line). Unknown talent effects stay **not reviewed**; these IDs/ranks are not a full level-unlock or talent-prerequisite guide.
- Ability records cover **reviewed high-priority actions only**. Each records multiple tags, exact source identity and line, GCD, actual native toggle (possibly none), source literal cost/cooldown where static, proposed APL lane **separately**, range evidence type, caveat and classification confidence. Absent ability records mean **not researched**.
- `docs/reference/Hunter_BeastMastery.md` and `Druid_Guardian.md` are readable pages **generated** from the class records. Never edit manually.
- `scripts/build_mechanics_reference.py` checks schema and generated pages with `--check`, regenerates pages with `--write`, and with `--source-root ../upstream/hekili` independently verifies the Git commit, class blob, exact ability source lines/IDs/GCD/toggle/resources, pinned world ranges and **all** talent registrations. Small CI runs this without Lua or expensive all-role testing.

## Evidence boundary

Native toggle is a registered **engine property**; proposed Major/Minor/Defensives/Interrupts/Potions/etc lanes are **design intent**, not supported toggle claims. Published world range is source-fixture verification, not live-client range, facing, auto-shot or DPS proof. Unobserved facts remain null/unreviewed. Use Forever sources only; do not backfill from Retail, Classic or SoD.

On each new addon release, inspect the diff first, reuse unaffected records and verify changed ones against the new pin; never overwrite historical evidence to look current. An APL is still a complete **standalone** role file and must have its own default/last-working/candidate and actual accepted-cast/in-game proof.

**Pilot:** 19 November 2026 · pinned Hekili Forever v0.9.0 commit `8f95f2ea0a45428554c1e938ed7357b870030514`. Hunter Beast Mastery and Druid Guardian remain joint top priority. Expand to another role only when it materially supports development.
