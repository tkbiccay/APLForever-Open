-- Issue #30: high-kit Guardian v0.9.0 post-setup natural low-Rage tail.
-- Compare shipped, exact reported-working v1.0 and both Drafts (v1.1,
-- v1.2 Barkskin Candidates). No synthetic combat resource drain or fake buffs.
-- The source world has unmeasured incoming-damage Rage and mitigation, so
-- this is a bounded castability/wait test, not tank survival or DPS proof.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local ws = require("Forever.helpers.wowsims")
local stock = require("Forever.helpers.druid_loop_world").Guardian
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local learn = setmetatable({
    [417141] = math.huge, [1328617] = math.huge, [1328616] = 34,
}, { __index = ws.learn("DRUID") })
local seed = 30417

local function profiles()
    local out = { { name = "shipped" } }
    for _, e in ipairs(manifest) do
        -- Every protected Guardian revision is included: the explicit
        -- v1.2 Candidates file is NOT the current/working selection, but
        -- must receive the SAME natural-Rage, unlock and fallback checks.
        if e.apl_name == "Druid_Guardian" and
            (e.revision == "v1.0" or e.revision == "v1.1"
                or e.revision == "v1.2") then
            out[#out + 1] = { name = e.revision, entry = e }
        end
    end
    assert.are.equal(4, #out, "shipped + all 3 source-compatible Guardian revisions")
    assert.are.equal("v1.0", out[2].name)
    assert.are.equal("v1.1", out[3].name)
    assert.are.equal("v1.2", out[4].name)
    assert.are.equal(
        "roles/Druid/Candidates/APL_Druid_Guardian_v1.2_Draft.txt",
        out[4].entry.apl_file, "Guardian v1.2 must remain the unselected Candidate")
    assert.are.equal(
        "da358b7c04b47732966c47a91b7f6f5d32410f9077aabe2aac39252139a47b76",
        out[4].entry.sha256, "Guardian candidate content pin unexpectedly changed")
    return out
end

local function install(H, content, e, testOnlyMoveMaul)
    local f = assert(io.open(root .. "/" .. e.apl_file, "rb"))
    local source = assert(f:read("*a"))
    f:close()
    if testOnlyMoveMaul then
        -- Full standalone v1.1 source, changed in memory ONLY for this
        -- counterfactual. No catalogued or runtime APL file is modified.
        local damage = "actions+=/call_action_list,name=damage"
        local maul = "actions+=/call_action_list,name=rage_dump,if=buff.bear_form.up"
        local lines, foundDamage, foundMaul = {}, 0, 0
        for line in source:gmatch("[^\r\n]+") do
            if line == maul then
                foundMaul = foundMaul + 1
            elseif line == damage then
                foundDamage = foundDamage + 1
                lines[#lines + 1] = maul
                lines[#lines + 1] = line
            else
                lines[#lines + 1] = line
            end
        end
        assert.are.equal(1, foundDamage)
        assert.are.equal(1, foundMaul)
        source = table.concat(lines, "\n") .. "\n"
    end
    local lists, warnings = H.Hekili:ImportSimcAPL(e.apl_name, "APLForever", source, content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name),
            "standalone APL list not active: " .. name)
    end
    assert.are.same({}, H.errors)
end

local function examine(profile, attackers)
    local content = ws.content(stock, {
        pack = stock.PACK, level = 60, learn = learn,
        talents = ws.header("druid_guardian").talents,
        race = ws.race("druid_guardian"), gear = ws.gear("druid_guardian"),
    })
    content.WORLD.attackers = attackers
    content.WORLD.mobHealth = 1000000000
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    if profile.entry then install(H, content, profile.entry, profile.testOnlyMoveMaul) end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    assert.is_true(H.Hekili.State:IsKnown("bear_form"))
    assert.is_true(H.Hekili.State:IsKnown("maul"))
    assert.is_true(H.Hekili.State:IsKnown("lacerate"))
    assert.is_true(H.Hekili.State:IsKnown("primal_bite"))

    local cursor, hasCombatAction, lowSince = 0, false, nil
    local firstThree = {}
    local pressedAfterSetup = {}
    local acceptedBetween = {}
    local trackedCount, minRage = 0, math.huge
    local maxTrueRage, maxBeliefLo = 0, 0
    local trueHighTicks, estimatedReserveTicks, highTruthLowBelief = 0, 0, 0
    local swingCheckpoints, highSwingCheckpoints = 0, {}
    local maulFirst, maulQueued = 0, false
    local reserveGuardTicks, reserveGuardSamples, haveCosts = 0, {}, false
    local run = loop.run(L, seed, {
        duration = 70,
        on = function(r, _, t)
            local successful = r.pressed[r.combat]
            if successful then
                if successful == "lacerate" or successful == "primal_bite"
                    or successful == "swipe_bear" then
                    hasCombatAction = true
                end
                if hasCombatAction then
                    pressedAfterSetup[successful] = (pressedAfterSetup[successful] or 0) + 1
                    acceptedBetween[successful] = (acceptedBetween[successful] or 0) + 1
                end
            end
            local swings = 0
            for i = cursor + 1, #r.W.truth do
                local event = r.W.truth[i]
                if event.kind == "swing" and event.src and event.src.kind == "mob"
                    and event.dst and event.dst.guid == r.us.guid then
                    swings = swings + 1
                end
            end
            cursor = #r.W.truth
            if hasCombatAction and r.us.form == 1 then
                minRage = math.min(minRage, r.us.power)
                -- These are post-press source truth and latest engine belief:
                -- record separate maxima, not pretend they are a simultaneous
                -- client reading. 35/50 are the existing custom reserve floors.
                local output = H.Hekili.Engine.Output.Primary
                local rec = output.count > 0 and output.recs[1] or {}
                local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                local floor = belief and belief.lo or 0
                maxTrueRage = math.max(maxTrueRage, r.us.power)
                maxBeliefLo = math.max(maxBeliefLo, floor)
                if r.us.power >= 35 then trueHighTicks = trueHighTicks + 1 end
                if floor >= 35 then estimatedReserveTicks = estimatedReserveTicks + 1 end
                if r.us.power >= 35 and floor < 35 then
                    highTruthLowBelief = highTruthLowBelief + 1
                end
                -- Reconstruct the candidate's *current* reserve predicate
                -- from source-registered action costs and belief. Source
                -- Hekili may forecast a different decision time; this is a
                -- checkpoint diagnostic, not an assertion of action selection.
                local S = H.Hekili.State
                local known = function(k) return S:IsKnown(k) end
                local mc = tonumber(S.action.maul.cost)
                local pc = tonumber(S.action.primal_bite.cost)
                local lc = tonumber(S.action.lacerate.cost)
                local sc = tonumber(S.action.swipe_bear.cost)
                local count = tonumber(S.active_enemies)
                if mc and pc and lc and sc and count then
                    haveCosts = true
                    local allowed = known("maul")
                        and not S.buff.maul.up and not S.buff.clearcasting.up
                        and (known("primal_bite") or known("lacerate"))
                        and floor >= 35 and (count < 3 or floor >= 50)
                        and (not known("primal_bite") or floor >= mc + pc + 10)
                        and (not known("lacerate") or floor >= mc + lc + 10)
                        and (count < 2 or not known("swipe_bear")
                            or floor >= mc + sc + 10)
                    if allowed then
                        reserveGuardTicks = reserveGuardTicks + 1
                        if #reserveGuardSamples < 4 then
                            reserveGuardSamples[#reserveGuardSamples + 1] = {
                                t = t, rageTruth = r.us.power, rageFloor = floor,
                                targets = count, maulCost = mc, biteCost = pc,
                                lacerateCost = lc, swipeCost = sc,
                                first = rec.actionName or "NO_ACTION",
                                wait = rec.wait, accepted = successful,
                                queue = r.us.queued and r.us.queued.key,
                            }
                        end
                    end
                end
                if rec.actionName == "maul" then maulFirst = maulFirst + 1 end
                if r.us.queued and r.us.queued.key == "maul" then maulQueued = true end
                if swings > 0 then
                    swingCheckpoints = swingCheckpoints + 1
                    if r.us.power >= 35 and #highSwingCheckpoints < 3 then
                        highSwingCheckpoints[#highSwingCheckpoints + 1] = {
                            t = t, actualRage = r.us.power,
                            floor = floor, first = rec.actionName or "NO_ACTION",
                            wait = rec.wait, accepted = successful,
                            queued = r.us.queued and r.us.queued.key,
                        }
                    end
                end
                if r.us.power <= 25 then
                    lowSince = lowSince or t
                    if swings > 0 and #firstThree < 3 then
                        local output = H.Hekili.Engine.Output.Primary
                        local rec = output.count > 0 and output.recs[1] or {}
                        local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                        firstThree[#firstThree + 1] = {
                            t = t, action = rec.actionName or "NO_ACTION",
                            wait = rec.wait, press = successful,
                            rage = r.us.power, beliefLo = belief and belief.lo,
                            floor = rec.floors and rec.floors.rage,
                            queued = r.us.queued and r.us.queued.key,
                            sinceLast = acceptedBetween,
                        }
                        acceptedBetween = {}
                    end
                end
            end
        end,
    }, { { H = H } })

    -- The Maul line is an on-next-swing ability. Confirm a source-accepted
    -- queue actually reached a later natural swing and paid its cost; a queue
    -- press alone does not prove a strike. Resolve its known rank from source.
    local maulID = H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.maul.id)
    local maulQueues, maulStrikes, maulUnqueues, maulCostPaid = 0, 0, 0, 0
    for _, ev in ipairs(run.W.truth) do
        if ev.src == run.us and ev.spell == maulID then
            if ev.kind == "queue" then
                maulQueues = maulQueues + 1
            elseif ev.kind == "unqueue" then
                maulUnqueues = maulUnqueues + 1
            elseif ev.kind == "strike" then
                maulStrikes = maulStrikes + 1
                maulCostPaid = maulCostPaid + (ev.cost or 0)
            end
        end
    end
    print("GUARDIAN_HIGHKIT_TAIL_V090 " .. profile.name .. " " .. pretty.write({
        source = "v0.9.0", seed = seed, attackers = attackers,
        testOnlyMoveMaul = profile.testOnlyMoveMaul or false,
        sha256 = not profile.testOnlyMoveMaul
            and profile.entry and profile.entry.sha256 or nil,
        sourceBaseSha256 = profile.testOnlyMoveMaul
            and profile.entry and profile.entry.sha256 or nil,
        reachedSetup = hasCombatAction, lowSince = lowSince,
        actualMinRage = minRage, samples = firstThree,
        maxTrueRage = maxTrueRage, maxBeliefLo = maxBeliefLo,
        trueHighTicks = trueHighTicks, estimatedReserveTicks = estimatedReserveTicks,
        highTruthLowBelief = highTruthLowBelief,
        swingCheckpoints = swingCheckpoints, highSwingCheckpoints = highSwingCheckpoints,
        maulFirst = maulFirst, maulQueued = maulQueued,
        maulQueues = maulQueues, maulStrikes = maulStrikes,
        maulUnqueues = maulUnqueues, maulCostPaid = maulCostPaid,
        haveCosts = haveCosts, reserveGuardTicks = reserveGuardTicks,
        reserveGuardSamples = reserveGuardSamples,
        accepted = run.pressedBy, refused = run.refused,
        errors = run.errors, raises = run.raises,
    }, ""))

    assert.is_true(hasCombatAction,
        "never observed accepted Lacerate/Primal Bite/Swipe before low Rage")
    if attackers == 2 then
        assert.is_not_nil(lowSince, "true Rage never reached <=25 after real setup")
        assert.are.equal(3, #firstThree,
            "require 3 distinct enemy swings after setup and at <=25 true Rage")
    else
        assert.is_true(swingCheckpoints >= 3,
            "multi-attacker case never advanced through 3 genuine source mob swing checkpoints")
        -- No fabricated Rage or client omniscience: if >=35 believed Rage was
        -- never attained, state that absence as a result, not false proof of a
        -- structurally dead APL tail.  Report any real high-Rage windows.
    end
    assert.are.same({}, run.refused,
        "refused source-world casts: distinguish APL from engine/observer fault")
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    if attackers == 2 then
        assert.is_true(haveCosts,
            "cannot evaluate source-defined high-kit Maul reserve without real action costs")
    end
    if profile.testOnlyMoveMaul then
        assert.is_true(maulQueues >= 1 and maulStrikes >= 1,
            "test-only high-kit Maul queue was not consumed by a real later swing")
        assert.are.equal(0, maulUnqueues,
            "test-only high-kit Maul dropped at the swing rather than executing")
        assert.is_true(maulCostPaid > 0,
            "test-only queued Maul strike had no source-true Rage payment")
    end
    -- A repeated immediate icon across state advances must have had an
    -- accepted action or an actual wait; mere repeated polls do not count.
    if attackers == 2 then
        local a, b, c = unpack(firstThree)
        if a.action == b.action and b.action == c.action
            and a.action ~= "NO_ACTION"
            and (a.wait or 0) <= 0.05 and (b.wait or 0) <= 0.05
            and (c.wait or 0) <= 0.05 then
            local n = (b.sinceLast[a.action] or 0)
                + (c.sinceLast[a.action] or 0)
            assert.is_true(n > 0,
                "same immediately ready icon recurred at 3 true enemy swings without an accepted press")
        end
    end
end

describe("Guardian high-kit natural Rage-starved fallback on released v0.9.0", function()
    for _, profile in ipairs(profiles()) do
        it(profile.name .. " advances three real low-Rage swing checkpoints", function()
            examine(profile, 2)
        end)
        it(profile.name .. " records real Rage/belief divergence with three attackers", function()
            examine(profile, 3)
        end)
    end
    local candidate
    for _, p in ipairs(profiles()) do
        if p.name == "v1.1" then candidate = p end
    end
    assert.is_not_nil(candidate)
    it("test-only full v1.1 with three attackers moves unchanged Maul guards before damage", function()
        examine({
            name = "v1.1-test-only-reorder", entry = candidate.entry,
            testOnlyMoveMaul = true,
        }, 3)
    end)
end)


-- Issue #30: one import per authentic Guardian unlock bracket.  Source-native
-- Guardian starts in Bear here, so caster-form levels 1-9 are explicitly OUT
-- OF SCOPE rather than being represented by a fictitious level-9 Bear.
-- This is a naturally progressing world, not a forced exact-Rage matrix.
local function unlockBoundary(profile, level)
    local content = ws.content(stock, {
        pack = stock.PACK, level = level, learn = learn,
        talents = ws.header("druid_guardian").talents,
        race = ws.race("druid_guardian"), gear = ws.gear("druid_guardian"),
    })
    content.WORLD.attackers = 2
    content.WORLD.mobHealth = 1000000000
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    if profile.entry then install(H, content, profile.entry) end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    local state = H.Hekili.State
    local known = {
        bear = state:IsKnown("bear_form"),
        maul = state:IsKnown("maul"),
        primal_bite = state:IsKnown("primal_bite"),
        lacerate = state:IsKnown("lacerate"),
        faerie_fire = state:IsKnown("faerie_fire"),
    }
    -- These gates come from pinned Forever DB2 learn data plus the source
    -- hotfix rank override above; never infer them from Retail.
    -- Lacerate has two independent legitimate source unlocks, NOT just the
    -- level-34 trained rank: hotfix 113554 made rank 1 a Feral talent
    -- (1328617). The pinned Guardian header spends its 22nd Feral point
    -- on that talent at level 31; rank 2 (1328616) is trained at 34.
    local character = content.character()
    local talentLacerate = (character.talents[1328617] or 0) > 0
    local trainedRank2 = false
    for _, id in ipairs(character.known) do
        if id == 1328616 then trainedRank2 = true end
    end
    known.talentLacerate = talentLacerate
    known.trainedRank2 = trainedRank2
    assert.is_true(known.bear and known.maul)
    assert.are.equal(level >= 25, known.primal_bite)
    assert.are.equal(level >= 31, talentLacerate)
    assert.are.equal(level >= 34, trainedRank2)
    assert.are.equal(talentLacerate or trainedRank2, known.lacerate)
    assert.are.equal(level >= 18, known.faerie_fire)

    local cursor, lastMobSwing, swingTimes = 0, nil, 0
    local acceptedBetween, sample, observedActions = {}, {}, {}
    local acceptedTotal, immediateRun = 0, 0
    local run = loop.run(L, seed, {
        duration = 42,
        on = function(r, _, t)
            local accepted = r.pressed[r.combat]
            if accepted then
                acceptedBetween[accepted] = (acceptedBetween[accepted] or 0) + 1
                observedActions[accepted] = (observedActions[accepted] or 0) + 1
                acceptedTotal = acceptedTotal + 1
            end
            local distinctSwing = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst and ev.dst.guid == r.us.guid then
                    if lastMobSwing ~= ev.t then
                        lastMobSwing = ev.t
                        swingTimes = swingTimes + 1
                        distinctSwing = true
                    end
                end
            end
            cursor = #r.W.truth
            if distinctSwing and r.us.form == 1 then
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                local name = rec.actionName or "NO_ACTION"
                if name == "lacerate" or name == "primal_bite"
                    or name == "maul" or name == "faerie_fire" then
                    assert.is_true(state:IsKnown(name),
                        "locked ability recommended at source level " .. level .. ": " .. name)
                end
                sample[#sample + 1] = {
                    t = t, first = name, wait = rec.wait,
                    actualRage = r.us.power,
                    acceptedSince = acceptedBetween,
                }
                acceptedBetween = {}
                -- Non-polling repeated-fallback checkpoint: the exact same
                -- immediately-ready first icon must not survive three
                -- distinct incoming swing transitions without an accepted
                -- copy of that action in either intervening window.
                if #sample >= 3 then
                    local a, b, c = sample[#sample - 2], sample[#sample - 1], sample[#sample]
                    if a.first ~= "NO_ACTION" and a.first == b.first and b.first == c.first
                        and (a.wait or 0) <= 0.05
                        and (b.wait or 0) <= 0.05 and (c.wait or 0) <= 0.05
                        and (b.acceptedSince[a.first] or 0) == 0
                        and (c.acceptedSince[a.first] or 0) == 0 then
                        immediateRun = immediateRun + 1
                    end
                end
            end
        end,
    }, { { H = H } })

    local firstThree = {}
    for i = 1, math.min(3, #sample) do firstThree[i] = sample[i] end
    print("GUARDIAN_UNLOCK_V090 " .. profile.name .. " L" .. level .. " "
        .. pretty.write({
            seed = seed, source = "v0.9.0", sha256 = profile.entry and profile.entry.sha256,
            known = known, accepted = run.pressedBy, refusal = run.refused,
            observedActions = observedActions, acceptedTotal = acceptedTotal,
            swingTimes = swingTimes, repeatedImmediate = immediateRun,
            samples = firstThree, errors = run.errors, raises = run.raises,
        }, ""))
    assert.is_true(swingTimes >= 3,
        "no three genuinely distinct hostile swings during unlock scenario")
    assert.is_true(acceptedTotal >= 2,
        "no cast progression; failed repeated-recommendation gate would be vacuous")
    assert.are.equal(0, immediateRun,
        "same immediately ready icon repeated across three actual incoming swings without an accepted cast")
    assert.are.same({}, run.refused,
        "source-world refused a recommendation at a Guardian unlock boundary")
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    if not known.primal_bite then assert.is_nil(run.pressedBy.primal_bite) end
    if not known.lacerate then assert.is_nil(run.pressedBy.lacerate) end
end

describe("Guardian source-native 24/25, 30/31 talent and 34 rank unlock/fallback gates, v0.9.0", function()
    for _, level in ipairs({ 24, 25, 29, 30, 31, 34 }) do
        for _, profile in ipairs(profiles()) do
            it(profile.name .. " progresses through level " .. level .. " after real swings", function()
                unlockBoundary(profile, level)
            end)
        end
    end
end)


-- Issue #30: Guardian's pre-Bear levels 1-9 must NOT use the
-- level-60 Guardian Bear/Rage source world. Reuse the *same source Druid
-- class* in the pinned Balance fixture's caster/Mana mode, which registers
-- real Wrath and Moonfire costs, durations, spell effects and mana FSR.
-- The 4,000 mana and level-60 spirit are NOT level-specific: this proves
-- import/unlocks/cast progression, NOT realistic lvl 1-9 OOM or DPS.
local casterBase = require("Forever.helpers.druid_loop_world").Balance
local preBearSourceKeys = { "wrath", "moonfire", "mark_of_the_wild", "thorns" }

local function preBearContent(level)
    -- Guardian's source closure has pt=RAGE and ignores mana costs of
    -- foreign spells. Merely changing Guardian.character.power would
    -- incorrectly make Wrath/Moonfire FREE. Balance's source closure uses
    -- pt=MANA and models those exact spells; import Guardian's custom APL
    -- and retain Guardian's PACK/spec while in that model.
    local base = setmetatable({
        PACK = stock.PACK,
        SPEC = stock.SPEC,
        character = function()
            local c = casterBase.character()
            local allowed = {}
            for _, key in ipairs(preBearSourceKeys) do
                for _, id in ipairs(assert(casterBase.IDS[key], key)) do
                    allowed[id] = true
                end
            end
            local known = {}
            for _, id in ipairs(c.known) do
                if allowed[id] then known[#known + 1] = id end
            end
            c.known, c.talents, c.form = known, {}, 0
            return c
        end,
        WORLD = setmetatable({
            mobHealth = 1000000000,
            mobDamage = { 1, 2 },
            attackers = 1,
        }, { __index = casterBase.WORLD }),
    }, { __index = casterBase })
    local C = ws.content(base, {
        pack = stock.PACK, level = level, learn = learn, talents = {},
    })
    -- The source loop copies OBSERVE via pairs, so materialise own keys.
    C.OBSERVE = {}
    for k, v in pairs(casterBase.OBSERVE) do C.OBSERVE[k] = v end
    C.SPEC = stock.SPEC
    return C
end

local function preBearScenario(profile, level)
    local C = preBearContent(level)
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    if profile.entry then install(H, C, profile.entry) end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    local S = H.Hekili.State
    local known = {
        bear = S:IsKnown("bear_form"), maul = S:IsKnown("maul"),
        wrath = S:IsKnown("wrath"), moonfire = S:IsKnown("moonfire"),
        thorns = S:IsKnown("thorns"), mark = S:IsKnown("mark_of_the_wild"),
    }
    assert.is_false(known.bear)
    assert.is_false(known.maul)
    assert.is_true(known.wrath and known.mark)
    assert.are.equal(level >= 4, known.moonfire)
    assert.are.equal(level >= 6, known.thorns)
    assert.are.equal(0, L.power.type)
    assert.are.equal(0, L.form)
    assert.are.equal(4000, C.WORLD.power)

    local samples, realSwings, casts, repeats = {}, 0, 0, 0
    local acceptedSince, cursor, previousMobSwing = {}, 0, nil
    local manaSpends, manaStarting = 0, C.WORLD.power
    local run = loop.run(L, seed, {
        duration = 30,
        on = function(r, _, t)
            local accepted = r.pressed[r.combat]
            if accepted then
                acceptedSince[accepted] = (acceptedSince[accepted] or 0) + 1
                casts = casts + 1
            end
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.src == r.us and (ev.kind == "cast" or ev.kind == "strike")
                    and ev.pt == 0 and (ev.cost or 0) > 0 then
                    manaSpends = manaSpends + 1
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and previousMobSwing ~= ev.t then
                    previousMobSwing = ev.t
                    realSwings = realSwings + 1
                    local out = H.Hekili.Engine.Output.Primary
                    local rec = out.count > 0 and out.recs[1] or {}
                    local name = rec.actionName or "NO_ACTION"
                    if name == "wrath" or name == "moonfire" or name == "bear_form"
                        or name == "maul" then
                        assert.is_true(S:IsKnown(name),
                            "unknown source spell recommended at level " .. level .. ": " .. name)
                    end
                    local sample = {
                        t = t, first = name, wait = rec.wait,
                        mana = r.us.power, since = acceptedSince,
                    }
                    samples[#samples + 1] = sample
                    acceptedSince = {}
                    if #samples >= 3 then
                        local a, b, c = samples[#samples - 2], samples[#samples - 1], sample
                        if a.first ~= "NO_ACTION" and a.first == b.first and b.first == c.first
                            and (a.wait or 0) <= 0.05 and (b.wait or 0) <= 0.05
                            and (c.wait or 0) <= 0.05
                            and (b.since[a.first] or 0) == 0
                            and (c.since[a.first] or 0) == 0 then
                            repeats = repeats + 1
                        end
                    end
                end
            end
            cursor = #r.W.truth
            assert.are.equal(0, r.us.form, "pre-Bear world shifted despite unknown Bear Form")
        end,
    }, { { H = H } })
    local firstThree = {}
    for i = 1, math.min(#samples, 3) do firstThree[i] = samples[i] end
    print("GUARDIAN_PREBEAR_V090 " .. profile.name .. " L" .. level .. " "
        .. pretty.write({
            source = "v0.9.0", seed = seed,
            sha256 = profile.entry and profile.entry.sha256,
            known = known, manaType = L.power.type,
            manaStart = manaStarting, manaEnd = run.us.power,
            positiveManaSpendEvents = manaSpends,
            accepted = run.pressedBy, refusals = run.refused,
            realSwings = realSwings, acceptedCount = casts,
            repeatedImmediatelyReady = repeats, samples = firstThree,
            errors = run.errors, raises = run.raises,
        }, ""))
    assert.is_true(realSwings >= 3, "cannot validate a zero-event repeated fallback")
    assert.are.same({}, run.refused)
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    assert.are.equal(0, repeats)
    assert.is_nil(run.pressedBy.bear_form)
    assert.is_nil(run.pressedBy.maul)
    if level < 4 then assert.is_nil(run.pressedBy.moonfire) end
    if profile.entry then
        assert.is_true(casts >= 2, "custom pre-Bear APL never advanced genuine casts")
        assert.is_true((run.pressedBy.wrath or 0) >= 1,
            "custom low-level APL never cast known Wrath")
        if level >= 4 then
            assert.is_true((run.pressedBy.moonfire or 0) >= 1,
                "custom low-level APL never cast known Moonfire")
        end
        assert.is_true(manaSpends > 0,
            "source caster registered no positive Mana costs: fixture suspect")
    end
end

describe("Guardian pre-Bear source-Mana caster castability at levels 1-9, v0.9.0", function()
    for _, level in ipairs({ 1, 3, 4, 6, 9 }) do
        for _, profile in ipairs(profiles()) do
            it(profile.name .. " safely follows caster-form level " .. level, function()
                preBearScenario(profile, level)
            end)
        end
    end
end)
