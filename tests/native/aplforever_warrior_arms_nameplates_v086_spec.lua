-- v0.8.6: Arms real nameplate-count and AoE/stance decision checkpoints.
-- Never invent active_enemies, cannot infer it from incoming mob count.
-- World emits distinct source mob/nameplate events, and the released
-- engine counts only its normal client/nameplate reads.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local ws = require("Forever.helpers.wowsims")
local ww = require("Forever.helpers.warrior_world")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local root = assert(os.getenv("APLFOREVER_ROOT"))

local function selected()
    local entry
    for _, e in ipairs(manifest) do
        if e.apl_name == "Warrior_Arms" then
            assert.is_nil(entry, "multiple Warrior Arms selected revisions")
            entry = e
        end
    end
    assert.is_table(entry, "Warrior Arms manifest not found")
    assert.are.equal("v1.0", entry.revision)
    assert.are.equal("3bb923e9b071a3d9432471731ce609a3e8852741364ce4334d136e4509335f2c",
        entry.sha256)
    return entry
end

local function import(H, C, entry)
    local file = assert(io.open(root .. "/" .. entry.apl_file, "rb"))
    local content = file:read("*a")
    file:close()
    local lists, warnings = H.Hekili:ImportSimcAPL(
        entry.apl_name, "APLForever", content, C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_true(#lists.default > 0)
    assert.is_table(lists.precombat)
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

local function runCase(profile, level, attackers, platesOn)
    local C = ws.content(ww, {
        pack = "Arms (wowsims.com)",
        level = level, talents = ws.header("warrior_arms").talents,
        learn = ws.learn("WARRIOR"), race = ws.race("warrior_arms"),
    })
    C.WORLD = setmetatable({
        mobHealth = 1000000000,
        attackers = attackers, mobPeriod = 2,
        mobDamage = { 2, 3 },
    }, { __index = C.WORLD })
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    local entry = selected()
    if profile == "current" then import(H, C, entry) end

    H.Hekili.DB.profile.toggles.movement.value = false
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.minor_cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    local S = H.Hekili.State
    assert.is_true(S:IsKnown("whirlwind"),
        "actual source rank 1680 must be known at 40/60")
    assert.is_true(S:IsKnown("berserker_stance"))
    assert.are.equal(1, L.form)
    -- Simulate the real required player option and nameplates, *not* an
    -- invented APL resource or a fabricated enemy-count value.
    local specID = assert(S.spec.id)
    local sp = assert(H.Hekili.DB.profile.specs[specID])
    sp.nameplates = true
    sp.nameplateRange = 10
    sp.cycle = false
    local liveSp = assert(H.Hekili.Engine.settings.specs[specID])
    liveSp.nameplates = true
    liveSp.nameplateRange = 10
    liveSp.cycle = false
    H.ctl.cvars.nameplateShowEnemies = platesOn and "1" or nil
    H.ctl.cvars.nameplateShowAll = platesOn and "1" or nil
    for i = 1, attackers do
        -- Exactly the actual source-world entities that the observer
        -- will announce at its prepull NAME_PLATE_UNIT_ADDED events.
        -- The native world's GUID/events remain authoritative.
        H.ctl.exists["nameplate" .. i] = platesOn or nil
    end

    local maxCount, maxActive = 1, 1
    local multiCountSamples, multiActiveSamples = 0, 0
    local minCount, maxObservedWorldMobs = math.huge, 0
    local firstActions, accepted, repeated = {}, 0, 0
    local whirls, berserkPresses, battlePresses, cleavePresses = 0, 0, 0, 0
    local stanceEvents, hostileSwings, cursor, prevHostileT = 0, 0, 0, nil
    local actualWhirlwindCasts, formEvents = 0, {}
    local whirlwindSpell = H.ns.VirtualState.KnownID(
        assert(H.Hekili.Class.abilities.whirlwind).id)
    local acceptedSince, last = {}, {}
    local rageWindowSamples, rageLoRangeSamples = 0, 0
    local world = loop.run(L, 30417, {
        duration = 75,
        on = function(r, _, t)
            local mobCount = 0
            for _, e in ipairs(r.W.ents) do
                if e.kind == "mob" then mobCount = mobCount + 1 end
            end
            maxObservedWorldMobs = math.max(maxObservedWorldMobs, mobCount)
            local count = H.Hekili:GetNumTargets() -- passive: no forced scan
            local active = S.active_enemies
            if type(count) == "number" then
                minCount = math.min(minCount, count)
                maxCount = math.max(maxCount, count)
                if count >= 2 and r.W.combat then
                    multiCountSamples = multiCountSamples + 1
                end
            end
            if type(active) == "number" then
                maxActive = math.max(maxActive, active)
                if active >= 2 and r.W.combat then
                    multiActiveSamples = multiActiveSamples + 1
                end
            end
            -- r.combat stops advancing after STOP, so indexing
            -- r.pressed[r.combat] out of combat repeats the final entry.
            -- Only treat presses with a *true* active combat world as new.
            local acceptedAction = r.W.combat and r.pressed[r.combat] or nil
            if acceptedAction then
                accepted = accepted + 1
                acceptedSince[acceptedAction] = (acceptedSince[acceptedAction] or 0) + 1
                firstActions[acceptedAction] = (firstActions[acceptedAction] or 0) + 1
                if acceptedAction == "whirlwind" then whirls = whirls + 1 end
                if acceptedAction == "berserker_stance" then berserkPresses = berserkPresses + 1 end
                if acceptedAction == "battle_stance" then battlePresses = battlePresses + 1 end
                if acceptedAction == "cleave" then cleavePresses = cleavePresses + 1 end
            end
            local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
            if type(active) == "number" and active >= 2 then
                rageWindowSamples = rageWindowSamples + 1
                if belief and belief.lo >= 25 and belief.lo <= 30 then
                    rageLoRangeSamples = rageLoRangeSamples + 1
                end
            end
            local freshSwing = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.kind == "form" and ev.t >= loop.PULL and ev.t < r.W.stopAt then
                    stanceEvents = stanceEvents + 1
                    if #formEvents < 12 then
                        formEvents[#formEvents + 1] = {
                            t = ev.t, form = ev.form, rage = r.us.power,
                        }
                    end
                end
                if ev.kind == "cast" and ev.src == r.us
                    and ev.spell == whirlwindSpell then
                    actualWhirlwindCasts = actualWhirlwindCasts + 1
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= prevHostileT then
                    prevHostileT = ev.t
                    hostileSwings = hostileSwings + 1
                    freshSwing = true
                end
            end
            cursor = #r.W.truth
            if freshSwing then
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                last[#last + 1] = {
                    name = rec.actionName or "NO_ACTION",
                    wait = rec.wait, since = acceptedSince,
                    active = active, targets = count,
                    actualRage = r.us.power,
                }
                if #last > 3 then table.remove(last, 1) end
                acceptedSince = {}
                if #last == 3 then
                    local a, b, c = last[1], last[2], last[3]
                    if a.name ~= "NO_ACTION" and a.name == b.name
                        and b.name == c.name
                        and (a.wait or 0) <= 0.05
                        and (b.wait or 0) <= 0.05
                        and (c.wait or 0) <= 0.05
                        and (b.since[a.name] or 0) == 0
                        and (c.since[a.name] or 0) == 0 then
                        repeated = repeated + 1
                    end
                end
            end
        end,
    }, { { H = H } })
    print("WARRIOR_ARMS_PLATES_V086 " .. profile .. " L" .. level
        .. " attackers=" .. attackers .. " nameplates=" .. tostring(platesOn)
        .. " " .. pretty.write({
            source = "Hekili Forever v0.8.6", seed = 30417,
            sha256 = profile == "current" and entry.sha256 or "shipped",
            sourceMobs = maxObservedWorldMobs, minCount = minCount,
            maxCount = maxCount, maxActive = maxActive,
            multiCountSamples = multiCountSamples,
            multiActiveSamples = multiActiveSamples,
            multiActiveLowBeliefWindow = rageLoRangeSamples,
            multiActiveWindows = rageWindowSamples,
            accepted = accepted, presses = world.pressedBy,
            whirlwind = whirls, berserkerStance = berserkPresses,
            battleStance = battlePresses, cleave = cleavePresses,
            sourceStanceTransitions = stanceEvents,
            actualWhirlwindCastEvents = actualWhirlwindCasts,
            firstTwelveSourceFormEvents = formEvents,
            genuineHostileSwingWindows = hostileSwings,
            refused = world.refused, errors = world.errors,
            raises = world.raises, repeatedReady = repeated,
            lastThree = last,
        }, ""))

    assert.are.equal(0, world.errors)
    assert.are.equal(0, world.raises)
    assert.are.equal(attackers, maxObservedWorldMobs)
    assert.is_true(hostileSwings >= 3)
    assert.is_true(accepted >= 1)
    assert.are.equal(0, repeated)
    assert.are.same({}, world.refused)
    assert.are.equal(actualWhirlwindCasts, whirls,
        "source-accepted Whirlwind presses must reconcile to genuine cast events")
    if platesOn and attackers == 2 then
        assert.is_true(multiCountSamples > 0,
            "real two mob nameplate events did not produce a source-counted AoE window")
        assert.is_true(multiActiveSamples > 0,
            "source counted 2 plates but APL active_enemies never reached 2")
    else
        assert.are.equal(0, multiCountSamples,
            "a nameplate-OFF/single-target control counted phantom enemies")
        assert.are.equal(0, multiActiveSamples,
            "a nameplate-OFF/single-target control recommended AoE mode")
    end
    if profile == "current" and (not platesOn or attackers == 1) then
        assert.are.equal(0, whirls, "Arms Whirlwind on single observed target")
        assert.are.equal(0, cleavePresses, "Arms Cleave on single observed target")
    end
    -- No must-cast Whirlwind assertion without a source-visible, affordable
    -- window satisfying the APL's verified stance/Rage constraints.
end

describe("Warrior Arms source-visible nameplate AoE and stance gate v0.8.6", function()
    for _, level in ipairs({ 40, 60 }) do
        for _, attackers in ipairs({ 1, 2 }) do
            for _, profile in ipairs({ "current", "shipped" }) do
                for _, platesOn in ipairs({ false, true }) do
                    it(profile .. " L" .. level .. " source-mobs=" .. attackers
                        .. " nameplates=" .. tostring(platesOn), function()
                        runCase(profile, level, attackers, platesOn)
                    end)
                end
            end
        end
    end
end)
