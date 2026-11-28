-- Druid Feral DPS priority #2: compare three independently imported profiles:
-- standalone Current v1.0, full standalone Draft Candidate v1.1 and shipped.
-- Exact released source v0.8.5. Not a damage or in-game position test.
-- No fabricated casts, successful presses, resource gains or class abilities.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local stock = require("Forever.helpers.druid_loop_world").Feral
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local SEED = 30417
local CANDIDATE = {
    apl_name = "Druid_Feral", revision = "v1.1",
    apl_file = "roles/Druid/Archive/APL_Druid_Feral_v1.1_Draft.txt",
    sha256 = "f611e4510a52ca125103eed9f3d1d4fc99a0b656b161cdc88134f0e72b6e52f7",
}

local function current()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Druid_Feral" then
            assert.are.equal("v1.0", entry.revision)
            return entry
        end
    end
    error("missing source-compatible Current Druid_Feral revision")
end

local function installed(H, content, e)
    local f = assert(io.open(root .. "/" .. e.apl_file, "rb"))
    local raw = assert(f:read("*a"))
    f:close()
    local lists, warnings = H.Hekili:ImportSimcAPL(e.apl_name, "APLForever", raw, content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name),
            "non-standalone list: " .. name)
    end
    assert.are.same({}, H.errors)
end

local function runOne(profile, notTargeted)
    -- loop.run copies OBSERVE through pairs(), which does not visit fields
    -- inherited through __index. Materialise the actual pinned source observer
    -- settings so the client receives ComboPoints, tokens and powerMax.
    local observe = {}
    for key, value in pairs(stock.OBSERVE) do observe[key] = value end
    -- This tells the source client whether the target targets us,
    -- NOT that the player is guaranteed behind the mob.
    observe.notTargeted = notTargeted
    local content = setmetatable({
        WORLD = setmetatable({
            mobHealth = 1000000000, mobPeriod = 2.0,
            mobDamage = { 1, 2 },
        }, { __index = stock.WORLD }),
        OBSERVE = observe,
    }, { __index = stock })
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    local e = profile == "candidate" and CANDIDATE or current()
    if profile ~= "shipped" then installed(H, content, e) end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    if H.Hekili.DB.profile.toggles.minor_cooldowns then
        H.Hekili.DB.profile.toggles.minor_cooldowns.value = true
    end

    assert.is_true(H.Hekili.State:IsKnown("cat_form"))
    assert.is_true(H.Hekili.State:IsKnown("claw"))
    assert.is_true(H.Hekili.State:IsKnown("shred"))
    assert.is_true(H.Hekili.State:IsKnown("rip"))
    assert.is_true(H.Hekili.State:IsKnown("rake"))
    local cursor, ticks, threeAdvances = 0, {}, 0
    local seen = { rake = false, rip = false }
    local observedEnergyMin, observedEnergyMax = math.huge, -math.huge
    local recs, refusalTrace, hooked = {}, {}, false
    local firstCombatCast = nil
    local maxTrueCombo, maxClientCombo, maxStateCombo = 0, 0, 0
    local cpWindows, cpChanges, lastTrueCP = {}, {}, nil
    local observerCursor, observerCPEvents, maxObserverCP = 0, 0, 0
    local latestObserverCP, latestObserverCPAt, controllerCPNilWindows = nil, nil, 0
    local minMana, maxMana = math.huge, -math.huge
    local result = loop.run(L, SEED, {
        duration = 85,
        on = function(r, steps, t)
            -- Trace only the already emitted source-observer stream, not invented client values.
            -- The loop feeds observers before today's possible press; world truth below is post-press.
            local stream = steps[1].obs.s
            for i = observerCursor + 1, stream.n do
                if stream.ev[i] == "@power" and stream.a1[i] == 4 then
                    observerCPEvents = observerCPEvents + 1
                    latestObserverCP, latestObserverCPAt = stream.a2[i], stream.t[i]
                    if type(latestObserverCP) == "number" then
                        maxObserverCP = math.max(maxObserverCP, latestObserverCP)
                    end
                end
            end
            observerCursor = stream.n
            if not hooked then
                local original = r.W.press
                r.W.press = function(player, key, resolved)
                    local start = r.W.t
                    local wasCastUntil = player.castUntil
                    local ok, reason = original(player, key, resolved)
                    if player == r.us and not ok and start >= loop.PULL then
                        refusalTrace[#refusalTrace + 1] = {
                            t = start, key = key, reason = reason,
                            castDelta = (wasCastUntil or 0) - start,
                            cost = resolved.cost, energy = player.power,
                        }
                    end
                    return ok, reason
                end
                hooked = true
            end
            local accepted = r.pressed[r.combat]
            if accepted then firstCombatCast = firstCombatCast or accepted end
            local advanced = false
            for i = cursor + 1, #r.W.truth do
                local event = r.W.truth[i]
                if event.src == r.us
                    and (event.kind == "strike" or event.kind == "aura"
                        or event.kind == "gain" or event.kind == "dot") then
                    advanced = true
                end
            end
            cursor = #r.W.truth
            if accepted then advanced = true end
            local enemy = r.us.target
            for _, aura in ipairs({ "rake", "rip" }) do
                local data = H.Hekili.Class.auras[aura]
                local a = data and enemy and enemy.auras[data.id]
                if a and (a.stacks or 0) > 0 and a.expires > r.W.t then seen[aura] = true end
            end
            observedEnergyMin = math.min(observedEnergyMin, r.us.power)
            observedEnergyMax = math.max(observedEnergyMax, r.us.power)
            local truthCP = r.W.res(r.us, 4)
            local clientCP = H.ctl.power and H.ctl.power[4]
            local state = H.Hekili.State
            local stateCP = state.combo_points and state.combo_points.current
            local truthMana = r.W.res(r.us, 0)
            local sp = state.action and state.action.shifting_power
            maxTrueCombo = math.max(maxTrueCombo, tonumber(truthCP) or 0)
            maxClientCombo = math.max(maxClientCombo, tonumber(clientCP) or 0)
            maxStateCombo = math.max(maxStateCombo, tonumber(stateCP) or 0)
            minMana = math.min(minMana, truthMana)
            maxMana = math.max(maxMana, truthMana)
            if t >= 8 and truthCP ~= lastTrueCP and #cpChanges < 12 then
                cpChanges[#cpChanges + 1] = {
                    t = t, trueCP = truthCP,
                    clientCP = clientCP, stateCP = stateCP,
                    actualMana = truthMana, energy = r.us.power,
                    pressed = accepted,
                }
            end
            lastTrueCP = truthCP
            if t >= 8 and truthCP >= 4 and advanced and #cpWindows < 5 then
                if clientCP == nil then controllerCPNilWindows = controllerCPNilWindows + 1 end
                local apiPower = H.api.UnitPower("player", 4)
                local apiTarget = H.api.GetComboPoints("player", "target")
                local function reportRead(value)
                    return type(value) == "number" and value or (value == nil and "nil" or "non-numeric")
                end
                local output = H.Hekili.Engine.Output.Primary
                local rec = output.count > 0 and output.recs[1] or {}
                cpWindows[#cpWindows + 1] = {
                    t = t, trueCP = truthCP, clientCP = clientCP, stateCP = stateCP,
                    observerCP = latestObserverCP, observerCPAt = latestObserverCPAt,
                    apiPowerCP = reportRead(apiPower), apiTargetCP = reportRead(apiTarget),
                    first = rec.actionName or "NO_ACTION", wait = rec.wait,
                    spKnown = state:IsKnown("shifting_power"),
                    spReady = sp and sp.ready,
                    manaTruth = truthMana, energyTruth = r.us.power,
                    pressed = accepted,
                }
            end
            if t >= 8 and advanced and #ticks < 5 then
                local o = H.Hekili.Engine.Output.Primary
                local rec = o.count > 0 and o.recs[1] or {}
                local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                ticks[#ticks + 1] = {
                    t = t, first = rec.actionName or "NO_ACTION",
                    wait = rec.wait, pressed = accepted,
                    actualEnergy = r.us.power, lowerEnergy = belief and belief.lo,
                    targetFocusesPlayer = not notTargeted,
                }
                threeAdvances = threeAdvances + 1
            end
            if t >= 8 and advanced then
                local o = H.Hekili.Engine.Output.Primary
                local rec = o.count > 0 and o.recs[1] or {}
                if #recs < 24 then
                    recs[#recs + 1] = {
                        t = t, first = rec.actionName or "NO_ACTION",
                        wait = rec.wait, pressed = accepted,
                    }
                end
            end
        end,
    }, { { H = H } })

    print("FERAL_DPS_BASELINE_V085 " .. profile
        .. "/" .. (notTargeted and "target-on-other" or "target-on-player")
        .. " " .. pretty.write({
            source = "v0.8.5", seed = SEED,
            revision = profile ~= "shipped" and e.revision or "shipped",
            sha256 = profile ~= "shipped" and e.sha256 or nil,
            accepted = result.pressedBy, refused = result.refused,
            refusalTrace = refusalTrace,
            first = firstCombatCast, observedBleeds = seen,
            minEnergy = observedEnergyMin, maxEnergy = observedEnergyMax,
            maxTruthCP = maxTrueCombo, maxClientCP = maxClientCombo,
            maxStateCP = maxStateCombo, cpWindows = cpWindows,
            observerCPEvents = observerCPEvents, maxObserverCP = maxObserverCP,
            controllerCPNilWindows = controllerCPNilWindows,
            cpChanges = cpChanges, minMana = minMana, maxMana = maxMana,
            decisions = ticks, nextRecommendations = recs,
            errors = result.errors, raises = result.raises,
        }, ""))
    assert.are.equal(0, result.errors)
    assert.are.equal(0, result.raises)
    assert.is_true(#ticks >= 3, "need at least three actual source world advances")
    -- This is a source-observer contract, NOT an assertion that post-cycle simulated
    -- state or same-tick post-press truth must equal pre-press controller readings.
    assert.is_true(observerCPEvents > 0 and maxObserverCP >= 4,
        "plain ComboPoints source observer never emitted a real >=4 CP value")
    assert.is_true((result.pressedBy.claw or 0) + (result.pressedBy.shred or 0)
        + (result.pressedBy.rake or 0) >= 3,
        "three real accepted Cat builders never occurred")
    assert.is_true(observedEnergyMin < observedEnergyMax,
        "Energy never spent and regenerated naturally")
    assert.are.equal(0, result.refused.cost or 0, "source-world cost refusal")
    assert.are.equal(0, result.refused.cooldown or 0, "source-world cooldown refusal")
    assert.are.equal(0, result.refused.range or 0, "source-world range refusal")
    for _, refusal in ipairs(refusalTrace) do
        if refusal.reason == "casting" then
            assert.is_true(refusal.castDelta > 0 and refusal.castDelta <= 1e-8,
                "material early-cast refusal")
        end
    end
    assert.is_true(#refusalTrace <= 1,
        "multiple source-world refusals require independent root-cause investigation")
    if profile == "candidate" then
        if notTargeted then
            assert.is_true((result.pressedBy.shred or 0) > 0,
                "candidate must actually cast source-accepted Shred while target focuses another")
        else
            assert.is_true((result.pressedBy.claw or 0) > 0,
                "candidate must retain a real accepted Claw fallback while target focuses player")
        end
    end
end

describe("Feral DPS standalone Current vs Candidate vs shipped native v0.8.5", function()
    for _, notTargeted in ipairs({ true, false }) do
        for _, profile in ipairs({ "current", "candidate", "shipped" }) do
            it(profile .. " vs "
                .. (notTargeted and "other target" or "own target"), function()
                runOne(profile, notTargeted)
            end)
        end
    end
end)


-- Feral DPS P1: the shipped/Current/Candidate priority's level-specific
-- Cat unlock chain, not a level-60 Cat fixture with an edited "level" field.
-- Use the pinned source WoWSims Feral talent order cut to legal points,
-- source DB2 learn table and original Energy/ComboPoints observer. Correct
-- two specific source-file hotfix/rank gaps and screen an unbought talent.
-- Neither the target-interest bit nor the headless world's damage is proof
-- of character facing, realistic level-specific gear, threat or DPS.
local ws = require("Forever.helpers.wowsims")
local LEARN_FERAL = setmetatable({
    -- Druid.lua's own hotfix 113554 explicitly says rank 1 Bite at 24;
    -- generated learn_druid has no 1328618 entry, so its fallback level 1
    -- would wrongly expose a lvl-24 Cat finisher at level 20.
    [1328618] = 24,
    -- The FB rank-copy set contains Forever ID 1289142 with no trainer
    -- learn row either. It MUST NOT be treated as lvl-1 at our lvl-20/24
    -- boundary. Hold that unknown variant out of these controlled
    -- early-level worlds; do not claim it is forever unlearnable.
    [1289142] = math.huge,
    -- Source Druid rank lists also contain Forever-specific last ranks
    -- for Rake (1289140) and Rip (1289141), neither with any DB2
    -- trainer row. If left unfiltered, the generic level helper's
    -- fallback of 1 silently grants Rake at 20 and replaces the
    -- actual level-20 rank of Rip with an unlevelled high copy.
    -- Hold these variants out of this 20-24 experiment only.
    [1289140] = math.huge,
    [1289141] = math.huge,
    -- No pinned 1-60 trainer level for this external Berserk ability;
    -- we must not silently treat its absent learn row as level 1.
    [417141] = math.huge,
}, { __index = ws.learn("DRUID") })
local FERAL_TALENTS = ws.header("druid_feral").talents

local function catUnlockContent(level, notTargeted)
    local observe = {}
    for key, value in pairs(stock.OBSERVE) do observe[key] = value end
    observe.notTargeted = notTargeted
    local base = setmetatable({
        OBSERVE = observe,
        WORLD = setmetatable({
            mobHealth = 1000000000,
            mobPeriod = 2.0,
            mobDamage = { 1, 2 },
            attackers = 1,
        }, { __index = stock.WORLD }),
    }, { __index = stock })
    local C = ws.content(base, {
        pack = stock.PACK, level = level, learn = LEARN_FERAL,
        talents = FERAL_TALENTS,
    })
    local oldCharacter = C.character
    function C.character()
        local c = oldCharacter()
        -- Feral base world includes Shifting Power in its lvl-60 kit,
        -- but the source class defines it as Feral talent 1322605.
        -- Merely running ws.content's trainer-rank filter would keep
        -- this level-1 DB2 spell even before buying the talent.
        local learnedShift = c.talents and c.talents[1322605]
            and c.talents[1322605] > 0
        -- Druid.lua FEROCIOUS_BITE rank list: first rank 1328618 is
        -- explicitly at 24; any higher/unknown copy cannot be learned
        -- before that first rank. The generated learn table lacks two
        -- rank rows, so explicitly model the earliest legal *family*
        -- unlock as well as individual DB2 ranks.
        local biteRanks = {
            [1328618] = true, [22568] = true, [22827] = true,
            [22828] = true, [22829] = true, [31018] = true,
            [1289142] = true,
        }
        local known = {}
        for _, id in ipairs(c.known) do
            local falseTalent = id == 1322605 and not learnedShift
            local unlearnedBite = level < 24 and biteRanks[id]
            if not falseTalent and not unlearnedBite then
                known[#known + 1] = id
            end
        end
        c.known = known
        return c
    end
    C.OBSERVE = observe -- materialise own keys; OBS-006 regression
    return C
end

local function catUnlock(profile, level, notTargeted)
    local content = catUnlockContent(level, notTargeted)
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    local entry = profile == "candidate" and CANDIDATE or current()
    if profile ~= "shipped" then installed(H, content, entry) end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    if H.Hekili.DB.profile.toggles.minor_cooldowns then
        H.Hekili.DB.profile.toggles.minor_cooldowns.value = true
    end

    local S = H.Hekili.State
    local known = {
        cat = S:IsKnown("cat_form"),
        claw = S:IsKnown("claw"),
        shred = S:IsKnown("shred"),
        rake = S:IsKnown("rake"),
        rip = S:IsKnown("rip"),
        bite = S:IsKnown("ferocious_bite"),
        shift = S:IsKnown("shifting_power"),
    }
    local originalCharacter = content.character()
    local talents = originalCharacter.talents
    local shredRank = talents and talents[16966] or 0
    local seenBiteRanks = {}
    local biteRanks = {
        [1328618] = true, [22568] = true, [22827] = true,
        [22828] = true, [22829] = true, [31018] = true,
        [1289142] = true,
    }
    for _, id in ipairs(originalCharacter.known) do
        if biteRanks[id] then seenBiteRanks[#seenBiteRanks + 1] = id end
    end
    print("FERAL_CAT_KIT_V085 L" .. level
        .. " biteRanks=" .. pretty.write(seenBiteRanks, "")
        .. " sourceKnownBite=" .. tostring(known.bite))
    if level < 24 then
        assert.are.same({}, seenBiteRanks,
            "fixture still grants a rank of Bite before its first source unlock")
    end
    assert.is_true(known.cat and known.claw and known.rip)
    assert.are.equal(level >= 22, known.shred)
    assert.are.equal(level >= 24, known.rake)
    assert.are.equal(level >= 24, known.bite)
    assert.is_false(known.shift)
    assert.are.equal(math.min(3, level - 19), shredRank)
    assert.are.equal(3, L.form, "Cat must already be source-known at 20+")
    assert.are.equal(3, L.power.type, "Energy, not Bear Rage or caster Mana")
    assert.are.equal(100, content.WORLD.power)

    local cursor, observerCursor, enemySwingT = 0, 0, nil
    local distinctEnemySwings, maxObservedCP, observerCPEvents = 0, 0, 0
    local beforeNextSwing, series, repeatedReady = {}, {}, 0
    local acceptedTotal, energyMin, energyMax = 0, math.huge, -math.huge
    local sawRakeAura, sawRipAura, realPaidEnergy = false, false, 0
    local eventsPaid = 0
    local result = loop.run(L, SEED, {
        duration = 38,
        on = function(r, steps, t)
            -- The upstream observer's true combo-point stream; do not
            -- compare a post-press world CP to the pre-press client poll.
            local stream = steps[1].obs.s
            for i = observerCursor + 1, stream.n do
                if stream.ev[i] == "@power" and stream.a1[i] == 4 then
                    observerCPEvents = observerCPEvents + 1
                    maxObservedCP = math.max(maxObservedCP, tonumber(stream.a2[i]) or 0)
                end
            end
            observerCursor = stream.n
            local accepted = r.pressed[r.combat]
            if accepted then
                acceptedTotal = acceptedTotal + 1
                beforeNextSwing[accepted] = (beforeNextSwing[accepted] or 0) + 1
            end
            energyMin = math.min(energyMin, r.us.power)
            energyMax = math.max(energyMax, r.us.power)
            local enemy = r.us.target
            for _, aura in ipairs({ "rake", "rip" }) do
                local data = H.Hekili.Class.auras[aura]
                local active = data and enemy and enemy.auras[data.id]
                if active and active.expires > r.W.t then
                    if aura == "rake" then sawRakeAura = true
                    else sawRipAura = true end
                end
            end
            local advancedEnemySwing = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.src == r.us and (ev.kind == "cast" or ev.kind == "strike")
                    and ev.pt == 3 and (ev.cost or 0) > 0 then
                    eventsPaid = eventsPaid + 1
                    realPaidEnergy = realPaidEnergy + ev.cost
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= enemySwingT then
                    enemySwingT = ev.t
                    distinctEnemySwings = distinctEnemySwings + 1
                    advancedEnemySwing = true
                end
            end
            cursor = #r.W.truth
            if advancedEnemySwing then
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                local action = rec.actionName or "NO_ACTION"
                -- One physical hostile swing represents a real source-world
                -- transition. A genuinely imminent first icon held three
                -- such transitions without an accepted corresponding press
                -- is a repeated-fallback failure; a forecast wait is not.
                series[#series + 1] = {
                    t = t, action = action, wait = rec.wait,
                    energyTrue = r.us.power,
                    cpTrue = r.W.res(r.us, 4),
                    cpClient = H.ctl.power and H.ctl.power[4],
                    acceptedSince = beforeNextSwing,
                }
                beforeNextSwing = {}
                if #series >= 3 then
                    local a, b, c = series[#series - 2], series[#series - 1], series[#series]
                    if a.action ~= "NO_ACTION" and a.action == b.action and b.action == c.action
                        and (a.wait or 0) <= 0.05 and (b.wait or 0) <= 0.05
                        and (c.wait or 0) <= 0.05
                        and (b.acceptedSince[a.action] or 0) == 0
                        and (c.acceptedSince[a.action] or 0) == 0 then
                        repeatedReady = repeatedReady + 1
                    end
                end
            end
        end,
    }, { { H = H } })

    local head = {}
    for i = 1, math.min(4, #series) do head[i] = series[i] end
    print("FERAL_CAT_UNLOCK_V085 " .. profile .. " L" .. level .. "/"
        .. (notTargeted and "target-other" or "target-player")
        .. " " .. pretty.write({
            release = "v0.8.5", seed = SEED,
            revision = profile ~= "shipped" and entry.revision or "shipped",
            sha256 = profile ~= "shipped" and entry.sha256 or nil,
            level = level, known = known, improvedShredRank = shredRank,
            rawTalentPoints = level - 9,
            accepted = result.pressedBy, refused = result.refused,
            paidEnergyEvents = eventsPaid, paidEnergy = realPaidEnergy,
            energyMin = energyMin, energyMax = energyMax,
            observerCPEvents = observerCPEvents, maxObserverCP = maxObservedCP,
            acceptedTotal = acceptedTotal,
            distinctEnemySwings = distinctEnemySwings,
            repeatedReady = repeatedReady, samples = head,
            rakeAura = sawRakeAura, ripAura = sawRipAura,
            errors = result.errors, raises = result.raises,
        }, ""))
    assert.are.equal(0, result.errors)
    assert.are.equal(0, result.raises)
    assert.are.same({}, result.refused, "source-world refused a level-reachable attack")
    assert.is_true(distinctEnemySwings >= 3)
    assert.are.equal(0, repeatedReady,
        "three immediately-ready first icons recurred after real swings, without accepted press")
    assert.is_true((result.pressedBy.claw or 0) + (result.pressedBy.shred or 0)
        + (result.pressedBy.rake or 0) >= 2,
        "no source-accepted early Cat builders")
    assert.is_true(eventsPaid > 0 and realPaidEnergy > 0,
        "source Energy costs were missing or accidentally free")
    assert.is_true(energyMin < energyMax, "no genuine Energy regeneration/spending")
    assert.is_true(observerCPEvents > 0 and maxObservedCP > 0,
        "the actual source CP observer never delivered builder gain")
    if level < 22 then assert.is_nil(result.pressedBy.shred) end
    if level < 24 then
        assert.is_nil(result.pressedBy.rake)
        assert.is_false(sawRakeAura)
        assert.is_nil(result.pressedBy.ferocious_bite)
    end
    assert.is_nil(result.pressedBy.shifting_power)
    if profile == "candidate" and level >= 22 and notTargeted then
        assert.is_true((result.pressedBy.shred or 0) > 0,
            "known, affordable Shred was never source-accepted with other-target heuristic")
    end
    if profile == "candidate" and not notTargeted then
        assert.is_true((result.pressedBy.claw or 0) > 0,
            "known source Claw fallback failed when target focused the player")
    end
end

describe("Feral Cat level 20/21/22/24 unlocks, source-talent cuts and safe final tail, v0.8.5", function()
    for _, level in ipairs({ 20, 21, 22, 24 }) do
        for _, notTargeted in ipairs({ true, false }) do
            for _, profile in ipairs({ "current", "candidate", "shipped" }) do
                it(profile .. " L" .. level .. " "
                    .. (notTargeted and "target-other" or "target-player"), function()
                    catUnlock(profile, level, notTargeted)
                end)
            end
        end
    end
end)


-- Issue #30 Feral DPS pre-Cat bridge (1-19), source v0.8.5.
-- The previously tested Cat source world's closure spends ENERGY, whereas
-- the actual pre-Cat class uses Mana as caster and Rage in Bear. Merely
-- changing the character power.type without changing the source resolver
-- would incorrectly price spells as FREE (FORM-009).
--
-- Therefore use the SAME SOURCE DRUID class's released Balance/MANA
-- resolver for 1-9 and Guardian/RAGE resolver for 10-19, retaining the
-- Feral shipped pack/spec and independently importing the Feral APLs.
-- These are two *separate* start-state worlds, NOT a reproduced 9->10
-- form switch or a live-levelled character. The Balance base retains
-- its level-60 4000 Mana/Spirit and the Guardian source has no Mana
-- pool: caster proves costed spells but NOT level-realistic OOM; Bear
-- proves Rage/Maul but NOT the Mana cost of entering Bear. True combat
-- costs, ranks, talents, buffs and swing events are never forged.
local precatCasterBase = require("Forever.helpers.druid_loop_world").Balance
local precatBearBase = require("Forever.helpers.druid_loop_world").Guardian
local precatForm = require("Forever.helpers.druid_loop_world").FORM
local precatCasterKeys = { "wrath", "moonfire", "mark_of_the_wild", "thorns" }
local precatBearKeys = {
    "bear_form", "cat_form", "aquatic_form", "travel_form",
    "maul", "swipe_bear", "demoralizing_roar", "enrage",
    "faerie_fire", "mark_of_the_wild", "thorns",
}
local precatSeed = 30417
local function precatContent(level)
    local caster = level < 10
    local source = caster and precatCasterBase or precatBearBase
    local keys = caster and precatCasterKeys or precatBearKeys
    local allowed = {}
    -- Source IDS must come from the actual class/source kit, not invented.
    source.character()
    for _, key in ipairs(keys) do
        for _, id in ipairs(assert(source.IDS[key], key)) do
            allowed[id] = true
        end
    end
    local base = setmetatable({
        PACK = stock.PACK,
        SPEC = stock.SPEC,
        character = function()
            local c = source.character()
            local known = {}
            for _, id in ipairs(c.known) do
                if allowed[id] then known[#known + 1] = id end
            end
            c.known = known
            -- At 1-9 there are no talents and no forms at all.
            if caster then
                c.talents, c.form = {}, 0
            else
                -- This source starts in Bear. Form-change Mana cost cannot
                -- be tested from this guardian Rage-only closure.
                c.talents = {}
            end
            return c
        end,
        WORLD = setmetatable({
            mobHealth = 1000000000,
            mobDamage = { 1, 2 },
            mobPeriod = 2.0,
            attackers = caster and 1 or 2,
        }, { __index = source.WORLD }),
    }, { __index = source })
    local C = ws.content(base, {
        pack = stock.PACK,
        level = level,
        learn = LEARN_FERAL,
        talents = caster and {} or FERAL_TALENTS,
    })
    C.SPEC = stock.SPEC
    C.OBSERVE = {}
    for k, v in pairs(source.OBSERVE) do C.OBSERVE[k] = v end
    return C
end

local function precatScenario(profile, level)
    local caster = level < 10
    local C = precatContent(level)
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    local e = profile == "candidate" and CANDIDATE or current()
    if profile ~= "shipped" then installed(H, C, e) end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    if H.Hekili.DB.profile.toggles.minor_cooldowns then
        H.Hekili.DB.profile.toggles.minor_cooldowns.value = false
    end

    local S = H.Hekili.State
    local known = {
        cat = S:IsKnown("cat_form"), bear = S:IsKnown("bear_form"),
        wrath = S:IsKnown("wrath"), moonfire = S:IsKnown("moonfire"),
        mark = S:IsKnown("mark_of_the_wild"), thorns = S:IsKnown("thorns"),
        maul = S:IsKnown("maul"), demoroar = S:IsKnown("demoralizing_roar"),
        swipe = S:IsKnown("swipe_bear"), faerie_fire = S:IsKnown("faerie_fire"),
        enrage = S:IsKnown("enrage"), lacerate = S:IsKnown("lacerate"),
        primal_bite = S:IsKnown("primal_bite"),
    }
    assert.is_false(known.cat)
    assert.is_true(known.mark and known.thorns == (level >= 6))
    assert.are.equal(level >= 10, known.bear)
    assert.are.equal(level >= 10, known.maul)
    assert.are.equal(level >= 10, known.demoroar)
    assert.are.equal(level >= 16, known.swipe)
    assert.are.equal(level >= 18, known.faerie_fire)
    assert.is_false(known.lacerate)
    assert.is_false(known.primal_bite)
    assert.are.equal(caster, known.wrath)
    assert.are.equal(caster and level >= 4, known.moonfire)
    assert.are.equal(caster and 0 or 1, L.power.type)
    assert.are.equal(caster and 0 or precatForm.bear_form, L.form)
    if caster then
        assert.are.equal(4000, C.WORLD.power,
            "Balance source Mana is L60 and cannot validate authentic early OOM")
    end
    -- The same source Feral talent header is cut to its level points.
    local talents = C.character().talents or {}
    local total = 0
    for _, rank in pairs(talents) do total = total + rank end
    assert.is_true(total <= math.max(0, level - 9))

    local cursor, realSwings, spentManaEvents, spentRageEvents = 0, 0, 0, 0
    local maulQueue, maulStrikes, maulUnqueue, paidMaulStrikes, maulRageCost = 0, 0, 0, 0, 0
    local maulKnownID = not caster
        and H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.maul.id)
        or nil
    local acceptedCount, repeatedReady, maxTrueRage, maxTrueMana = 0, 0, 0, 0
    local since, snapshots, previousSwing = {}, {}, nil
    local run = loop.run(L, precatSeed, {
        duration = caster and 30 or 45,
        on = function(r, _, t)
            local accepted = r.pressed[r.combat]
            if accepted then
                acceptedCount = acceptedCount + 1
                since[accepted] = (since[accepted] or 0) + 1
            end
            if caster then maxTrueMana = math.max(maxTrueMana, r.us.power)
            else maxTrueRage = math.max(maxTrueRage, r.us.power) end

            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.src == r.us and (ev.kind == "cast" or ev.kind == "strike")
                    and (ev.cost or 0) > 0 then
                    if ev.pt == 0 then spentManaEvents = spentManaEvents + 1 end
                    if ev.pt == 1 then spentRageEvents = spentRageEvents + 1 end
                end
                -- Maul is QUEUED off-GCD and its REAL Rage cost is paid
                -- at the later weapon strike. The World truth strike stores
                -- its cost under ev.cost but does NOT set ev.pt=RAGE.
                -- Never infer a free attack from the absent generic pt.
                if not caster and ev.src == r.us and ev.spell == maulKnownID then
                    if ev.kind == "queue" then
                        maulQueue = maulQueue + 1
                    elseif ev.kind == "strike" then
                        maulStrikes = maulStrikes + 1
                        if (ev.cost or 0) > 0 then
                            paidMaulStrikes = paidMaulStrikes + 1
                            maulRageCost = maulRageCost + ev.cost
                            spentRageEvents = spentRageEvents + 1
                        end
                    elseif ev.kind == "unqueue" then
                        maulUnqueue = maulUnqueue + 1
                    end
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= previousSwing then
                    previousSwing = ev.t
                    realSwings = realSwings + 1
                    local out = H.Hekili.Engine.Output.Primary
                    local rec = out.count > 0 and out.recs[1] or {}
                    local action = rec.actionName or "NO_ACTION"
                    if action ~= "NO_ACTION" and action ~= "wait" then
                        assert.is_true(S:IsKnown(action),
                            "unknown " .. action .. " first icon at level " .. level)
                    end
                    snapshots[#snapshots + 1] = {
                        t = t, action = action, wait = rec.wait,
                        truePower = r.us.power, acceptedSince = since,
                    }
                    since = {}
                    if #snapshots >= 3 then
                        local a, b, c = snapshots[#snapshots - 2],
                            snapshots[#snapshots - 1], snapshots[#snapshots]
                        if a.action ~= "NO_ACTION" and a.action == b.action
                            and b.action == c.action
                            and (a.wait or 0) <= 0.05
                            and (b.wait or 0) <= 0.05
                            and (c.wait or 0) <= 0.05
                            and (b.acceptedSince[a.action] or 0) == 0
                            and (c.acceptedSince[a.action] or 0) == 0 then
                            repeatedReady = repeatedReady + 1
                        end
                    end
                end
            end
            cursor = #r.W.truth
            assert.are.equal(caster and 0 or precatForm.bear_form, r.us.form,
                "Feral pre-Cat source unexpectedly changed its main resource/form")
        end,
    }, { { H = H } })

    local first = {}
    for i = 1, math.min(#snapshots, 4) do first[i] = snapshots[i] end
    print("FERAL_PRECAT_BRIDGE_V085 " .. profile .. " L" .. level
        .. " " .. (caster and "source-Mana" or "source-Rage") .. " "
        .. pretty.write({
            release = "v0.8.5", seed = precatSeed,
            sha256 = profile ~= "shipped" and e.sha256 or nil,
            level = level, source = caster and "Balance-Mana" or "Guardian-Rage",
            known = known, talentPointsSpent = total,
            powerType = L.power.type, maxTrueRage = maxTrueRage,
            maxTrueMana = maxTrueMana, realSwings = realSwings,
            paidManaEvents = spentManaEvents, paidRageEvents = spentRageEvents,
            maulQueue = maulQueue, maulStrikes = maulStrikes,
            maulUnqueue = maulUnqueue, paidMaulStrikes = paidMaulStrikes,
            maulRageCost = maulRageCost,
            acceptedCount = acceptedCount, accepted = run.pressedBy,
            refused = run.refused, errors = run.errors, raises = run.raises,
            repeatedReady = repeatedReady, firstFour = first,
        }, ""))

    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    assert.are.same({}, run.refused, "pre-Cat source rejected a recommended spell")
    assert.is_true(realSwings >= 3,
        "cannot use zero-event fixture as proof of fallback safety")
    assert.are.equal(0, repeatedReady,
        "first immediately-ready recommendation repeated 3 enemy swings unaccepted")
    assert.is_nil(run.pressedBy.cat_form)
    assert.is_nil(run.pressedBy.shifting_power)
    assert.is_nil(run.pressedBy.primal_bite)
    assert.is_nil(run.pressedBy.lacerate)
    if caster then
        assert.is_nil(run.pressedBy.bear_form)
        assert.is_nil(run.pressedBy.maul)
        if level < 4 then assert.is_nil(run.pressedBy.moonfire) end
        if profile ~= "shipped" then
            assert.is_true((run.pressedBy.wrath or 0) >= 1,
                "Feral custom caster fallback never cast affordable Wrath")
            assert.is_true(acceptedCount >= 2)
            if level >= 4 then
                assert.is_true((run.pressedBy.moonfire or 0) >= 1,
                    "Feral custom caster branch did not apply unlocked Moonfire")
            end
            assert.is_true(spentManaEvents >= 1,
                "source Mana caster resolver returned unpriced combat spells")
        end
    else
        assert.is_nil(run.pressedBy.wrath)
        assert.is_nil(run.pressedBy.moonfire)
        assert.is_true(maxTrueRage > 0,
            "Bear source never generated real Rage from combat")
        if level < 16 then assert.is_nil(run.pressedBy.swipe_bear) end
        if level < 18 then assert.is_nil(run.pressedBy.faerie_fire) end
        -- A real paid next-swing Maul is mandatory for the custom APL,
        -- not merely an accepted off-GCD queue.
        assert.is_true(maulStrikes <= maulQueue,
            "Maul struck more often than true source queue events")
        assert.is_true(maulStrikes + maulUnqueue <= maulQueue,
            "Maul strikes/unqueues exceeded actual source queues")
        if profile ~= "shipped" then
            assert.is_true((run.pressedBy.maul or 0) >= 1,
                "Feral custom Bear final tail never queued Maul")
            assert.is_true(spentRageEvents >= 1 and paidMaulStrikes >= 1
                and maulRageCost > 0,
                "Feral custom Bear never executed a genuinely Rage-paid Maul strike")
        end
    end
end

describe("Feral DPS pre-Cat source-Mana 1/4/6/9 and source-Rage Bear 10/12/16/18/19, v0.8.5", function()
    for _, level in ipairs({ 1, 4, 6, 9, 10, 12, 16, 18, 19 }) do
        for _, profile in ipairs({ "current", "candidate", "shipped" }) do
            it(profile .. " level " .. level .. " source-specific pre-Cat bridge", function()
                precatScenario(profile, level)
            end)
        end
    end
end)


-- Feral DPS P1: new mid-kit Cat level/rank and real-world finisher tail.
-- Reuse PR #71's legal Feral rank-family filter and source WoWSims
-- level-cut talent order, without replaying its already-green L20-24
-- worlds, mutating actual spellbooks after the build, or copying an APL.
-- Cases: first after the L25 primal_bite trainer boundary, actual first
-- Cat rank upgrades at L28/L30/L32/L34, and later selected talents L50.
-- Target-interest is NOT a real character-behind / positional oracle.
local midkitLevels = { 25, 28, 30, 32, 34, 50 }
local midkitRankBoundaries = {
    { id = 3029, level = 28, key = "claw-rank2" },
    { id = 9492, level = 28, key = "rip-rank2" },
    { id = 6800, level = 30, key = "shred-rank2" },
    { id = 22568, level = 32, key = "ferocious-bite-rank2" },
    { id = 1823, level = 34, key = "rake-rank2" },
}

local function midkitScenario(profile, level, notTargeted)
    -- catUnlockContent keeps the full source Cat/Energy and separate
    -- Mana pool, while refusing false early access to unlevelled
    -- Forever-specific rank copies; later unknown variant acquisition
    -- is NOT proved by this bracket.
    local C = catUnlockContent(level, notTargeted)
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    local entry = profile == "candidate" and CANDIDATE or current()
    if profile ~= "shipped" then installed(H, C, entry) end

    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    if H.Hekili.DB.profile.toggles.minor_cooldowns then
        H.Hekili.DB.profile.toggles.minor_cooldowns.value = true
    end
    local S = H.Hekili.State
    local char = C.character()
    local knownByID = {}
    for _, id in ipairs(char.known) do knownByID[id] = true end
    for _, info in ipairs(midkitRankBoundaries) do
        assert.are.equal(level >= info.level, not not knownByID[info.id],
            "source known rank boundary: " .. info.key .. " at L" .. level)
    end
    local talents = char.talents or {}
    local points = 0
    for _, n in pairs(talents) do points = points + n end
    assert.is_true(points <= level - 9)
    assert.is_true(S:IsKnown("cat_form") and S:IsKnown("claw")
        and S:IsKnown("shred") and S:IsKnown("rake")
        and S:IsKnown("rip") and S:IsKnown("ferocious_bite"))
    assert.are.equal((talents[1322605] or 0) > 0,
        S:IsKnown("shifting_power"),
        "Shifting Power must be bought in Feral tree, not granted by DB2 lvl1")
    assert.is_false(S:IsKnown("berserk"),
        "unknown Berserk trainer/talent acquisition is out of this bounded fixture")
    assert.are.equal(3, L.form)
    assert.are.equal(3, L.power.type)
    assert.are.equal(100, C.WORLD.power)

    local energyMin, energyMax = math.huge, -math.huge
    local observerCPEvents, maxObserverCP, observerCursor = 0, 0, 0
    local maxTrueCP, clearcastingSeen = 0, false
    local ripSeen, rakeSeen, lowEnergyWindows = false, false, 0
    local highCPHighEnergyWindows, highCPHighEnergyIdle = 0, 0
    local castPaidEnergy, manaPaidShift, otherManaSpend = 0, 0, 0
    local zeroCostEnergyCasts, truthCursor = 0, 0
    local swings, lastSwing, repeatedReady = 0, nil, 0
    local since, samples, lastThreeEnergy = {}, {}, {}
    local acceptedCount = 0
    local result = loop.run(L, SEED, {
        duration = 74,
        on = function(r, steps, t)
            local stream = steps[1].obs.s
            for i = observerCursor + 1, stream.n do
                if stream.ev[i] == "@power" and stream.a1[i] == 4 then
                    observerCPEvents = observerCPEvents + 1
                    maxObserverCP = math.max(maxObserverCP,
                        tonumber(stream.a2[i]) or 0)
                end
            end
            observerCursor = stream.n

            local accepted = r.pressed[r.combat]
            if accepted then
                acceptedCount = acceptedCount + 1
                since[accepted] = (since[accepted] or 0) + 1
            end
            energyMin = math.min(energyMin, r.us.power)
            energyMax = math.max(energyMax, r.us.power)
            local trueCP = r.W.res(r.us, 4)
            maxTrueCP = math.max(maxTrueCP, trueCP)
            local mana = r.W.res(r.us, 0)
            local X = H.Hekili.Class.auras
            local cc = X.clearcasting and r.us.auras[X.clearcasting.id]
            if cc and cc.expires > r.W.t then clearcastingSeen = true end
            local target = r.us.target
            local rip = X.rip and target and target.auras[X.rip.id]
            local rake = X.rake and target and target.auras[X.rake.id]
            if rip and rip.expires > r.W.t then ripSeen = true end
            if rake and rake.expires > r.W.t then rakeSeen = true end
            local ripRemains = rip and math.max(0, rip.expires - r.W.t) or 0
            local newSwing = false
            for i = truthCursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.src == r.us and (ev.kind == "cast" or ev.kind == "strike") then
                    if ev.pt == 3 then
                        if (ev.cost or 0) > 0 then
                            castPaidEnergy = castPaidEnergy + 1
                        else
                            zeroCostEnergyCasts = zeroCostEnergyCasts + 1
                        end
                    elseif ev.pt == 0 and (ev.cost or 0) > 0 then
                        if ev.spell == H.ns.VirtualState.KnownID(
                            H.Hekili.Class.abilities.shifting_power.id) then
                            manaPaidShift = manaPaidShift + 1
                        else
                            otherManaSpend = otherManaSpend + 1
                        end
                    end
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= lastSwing then
                    lastSwing = ev.t
                    swings = swings + 1
                    newSwing = true
                end
            end
            truthCursor = #r.W.truth
            if newSwing then
                local output = H.Hekili.Engine.Output.Primary
                local rec = output.count > 0 and output.recs[1] or {}
                local action = rec.actionName or "NO_ACTION"
                local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                local floor = belief and belief.lo
                local sample = {
                    t = t, action = action, wait = rec.wait,
                    trueEnergy = r.us.power, energyLo = floor,
                    trueCP = trueCP, clientCP = H.ctl.power and H.ctl.power[4],
                    manaTruth = mana, ripRemaining = ripRemains,
                    since = since,
                }
                if #samples < 6 then samples[#samples + 1] = sample end
                if r.us.power < S.action.claw.cost and trueCP < 5 then
                    lowEnergyWindows = lowEnergyWindows + 1
                end
                if trueCP >= 5 and r.us.power >= 90 and ripRemains >= 8 then
                    highCPHighEnergyWindows = highCPHighEnergyWindows + 1
                    if action == "NO_ACTION" then
                        highCPHighEnergyIdle = highCPHighEnergyIdle + 1
                    end
                end
                lastThreeEnergy[#lastThreeEnergy + 1] = sample
                if #lastThreeEnergy > 3 then table.remove(lastThreeEnergy, 1) end
                if #lastThreeEnergy == 3 then
                    local a, b, c = lastThreeEnergy[1],
                        lastThreeEnergy[2], lastThreeEnergy[3]
                    if a.action ~= "NO_ACTION" and a.action == b.action
                        and b.action == c.action
                        and (a.wait or 0) <= 0.05
                        and (b.wait or 0) <= 0.05
                        and (c.wait or 0) <= 0.05
                        and (b.since[a.action] or 0) == 0
                        and (c.since[a.action] or 0) == 0 then
                        repeatedReady = repeatedReady + 1
                    end
                end
                since = {}
            end
        end,
    }, { { H = H } })

    print("FERAL_MIDKIT_FINISHER_V085 " .. profile .. " L" .. level
        .. "/" .. (notTargeted and "target-other" or "target-player")
        .. " " .. pretty.write({
            seed = SEED, release = "v0.8.5", level = level,
            revision = profile == "shipped" and "shipped" or entry.revision,
            sha256 = profile ~= "shipped" and entry.sha256 or nil,
            known = { rip = S:IsKnown("rip"), bite = S:IsKnown("ferocious_bite"),
                shift = S:IsKnown("shifting_power"), berserk = S:IsKnown("berserk") },
            talents = { ferocity = talents[16934] or 0,
                improvedShred = talents[16966] or 0,
                predatoryDiscipline = talents[1328613] or 0,
                shiftingPower = talents[1322605] or 0 },
            accepted = result.pressedBy, refused = result.refused,
            errors = result.errors, raises = result.raises,
            observerCPEvents = observerCPEvents, maxObserverCP = maxObserverCP,
            maxTrueCP = maxTrueCP, energyMin = energyMin, energyMax = energyMax,
            truePaidEnergyEvents = castPaidEnergy,
            truePaidShiftingPowerManaEvents = manaPaidShift,
            otherManaEvents = otherManaSpend,
            zeroCostEnergyCasts = zeroCostEnergyCasts,
            realSwings = swings, repeatedReady = repeatedReady,
            lowEnergyWindows = lowEnergyWindows, clearcastingSeen = clearcastingSeen,
            ripAura = ripSeen, rakeAura = rakeSeen,
            highCPHighEnergyWindows = highCPHighEnergyWindows,
            highCPHighEnergyNoAction = highCPHighEnergyIdle,
            firstSix = samples,
        }, ""))

    assert.are.equal(0, result.errors)
    assert.are.equal(0, result.raises)
    assert.are.same({}, result.refused,
        "real source world refused a finisher/build, not just a forecast wait")
    assert.is_true(swings >= 3,
        "insufficient hostile state advances for final-fallback checkpoint")
    assert.are.equal(0, repeatedReady,
        "first ready recommendation repeated three source swings without accepted action")
    assert.is_true(energyMin < energyMax,
        "world Energy never advanced naturally through spend and regen")
    assert.is_true(castPaidEnergy > 0,
        "source Energy action was not genuinely charged")
    assert.is_true(observerCPEvents > 0 and maxObserverCP >= 4,
        "actual native CP observer failed to emit a finisher-capable window")
    assert.is_true((result.pressedBy.claw or 0) +
        (result.pressedBy.shred or 0) + (result.pressedBy.rake or 0) > 2,
        "Cat builder never actually accepted")
    assert.is_true((result.pressedBy.rip or 0) >= 1 and ripSeen,
        "known Rip finisher was not accepted nor did source target carry its aura")
    assert.is_true(rakeSeen, "source Rake effect never reached the target")
    if (talents[1322605] or 0) == 0 then
        assert.is_nil(result.pressedBy.shifting_power)
    elseif (result.pressedBy.shifting_power or 0) > 0 then
        assert.is_true(manaPaidShift > 0,
            "accepted Shifting Power did not spend actual source Mana")
    end
    if profile == "candidate" and notTargeted then
        assert.is_true((result.pressedBy.shred or 0) > 0,
            "candidate failed source-accepted Shred in other-target heuristic")
    end
    if profile == "candidate" and not notTargeted then
        assert.is_true((result.pressedBy.claw or 0) > 0,
            "candidate lost source-accepted Claw in own-target fallback")
    end
    -- No mandatory Bite count: at full Rip uptime Bite is conditional
    -- on real CP/energy/remaining duration, including purchased PD.
    -- The log reports observed actual Bite and eligible/idle windows so
    -- a genuine omission can be investigated without invented oracle.
end

describe("Feral DPS midkit 25/28/30/32/34/50 source-unlock, CP finisher and energy tail, v0.8.5", function()
    for _, level in ipairs(midkitLevels) do
        for _, notTargeted in ipairs({ true, false }) do
            for _, profile in ipairs({ "current", "candidate", "shipped" }) do
                it(profile .. " L" .. level .. " "
                    .. (notTargeted and "other-target" or "own-target"), function()
                    midkitScenario(profile, level, notTargeted)
                end)
            end
        end
    end
end)
