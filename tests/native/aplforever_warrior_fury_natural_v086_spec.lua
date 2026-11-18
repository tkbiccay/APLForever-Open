-- Fury Current v1.0, archived failed v1.1 and guarded v1.2 Draft: source-native 1–60 castability and
-- final/repeated-fallback comparison against shipped Fury (wowsims.com).
-- Hekili Forever v0.8.6 ONLY. No oracle-seeded Rage, fabricated casts,
-- guessed target counts, hidden enemy health, or actual in-game claims.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local ws = require("Forever.helpers.wowsims")
local ww = require("Forever.helpers.warrior_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function read(path)
    local f = assert(io.open(path, "rb"))
    local body = f:read("*a")
    f:close()
    return body
end

local function selected()
    local found
    for _, row in ipairs(manifest) do
        if row.apl_name == "Warrior_Fury" then
            assert.is_nil(found, "duplicate selected Fury revision")
            found = row
        end
    end
    assert.is_table(found)
    assert.are.equal("v1.0", found.revision)
    assert.are.equal("roles/Warrior/Current/APL_Warrior_Fury_DPS_v1.0_Draft.txt",
        found.apl_file)
    assert.are.equal("bff9e4ecfac234f58d7057f47c1c1c4ef047f8d98f9018c506530d143e5d5b23",
        found.sha256)
    return found
end

local function install(H, C, entry)
    local lists, warnings = H.Hekili:ImportSimcAPL(
        entry.apl_name, "APLForever",
        read(root .. "/" .. entry.apl_file), C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_true(#lists.default > 0)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    for _, key in ipairs({ "engage", "stance_recovery", "aoe", "single_target",
        "rage_dumps", "final_fallback" }) do
        assert.is_table(lists[key], "Fury full list missing " .. key)
        assert.is_true(#lists[key] > 0, "Fury list empty " .. key)
    end
    local pack = assert(H.Hekili.DB.profile.packs[C.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for key in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK, key),
            "Fury list never compiled " .. key)
    end
    assert.are.same({}, H.errors)
end

local function runCase(profile, level, attackers)
    -- Source's real Fury dual-wield kit and talents; low-level world
    -- inherits source level-60 one-hand gear, so this is a castability
    -- and final-fallback gate, not a faithful levelling DPS model.
    local C = ws.content(ww.Fury, {
        pack = "Fury (wowsims.com)",
        level = level, talents = ws.header("warrior_fury").talents,
        learn = ws.learn("WARRIOR"), race = ws.race("warrior_fury"),
        kit = { "berserker_rage", "reckless_swings" },
    })
    C.WORLD = setmetatable({
        mobHealth = 1000000000,
        attackers = attackers,
        mobPeriod = 2,
        mobDamage = { 2, 3 },
    }, { __index = C.WORLD })
    local L = loop.new(C)
    local H = L.us
    local prior = selected()
    local archivedV11 = {
        apl_name = prior.apl_name,
        apl_file = "roles/Warrior/Archive/APL_Warrior_Fury_v1.1_Draft.txt",
        sha256 = "4c18938e392f8b4e785fda079b11a2f8e3dd41b850fe8e2e149ad1d8c264a2ff",
    }
    local candidateV12 = {
        apl_name = prior.apl_name,
        apl_file = "roles/Warrior/Candidates/APL_Warrior_Fury_v1.2_Draft.txt",
        sha256 = "7280a021e796bfe97112e3b091e34e234348ead476305ef6a57856524ddf84d3",
    }
    local entry = profile == "archived" and archivedV11 or
        (profile == "candidate" and candidateV12 or prior)
    assert.are.same({}, H.loadErrors)
    if profile ~= "shipped" then
        install(H, C, entry)
    end
    local toggles = H.Hekili.DB.profile.toggles
    toggles.cooldowns.value = false
    toggles.minor_cooldowns.value = false
    toggles.defensives.value = false
    toggles.movement.value = false
    if toggles.interrupts then toggles.interrupts.value = false end

    local S = H.Hekili.State
    assert.are.equal(1, L.form, "Fury source starts in Battle Stance")
    assert.is_true(S:IsKnown("heroic_strike"))
    assert.is_true(S:IsKnown("battle_stance"))
    assert.are.equal(level >= 4, S:IsKnown("rend"),
        "source trainer: Rend first rank level 4")
    assert.are.equal(level >= 10, S:IsKnown("sunder_armor"),
        "source trainer: Sunder Armor first rank level 10")
    assert.are.equal(level >= 30, S:IsKnown("berserker_stance"),
        "source trainer: Berserker Stance first rank level 30")
    assert.are.equal(level >= 36, S:IsKnown("whirlwind"),
        "source trainer: Whirlwind first rank level 36")
    local known = {
        rend = S:IsKnown("rend"),
        sunder_armor = S:IsKnown("sunder_armor"),
        heroic_strike = S:IsKnown("heroic_strike"),
        cleave = S:IsKnown("cleave"),
        bloodthirst = S:IsKnown("bloodthirst"),
        whirlwind = S:IsKnown("whirlwind"),
        berserker_stance = S:IsKnown("berserker_stance"),
        execute = S:IsKnown("execute"),
        overpower = S:IsKnown("overpower"),
        charge = S:IsKnown("charge"),
        intercept = S:IsKnown("intercept"),
    }
    local a = H.Hekili.Class.abilities
    local ids = H.ns.VirtualState.KnownID
    local heroicID = ids(assert(a.heroic_strike).id)
    local cleaveID = ids(assert(a.cleave).id)
    local lastHostile, cursor, hostileSwings = nil, 0, 0
    local accepted, acceptedUnknown, refused, repeated = 0, 0, 0, 0
    local lowRageSwings, paidCasts, rageSpent = 0, 0, 0
    local sourceStanceEvents, maxRage, minRage = 0, -math.huge, math.huge
    local nearFallback = { "final_fallback", "rage_dumps" }
    local queued, strikes, unqueued, truePaid = {}, {}, {}, {}
    local acceptedSince, last = {}, {}
    local samples, noActions = 0, 0
    local refusalEvents, prevRefusedCost = {}, 0
    local r = loop.run(L, 30417, {
        duration = 48,
        on = function(w, _, t)
            local costRefused = w.refused.cost or 0
            if costRefused > prevRefusedCost and w.combat > 0 then
                local key = w.ours[w.combat]
                local item = H.Hekili.Engine.Output.Primary.recs[1] or {}
                local observed = H.ns.VirtualState.Power(
                    L.power.type, H.ctl.now)
                local currentCost = key and S.action[key] and S.action[key].cost or nil
                refusalEvents[#refusalEvents + 1] = {
                    t = t,
                    refusedDelta = costRefused - prevRefusedCost,
                    attempted = key,
                    firstIcon = item.actionName,
                    wait = item.wait,
                    actualRage = w.us.power,
                    stateRageLo = observed.lo,
                    stateRageHi = observed.hi,
                    actionCost = currentCost,
                    sourceForm = w.us.form,
                }
            end
            prevRefusedCost = costRefused
            local pressed = w.W.combat and w.pressed[w.combat] or nil
            if pressed then
                accepted = accepted + 1
                acceptedSince[pressed] = (acceptedSince[pressed] or 0) + 1
                if not S:IsKnown(pressed) then
                    acceptedUnknown = acceptedUnknown + 1
                end
            end
            minRage = math.min(minRage, w.us.power)
            maxRage = math.max(maxRage, w.us.power)
            local freshSwing = false
            for i = cursor + 1, #w.W.truth do
                local ev = w.W.truth[i]
                if ev.kind == "form" and ev.t >= loop.PULL and
                    ev.t < w.W.stopAt then
                    sourceStanceEvents = sourceStanceEvents + 1
                end
                if ev.src == w.us and ev.kind == "cast" and
                    (ev.cost or 0) > 0 then
                    paidCasts = paidCasts + 1
                    rageSpent = rageSpent + ev.cost
                end
                if ev.src == w.us and
                    (ev.spell == heroicID or ev.spell == cleaveID) then
                    local key = ev.spell == heroicID and
                        "heroic_strike" or "cleave"
                    if ev.kind == "queue" then
                        queued[key] = (queued[key] or 0) + 1
                    elseif ev.kind == "strike" then
                        strikes[key] = (strikes[key] or 0) + 1
                        if (ev.cost or 0) > 0 then
                            truePaid[key] = (truePaid[key] or 0) + ev.cost
                        end
                    elseif ev.kind == "unqueue" then
                        unqueued[key] = (unqueued[key] or 0) + 1
                    end
                end
                if ev.kind == "swing" and ev.src and
                    ev.src.kind == "mob" and ev.dst == w.us and
                    ev.t ~= lastHostile then
                    lastHostile = ev.t
                    hostileSwings = hostileSwings + 1
                    freshSwing = true
                end
            end
            cursor = #w.W.truth
            if freshSwing then
                samples = samples + 1
                if w.us.power < S.action.heroic_strike.cost then
                    lowRageSwings = lowRageSwings + 1
                end
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                local row = {
                    name = rec.actionName or "NO_ACTION",
                    wait = rec.wait, t = t,
                    actualRage = w.us.power,
                    believedLo = H.ns.VirtualState.Power(
                        L.power.type, H.ctl.now).lo,
                    acceptedSince = acceptedSince,
                }
                if row.name == "NO_ACTION" then
                    noActions = noActions + 1
                end
                last[#last + 1] = row
                if #last > 3 then table.remove(last, 1) end
                acceptedSince = {}
                if #last == 3 then
                    local x, y, z = last[1], last[2], last[3]
                    if x.name ~= "NO_ACTION" and
                        x.name == y.name and y.name == z.name and
                        (x.wait or 0) <= 0.05 and
                        (y.wait or 0) <= 0.05 and
                        (z.wait or 0) <= 0.05 and
                        (y.acceptedSince[x.name] or 0) == 0 and
                        (z.acceptedSince[x.name] or 0) == 0 then
                        repeated = repeated + 1
                    end
                end
            end
        end,
    }, {{ H = H }})
    local refCount = 0
    for _ in pairs(r.refused) do refCount = refCount + 1 end
    refused = refCount

    print("WARRIOR_FURY_NATURAL_V086 " .. profile ..
        " L" .. level .. " attackers=" .. attackers .. " " .. pretty.write({
        addon = "zmsl/hekili v0.8.6",
        seed = 30417, hash = profile ~= "shipped" and
            entry.sha256 or "shipped",
        known = known, presses = r.pressedBy,
        sourceRefusals = r.refused,
        errors = r.errors, raises = r.raises,
        accepted = accepted, unknownAccepted = acceptedUnknown,
        hostileSwings = hostileSwings, sampled = samples,
        repeatReady = repeated, noActions = noActions,
        lowRageHostileSwings = lowRageSwings,
        minRage = minRage, maxRage = maxRage,
        paidCastEvents = paidCasts, trueCastRagePaid = rageSpent,
        nextSwingQueue = queued, nextSwingStrike = strikes,
        nextSwingUnqueue = unqueued,
        trueNextSwingRagePaid = truePaid,
        inCombatFormChanges = sourceStanceEvents,
        sourceCostRefusalDetail = refusalEvents,
        finalThree = last,
    }, ""))

    assert.are.equal(0, r.errors)
    assert.are.equal(0, r.raises)
    assert.is_true(hostileSwings >= 3,
        "no three genuine source hostile swings")
    assert.is_true(accepted > 0,
        "source did not accept any abilities in this bounded window")
    assert.are.equal(0, acceptedUnknown,
        "an untrained rank was accepted")
    if level < 4 then assert.is_nil(r.pressedBy.rend) end
    if level < 10 then assert.is_nil(r.pressedBy.sunder_armor) end
    if level < 30 then assert.is_nil(r.pressedBy.berserker_stance) end
    if level < 36 then assert.is_nil(r.pressedBy.whirlwind) end
    for _, key in ipairs({ "heroic_strike", "cleave" }) do
        assert.is_true((strikes[key] or 0) +
            (unqueued[key] or 0) <= (queued[key] or 0),
            "source next-swing strikes+unqueues exceeded queues")
        if (strikes[key] or 0) > 0 then
            assert.is_true((truePaid[key] or 0) > 0,
                "source next-swing strike had no Rage cost")
        end
    end
    if profile ~= "shipped" then
        if profile == "archived" and level == 60 and attackers == 2 then
            -- Historical failed v1.1 Draft is intentionally retained as an
            -- EXACT negative-control artefact; never regard as safe Current.
            assert.are.same({ cost = 4 }, r.refused,
                "v1.1 archived safety failure no longer reproduced: investigate")
        else
            assert.are.same({}, r.refused,
                "custom Fury source cast refused; new Candidate must pass")
        end
        assert.are.equal(0, repeated,
            "custom Fury repeated a ready first icon across 3 genuine hostile swings without accepted cast")
        assert.is_nil(r.pressedBy.bloodrage,
            "Current Fury must not cast Bloodrage with off-switches")
        assert.is_nil(r.pressedBy.death_wish,
            "Current Fury major cooldowns must remain OFF")
        assert.is_nil(r.pressedBy.berserker_rage,
            "Current Fury minor cooldowns must remain OFF")
        assert.is_nil(r.pressedBy.shield_wall,
            "custom Fury defensives must remain OFF")
        if profile == "candidate" or profile == "archived" then
            assert.is_nil(r.pressedBy.charge,
                "candidate must respect Movement OFF for Charge at every level")
            assert.is_nil(r.pressedBy.intercept,
                "candidate must respect Movement OFF for Intercept at every level")
        end
    end
end

describe("Warrior Fury natural resource, unlock and terminal fallbacks v0.8.6", function()
    for _, level in ipairs({ 1, 9, 10, 20, 24, 30, 36, 40, 60 }) do
        for _, attackers in ipairs({ 1, 2 }) do
            for _, profile in ipairs({ "current", "archived", "candidate", "shipped" }) do
                it(profile .. " level=" .. level .. " mobs=" .. attackers, function()
                    runCase(profile, level, attackers)
                end)
            end
        end
    end
end)
