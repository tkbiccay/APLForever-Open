-- Hekili Forever v0.9.0 source-native BM Turret combat progression.
-- Exact upstream tag: 8f95f2ea0a45428554c1e938ed7357b870030514.
-- This is NOT a DPS simulation or proof of in-game pet recovery/range/facing.
-- No mutation of any APL; compare shipped, archived v1.0 and draft v1.1.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local hunter = require("Forever.helpers.hunter_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local C = assert(hunter.BeastMasteryTurret, "released BM Turret world required")

local function draft()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Hunter_BeastMastery" then
            assert.are.equal("v1.1", entry.revision,
                "source-compatible BM revision is only a testing Draft")
            return entry
        end
    end
    error("Hunter BM missing from verified manifest")
end

local function readFile(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local bytes = assert(f:read("*a"))
    f:close()
    return bytes
end

local profiles = {
    { name = "shipped" },
    { name = "archived-v1.0", path = "roles/Hunter/Current/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt" },
    { name = "draft-v1.1", path = draft().apl_file },
    { name = "candidate-v1.2", path = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt" },
}

local function install(H, profile)
    if not profile.path then return end
    local src = readFile(profile.path)
    if profile.testOnlySixYardHawk then
        -- The source registers Summon Hawk's 0-35 yd range. This in-memory
        -- hypothesis relaxes ONLY the inherited 8yd Hunter ranged-shot
        -- boundary; both protected full APLs remain byte-for-byte intact.
        local old = "actions+=/summon_hawk,if=target.outside8&action.summon_hawk.in_range&pet.hawk.count<2"
        local new = "actions+=/summon_hawk,if=action.summon_hawk.in_range&pet.hawk.count<2"
        local at = src:find(old, 1, true)
        assert.is_not_nil(at, "standalone BM v1.1 Hawk anchor changed")
        assert.is_nil(src:find(old, at + #old, true),
            "ambiguous source anchor: never alter multiple Hawk lines")
        src = src:sub(1, at - 1) .. new .. src:sub(at + #old)
    end
    local parsed, warnings = H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery", "APLForever", src, C.PACK)
    assert.is_table(parsed)
    assert.is_table(parsed.default)
    assert.is_table(parsed.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true),
        "release importer rejected a priority action")
    local pack = assert(H.Hekili.DB.profile.packs[C.PACK])
    pack.lists = parsed
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(parsed) do
        assert.is_true(H.Hekili:IsListActive(C.PACK, name),
            "inactive independent list " .. name)
    end
    assert.are.same({}, H.errors)
end

local function exercise(profile, cooldowns)
    -- Actual published source-world BM build: level 60, living main pet,
    -- 12 yd, 3330 natural Mana, 1 target and normal auto-shot mechanics.
    -- No forced resource refill/drain, extra pet recovery, fake damage or
    -- unsupported low-level rank overrides.
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    install(H, profile)

    local toggles = H.Hekili.DB.profile.toggles
    assert.is_table(toggles.cooldowns)
    toggles.cooldowns.value = cooldowns
    toggles.defensives.value = false
    toggles.movement.value = false
    assert.is_true(H.Hekili.State:IsKnown("bestial_wrath"),
        "published BM Turret build must actually know Bestial Wrath")
    assert.is_true(H.Hekili.State:IsKnown("arcane_shot"),
        "published BM Turret build must actually know Arcane Shot")

    local refusalsDetailed, hooked = {}, false
    local run = loop.run(L, 30417, {
        duration = 40,
        on = function(r)
            if not hooked then
                -- Copy the source-backed WORLD-002 instrumentation method:
                -- measure real refused-press timestamps before deciding
                -- whether a refusal is a real early press or only float ulps.
                local original = r.W.press
                r.W.press = function(player, key, resolved)
                    local pre = {
                        t = r.W.t, key = key,
                        mana = player.power, cost = resolved.cost,
                        gcdUntil = player.gcdUntil,
                        castUntil = player.castUntil,
                        castOverhang = (player.castUntil or 0) - r.W.t,
                        castPrecise = string.format("%.17g", player.castUntil or 0),
                        nowPrecise = string.format("%.17g", r.W.t),
                        offGcd = resolved.offGcd, clip = resolved.clip,
                    }
                    local ok, why = original(player, key, resolved)
                    if player == r.us and not ok and r.W.t >= loop.PULL then
                        pre.reason = why
                        refusalsDetailed[#refusalsDetailed + 1] = pre
                    end
                    return ok, why
                end
                hooked = true
            end
        end,
    }, { { H = H } })
    local presses = run.pressedBy or {}
    local major = (presses.bestial_wrath or 0) + (presses.rapid_fire or 0)
        + (presses.blood_fury or 0) + (presses.elunes_light or 0)
        + (presses.berserking or 0)
    local ranged = (presses.arcane_shot or 0) + (presses.aimed_shot or 0)
        + (presses.summon_hawk or 0)

    print(string.format(
        "BM_V090_PROGRESS profile=%s major_on=%s accepted=%s ranged=%d major=%d bestial_wrath=%d rapid_fire=%d start_mana=%s end_mana=%s",
        profile.name, tostring(cooldowns), tostring(run.presses), ranged, major,
        presses.bestial_wrath or 0, presses.rapid_fire or 0,
        tostring(C.WORLD.power), tostring(run.us.power)))

    assert.are.equal(0, run.errors, "source engine errors")
    assert.are.equal(0, run.raises, "source engine raises")
    if #refusalsDetailed > 0 then
        print("BM_V090_REFUSAL " .. profile.name .. " " .. pretty.write(refusalsDetailed, ""))
    end
    -- A casting refusal is NOT globally forgiven. In this released 5Hz
    -- loop, a single demonstrably sub-1e-8s cast-end rounding boundary
    -- can be labelled, never counted as a fully clean/no-refusal run.
    -- Every other refusal, repeated refusal, cost/cooldown/facing issue
    -- or significant early cast must fail the test and protect the APL.
    local allowable = {}
    for _, refused in ipairs(refusalsDetailed) do
        -- Released v0.9.0 shipped BM Turret: the one proven Bestial
        -- Wrath (off-GCD) boundary at t=8.6 has castUntil precisely
        -- 8.6000000000000014, 1.78e-15s over the world tick. It has
        -- sufficient real Mana, completed GCD and no second refusal.
        -- Unlike WARLOCK's on-GCD-only historical guard, this exact
        -- pinned off-GCD action is allowed only at this microscopic edge.
        local pinnedOffGcdBoundary = profile.name == "shipped"
            and cooldowns and refused.key == "bestial_wrath"
            and refused.offGcd == true
            and refused.mana >= (refused.cost or math.huge)
        assert.is_true(refused.reason == "casting"
            and refused.castOverhang > 0 and refused.castOverhang <= 1e-8
            and (refused.gcdUntil or 0) <= refused.t + 1e-8
            and ((not refused.offGcd) or pinnedOffGcdBoundary),
            "true refused cast: inspect precise timestamps, spell and state")
        allowable.casting = (allowable.casting or 0) + 1
    end
    assert.is_true(#refusalsDetailed <= 1,
        "repeated cast-boundary refusals need separate investigation")
    assert.are.same(allowable, run.refused,
        "instrumentation must reconcile EVERY refused source-world press")
    assert.is_true(run.presses >= 3, "non-vacuous accepted combat progression required")
    assert.is_true(ranged > 0, "no actual accepted ranged shot/Hawk priority actions")
    if not cooldowns then
        assert.are.equal(0, major, "Major OFF must prevent real offensive CD casts")
    elseif profile.name ~= "archived-v1.0" then
        -- Positive current-engine toggle check, rather than a vacuous OFF test.
        -- A failure may mean world pet exposure/pack conditions need diagnosis;
        -- do NOT weaken this to an icon-only recommendation.
        assert.is_true((presses.bestial_wrath or 0) >= 1,
            "Major ON never produced source-accepted Bestial Wrath with living pet")
    end
end

describe("Hunter BM v0.9.0 source-native combat and Major toggle", function()
    for _, profile in ipairs(profiles) do
        for _, cooldowns in ipairs({ false, true }) do
            it(profile.name .. " real casts with Major " .. (cooldowns and "ON" or "OFF"), function()
                exercise(profile, cooldowns)
            end)
        end
    end
end)


-- Natural long-fight Mana exhaustion. This is deliberately NOT synthetic
-- low-resource injection: the exact v0.9.0 world pays ranks from its own
-- source, regenerates by the published five-second rule and fires Auto Shots.
-- Sample a true world advancement, not three recommendation UI polls.
local function naturalManaTail(profile)
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    install(H, profile)
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    local lowThreshold = 200 -- 6% of the exact 3330 starting Mana; Aimed Shot > this cost.
    local samples, acceptedAfterLow = {}, {}
    local firstLowTick, firstLowTime, minMana = nil, nil, math.huge
    local lastSampleTime, lastEventCount = -math.huge, -1
    local realWorldAdvances = 0
    local run = loop.run(L, 30417, {
        duration = 175,
        on = function(r, _, t)
            if r.combat <= 0 then return end
            local mana = r.us.power
            if mana < minMana then minMana = mana end
            if mana > lowThreshold then return end
            if not firstLowTick then
                firstLowTick, firstLowTime = r.combat, t
            end
            local accepted = r.pressed[r.combat]
            if accepted then
                acceptedAfterLow[accepted] = (acceptedAfterLow[accepted] or 0) + 1
            end
            -- #W.truth counts actual processed source-world events (casts,
            -- auto-shots, auras, mob swings). Distinct events + >=0.8s time
            -- prove actual combat advancement, not identical display polls.
            local events = #r.W.truth
            if events > lastEventCount and t - lastSampleTime >= 0.8
                and #samples < 3 then
                local output = H.Hekili.Engine.Output.Primary
                local rec = output and output.recs[1]
                local first = r.ours[r.combat] or "NO_ACTION"
                samples[#samples + 1] = {
                    t = t, tick = r.combat, first = first, wait = rec and rec.wait or nil,
                    mana = mana, accepted = accepted, events = events,
                }
                if lastEventCount >= 0 then realWorldAdvances = realWorldAdvances + 1 end
                lastEventCount, lastSampleTime = events, t
            end
        end,
    }, { { H = H } })

    print("BM_V090_NATURAL_TAIL " .. profile.name .. " " .. pretty.write({
        minimumMana = minMana, lowThreshold = lowThreshold,
        firstLowTime = firstLowTime, firstLowTick = firstLowTick,
        accepted = run.pressedBy, acceptedAfterLow = acceptedAfterLow,
        samples = samples, advancedWorldEvents = realWorldAdvances,
        rawRefused = run.refused, errors = run.errors, raises = run.raises,
    }, ""))

    assert.are.equal(0, run.errors, "source world error during natural exhaustion")
    assert.are.equal(0, run.raises, "source engine raised during natural exhaustion")
    assert.are.same({}, run.refused,
        "a cast/refusal during low Mana is a real failure requiring diagnosis")
    assert.is_true(run.presses >= 3, "non-vacuous actual casts before exhaustion")
    assert.is_true((run.pressedBy.serpent_sting or 0) > 0,
        "no source-accepted Serpent Sting upkeep before low-Mana tail")
    assert.is_not_nil(firstLowTick, "natural world never reached the defined low-Mana band")
    assert.are.equal(3, #samples,
        "need three genuinely event-advanced low-Mana checkpoints")
    assert.is_true(realWorldAdvances >= 2,
        "three low-Mana recommendations were not separated by source events")

    local a, b, c = samples[1], samples[2], samples[3]
    assert.is_true(a.events < b.events and b.events < c.events
        and a.t < b.t and b.t < c.t,
        "tail must represent three DIFFERENT world states")
    local first = a.first
    local immediateRepeat = first ~= "NO_ACTION"
        and b.first == first and c.first == first
        and (a.wait or 0) <= 0.05 and (b.wait or 0) <= 0.05
        and (c.wait or 0) <= 0.05
    if immediateRepeat then
        local acceptedOfFirst = 0
        for i = a.tick, c.tick do
            if run.pressed[i] == first then acceptedOfFirst = acceptedOfFirst + 1 end
        end
        assert.is_true(acceptedOfFirst > 0,
            "same ready first icon repeats after real state advances without a single accepted press")
    end
end

describe("Hunter BM v0.9.0 natural sub-200 Mana tail / repeated fallback", function()
    for _, profile in ipairs(profiles) do
        it(profile.name .. " advances through three true low-Mana checkpoints", function()
            naturalManaTail(profile)
        end)
    end
end)


-- At 5-8 yards the source client cannot legally cast ranged shots (min 8)
-- or melee actions (max 5). Summon Hawk and Hunter's Mark have their OWN
-- verified range bands; never incorrectly label them as ranged shots.
-- This checks source-world on-demand presses and refusals only: the
-- upstream turret fixture auto-starts ranged white attacks even when
-- moved to 6 yd, so it cannot prove real auto-shot clipping/suppression.
local function sourceDeadZone(profile)
    local gapWorld = setmetatable({ distance = 6 }, { __index = C.WORLD })
    local gapContent = setmetatable({ WORLD = gapWorld }, { __index = C })
    local L = loop.new(gapContent)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    install(H, profile)
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    -- The source Belief registers a modelled two-slot 18s Hawk guardian,
    -- not a directly observed pet. Verify the installed candidate uses
    -- that actual model without accepting a cast while both slots are up.
    local checkGuardians = profile.name == "candidate-v1.2" or profile.testOnlySixYardHawk
    local pet = checkGuardians and H.Hekili.Class.pets.hawk or nil
    if checkGuardians then
        assert.is_not_nil(pet, "released pet model missing")
        assert.are.equal(2, pet.cap, "v0.9.0 registered Hawk cap changed")
        assert.is_true(type(pet.slot) == "number" and pet.slot >= 6)
    end
    local maxGuardians, hawkPresses, tickSamples = 0, {}, {}
    local run = loop.run(L, 30417, {
        duration = 22,
        on = function(r, steps, t)
            if not checkGuardians or r.combat <= 0 then return end
            local live = 0
            for slot = pet.slot, pet.slot + pet.cap - 1 do
                local key, _, duration, expires = H.ns.VirtualState.Guardian(slot)
                assert.are.equal("hawk", key)
                if duration > 0 and expires > H.ctl.now then
                    live = live + 1
                end
            end
            if live > maxGuardians then maxGuardians = live end
            -- The recommendation is sampled BEFORE this tick's press.
            -- Preserve both the accepted press and the next independently
            -- evaluated icon; firstThree alone is not a post-cast trace.
            local n = r.combat
            tickSamples[n] = {
                t = t, first = r.ours[n] or "NO_ACTION",
                accepted = r.pressed[n], events = #r.W.truth,
                live = live, wait = steps[1].q.time[1],
            }
            if r.pressed[n] == "summon_hawk" then
                hawkPresses[#hawkPresses + 1] = {
                    t = t, tick = n, modelled_live_before_feed = live,
                }
                assert.is_true(live < 2,
                    "accepted Hawk while TWO source-modelled guardians already active")
            end
        end,
    }, { { H = H } })
    local pressed = run.pressedBy or {}
    local outOfBand = {
        "arcane_shot", "aimed_shot", "serpent_sting", "multi_shot",
        "raptor_strike", "mongoose_bite", "strider_kick",
    }
    local firstThree = {}
    for i = 1, math.min(3, run.combat) do
        firstThree[#firstThree + 1] = run.ours[i] or "NO_ACTION"
    end
    -- NEW: real acceptance -> subsequent source tick -> fresh recommendation.
    -- Unlike three early UI samples, these rows can only exist following a
    -- source-accepted Hawk press. Do not assume different icons: casting a
    -- second Hawk is legitimate while the modelled two-slot cap permits it.
    local postAcceptedHawk = {}
    if checkGuardians then
        for _, accepted in ipairs(hawkPresses) do
            local before = assert(tickSamples[accepted.tick], "missing accepted Hawk tick")
            local after = assert(tickSamples[accepted.tick + 1],
                "accepted Hawk had no subsequent recommendation update")
            assert.are.equal("summon_hawk", before.accepted)
            assert.are.equal("summon_hawk", before.first)
            assert.is_true(after.t > before.t and after.events >= before.events,
                "post-cast sample did not advance actual source time/events")
            assert.is_false(after.live >= pet.cap and after.first == "summon_hawk"
                and (after.wait or 0) <= 0.05,
                "immediately ready Hawk suggested despite full modelled guardian cap")
            postAcceptedHawk[#postAcceptedHawk + 1] = {
                accepted_at = before.t, next_at = after.t,
                next_icon = after.first, next_wait = after.wait,
                modelled_hawks = after.live, events_after = after.events,
            }
        end
    end
    print("BM_V090_SIX_YARD " .. profile.name .. " " .. pretty.write({
        distance = run.W.distance, accepted = pressed, firstThree = firstThree,
        rawRefused = run.refused, worldEvents = #run.W.truth,
        errors = run.errors, raises = run.raises,
        hawkPresses = hawkPresses, maxModelledGuardians = maxGuardians,
        postAcceptedHawk = postAcceptedHawk,
    }, ""))

    assert.are.equal(6, run.W.distance,
        "published world did not actually apply the six-yard gap")
    assert.is_true(run.combat >= 20 and #run.W.truth > 3,
        "dead-zone negative case did not genuinely advance combat time/events")
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    if profile.name == "shipped" then
        -- FAILED-FIRST negative control: actual pinned shipped v0.9.0
        -- Turret repeatedly suggests 8-35yd Serpent Sting at 6yd. The
        -- source world rejected 109 range attempts / 22s in run 44488313535.
        -- Preserve this failing comparator as explicit expected failure,
        -- NOT as proof that a bad recommendation is safe or acceptable.
        assert.is_true((run.refused.range or 0) >= 3,
            "shipped native range regression changed: re-investigate")
        for reason in pairs(run.refused) do
            assert.are.equal("range", reason,
                "unclassified additional shipped refusal")
        end
        assert.are.same({ "serpent_sting", "serpent_sting", "serpent_sting" },
            firstThree, "expected shipped repeated uncastable first action")
    else
        assert.are.same({}, run.refused,
            "custom six-yard range/facing/resource refusal: FAIL")
    end
    if checkGuardians then
        assert.is_true((pressed.summon_hawk or 0) >= 1,
            "verified-range Hawk was never source-accepted")
        assert.is_true(#hawkPresses >= 1 and maxGuardians == 2,
            "source guardian Belief must actually reach two tracked hawks")
        assert.are.equal(#hawkPresses, #postAcceptedHawk,
            "each accepted Hawk needs a distinct subsequent source recommendation")
        if profile.name == "candidate-v1.2" then
            assert.is_true(#postAcceptedHawk >= 3,
                "v1.2 needs three accepted Hawk -> next-state recommendation transitions")
        end
    end
    for _, key in ipairs(outOfBand) do
        assert.are.equal(0, pressed[key] or 0,
            "source accepted " .. key .. " outside its verified range band")
    end
end

describe("Hunter BM v0.9.0 source-world six-yard ranged/melee dead zone", function()
    for _, profile in ipairs(profiles) do
        it(profile.name .. " source-native range comparator", function()
            sourceDeadZone(profile)
        end)
    end
    it("in-memory complete v1.1 relaxes only Hawk's verified 0-35yd range", function()
        sourceDeadZone({
            name = "draft-v1.1-test-only-hawk-gap",
            path = draft().apl_file, testOnlySixYardHawk = true,
        })
    end)
end)
