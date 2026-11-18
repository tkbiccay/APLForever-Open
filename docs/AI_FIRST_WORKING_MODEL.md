# APLForever-Open — proudly AI-developed, human-maintained

**We build this because it is fun.** This is a transparent, open-source hobby experiment in how far careful AI-assisted engineering can improve reliable World of Warcraft: Forever APL recommendations. We aim for excellent gameplay, not marketing claims, unnecessary infrastructure or endless AI-generated code churn.

**Canonical working repository:** https://github.com/tkbiccay/APLForever-Open (GPL-3.0-only for original work). Historical private `tkbiccay/APLForever` is read-only reference. The project is independent of Blizzard, Hekili Forever, WoWSims and OpenAI, none of whom endorse these APLs.

## Who does what

- **Human maintainer @tkbiccay:** sole official ownership, final gameplay judgement, merges, releases, in-game verification and Approved status.
- **ChatGPT + maintainer:** lead priorities, original APL designs, source research, mechanical reasoning, regression triage, available headless validation and public evidence. AI assistance is welcomed and credited, but outputs are not automatically correct.
- **Codex (when explicitly delegated):** bounded specialist code/test/CI implementation. Stop and return evidence after the assigned task. No autonomous backlog, private-repo development or automatic merge.
- **Community:** issues, critiques, reproducible gameplay evidence, forks and proposed PRs welcome. Credit authors and respect third-party licences.

## Active gameplay priorities — equal first tier

1. **Druid Guardian / Feral Tank**: protect v1.0 Reported Working / Needs Retest; independently assess Barkskin/Roar/mitigation, Rage/queue limits and repeated final fallback against source v0.9.0, the default and last working.
2. **Hunter Beast Mastery**: co-equal priority; v1.1 is a *Draft file under Current* but `preferred_apl: null` in catalogue; **no proven selected APL**. Research default Turret pack in released engine, pet summon/revive and state, resources, levelling unlocks, movement/range/melee weave, Major/Minor/Defensives/Interrupts/Potions toggles and repeated low-mana/pet-upkeep tails. Compare both v1.0/v1.1 Drafts, without assigning a preferred or approved status from file placement.
3. **Feral DPS**, then other 23 supported roles by live impact and resolved risk. Critical cross-spec safety defects and release compatibility can pre-empt order.

These are work allocation priorities, **not guaranteed superiority claims**.

## Smarter evidence and credit strategy

**Three layers, use the least expensive layer that answers the question:**

| Layer | When | Acceptance |
|---|---|---|
| Fast static / catalogue / privacy integrity | Every PR, always | No broken hashes, secrets, schema, rollback or syntax |
| Targeted released-source native checks | One role/engine hypothesis; source release, shared engine changes or pre-promotion | Imported/castable; accepted/refused state progression; correct toggles, unlocks, resources and 3-state final/repeated fallback |
| In-game evidence | Hidden HP/Rage, pets or auras, movement, threat/mitigation, timing and anything source harness cannot faithfully prove | Player captures actual behaviour, compares default and last-working, and explicitly approves or rejects |

Run broad multi-role native gates for upstream releases, source-shared changes or justified critical regression, **not** on every prose edit. Reuse cached pins, learned fixture limits and existing tests. Avoid unnecessary CI reruns, repeated research, duplicate branches and speculative DPS sims.

**Strict vs experimental coverage:** A required regression failing is a FAIL; preserve rollback and stop promotion. A novel positive counterfactual which cannot enter its preconditions is *BLOCKED / Not Demonstrated*. Keep its strict assertion and negative traces in a separately labelled experimental run, without weakening it or falsely treating it as a PASS. Its lack of proof cannot justify adopting that candidate. Independent release-compatibility checks may be independently reported as passed **within their explicit scope**, but no one may claim all outstanding scenarios passed.

**No phantom gains:** Source compilation, cast progression, default agreement or a simulated damage result cannot establish gameplay optimality. Record sample size, noise, engine limits and actual test scope. Include final fallback and three consecutive state-advanced recommendations game-wide. APL architecture is freely custom; shipped default is a comparator, not a ceiling. Use no invented spells, secret reads, fabricated Rage or positive scenarios.

## Public communication and fun

Share small milestones, interesting discoveries, failed experiments, labelled drafts and open technical limitations. Write plainly in UK English; it is fine to say *AI helped us build this* — we are proud of that. Honour upstream contributors and GPLv3 obligations. Be friendly, curious and transparent. Do not pretend human-only authorship or imply that all content was generated autonomously by AI.

**Success** means the addon gives more reliably useful, castable and stable recommendations in real play. It is not the number of commits, test cases, simulations, automation runs or APL complexity.
