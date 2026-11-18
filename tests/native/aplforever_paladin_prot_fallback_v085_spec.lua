-- Issue #30 P0: Protection Paladin current Draft vs untouched shipped.
-- Pinned Forever v0.8.5 source-world: real seal/Righteous Fury upkeep,
-- genuine Mana expenditure and incoming swings. Never invent a cast.
-- Level-60-only. No validation of live protection/threat/survival.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local stock = require("Forever.helpers.paladin_world").Protection
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function selected()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Paladin_Protection" then return entry end
    end
    error("missing Paladin_Protection in pinned native manifest")
end

local function install(H, content, entry)
    local f = assert(io.open(root .. "/" .. entry.apl_file, "rb"))
    local source = assert(f:read("*a"))
    f:close()
    local lists, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", source, content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name), "inactive " .. name)
    end
    assert.are.same({}, H.errors)
end

local function testOne(custom)
    local initial = stock.WORLD.max * 0.55
    local content = setmetatable({
        WORLD = setmetatable({
            power = initial, mobHealth = 1e9, mobPeriod = 2.0,
            mobDamage = { 1, 2 },
        }, { __index = stock.WORLD }),
        OBSERVE = setmetatable({
            plainPower = { [0] = "ooc" },
        }, { __index = stock.OBSERVE }),
    }, { __index = stock })
    local L = loop.new(content)
    local H = L.us
    local entry = selected()
    if custom then install(H, content, entry) end

    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    local aura = H.Hekili.Class.auras
    local furyId = assert(aura.righteous_fury).id
    local sealIds = {
        assert(aura.seal_of_fury).id,
        assert(aura.seal_of_the_crusader).id,
        assert(aura.seal_of_righteousness).id,
    }
    local started, seenFury, seenSeal = false, false, false
    local cursor, lowSince, samples, trace = 0, nil, {}, {}
    local observedNumericalMana, hooked = false, false
    local lowestMana, lowestBelief = math.huge, math.huge

    local run = loop.run(L, 30417, {
        duration = 95,
        on = function(r, _, t)
            if not hooked then
                local actual = r.W.press
                r.W.press = function(player, key, p)
                    local row = {
                        t = r.W.t, key = key, cost = p.cost, mana = player.power,
                        castUntil = player.castUntil, gcdUntil = player.gcdUntil,
                        overhang = (player.castUntil or 0) - r.W.t,
                        nowPrecise = string.format("%.17g", r.W.t),
                        castPrecise = string.format("%.17g", player.castUntil or 0),
                    }
                    local ok, why = actual(player, key, p)
                    if player == r.us and not ok and r.W.t >= loop.PULL then
                        row.reason = why
                        trace[#trace + 1] = row
                    end
                    return ok, why
                end
                hooked = true
            end

            local freshSwing = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst and ev.dst.guid == r.us.guid then freshSwing = true end
            end
            cursor = #r.W.truth
            local rf = r.us.auras[furyId]
            local hasFury = rf and (rf.stacks or 0) > 0 and rf.expires > r.W.t
            local hasSeal = false
            for _, id in ipairs(sealIds) do
                local buff = r.us.auras[id]
                if buff and (buff.stacks or 0) > 0 and buff.expires > r.W.t then hasSeal = true end
            end
            seenFury = seenFury or not not hasFury
            seenSeal = seenSeal or hasSeal
            started = started or (hasFury and hasSeal)
            if started then lowestMana = math.min(lowestMana, r.us.power) end
            local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
            if started and belief then lowestBelief = math.min(lowestBelief, belief.lo) end

            if started and r.us.power <= r.us.powerMax * 0.25 then
                lowSince = lowSince or t
                if freshSwing and #samples < 3 then
                    local o = H.Hekili.Engine.Output.Primary
                    local rec = o.count > 0 and o.recs[1] or {}
                    local exposed = H.ctl.power[L.power.type]
                    if exposed ~= nil then observedNumericalMana = true end
                    samples[#samples + 1] = {
                        t = t, rec = rec.actionName or "NO_ACTION",
                        wait = rec.wait, key = r.ours[r.combat],
                        actualPress = r.pressed[r.combat],
                        manaTruth = r.us.power, manaLower = belief.lo,
                        manaEst = belief.est, exposedMana = exposed,
                        rf = not not hasFury, seal = hasSeal,
                        castUntil = r.us.castUntil, gcdUntil = r.us.gcdUntil,
                    }
                end
            end
        end,
    }, { { H = H } })

    local label = custom and "custom" or "shipped"
    print("PALADIN_PROT_FALLBACK_V085 " .. label .. " " .. pretty.write({
        source = "v0.8.5", seed = 30417,
        revision = custom and entry.revision or "shipped",
        initialMana = initial, lowSince = lowSince,
        minActualMana = lowestMana, minManaBelief = lowestBelief,
        sawFury = seenFury, sawSeal = seenSeal, reachedFullUpkeep = started,
        samples = samples, accepted = run.pressedBy,
        refused = run.refused, refuseTrace = trace,
        errors = run.errors, raises = run.raises,
    }, ""))

    assert.is_true(seenFury, "source world never applied actual Righteous Fury")
    assert.is_true(seenSeal, "source world never applied any actual seal")
    assert.is_true(started, "source world never had both tank upkeep buffs")
    assert.is_true(lowSince ~= nil, "Mana never fell to <=25% after real upkeep")
    assert.are.equal(3, #samples, "need three distinct enemy-swing checkpoints at <=25% Mana")
    assert.is_false(observedNumericalMana, "fake UnitPower numeric Mana leaked into combat")
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    assert.are.equal(0, run.refused.cost or 0, "published ability was unaffordable in the real source world")
    assert.are.equal(0, run.refused.gcd or 0, "GCD refusal")
    assert.are.equal(0, run.refused.cooldown or 0, "Cooldown refusal")
    assert.are.equal(0, run.refused.range or 0, "Range refusal")
    local rounding = 0
    for _, refusal in ipairs(trace) do
        assert.are.equal("casting", refusal.reason,
            "unexpected refused action: identify engine/world/APL fault")
        assert.is_true(refusal.overhang > 0 and refusal.overhang <= 1e-8
            and refusal.gcdUntil <= refusal.t + 1e-8,
            "materially early cast, not a measured native floating-point boundary")
        rounding = rounding + 1
    end
    assert.is_true(rounding <= 1, "repeated source cast boundary refusals require investigation")
    assert.are.same(rounding, run.refused.casting or 0,
        "all source casting refusals must appear in instrumented trace")
end

describe("Protection Paladin v0.8.5 real post-upkeep low-Mana fallback", function()
    for _, custom in ipairs({ true, false }) do
        it((custom and "current custom" or "untouched shipped")
           .. " reaches three true swing-advanced checkpoints", function()
            testOne(custom)
        end)
    end
end)
