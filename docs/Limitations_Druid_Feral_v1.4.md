# Limitations — Feral DPS v1.4 Draft

**Static/native-only** at Hekili Forever v0.11.0. Source-native tests can confirm `moving`, Travel aura, combat and accepted action sequence under controlled fake-client behaviour; **not** real client motion latency, actual player escape intent, DPS, HP, TTD, target swaps or survival. A momentary pause while escaping might intentionally meet the stationary condition; this is a possible **user-intent regression**, even if the engine legally casts Cat Form.

- Only Cat Form recovery tested at source level 60 with learned Cat. Missing Cat, Bear-only Feral, aquatic underwater movement, Moonkin hybrid use and 1–60 class-quest unlock boundaries remain unverified. No inference that the addon can distinguish a combat engagement from a deliberate retreat when standing still.
- Original movement control (native GetUnitSpeed) is source-reported, not a private event API guarantee. Exact stored-file v1.4 [4/4 source-native tests PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/44821443310); actual /hek snap is still required on surprising in-game behaviour.
- Source-native original v1.3 Travel zero-action ending is observed in fixture; moving Travel remains an **intentional no-action recommendation** in v1.4, not a failure.
- Existing Feral defensives use reported combat aggro, not hidden player health. No required per-spec tick boxes; optional source-owned off-switches remain binding.
- Status **Draft / Needs In-Game Validation**; Current v1.0 still a Draft, v1.3 retained, no Approved or last-working Feral reference.
