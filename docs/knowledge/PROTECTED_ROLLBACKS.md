# Protected development rollback registry

Owner decision, 28 November 2026. Catalogue snapshot `fd935a8ed76b8973de0f92ab0fc8b0ffe87a1630`. This register selects engineering rollback references, not player-facing preferred/last-working/Approved pointers or runtime dependencies. All 23 Supported roles have exact v1.0 bytes; Feral v1.6 is the sole owner-designated newer exception. Five blocked healers have no rollback APL and remain blocked. All 59 existing revisions are preserved. Update this register only after explicit owner designation and evidence review. For actual gameplay regression restore a known working profile if available; never recommend a known-defective historical Draft as safe. Candidate revisions remain separate from rollback, and all previous checkpoints remain accessible.

| Role | Protected revision / catalogue status | Exact file | SHA-256 |
| --- | --- | --- | --- |
| Druid_Balance | v1.0 / Draft | `roles/Druid/Current/APL_Druid_Balance_DPS_v1.0_Draft.txt` | `1cf83328f343e20a8efc93ed06645e862979e8d2f8bfce79acdcfcbedc55c1c2` |
| Druid_Feral | v1.6 / Draft | `roles/Druid/Candidates/APL_Druid_Feral_v1.6_Draft.txt` | `701838368217898cdc0e2035a2c17ee8bbc3f4d692a992171b382194234bcc62` |
| Druid_Guardian | v1.0 / ReportedWorking | `roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt` | `f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786` |
| Hunter_BeastMastery | v1.0 / Draft | `roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt` | `8b552b6dd6fc9f0c4221e75242ef147c840242b3c03c3e2a75d46aedfe039eba` |
| Hunter_Marksmanship | v1.0 / Draft | `roles/Hunter/Current/APL_Hunter_Marksmanship_DPS_v1.0_Draft.txt` | `43c78f4517f260e54d59cb2bac06f7464bdc78306d1df6a2977b4366c335bc9a` |
| Hunter_Survival | v1.0 / Draft | `roles/Hunter/Current/APL_Hunter_Survival_DPS_v1.0_Draft.txt` | `e58fe21c311c90d49c7cac8424f369ff08199d5c6cb35adbab2a03374ae7b12c` |
| Mage_Arcane | v1.0 / Draft | `roles/Mage/Current/APL_Mage_Arcane_v1.0_Draft.txt` | `d89600259308d74e56dc96decd2af9a27c60d561d90fe2cca1a2ed15b359a036` |
| Mage_Fire | v1.0 / Draft | `roles/Mage/Current/APL_Mage_Fire_v1.0_Draft.txt` | `500a40752f3f3c1ec125262ce243996c1fb69b3da8a91af5c59ca6c3d165982a` |
| Mage_Frost | v1.0 / Draft | `roles/Mage/Current/APL_Mage_Frost_v1.0_Draft.txt` | `f05a17a34b9d13238d6594e27f4fa7994cf2ce9eae5c4e5916ecc7dc0decbd22` |
| Paladin_Protection | v1.0 / Draft | `roles/Paladin/Current/APL_Paladin_Protection_Tank_v1.0_Draft.txt` | `8f1ba35a46634b615ce42d3983a6ace740da499bd96cb91b5470a850159a9690` |
| Paladin_Retribution | v1.0 / Draft | `roles/Paladin/Archive/APL_Paladin_Retribution_DPS_v1.0_Draft.txt` | `dcbfa7e6c9ba4d34d40c3d464652917c47b240c4743ace3f2ba89595f693a3aa` |
| Priest_Shadow | v1.0 / Draft | `roles/Priest/Current/APL_Priest_Shadow_v1.0_Draft.txt` | `66ee308453ae07c1e2c77b5f82e414e61abbd5f2099d21a252448174be7eec79` |
| Rogue_Assassination | v1.0 / Draft | `roles/Rogue/Current/APL_Rogue_Assassination_v1.0_Draft.txt` | `f817fe4ab906e82c3244a886457216822824c2598cd53cbf619610b4709ee4e0` |
| Rogue_Combat | v1.0 / Draft | `roles/Rogue/Current/APL_Rogue_Combat_v1.0_Draft.txt` | `ff69f6d4baa3e74d054f8e96595993b5bd931e283e0b7a81cf1dd95a03b13218` |
| Rogue_Subtlety | v1.0 / Draft | `roles/Rogue/Current/APL_Rogue_Subtlety_v1.0_Draft.txt` | `3d5fa90ecfd4a9d1f57fa8c73f6cb6f72a7bf8dff48577285125af16433ff77e` |
| Shaman_Elemental | v1.0 / Draft | `roles/Shaman/Current/APL_Shaman_Elemental_v1.0_Draft.txt` | `fd19fe1d83d996be6b3d65a47ef374957e21deb154722a61e31f4cadacebe915` |
| Shaman_Enhancement | v1.0 / Draft | `roles/Shaman/Current/APL_Shaman_Enhancement_v1.0_Draft.txt` | `76c3ed75a4b01ebe18980104261bcd5589b48924fcaef87a3ed356f00de6ab35` |
| Warlock_Affliction | v1.0 / Draft | `roles/Warlock/Current/APL_Warlock_Affliction_DPS_v1.0_Draft.txt` | `65c664533b6918db6e0b1b4bd2c1e360edf56c2bcd647511c63dbd3cd4437c6d` |
| Warlock_Demonology | v1.0 / ReportedWorking | `roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt` | `067ae757344a71f4a0d02f0a18e2f36745ceb8c0015761970948381aba8e7bf7` |
| Warlock_Destruction | v1.0 / Draft | `roles/Warlock/Current/APL_Warlock_Destruction_DPS_v1.0_Draft.txt` | `560235675b9882a40a4fee90fdc729f4f55536222c8277a4ffc5649b68bb6ac0` |
| Warrior_Arms | v1.0 / StaticValidated | `roles/Warrior/Current/APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt` | `3bb923e9b071a3d9432471731ce609a3e8852741364ce4334d136e4509335f2c` |
| Warrior_Fury | v1.0 / Draft | `roles/Warrior/Current/APL_Warrior_Fury_DPS_v1.0_Draft.txt` | `bff9e4ecfac234f58d7057f47c1c1c4ef047f8d98f9018c506530d143e5d5b23` |
| Warrior_Protection | v1.0 / PendingInGame | `roles/Warrior/Current/APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt` | `e97acd14bdebf1fdc6d8c5b482814471cad7065bef30b4f14f48b07c4f6468e0` |

Feral v1.6: owner selected engineering baseline, [20/20 native, 40 combat worlds](https://github.com/tkbiccay/APLForever-Open/actions/runs/46136566441); live gate remains pending. v1.5 retained as prior checkpoint, v1.0 historical reference. Demonology v1.0 is exact DEMO-006 reported-working, needs retest, not Approved; no v1.1 file in canonical catalogue. Guardian v1.0 reported-working retained despite v1.7 Draft native result. BM and Retribution v1.0 are historical Archive references; do not displace their newer Current profiles. Feral historical v1.0 import diagnostics remain recorded. No other newer revision is automatically designated based on CI alone.


## Owner lifecycle clarification — 28 November 2026

The table above records pre-migration exact paths, not the desired folder layout. Current must contain exactly the protected development rollback for each Supported role; Candidates only active newer Drafts; Archive all below-rollback and superseded/rejected versions. On owner designation/approval of a replacement, move it to Current, move the displaced Current and other superseded candidates to Archive, then continue development with a new numbered Draft. No byte edits or gameplay approval from relocation. Preserve actual last-working/approved pointers (including archived files if necessary), status and SHA. Existing Checkpoints are historical and require safe reconciliation rather than duplication.

Initial migration exceptions identified from catalogue: Feral v1.6 Candidates→Current and v1.0–v1.5→Archive; BM v1.0 Archive→Current and v1.1 Current→Candidates; Retribution v1.0 Archive→Current and v1.2 Current→Candidates. Audit every role, including any existing archived newer rejected candidates (leave archived), plus all known path references in catalogue, registry, native tests, workflows, docs, allowlists and historical evidence. Implement atomically after reconciling open PRs, verify exact hashes and run full affected validation before merge. This policy commit does not relocate files. No change to the actual player-facing preferred/working status, even when its path must be updated.
