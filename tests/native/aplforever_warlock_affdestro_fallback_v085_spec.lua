-- Issue #30: source-native Affliction and Destruction Mana fallback audit.
-- Real registered casts apply and refresh all upkeep auras. Mana spends and
-- regenerates only via the pinned source world; NO synthetic post-pull drain.
-- A known 65%-Mana pull is a partial-resource initial condition, not a cast.
-- The native observer clears all numeric Mana reads on combat transition.
-- This is not in-game health/cast/range validation or proof of DPS ranking.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local stock = require("Forever.helpers.warlock_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local CASES = {
    { name = "Warlock_Affliction", kit = stock.Affliction,
      upkeep = { "corruption", "bane_of_agony" } },
    { name = "Warlock_Destruction", kit = stock.Destruction,
      upkeep = { "immolate", "corruption" } },
}
local SEED = 30417

local function selected(name)
    for _, entry in ipairs(manifest) do
        if entry.apl_name == name then return entry end
    end
    error("missing exact Warlock native manifest selection: " .. name)
end

local function install(H, content, entry)
    local f = assert(io.open(root .. "/" .. entry.apl_file, "rb"))
    local apl = assert(f:read("*a"))
    f:close()
    local lists, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", apl, content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.is_true(H.Hekili:IsListActive(content.PACK, "default"))
    assert.are.same({}, H.errors)
end

local function testCase(c, custom)
    local mana = c.kit.WORLD.max * 0.65
    local content = setmetatable({
        WORLD = setmetatable({
            power = mana, mobHealth = 1e9, mobPeriod = 2.25,
            mobDamage = { 1, 2 }, noMelee = true,
        }, { __index = c.kit.WORLD }),
        OBSERVE = setmetatable({ plainPower = { [0] = "ooc" } },
            { __index = c.kit.OBSERVE }),
    }, { __index = c.kit })
    local L = loop.new(content)
    local H = L.us
    local entry = selected(c.name)
    if custom then install(H, content, entry) end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    if H.Hekili.DB.profile.toggles.minor_cooldowns then
        H.Hekili.DB.profile.toggles.minor_cooldowns.value = false
    end

    -- The shipped Affliction priority uses Bane of Doom, not the custom
    -- Bane of Agony. Both comparators must earn their own genuine upkeep.
    local upkeep = c.name == "Warlock_Affliction" and not custom
        and { "corruption", "bane_of_doom" } or c.upkeep
    local auraIDs = {}
    for _, key in ipairs(upkeep) do
        auraIDs[key] = assert(H.Hekili.Class.auras[key], key).id
    end
    local seen = {}
    local started, lowSince, exposedMana = false, nil, false
    local cursor, samples = 0, {}
    local acceptedAfterLow, refusalsDetailed = {}, {}
    local hooked = false
    local minimumWorldMana, minimumBelief = math.huge, math.huge
    local run = loop.run(L, SEED, {
        duration = 90,
        on = function(r, _, t)
            if not hooked then
                local original = r.W.press
                r.W.press = function(player, key, resolved)
                    local pre = {
                        t = r.W.t, key = key,
                        mana = player.power, cost = resolved.cost,
                        gcdUntil = player.gcdUntil,
                        castUntil = player.castUntil,
                        castOverhang = (player.castUntil or 0) - r.W.t,
                        castTimePrecise = string.format("%.17g", player.castUntil or 0),
                        nowPrecise = string.format("%.17g", r.W.t),
                        channel = player.channel and player.channel.key,
                        offGcd = resolved.offGcd,
                        clip = resolved.clip,
                        q = r.ours[r.combat],
                    }
                    local ok, why = original(player, key, resolved)
                    if player == r.us and not ok and r.W.t >= loop.PULL then
                        pre.reason = why
                        local output = H.Hekili.Engine.Output.Primary
                        pre.icon = output.count > 0 and output.recs[1].actionName
                        pre.wait = output.count > 0 and output.recs[1].wait
                        refusalsDetailed[#refusalsDetailed + 1] = pre
                    end
                    return ok, why
                end
                hooked = true
            end
            local freshEnemyEvent = false
            for i = cursor + 1, #r.W.truth do
                local event = r.W.truth[i]
                if event.kind == "swing" and event.src and event.src.kind == "mob"
                  and event.dst and event.dst.guid == r.us.guid then
                    freshEnemyEvent = true
                end
            end
            cursor = #r.W.truth

            local target = r.us.target
            local allUp = target ~= nil
            for _, key in ipairs(upkeep) do
                local aura = target and target.auras[auraIDs[key]]
                local up = aura and (aura.stacks or 0) > 0 and aura.expires > r.W.t
                seen[key] = seen[key] or not not up
                allUp = allUp and not not up
            end
            if allUp then started = true end
            if started then
                minimumWorldMana = math.min(minimumWorldMana, r.us.power)
            end
            local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
            if started and belief and belief.lo then
                minimumBelief = math.min(minimumBelief, belief.lo)
            end

            -- A low-Mana checkpoint must follow genuine successful upkeep;
            -- it is not a simulated aura applied by the test.
            if started and r.us.power <= r.us.powerMax * 0.28 then
                lowSince = lowSince or t
                local accepted = r.pressed[r.combat]
                if accepted then
                    acceptedAfterLow[accepted] = (acceptedAfterLow[accepted] or 0) + 1
                end
                if freshEnemyEvent and #samples < 3 then
                    local output = H.Hekili.Engine.Output.Primary
                    local rec = output.count > 0 and output.recs[1] or {}
                    samples[#samples + 1] = {
                        t = t, first = rec.actionName or "NO_ACTION",
                        wait = rec.wait, pressed = r.pressed[r.combat],
                        driverFirst = r.ours[r.combat],
                        castUntil = r.us.castUntil, gcdUntil = r.us.gcdUntil,
                        worldMana = r.us.power, worldMax = r.us.powerMax,
                        lowerBelief = belief and belief.lo,
                        estimatedMana = belief and belief.est,
                        upkeepNow = allUp,
                        clientPower = H.ctl.power[L.power.type],
                    }
                    if H.ctl.power[L.power.type] ~= nil then
                        exposedMana = true
                    end
                end
            end
        end,
    }, { { H = H } })

    -- run.refused is a reason->count MAP, not an array; ipairs would
    -- silently make even real source refusals look empty (v1 fixture bug).
    local tag = custom and "custom" or "shipped"
    print("WARLOCK_FINAL_V085 " .. c.name .. "/" .. tag .. " " .. pretty.write({
        source = "v0.8.5", seed = SEED,
        revision = custom and entry.revision or "shipped",
        manaAtPull = mana, actualManaMinimum = minimumWorldMana,
        lowBeliefMinimum = minimumBelief, lowSince = lowSince,
        upkeeps = seen, samples = samples, pressed = run.pressedBy,
        acceptedAfterLow = acceptedAfterLow, refused = run.refused,
        refusalsDetailed = refusalsDetailed,
        errors = run.errors, raises = run.raises,
    }, ""))

    for _, key in ipairs(upkeep) do
        assert.is_true(seen[key], "source-world never applied the " .. key .. " aura")
        assert.is_true((run.pressedBy[key] or 0) > 0,
            "upkeep " .. key .. " was not genuinely cast")
    end
    assert.is_true(started, "two genuine upkeep auras were never simultaneously active")
    assert.is_true(lowSince ~= nil, "Mana never reached the explicit <=28% world threshold")
    assert.are.equal(3, #samples,
        "need three distinct real enemy-swing checkpoints below 28% after upkeep")
    assert.is_false(exposedMana, "fake client leaked numeric Mana after pull")
    for _, sample in ipairs(samples) do
        assert.is_nil(sample.clientPower, "out-of-combat Mana observation leaked into combat")
    end
    -- The driver's actual press is driven by its own first-icon reaction
    -- timeline, not necessarily the concurrently sampled output rec.
    -- A ready icon on an enemy-swing checkpoint without that tick's press
    -- is not by itself an inappropriate repeated recommendation.
    local repeated = #samples == 3 and samples[1].first ~= "NO_ACTION"
    local repeatedKey = samples[1] and samples[1].first or nil
    for _, sample in ipairs(samples) do
        repeated = repeated and sample.first == repeatedKey
            and (sample.wait or 0) <= 0.05
    end
    if repeated then
        assert.is_true((acceptedAfterLow[repeatedKey] or 0) > 0,
            "three ready fallback icons and no real accepted post-low press of that action")
    end
    -- The pinned source loop reports refusals keyed by reason (cost/gcd/
    -- casting/cooldown), not as an array. A floating point boundary where
    -- the cast ends a few ulps after the nominal tick is distinguishable
    -- from a genuinely early or unaffordable recommendation. Fail the test
    -- for EVERY real refusal; document at most one source-loop rounding
    -- artefact per profile and never present it as zero raw refusals.
    local allowableBoundary = {}
    for _, refused in ipairs(refusalsDetailed) do
        assert.is_true(refused.reason == "casting"
            and refused.castOverhang > 0 and refused.castOverhang <= 1e-8
            and refused.gcdUntil <= refused.t + 1e-8
            and not refused.offGcd,
            "world refused a true early/unaffordable action: inspect full-precision cast boundary")
        allowableBoundary.casting = (allowableBoundary.casting or 0) + 1
    end
    assert.is_true(#refusalsDetailed <= 1,
        "repeated floating-boundary press failures need separate investigation")
    assert.are.same(allowableBoundary, run.refused,
        "instrumented world refusals must match every genuine source-loop refusal")
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
end

describe("Warlock v0.8.5 natural post-upkeep low-Mana fallback (no synthetic drain)", function()
    for _, c in ipairs(CASES) do
        for _, custom in ipairs({ true, false }) do
            it(c.name .. "/" .. (custom and "custom" or "shipped")
                .. " has three truly advanced low-Mana checkpoints", function()
                testCase(c, custom)
            end)
        end
    end
end)
