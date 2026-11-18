-- Warrior Arms v1.0: 1–60 bounded native progression and repeated-final-tail gate.
-- Released Hekili Forever v0.8.6; source engine only; no invented Rage,
-- health reads, AoE, casts, ranks, or damage/threat oracle.
-- Independent imported Current vs shipped Arms (wowsims.com).
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local ws = require("Forever.helpers.wowsims")
local ww = require("Forever.helpers.warrior_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function read(path)
    local f = assert(io.open(path, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end

local function selected()
    local found
    for _, row in ipairs(manifest) do
        if row.apl_name == "Warrior_Arms" then
            assert.is_nil(found, "duplicate selected Warrior Arms revision")
            found = row
        end
    end
    assert.is_table(found)
    assert.are.equal("v1.0", found.revision)
    assert.are.equal("roles/Warrior/Current/APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt", found.apl_file)
    return found
end

local function install(H, C, entry)
    local lists, warnings = H.Hekili:ImportSimcAPL(
        entry.apl_name, "APLForever", read(root .. "/" .. entry.apl_file), C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_true(#lists.default > 0)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[C.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK, name), name)
    end
    assert.are.same({}, H.errors)
end

local function runCase(profile, level, attackers)
    local C = ws.content(ww, {
        pack = "Arms (wowsims.com)",
        level = level,
        talents = ws.header("warrior_arms").talents,
        learn = ws.learn("WARRIOR"),
        race = ws.race("warrior_arms"),
    })
    C.WORLD = setmetatable({
        mobHealth = 1000000000,
        attackers = attackers,
        mobPeriod = 2.0,
        mobDamage = { 2, 3 },
    }, { __index = C.WORLD })
    local L = loop.new(C)
    local H = L.us
    local entry = selected()
    assert.are.same({}, H.loadErrors)
    if profile == "current" then
        install(H, C, entry)
    end
    local toggles = H.Hekili.DB.profile.toggles
    toggles.cooldowns.value = false
    toggles.minor_cooldowns.value = false
    toggles.defensives.value = false
    toggles.movement.value = false

    local S = H.Hekili.State
    assert.are.equal(1, L.form, "Arms must begin in legal Battle Stance")
    assert.is_true(S:IsKnown("heroic_strike"))
    assert.is_true(S:IsKnown("battle_stance"))
    assert.are.equal(level >= 4, S:IsKnown("rend"),
        "source trainer Rend rank-1 must be level 4, not inherited at L1")
    assert.are.equal(level >= 10, S:IsKnown("sunder_armor"))
    assert.are.equal(level >= 30, S:IsKnown("berserker_stance"))
    local known = {
        rend = S:IsKnown("rend"), execute = S:IsKnown("execute"),
        overpower = S:IsKnown("overpower"),
        mortal_strike = S:IsKnown("mortal_strike"),
        whirlwind = S:IsKnown("whirlwind"),
        berserker_stance = S:IsKnown("berserker_stance"),
        spearing_strike = S:IsKnown("spearing_strike"),
    }
    local abilities = H.Hekili.Class.abilities
    local heroicID = H.ns.VirtualState.KnownID(assert(abilities.heroic_strike).id)
    local cleaveID = H.ns.VirtualState.KnownID(assert(abilities.cleave).id)
    local lastEnemySwing, cursor, swings = nil, 0, 0
    local accepted, unknownPresses, repeatReady, lowRageSwings = 0, 0, 0, 0
    local rageSpent, positiveCastCosts = 0, 0
    local queued, strikes, unqueues, truePaid = {}, {}, {}, {}
    local stanceChanges = 0
    local minRage, maxRage = math.huge, -math.huge
    local since, last = {}, {}
    local result = loop.run(L, 30417, {
        duration = 48,
        on = function(r, _, t)
            local pressed = r.pressed[r.combat]
            if pressed then
                accepted = accepted + 1
                since[pressed] = (since[pressed] or 0) + 1
                if not S:IsKnown(pressed) then
                    unknownPresses = unknownPresses + 1
                end
            end
            minRage = math.min(minRage, r.us.power)
            maxRage = math.max(maxRage, r.us.power)
            local freshSwing = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.kind == "form" then
                    stanceChanges = stanceChanges + 1
                end
                if ev.src == r.us and ev.kind == "cast" and (ev.cost or 0) > 0 then
                    positiveCastCosts = positiveCastCosts + 1
                    rageSpent = rageSpent + ev.cost
                end
                if ev.src == r.us and (ev.spell == heroicID or
                    (cleaveID and ev.spell == cleaveID)) then
                    local k = ev.spell == heroicID and "heroic_strike" or "cleave"
                    if ev.kind == "queue" then
                        queued[k] = (queued[k] or 0) + 1
                    elseif ev.kind == "strike" then
                        strikes[k] = (strikes[k] or 0) + 1
                        if (ev.cost or 0) > 0 then
                            truePaid[k] = (truePaid[k] or 0) + ev.cost
                        end
                    elseif ev.kind == "unqueue" then
                        unqueues[k] = (unqueues[k] or 0) + 1
                    end
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= lastEnemySwing then
                    lastEnemySwing = ev.t
                    swings = swings + 1
                    freshSwing = true
                end
            end
            cursor = #r.W.truth
            -- A repeat is meaningful only after three genuine hostile
            -- world-state advances with no accepted corresponding action.
            if freshSwing then
                if r.us.power < S.action.heroic_strike.cost then
                    lowRageSwings = lowRageSwings + 1
                end
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                local sample = {
                    name = rec.actionName or "NO_ACTION",
                    wait = rec.wait, time = t,
                    rage = r.us.power,
                    beliefFloor = H.ns.VirtualState.Power(L.power.type, H.ctl.now).lo,
                    acceptedSince = since,
                }
                last[#last + 1] = sample
                if #last > 3 then table.remove(last, 1) end
                since = {}
                if #last == 3 then
                    local a, b, c = last[1], last[2], last[3]
                    if a.name ~= "NO_ACTION" and a.name == b.name
                        and b.name == c.name
                        and (a.wait or 0) <= 0.05
                        and (b.wait or 0) <= 0.05
                        and (c.wait or 0) <= 0.05
                        and (b.acceptedSince[a.name] or 0) == 0
                        and (c.acceptedSince[a.name] or 0) == 0 then
                        repeatReady = repeatReady + 1
                    end
                end
            end
        end,
    }, { { H = H } })

    print("WARRIOR_ARMS_NATURAL_V086 " .. profile .. " L" .. level
        .. " attackers=" .. attackers .. " " .. pretty.write({
            source = "zmsl/hekili v0.8.6",
            seed = 30417, hash = profile == "current" and entry.sha256 or "shipped",
            known = known, presses = result.pressedBy, refusals = result.refused,
            errors = result.errors, raises = result.raises,
            accepted = accepted, unknownAccepted = unknownPresses,
            hostileSwings = swings, repeatReady = repeatReady,
            lowRageSwings = lowRageSwings, minRage = minRage, maxRage = maxRage,
            positiveRageCastEvents = positiveCastCosts, castRagePaid = rageSpent,
            nextSwingQueues = queued, nextSwingStrikes = strikes,
            nextSwingUnqueues = unqueues, trueNextSwingRagePaid = truePaid,
            stanceChanges = stanceChanges, lastThree = last,
        }, ""))

    assert.are.equal(0, result.errors)
    assert.are.equal(0, result.raises)
    assert.is_true(swings >= 3, "did not advance three true hostile swings")
    assert.is_true(accepted >= 1, "no source accepted actions, not a progression test")
    assert.are.equal(0, unknownPresses)
    if not known.mortal_strike then
        assert.is_nil(result.pressedBy.mortal_strike,
            "unknown Mortal Strike should not be cast")
    end
    if level < 4 then assert.is_nil(result.pressedBy.rend) end
    if level < 10 then assert.is_nil(result.pressedBy.sunder_armor) end
    if level < 30 then assert.is_nil(result.pressedBy.berserker_stance) end
    for _, key in ipairs({ "heroic_strike", "cleave" }) do
        assert.is_true((strikes[key] or 0) + (unqueues[key] or 0) <=
            (queued[key] or 0), "next-swing strike/unqueuing exceeds real queues")
        if (strikes[key] or 0) > 0 then
            assert.is_true((truePaid[key] or 0) > 0,
                "actual next-swing strike had no real Rage cost")
        end
    end
    if profile == "current" then
        assert.are.same({}, result.refused, "custom Arms cast was source-refused")
        assert.are.equal(0, repeatReady,
            "custom first icon repeatedly ready across three hostile swings with no cast")
        assert.is_nil(result.pressedBy.bloodrage,
            "Bloodrage should never run while minor CDs and cooldowns are OFF")
    end
end

describe("Warrior Arms v0.8.6 low/medium/high natural Rage and final fallback", function()
    for _, level in ipairs({ 1, 9, 10, 20, 30, 40, 60 }) do
        for _, attackers in ipairs({ 1, 2 }) do
            for _, profile in ipairs({ "current", "shipped" }) do
                it(profile .. " level=" .. level .. " attackers=" .. attackers, function()
                    runCase(profile, level, attackers)
                end)
            end
        end
    end
end)
