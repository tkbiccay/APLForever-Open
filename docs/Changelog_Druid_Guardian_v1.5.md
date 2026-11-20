# Changelog — Guardian v1.5

**20 November 2026 — Draft / UNSELECTED.** Source v0.10.0 `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. Full APL SHA256 `75de4388516e3e70cd77f292901c1205f1176dc3561ac9b54dac8fef6c2abcc2`.

Only one change from protected complete Guardian v1.4: Roar timing condition `((group&tanking&time>=5)|(target.is_boss&time>=4)|(solo&tanking&time>=12))` → `aggro&((group&time>=5)|(target.is_boss&time>=4)|(solo&time>=12))`. Source `tanking` depends on pseudo-role TANK in addition to aggro; the earlier completely role-free alternative cast once in a group without aggro. New candidate keeps eligible casts when source reports actual threat regardless of client role, but avoids that non-aggro waste. Every other APL action/condition/list/last fallback, native CD toggle and 10-Rage reserve remains identical. No checkbox requirements.

**Evidence:** 5/5 in-memory role/threat cases passed 44756795738; full-file equality and three real post-Roar actions gated by new CI. Live game, mitigation/output and default comparison remain unverified. Protected v1.0 Reported Working/Needs Retest is still current and rollback; v1.1–v1.4 immutable. No promotion.
