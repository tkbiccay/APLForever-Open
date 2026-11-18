-- Source-pinned, TEST-ONLY Warlock Life Tap health-payment calculator.
-- Hekili Forever v0.8.3 Warlock.lua: rank/level/Spirit scaling.
-- WoWSims/Forever e5a9cd2a2dfc: pay HP, gain Mana;
-- Improved Life Tap changes Mana awarded, not the HP payment.
-- Pure mechanic + source-world event helper. No APL modification, no
-- level-specific health/Mana pool or future-health prediction.
local M = {}
local MANA = 0
local IDS = { 1454, 1455, 1456, 11687, 11688, 11689 }
local LEVELS = { 6, 16, 26, 36, 46, 56 }
local POINTS = { 20, 65, 130, 210, 300, 420 }

function M.rank(level)
    local r = 0
    for i, required in ipairs(LEVELS) do
        if level >= required then r = i end
    end
    return r
end

function M.amount(level, spirit, improved)
    assert(type(level) == "number" and type(spirit) == "number"
      and spirit >= 0, "requires a verified level and nonnegative Spirit")
    assert(type(improved) == "number" and improved >= 0 and improved <= 2,
      "Improved Life Tap must be 0-2")
    local r = M.rank(level)
    assert(r > 0, "Life Tap is not known below level six")
    local base = POINTS[r] + math.min(level - LEVELS[r], 10)
    local health = base + spirit
    return { rank = r, spell = IDS[r], health = health,
      mana = health * (1 + 0.1 * improved), base = base }
end

-- This helper intentionally uses the existing *source-world* event verbs.
-- It is called only by the isolated health-payment test; callers must supply
-- verified input parameters for any non-synthetic application.
function M.pay(W, e, amount, petRank, records, improved)
    local hpBefore = e.health
    local ev = W.emit({
        kind = "spell", src = e, dst = e,
        act = "WOUND", amount = amount.health, spell = amount.spell,
    })
    assert(ev.health == math.max(0, hpBefore - amount.health),
        "Source-world did not deduct the modelled Life Tap health")
    W.emit({ kind = "gain", src = e, pt = MANA, rage = amount.mana })
    if petRank > 0 then
        W.petGain(e, amount.mana * 0.5 * petRank)
    end
    records[#records + 1] = {
        t = W.t, before = hpBefore, after = e.health,
        rank = amount.rank, spell = amount.spell, health = amount.health,
        mana = amount.mana, improved = improved,
    }
end

return M
