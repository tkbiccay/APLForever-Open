# Changelog — Druid Feral DPS v1.3

**Date:** 20 November 2026. **Status:** Draft / unselected. **Source:** Forever v0.10.0 `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`.

Previous **v1.2 full standalone** → new **v1.3 full standalone**: replaced exactly the Barkskin defensive's `tanking` role gate with **`aggro&(group|active_enemies>=2)`** and required **`gcd.remains<=0`**, retaining its `combat>0`, within 5 yards, native Defensives off-switch, source-known/ready and aura-down guard. Every other list/line/resource/fallback is identical. No settings dependency or capability claim based on hidden player health. The first role-free alternative made a real Barkskin but one GCD refusal; `line_cd=2` did not fix it; the verified GCD guard did in the scoped test. Exact APL v1.3 SHA-256 `f235f9c0512a8ceab0ec46daadc2de6b7b497e85de1ad116459aa874f93a9450`.

**Promotion:** Not selected; current v1.0 is an unapproved Draft. Source-native tests are not numerical DPS, threat or survival. Future failures mandate rollback to earlier complete file, not a silent hotfix.
