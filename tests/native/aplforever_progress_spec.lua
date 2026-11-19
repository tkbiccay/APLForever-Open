-- Issue #30 pilot: actually press imported Warrior Protection recommendations
-- through the pinned source-native Forever world and cast driver. No fake
-- state advancement, ability IDs, resources, or combat results are invented.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")

local root = assert(os.getenv("APLFOREVER_ROOT"), "APLFOREVER_ROOT is required")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local fixture = {
    Druid = require("Forever.helpers.druid_loop_world"),
    Hunter = require("Forever.helpers.hunter_world"),
    Mage = require("Forever.helpers.mage_world"),
    Paladin = require("Forever.helpers.paladin_world"),
    Priest = require("Forever.helpers.priest_world"),
    Rogue = require("Forever.helpers.rogue_world"),
    Shaman = require("Forever.helpers.shaman_world"),
    Warlock = require("Forever.helpers.warlock_world"),
    Warrior = require("Forever.helpers.warrior_world"),
}

-- BM and MM Turret source worlds replaced the weave worlds in v0.9.0.
-- Legacy pins keep their exact older fixtures; later releases retain Turret.
local function usesTurretHunterFixture()
    local release = os.getenv("APLFOREVER_SOURCE_RELEASE") or "v0.8.2"
    local major, minor, patch = release:match("^v(%d+)%.(%d+)%.(%d+)$")
    assert(major and minor and patch, "invalid Forever source release: " .. release)
    return tonumber(major) > 0 or tonumber(minor) >= 9
end

local function contentFor(entry)
    if entry.apl_name == "Warrior_Protection" then
        return require("Forever.helpers.protection_gate").content()
    end
    local byClass = assert(fixture[entry.class], "no source fixture for " .. entry.class)
    if entry.class == "Warrior" and entry.spec == "Arms" then
        return byClass
    end
    -- Since published v0.9.0, retired BM/MM weave worlds ship only
    -- BeastMasteryTurret / MarksmanshipTurret. Older pinned v0.8.x
    -- workflows must retain their original BeastMastery / Marksmanship
    -- fixtures, not silently compare unlike reference builds.
    if entry.class == "Hunter"
        and (entry.spec == "BeastMastery" or entry.spec == "Marksmanship") then
        if usesTurretHunterFixture() then
            return assert(byClass[entry.spec .. "Turret"],
                "v0.9.0+ source lacks the expected Hunter Turret world for " .. entry.apl_name)
        end
        return assert(byClass[entry.spec],
            "legacy source lacks Hunter world for " .. entry.apl_name)
    end
    return assert(byClass[entry.spec], "no source fixture for " .. entry.apl_name)
end

local function read(path)
    local handle = assert(io.open(path, "rb"))
    local txt = handle:read("*a")
    handle:close()
    return txt
end

local function install(H, content, entry)
    local actual = read(root .. "/" .. entry.apl_file)
    local imported, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", actual, content.PACK)
    assert.is_table(imported)
    assert.is_table(imported.default)
    assert.is_true(#imported.default > 0)
    assert.is_table(imported.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = imported
    H.Hekili:LoadScripts()
    local inactive = {}
    for name in pairs(imported) do
        if not H.Hekili:IsListActive(content.PACK, name) then
            inactive[#inactive + 1] = name
        end
    end
    table.sort(inactive)
    -- The headless boot cached the shipped pack's lists. Replacing them
    -- directly requires the same review used by the native pack lifecycle.
    H.Hekili:ReviewPacks()
    for name in pairs(imported) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name), name)
    end
    print("PROGRESS_PACK " .. entry.apl_file .. " inactiveBeforeReview=" .. table.concat(inactive, ","))
    assert.are.same({}, H.errors)
end

describe("Elemental low-Mana Clearcasting observation", function()
    for _, custom in ipairs({ true, false }) do
        local label = custom and "custom" or "shipped"
        it("observes the " .. label .. " pack with a registered seeded proc", function()
            local stock = fixture.Shaman.Elemental
            local content = setmetatable({
                WORLD = setmetatable({ power = stock.WORLD.max * 0.20 }, { __index = stock.WORLD }),
            }, { __index = stock })
            local L = loop.new(content)
            local H = L.us
            if custom then
                for _, entry in ipairs(manifest) do
                    if entry.apl_name == "Shaman_Elemental" then install(H, content, entry) end
                end
            end
            local auras = H.Hekili.Class.auras
            local procID = assert(auras.clearcasting).id
            local shockID = assert(auras.flame_shock).id
            local toggles = H.Hekili.DB.profile.toggles
            toggles.cooldowns.value = false
            toggles.defensives.value = false
            local seeded = false
            local run = loop.run(L, 30417, {
                duration = 16,
                on = function(r, _, t)
                    if not seeded and t >= 3 and r.us.target then
                        r.W.applyAura(r.us, procID, auras.clearcasting.duration)
                        r.W.applyAura(r.us.target, shockID, 12)
                        seeded = true
                    elseif seeded then
                        local out = H.Hekili.Engine.Output.Primary
                        local rec = out.count > 0 and out.recs[1] or {}
                        local p = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                        local proc = r.us.auras[procID]
                        local cl = content.resolve("chain_lightning", H)
                        print("ELEMENTAL_P0 " .. label .. " " .. pretty.write({
                            t = t, action = rec.actionName, wait = rec.wait, script = rec.script,
                            forecast = rec.floors, press = r.pressed[r.combat], afterMana = r.us.power,
                            charge = proc and proc.stacks or 0, chainCost = cl.cost,
                            lo = p.lo, estimate = p.est, hi = p.hi,
                            chainCooldownUntil = r.us.cdUntil.chain_lightning,
                        }, ""))
                    end
                end,
            }, { { H = H } })
            assert.is_true(seeded)
            assert.are.equal(0, run.raises)
            assert.are.equal(0, run.errors)
            print("ELEMENTAL_RESULT " .. label .. " " .. pretty.write({
                pressed = run.pressedBy, refused = run.refused,
            }, ""))
        end)
    end
end)

describe("Retribution v0.8.2 seal and Mana observation", function()
    for _, fraction in ipairs({ 0.20, 1 }) do
        for _, custom in ipairs({ true, false }) do
            local label = (custom and "v1.2" or "shipped") .. "/" .. fraction
            it("observes " .. label .. " with the same Twist of Light kit", function()
                local stock = fixture.Paladin.Retribution
                local content = setmetatable({
                    WORLD = setmetatable({ power = stock.WORLD.max * fraction }, { __index = stock.WORLD }),
                }, { __index = stock })
                local L = loop.new(content)
                local H = L.us
                if custom then
                    for _, entry in ipairs(manifest) do
                        if entry.apl_name == "Paladin_Retribution" then install(H, content, entry) end
                    end
                end
                assert.is_table(H.Hekili.Class.auras.blessing_of_might)
                assert.is_nil(H.Hekili.Class.abilities.blessing_of_might)
                H.Hekili.DB.profile.toggles.cooldowns.value = false
                H.Hekili.DB.profile.toggles.defensives.value = false
                local decisions, cursor = {}, 0
                local run = loop.run(L, 30417, {
                    duration = 30,
                    on = function(r, _, t)
                        local out = H.Hekili.Engine.Output.Primary
                        local rec = out.count > 0 and out.recs[1] or {}
                        local press = r.pressed[r.combat]
                        if t >= 3 and t < 33 and (press or (#r.W.truth > cursor and #decisions < 3)) then
                            local p = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                            decisions[#decisions + 1] = {
                                t = t, action = rec.actionName, script = rec.script, wait = rec.wait,
                                forecast = rec.floors, press = press, mana = r.us.power,
                                belief = { lo = p.lo, est = p.est, hi = p.hi },
                                auras = pretty.write(r.us.auras, ""),
                                targetAuras = pretty.write(r.us.target and r.us.target.auras or {}, ""),
                            }
                        end
                        cursor = #r.W.truth
                    end,
                }, { { H = H } })
                print("RET_P0 " .. label .. " " .. pretty.write({
                    decisions = decisions, pressed = run.pressedBy, refused = run.refused,
                    endMana = run.us.power, attempts = run.attempts,
                }, ""))
                assert.are.equal(0, run.errors)
                assert.are.equal(0, run.raises)
            end)
        end
    end
end)

describe("DEMO-006 pinned low-mana comparison", function()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Warlock_Demonology" then
            it("observes the post-upkeep tail of " .. entry.revision, function()
                local stock = contentFor(entry)
                local content = setmetatable({
                    WORLD = setmetatable({ power = stock.WORLD.max * 0.20 }, { __index = stock.WORLD }),
                }, { __index = stock })
                local L = loop.new(content)
                local H = L.us
                install(H, content, entry)
                H.Hekili.DB.profile.toggles.cooldowns.value = false
                H.Hekili.DB.profile.toggles.defensives.value = false
                local run = loop.run(L, 30417, {
                    duration = 25,
                    on = function(r, _, t)
                        local out = H.Hekili.Engine.Output.Primary
                        local rec = out.count > 0 and out.recs[1] or {}
                        local press = r.pressed[r.combat]
                        if t >= 3 and t < 28 and (press or rec.actionName == "life_tap") then
                            local mana = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                            print("DEMO006 " .. entry.revision .. " " .. pretty.write({
                                t = t, engineTime = H.ctl.now, first = rec.actionName, wait = rec.wait,
                                script = rec.script, forecast = rec.floors, press = press,
                                afterPollMana = r.us.power, afterPollHealth = r.us.health,
                                afterPollBelief = { lo = mana.lo, est = mana.est, hi = mana.hi },
                                targetAuras = r.us.target and r.us.target.auras,
                            }, ""))
                        end
                    end,
                }, { { H = H } })
                print("DEMO006_RESULT " .. entry.revision .. " " .. pretty.write({
                    sha256 = entry.sha256, character = content.character(),
                    pressed = run.pressedBy, refused = run.refused, attempts = run.attempts,
                    endMana = run.us.power, endHealth = run.us.health,
                }, ""))
                assert.are.equal(0, run.errors)
                assert.are.equal(0, run.raises)
                if entry.revision == "v1.0" then
                    assert.is_nil(run.pressedBy.life_tap)
                end
            end)
        end
    end
end)

describe("Warrior Protection Revenge window", function()
    for _, attackers in ipairs({ 1, 2 }) do
        local label = attackers == 1 and "custom" or "custom-two-attackers"
        it("observes natural incoming avoidance with the " .. label .. " fixture", function()
            local content = require("Forever.helpers.protection_gate").content(14)
            if attackers == 2 then
                content.WORLD = setmetatable({ attackers = attackers }, { __index = content.WORLD })
            end
            local L = loop.new(content)
            local H = L.us
            for _, entry in ipairs(manifest) do
                if entry.apl_name == "Warrior_Protection" then install(H, content, entry) end
            end
            H.Hekili.DB.profile.toggles.cooldowns.value = false
            H.Hekili.DB.profile.toggles.defensives.value = false
            local cursor, avoid, count, expiry = 0, nil, 0, nil
            local run = loop.run(L, 30417, {
                duration = 60,
                on = function(r, _, t)
                    local events = {}
                    for i = cursor + 1, #r.W.truth do
                        local e = r.W.truth[i]
                        if e.kind == "swing" and e.dst == r.us and
                            (e.act == "DODGE" or e.act == "PARRY" or e.act == "BLOCK") then
                            avoid, count = e.t, count + 1
                            events[#events + 1] = { time = e.t, outcome = e.act }
                        end
                    end
                    cursor = #r.W.truth
                    if t < 3 or t >= 63 then return end
                    local out = H.Hekili.Engine.Output.Primary
                    local rec = out.count > 0 and out.recs[1] or {}
                    local press = r.pressed[r.combat]
                    local remaining = avoid and math.max(0, avoid + 5 - t) or 0
                    local expired = avoid and t > avoid + 5 and expiry ~= avoid
                    if expired then expiry = avoid end
                    if press or #events > 0 or expired or rec.actionName == "revenge" or t == 3 then
                        local p = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                        print("REVENGE_P0 " .. label .. " " .. pretty.write({
                            t = t, events = events, lastAvoid = avoid, worldWindow = remaining,
                            action = rec.actionName, wait = rec.wait, script = rec.script,
                            forecast = rec.floors, press = press, form = r.us.form,
                            afterPollRage = r.us.power, belief = { lo = p.lo, est = p.est, hi = p.hi },
                            targetAuras = r.us.target and r.us.target.auras,
                            cooldownUntil = r.us.cdUntil.revenge,
                        }, ""))
                    end
                    if press == "revenge" then
                        assert.is_true(avoid ~= nil and t - avoid <= 5, "Revenge accepted outside world window")
                    end
                end,
            }, { { H = H } })
            print("REVENGE_RESULT " .. label .. " " .. pretty.write({
                avoidance = count, presses = run.pressedBy, refusals = run.refused,
            }, ""))
            assert.are.equal(0, run.errors)
            assert.are.equal(0, run.raises)
        end)
    end
end)

describe("Warrior Protection unlock boundaries", function()
    for _, level in ipairs({ 9, 10, 14 }) do
        it("drives the imported level " .. level .. " priority", function()
            local content = require("Forever.helpers.protection_gate").content(level)
            local entry
            for _, row in ipairs(manifest) do
                if row.apl_name == "Warrior_Protection" then entry = row end
            end
            local L = loop.new(content)
            local H = L.us
            install(H, content, assert(entry))
            local state = H.Hekili.State
            assert.are.equal(level >= 10, state:IsKnown("sunder_armor"))
            assert.are.equal(level >= 14, state:IsKnown("revenge"))
            H.Hekili.DB.profile.toggles.cooldowns.value = false
            H.Hekili.DB.profile.toggles.defensives.value = false
            local run = loop.run(L, 30417, {
                duration = 25,
                on = function(r, _, t)
                    local output = H.Hekili.Engine.Output.Primary
                    local rec = output.count > 0 and output.recs[1] or {}
                    local press = r.pressed[r.combat]
                    if t >= 3 and t < 28 and (press or rec.actionName == "sunder_armor" or rec.actionName == "revenge") then
                        local power = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                        print("PROTECTION_P0 " .. level .. " " .. pretty.write({
                            t = t, action = rec.actionName, wait = rec.wait, script = rec.script,
                            forecast = rec.floors, press = press, afterPollRage = r.us.power,
                            belief = { lo = power.lo, est = power.est, hi = power.hi },
                            targetAuras = r.us.target and r.us.target.auras,
                        }, ""))
                    end
                end,
            }, { { H = H } })
            print("PROTECTION_RESULT " .. level .. " " .. pretty.write({
                sha256 = entry.sha256, attempts = run.attempts, pressed = run.pressedBy,
                refused = run.refused, character = content.character(),
            }, ""))
            assert.are.equal(0, run.errors)
            assert.are.equal(0, run.raises)
            if level < 10 then assert.is_nil(run.pressedBy.sunder_armor) end
            if level < 14 then assert.is_nil(run.pressedBy.revenge) end
        end)
    end
end)

describe("imported APLForever cast progression", function()
    for _, entry in ipairs(manifest) do
        it("executes three combat presses for " .. entry.apl_file, function()
            local content = contentFor(entry)
            print("PROGRESS_FIXTURE " .. entry.apl_file .. " pack=" .. content.PACK .. " " ..
                pretty.write(content.character(), ""))
            local L = loop.new(content)
            for _, H in ipairs({ L.us, L.oracle }) do
                assert.are.same({}, H.loadErrors)
                install(H, content, entry)
            end

            -- The real driver uses content.resolve and W.press and feeds their
            -- true costs, damage, auras and cooldowns back through real Hekili.
            -- No source-owned default pack is substituted after this import.
            local resolve = content.resolve
            local resolved, first, published, actions = {}, nil, 0, {}
            L.content = setmetatable({
                resolve = function(key, H)
                    local result = resolve(key, H)
                    resolved[key] = resolved[key] or pretty.write(result or "<nil>", "")
                    return result
                end,
            }, { __index = content })
            local run = loop.run(L, 30417, {
                duration = 25,
                on = function(r, steps, t)
                    local out = steps[1].H.Hekili.Engine.Output.Primary
                    if out.count > 0 then
                        published = published + 1
                        local key = out.recs[1].actionName or "<missing actionName>"
                        actions[key] = (actions[key] or 0) + 1
                        if not first then
                            first = { time = t, record = pretty.write(out.recs[1], ""),
                                power = r.us.power, stance = r.us.stance, form = r.us.form,
                                auras = pretty.write(r.us.auras, ""),
                                targetAuras = pretty.write(r.us.target and r.us.target.auras or {}, ""),
                                cooldowns = pretty.write(r.us.cdUntil, "") }
                        end
                    end
                end,
            }, { { H = L.us } })

            local actual = {}
            for i = 1, run.combat do
                if run.pressed[i] then
                    actual[#actual + 1] = run.pressed[i]
                end
            end
            print("PROGRESS_DIAG " .. entry.apl_file .. " " .. pretty.write({
                publishedTicks = published, actions = actions, first = first, resolved = resolved,
                attempts = run.attempts, refused = run.refused, pressedBy = run.pressedBy,
                combatCasts = actual, errors = run.errors, raises = run.raises,
            }, ""))
            assert.are.equal(0, run.raises, "native update raised an error")
            assert.are.equal(0, run.errors, "native engine raised an error")
            assert.is_true(run.presses >= 3, "imported profile did not execute three successful presses")
            assert.is_true(#actual >= 3, "fewer than three in-combat successful presses")
            print(string.format(
                "NATIVE_PROGRESS role=%s file=%s presses=%d combat=%d attempts=%d first3=%s,%s,%s errors=%d raises=%d",
                entry.apl_name, entry.apl_file, run.presses, run.combat, run.attempts,
                actual[1], actual[2], actual[3], run.errors, run.raises
            ))
        end)
    end
end)

describe("Guardian Roar publication comparison", function()
    local function compare(label, entry, defensives, seeded)
        local content = fixture.Druid.Guardian
        local L = loop.new(content)
        assert.are.same({}, L.us.loadErrors)
        if entry then
            install(L.us, content, entry)
        end
        local pack = assert(L.us.Hekili.DB.profile.packs[content.PACK])
        local decisions, postOpener, defensiveRoar = {}, {}, 0
        local seededPolls, firstRoar, projectedRoar = 0, 0, nil
        if defensives ~= nil then
            local toggles = L.us.Hekili.DB.profile.toggles
            toggles.defensives.value = defensives
            toggles.cooldowns.value = false
        end
        local roar, stop, previous, cursor, gap = nil, nil, 0, 0, nil
        local seededRoar, maulEvents = nil, {}
        if seeded then
            L.content = setmetatable({
                WORLD = setmetatable({ power = 100 }, { __index = content.WORLD }),
            }, { __index = content })
            seededRoar = assert(L.us.Hekili.Class.auras.demoralizing_roar).id
        end
        local run = loop.run(L, 30417, {
            duration = 25,
            on = function(r, steps, t)
                local H = steps[1].H
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                local press = r.pressed[r.combat]
                if seeded and t < 1 and r.us.target and not r.us.target.auras[seededRoar] then
                    r.W.applyAura(r.us.target, seededRoar, 30)
                end
                if defensives ~= nil and t >= 3 and t < 28 then
                    local aura = seeded and r.us.target and r.us.target.auras[seededRoar]
                    if aura and aura.expires > t then
                        seededPolls = seededPolls + 1
                        if rec.actionName == "demoralizing_roar" then
                            firstRoar = firstRoar + 1
                        end
                    end
                    local toggles = H.Hekili.DB.profile.toggles
                    assert.are.equal(defensives, toggles.defensives.value)
                    assert.is_false(toggles.cooldowns.value)
                    for i = 1, out.count do
                        local candidate = out.recs[i]
                        if candidate.actionName == "demoralizing_roar" and candidate.listName == "mitigation" then
                            defensiveRoar = defensiveRoar + 1
                            if aura and not projectedRoar then
                                projectedRoar = { slot = i, t = t, wait = candidate.wait,
                                    delay = candidate.delay, exactTime = candidate.exact_time,
                                    engineNow = H.ctl.now, expires = aura.expires }
                            end
                        end
                    end
                    if press or (t >= 8 and #postOpener < 3) then
                        local decision = { t = t, action = rec.actionName,
                            wait = rec.wait, press = press, rage = r.W.res(r.us, L.power.type),
                            auras = pretty.write(r.us.target and r.us.target.auras or {}, "") }
                        if press then
                            decisions[#decisions + 1] = decision
                        end
                        if t >= 8 and #postOpener < 3 then
                            postOpener[#postOpener + 1] = decision
                        end
                    end
                end
                if press == "demoralizing_roar" and not roar then
                    roar = t
                end
                if roar and previous > 0 and out.count == 0 and not stop then
                    stop = t
                end
                if t >= 3 and out.count == 0 and not gap then
                    gap = t
                end
                local events = {}
                for i = cursor + 1, #r.W.truth do
                    local ev = r.W.truth[i]
                    if ev.src == r.us and (ev.kind == "queue" or ev.kind == "strike" or ev.kind == "unqueue") then
                        maulEvents[#maulEvents + 1] = { t = ev.t, kind = ev.kind, outcome = ev.act,
                            spell = ev.spell, cost = ev.cost, rageAfterPoll = r.us.power,
                            pendingAfterPoll = r.us.queued and r.us.queued.key, nextIcon = rec.actionName }
                    end
                    events[#events + 1] = {
                        kind = ev.kind, act = ev.act, hand = ev.hand,
                        player = ev.src == r.us, onPlayer = ev.dst == r.us,
                    }
                end
                cursor = #r.W.truth
                if (gap and t <= gap + 1.6) or press or
                    (roar and (not stop or t <= stop + 2.6)) or (#events > 0 and t >= 3) then
                    local power = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                    print("GUARDIAN_TICK " .. label .. " " .. pretty.write({
                        t = t, count = out.count, action = rec.actionName, wait = rec.wait,
                        script = rec.script, evaluatedPack = rec.pack, press = press,
                        rage = r.W.res(r.us, L.power.type), estimatedRage = power.est,
                        form = r.us.form, gcdUntil = r.us.gcdUntil, castUntil = r.us.castUntil,
                        targetHealth = r.us.target and r.us.target.health,
                        targetAuras = r.us.target and r.us.target.auras, events = events,
                        refusalsSoFar = r.refused,
                    }, ""))
                end
                previous = out.count
            end,
        }, { { H = L.us } })
        print("GUARDIAN_COMPARE " .. label .. " " .. pretty.write({
            pack = content.PACK, defaultEntries = #pack.lists.default, roar = roar,
            firstCombatGap = gap, firstStop = stop, attempts = run.attempts, presses = run.presses,
            successful = run.pressedBy, refusals = run.refused,
        }, ""))
        assert.are.equal(0, run.raises)
        assert.are.equal(0, run.errors)
        if defensives ~= nil then
            print("GUARDIAN_P0 " .. label .. " " .. pretty.write({
                sha256 = entry and entry.sha256, defensives = defensives,
                acceptedDecisions = decisions, postOpener = postOpener,
                refused = run.refused, defensiveRoar = defensiveRoar,
                pressed = run.pressedBy,
                seeded = seeded, swingEvents = maulEvents,
                seededPolls = seededPolls, firstRoarDuringSeed = firstRoar,
                firstProjectedRoarDuringSeed = projectedRoar,
            }, ""))
            if entry and entry.revision == "v1.1" then
                if seeded then
                    assert.is_true(seededPolls > 0, "seeded Roar aura never reached combat")
                    assert.are.equal(0, firstRoar, "Roar was the first icon while the seeded debuff was active")
                    assert.are.equal(0, run.pressedBy.demoralizing_roar or 0, "redundant Roar press")
                    if not defensives then
                        assert.are.equal(0, defensiveRoar, "Defensives OFF published mitigation Roar")
                    end
                    assert.is_true((run.pressedBy.primal_bite or 0) + (run.pressedBy.lacerate or 0) > 0)
                elseif defensives then
                    assert.is_true(defensiveRoar > 0, "eligible Roar did not publish")
                else
                    assert.are.equal(0, defensiveRoar, "defensive branch published Roar with Defensives OFF")
                    assert.is_true((run.pressedBy.primal_bite or 0) + (run.pressedBy.lacerate or 0) > 0)
                end
            end
        end
    end

    it("records the untouched upstream default", function()
        compare("upstream", nil)
    end)
    it("records the untouched upstream default with Defensives OFF", function()
        compare("upstream-off", nil, false)
    end)
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Druid_Guardian" then
            it("records " .. entry.revision .. " around Roar", function()
                compare(entry.revision, entry)
            end)
            for _, enabled in ipairs({ false, true }) do
                it("compares " .. entry.revision .. " with Defensives=" .. tostring(enabled), function()
                    compare(entry.revision, entry, enabled)
                end)
                it("observes seeded Roar and excess Rage for " .. entry.revision .. " with Defensives=" .. tostring(enabled), function()
                    compare(entry.revision .. "-seeded", entry, enabled, true)
                end)
            end
        end
    end
end)

describe("Guardian source world Maul", function()
    for _, case in ipairs({ "insufficient", "exact", "excess" }) do
        it("checks Maul queue and swing with " .. case .. " Rage", function()
            local content = fixture.Druid.Guardian
            local H = loop.new(content).us
            H.Hekili.State.reset("Primary", true)
            local maul = content.resolve("maul", H)
            assert.is_true(maul.cost > 0)
            local rage = maul.cost + ({ insufficient = -1, exact = 0, excess = 20 })[case]
            local world = require("Game.harness.scenarios").world(setmetatable({
                power = rage, form = content.character().form,
            }, { __index = content.WORLD }), 30417)
            local player = world.ents[1]
            world.run(1)
            local before = player.power
            local accepted, reason = world.press(player, "maul", maul)
            assert.are.equal(before, player.power, "queue must not spend Rage")
            if case == "insufficient" then
                assert.is_false(accepted)
                assert.are.equal("cost", reason)
                assert.is_nil(player.queued)
            else
                assert.is_true(accepted, tostring(reason))
                assert.are.equal("maul", assert(player.queued).key)
                world.run(6)
                assert.is_nil(player.queued)
                local strike
                for _, event in ipairs(world.truth) do
                    if event.kind == "strike" and event.src == player and event.spell == maul.spell then
                        strike = event
                        break
                    end
                end
                assert.are.equal(maul.cost, assert(strike, "queued Maul did not execute").cost)
                print("GUARDIAN_MAUL " .. case .. " strikeCost=" .. strike.cost .. " outcome=" .. strike.act)
            end
            print("GUARDIAN_MAUL " .. case .. " queueRage=" .. before .. " accepted=" ..
                tostring(accepted) .. " reason=" .. tostring(reason))
        end)
    end
end)

describe("Guardian imported low-kit Maul", function()
    it("drives the v1.1 level-10 branch through a native swing", function()
        local ws = require("Forever.helpers.wowsims")
        -- Same hotfix overrides and talent cut as upstream wowsims_druid_spec.lua.
        local learn = setmetatable({ [417141] = math.huge, [1328617] = math.huge, [1328616] = 34 },
            { __index = ws.learn("DRUID") })
        local stock = fixture.Druid.Guardian
        local content = ws.content(stock, {
            pack = stock.PACK, level = 10, learn = learn,
            talents = ws.header("druid_guardian").talents,
            race = ws.race("druid_guardian"), gear = ws.gear("druid_guardian"),
        })
        local entry
        for _, row in ipairs(manifest) do
            if row.apl_name == "Druid_Guardian" and row.revision == "v1.1" then entry = row end
        end
        local L = loop.new(content)
        install(L.us, content, assert(entry))
        local H = L.us
        H.Hekili.DB.profile.toggles.defensives.value = false
        H.Hekili.DB.profile.toggles.cooldowns.value = false
        local state = H.Hekili.State
        local known = { bear = state:IsKnown("bear_form"), maul = state:IsKnown("maul"),
            bite = state:IsKnown("primal_bite"), lacerate = state:IsKnown("lacerate") }
        print("GUARDIAN_LOW_KIT fixture=" .. pretty.write(content.character(), "") ..
            " known=" .. pretty.write(known, "") .. " sha256=" .. entry.sha256)
        assert.is_true(known.bear and known.maul)
        assert.is_false(known.bite or known.lacerate)
        local queue, strike, cursor, nextDecisions = nil, nil, 0, {}
        local run = loop.run(L, 30417, {
            duration = 25,
            on = function(r, _, t)
                if cursor == 0 then
                    local press = r.W.press
                    r.W.press = function(e, key, resolved)
                        local before = e.power
                        local ok, why = press(e, key, resolved)
                        if key == "maul" and ok and not queue then
                            queue = { t = r.W.t, before = before, after = e.power,
                                key = e.queued and e.queued.key, spell = resolved.spell, cost = resolved.cost }
                        end
                        return ok, why
                    end
                end
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                for i = cursor + 1, #r.W.truth do
                    local ev = r.W.truth[i]
                    if queue and not strike and ev.kind == "strike" and ev.src == r.us and ev.spell == queue.spell then
                        strike = { t = ev.t, cost = ev.cost, outcome = ev.act,
                            queueCleared = not r.us.queued }
                    end
                end
                cursor = #r.W.truth
                if t >= 3 then
                    local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                    local decision = { t = t, action = rec.actionName, wait = rec.wait, script = rec.script,
                        publishedFloor = rec.floors and rec.floors.rage, afterPollRage = r.us.power,
                        afterPollBelief = { lo = belief.lo, est = belief.est, hi = belief.hi },
                        queued = r.us.queued and r.us.queued.key }
                    print("GUARDIAN_LOW_KIT tick=" .. pretty.write(decision, ""))
                    if strike and #nextDecisions < 3 then nextDecisions[#nextDecisions + 1] = decision end
                end
            end,
        }, { { H = H } })
        print("GUARDIAN_LOW_KIT result=" .. pretty.write({
            queue = queue, strike = strike, nextDecisions = nextDecisions,
            refused = run.refused, pressed = run.pressedBy,
        }, ""))
        assert.are.equal(0, run.raises)
        assert.are.equal(0, run.errors)
        assert.are.same({}, run.refused)
        assert.are.equal("maul", assert(queue, "the imported APL did not queue Maul").key)
        assert.are.equal(queue.before, queue.after)
        assert.are.equal(queue.cost, assert(strike, "Maul did not execute").cost)
        assert.is_true(strike.queueCleared)
        assert.are.equal(3, #nextDecisions)
    end)
end)


-- Protection Warrior final-tail experiment, source Hekili Forever v0.8.5.
-- This extends the existing 9/10/14 native pilot but does NOT replace
-- it. Source protection_gate is the pinned shipped Protection wowsims
-- character / class kit, *not* Arms/Fury or an invented tank world.
-- Rage is secret and estimated; a real source cost refusal is a FAIL.
-- True threat, taunt, mitigation effectiveness and actual in-game
-- readiness are NOT modelled, so these are castability regression gates.
local function protectionTail(profile, level, attackers)
    local base = require("Forever.helpers.protection_gate").content(level)
    local content = setmetatable({
        WORLD = setmetatable({
            attackers = attackers,
            mobHealth = 1000000000,
            mobDamage = { 2, 3 },
        }, { __index = base.WORLD }),
    }, { __index = base })
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    local selected
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Warrior_Protection" then
            assert.is_nil(selected, "duplicate Protection revision")
            selected = entry
        end
    end
    assert.is_table(selected)
    assert.are.equal("v1.0", selected.revision)
    if profile == "current" then install(H, content, selected) end
    local toggles = H.Hekili.DB.profile.toggles
    toggles.cooldowns.value = false
    toggles.defensives.value = false
    toggles.movement.value = false

    local S = H.Hekili.State
    assert.is_true(S:IsKnown("heroic_strike"))
    assert.are.equal(level >= 10, S:IsKnown("sunder_armor"))
    assert.are.equal(level >= 14, S:IsKnown("revenge"))
    assert.are.equal(level >= 16, S:IsKnown("shield_block"))
    assert.are.equal(level >= 10, S:IsKnown("defensive_stance"))
    assert.are.equal(level >= 6, S:IsKnown("thunder_clap"))
    local heroicID = H.ns.VirtualState.KnownID(
        H.Hekili.Class.abilities.heroic_strike.id)
    local cleaveID = H.ns.VirtualState.KnownID(
        H.Hekili.Class.abilities.cleave.id)

    local cursor, hostileSwings, enemySwingT = 0, 0, nil
    local queue, strike, unqueue, realPaid = 0, 0, 0, 0
    local ragePaid, minRage, maxRage = 0, math.huge, -math.huge
    local acceptedTotal, repetition, lowRageWindows = 0, 0, 0
    local since, last, samples = {}, {}, {}
    local knownAtPressViolations, revengeOutsideWindow = 0, 0
    local lastAvoid, avoidCount = nil, 0
    local run = loop.run(L, 30417, {
        duration = 48,
        on = function(r, _, t)
            local accepted = r.pressed[r.combat]
            if accepted then
                acceptedTotal = acceptedTotal + 1
                since[accepted] = (since[accepted] or 0) + 1
                if not S:IsKnown(accepted) then
                    knownAtPressViolations = knownAtPressViolations + 1
                end
            end
            minRage = math.min(minRage, r.us.power)
            maxRage = math.max(maxRage, r.us.power)
            local advanced = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.kind == "swing" and ev.dst == r.us
                    and (ev.act == "DODGE" or ev.act == "PARRY"
                        or ev.act == "BLOCK") then
                    avoidCount = avoidCount + 1
                    lastAvoid = ev.t
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= enemySwingT then
                    enemySwingT = ev.t
                    hostileSwings = hostileSwings + 1
                    advanced = true
                end
                if ev.src == r.us and
                    (ev.spell == heroicID or ev.spell == cleaveID) then
                    if ev.kind == "queue" then
                        queue = queue + 1
                    elseif ev.kind == "strike" then
                        strike = strike + 1
                        if (ev.cost or 0) > 0 then
                            realPaid = realPaid + 1
                            ragePaid = ragePaid + ev.cost
                        end
                    elseif ev.kind == "unqueue" then
                        unqueue = unqueue + 1
                    end
                end
            end
            cursor = #r.W.truth
            if accepted == "revenge" and
                (not lastAvoid or t - lastAvoid > 5) then
                revengeOutsideWindow = revengeOutsideWindow + 1
            end
            if advanced then
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                local name = rec.actionName or "NO_ACTION"
                local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                if r.us.power < S.action.heroic_strike.cost then
                    lowRageWindows = lowRageWindows + 1
                end
                local sample = {
                    t = t, first = name, wait = rec.wait,
                    actualRage = r.us.power, beliefLo = belief and belief.lo,
                    acceptedSince = since,
                }
                if #samples < 5 then samples[#samples + 1] = sample end
                last[#last + 1] = sample
                if #last > 3 then table.remove(last, 1) end
                if #last == 3 then
                    local a, b, c = last[1], last[2], last[3]
                    if a.first ~= "NO_ACTION" and a.first == b.first
                        and b.first == c.first
                        and (a.wait or 0) <= 0.05
                        and (b.wait or 0) <= 0.05
                        and (c.wait or 0) <= 0.05
                        and (b.acceptedSince[a.first] or 0) == 0
                        and (c.acceptedSince[a.first] or 0) == 0 then
                        repetition = repetition + 1
                    end
                end
                since = {}
            end
        end,
    }, { { H = H } })
    print("WARRIOR_PROTECTION_TAIL_V085 " .. profile .. " L" .. level
        .. " attackers=" .. attackers .. " "
        .. pretty.write({
            seed = 30417, source = "v0.8.5", level = level,
            sha256 = profile == "current" and selected.sha256 or "shipped",
            accepted = run.pressedBy, refused = run.refused,
            errors = run.errors, raises = run.raises,
            realSwings = hostileSwings, sourceAvoids = avoidCount,
            revengeOutsideWindow = revengeOutsideWindow,
            heroicOrCleaveQueue = queue, strikes = strike,
            unqueue = unqueue, paidStrikes = realPaid,
            trueRagePaidAtStrike = ragePaid,
            lowRageWindows = lowRageWindows,
            minRage = minRage, maxRage = maxRage,
            acceptedTotal = acceptedTotal,
            unknownAccepted = knownAtPressViolations,
            repeatedReady = repetition, samples = samples,
        }, ""))
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    assert.is_true(hostileSwings >= 3)
    assert.are.equal(0, knownAtPressViolations)
    assert.are.equal(0, revengeOutsideWindow)
    assert.are.equal(0, repetition,
        "first immediately-ready recommendation repeated through 3 hostile swings without accepted action")
    assert.are.same({}, run.refused,
        "source native refused a recommendation, including hidden-Rage cost")
    assert.is_true(strike <= queue)
    assert.is_true(strike + unqueue <= queue)
    if strike > 0 then
        assert.is_true(realPaid > 0 and ragePaid > 0,
            "true next-swing strike recorded but no real Rage payment")
    end
    assert.is_nil(run.pressedBy.mortal_strike,
        "Protection source kit must not grant Arms Mortal Strike")
    if level < 14 then assert.is_nil(run.pressedBy.revenge) end
    if level < 10 then assert.is_nil(run.pressedBy.sunder_armor) end
    if profile == "current" then
        assert.is_true(acceptedTotal > 0,
            "selected custom Protection APL produced no accepted source actions")
    end
end

describe("Warrior Protection source-paid next-swing and full repeated-final-tail checks v0.8.5", function()
    for _, level in ipairs({ 9, 10, 14, 16, 30, 60 }) do
        for _, attackers in ipairs({ 1, 2 }) do
            for _, profile in ipairs({ "shipped", "current" }) do
                it(profile .. " L" .. level .. " attacker-count " .. attackers, function()
                    protectionTail(profile, level, attackers)
                end)
            end
        end
    end
end)

-- Warrior Protection next user priority after Guardian/Feral.
-- Regression issue #30: source-native level 9/10/12/14/16/28 low-kit
-- Sunder/stance and next-swing final/repeated fallback comparison.
-- This extends the *existing* level 9/10/14 and Revenge observations
-- with genuine source combat, not a copied Retail/Classic rotation.
-- Source fixture inherits a level-60 one-hander/shield, so this is a
-- CASTABILITY and logical priority check, NOT realistic low-level
-- threat, mitigation, Rage-income, damage or survival.
local function warriorProtSunder(profile, level, attackers)
    local C = require("Forever.helpers.protection_gate").content(level)
    local previous = C.character
    if level < 10 then
        -- The upstream Protection fixture starts already Defensive
        -- even before the *trained* level-10 stance is unlocked.
        -- Correct only this pre-unlock start; no invented form casts.
        function C.character()
            local c = previous()
            c.form = 1 -- source Warrior battle_stance enum, trained at L1
            return c
        end
    end
    C.WORLD = setmetatable({
        mobHealth = 1000000000,
        attackers = attackers,
        mobDamage = { 1, 2 },
        mobPeriod = 2.0,
    }, { __index = C.WORLD })
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    local entry = nil
    for _, e in ipairs(manifest) do
        if e.apl_name == "Warrior_Protection" then entry = e end
    end
    entry = assert(entry, "Warrior Protection immutable Current manifest missing")
    if profile == "current" then
        assert.are.equal("v1.0", entry.revision)
        install(H, C, entry)
    end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    local S = H.Hekili.State
    local known = {
        battle = S:IsKnown("battle_stance"),
        defensive = S:IsKnown("defensive_stance"),
        sunder = S:IsKnown("sunder_armor"),
        revenge = S:IsKnown("revenge"),
        block = S:IsKnown("shield_block"),
        wall = S:IsKnown("shield_wall"),
        heroic = S:IsKnown("heroic_strike"),
        cleave = S:IsKnown("cleave"),
    }
    assert.is_true(known.battle and known.heroic)
    assert.are.equal(level >= 10, known.defensive)
    assert.are.equal(level >= 10, known.sunder)
    assert.are.equal(level >= 14, known.revenge)
    assert.are.equal(level >= 16, known.block)
    -- The released trainer source (learn_warrior.lua) unlocks spell 871
    -- at 28, but shipped's pack can report State:IsKnown(shield_wall)
    -- false at 28 while exact Current's imported pack reports true.
    -- Separate the SOURCE CHARACTER's actual known rank from pack
    -- visibility. Preserve the shipped difference in the output; do
    -- not call it an APL defect or suppress the Current safety gate.
    local rawShieldWall = false
    for _, id in ipairs(C.character().known) do
        if id == 871 then rawShieldWall = true end
    end
    assert.are.equal(level >= 28, rawShieldWall,
        "source Warrior spellbook must have Shield Wall at trained rank")
    if profile == "current" then
        assert.are.equal(level >= 28, known.wall,
            "Current pack lost its legitimate level-28 Shield Wall known state")
    end
    assert.are.equal(level < 10 and 1 or 2, L.form)

    local ids = H.Hekili.Class.auras
    local sunderID = assert(ids.sunder_armor).id
    local battleShoutID = assert(ids.battle_shout).id
    local hsID = H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.heroic_strike.id)
    local cleaveID = H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.cleave.id)
    local cursor, lastMobSwing = 0, nil
    local swingWindows, acceptedSince, first = 0, {}, {}
    local repeats, appliedSunder, sunderOverlap = 0, 0, 0
    local sunderOldExp, sunderOldStacks = -math.huge, 0
    local maxSunderStacks, positiveRageCastSpend = 0, 0
    local queued, strikes, unqueues, paid = {}, {}, {}, {}
    local accepted = 0
    local seenBattleShout, stanceTransitions = false, 0
    local combatBattleSwingWindows, combatDefensiveSwingWindows = 0, 0
    local combatStanceEvents, postCombatStanceEvents = 0, 0
    local result = loop.run(L, 30417, {
        duration = 45,
        on = function(r, _, t)
            local pressed = r.pressed[r.combat]
            if pressed then
                accepted = accepted + 1
                acceptedSince[pressed] = (acceptedSince[pressed] or 0) + 1
            end
            if r.us.auras[battleShoutID] then seenBattleShout = true end
            local freshSwing = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                -- Source W.setForm emits {kind="form", form=...}
                -- with NO src field; it is the player's form transition.
                -- Distinguish combat stance shifts from restoration after
                -- the fight stops (the final form alone is misleading).
                if ev.kind == "form" then
                    stanceTransitions = stanceTransitions + 1
                    if ev.t >= loop.PULL and ev.t < r.W.stopAt then
                        combatStanceEvents = combatStanceEvents + 1
                    else
                        postCombatStanceEvents = postCombatStanceEvents + 1
                    end
                end
                if ev.src == r.us and ev.kind == "cast"
                    and (ev.cost or 0) > 0 then
                    -- Warrior only has primary Rage. The source Warrior
                    -- resolve() passes a cost but leaves p.pt nil, and
                    -- the native world treats nil as the main power.
                    -- Unlike Shaman, checking ev.pt==1 here would
                    -- falsely count all real Sunder/Rend costs as zero.
                    positiveRageCastSpend = positiveRageCastSpend + 1
                end
                if ev.kind == "aura" and ev.dst == r.us.target
                    and ev.aura == sunderID then
                    if (ev.stacks or 0) > 0 then
                        appliedSunder = appliedSunder + 1
                        maxSunderStacks = math.max(maxSunderStacks, ev.stacks)
                        if sunderOldExp > ev.t and sunderOldStacks > 0 then
                            sunderOverlap = sunderOverlap + 1
                        end
                        sunderOldExp, sunderOldStacks = ev.expires, ev.stacks
                    else
                        sunderOldExp, sunderOldStacks = 0, 0
                    end
                end
                if ev.src == r.us and (ev.spell == hsID or ev.spell == cleaveID) then
                    local key = ev.spell == hsID and "heroic_strike" or "cleave"
                    if ev.kind == "queue" then
                        queued[key] = (queued[key] or 0) + 1
                    elseif ev.kind == "strike" then
                        strikes[key] = (strikes[key] or 0) + 1
                        if (ev.cost or 0) > 0 then
                            paid[key] = (paid[key] or 0) + ev.cost
                        end
                    elseif ev.kind == "unqueue" then
                        unqueues[key] = (unqueues[key] or 0) + 1
                    end
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= lastMobSwing then
                    lastMobSwing = ev.t
                    freshSwing = true
                    swingWindows = swingWindows + 1
                end
            end
            cursor = #r.W.truth
            if freshSwing then
                if t >= loop.PULL and t < r.W.stopAt then
                    if r.us.form == 2 then
                        combatDefensiveSwingWindows = combatDefensiveSwingWindows + 1
                    elseif r.us.form == 1 then
                        combatBattleSwingWindows = combatBattleSwingWindows + 1
                    end
                end
                local out = H.Hekili.Engine.Output.Primary
                local rec = out.count > 0 and out.recs[1] or {}
                local action = rec.actionName or "NO_ACTION"
                local current = {
                    t = t, action = action, wait = rec.wait,
                    rage = r.us.power,
                    rageLo = H.ns.VirtualState.Power(L.power.type, H.ctl.now).lo,
                    sunderStacks = sunderOldStacks,
                    sunderExpires = sunderOldExp,
                    since = acceptedSince,
                }
                first[#first + 1] = current
                if #first > 3 then table.remove(first, 1) end
                acceptedSince = {}
                if #first == 3 then
                    local a, b, c = first[1], first[2], first[3]
                    if a.action ~= "NO_ACTION" and a.action == b.action
                        and b.action == c.action
                        and (a.wait or 0) <= 0.05 and (b.wait or 0) <= 0.05
                        and (c.wait or 0) <= 0.05
                        and (b.since[a.action] or 0) == 0
                        and (c.since[a.action] or 0) == 0 then
                        repeats = repeats + 1
                    end
                end
            end
        end,
    }, { { H = H } })
    print("WARRIOR_PROT_SUNDER_P0_V085 " .. profile .. " L" .. level
        .. " attackers=" .. attackers .. " " .. pretty.write({
            seed = 30417, pin = "v0.8.5",
            source = "Warrior Protection onehand+shield/level60 gear",
            sha256 = profile == "current" and entry.sha256 or nil,
            known = known, rawShieldWallTrained = rawShieldWall,
            shieldWallKnownVisibilityDifference = rawShieldWall and not known.wall,
            actualPresses = result.pressedBy,
            sourceRefusals = result.refused,
            sourceErrors = result.errors, sourceRaises = result.raises,
            finalStance = result.us.form,
            acceptedTotal = accepted, hostileSwingWindows = swingWindows,
            repeatedReady = repeats, sunderApplications = appliedSunder,
            redundantSunderWhenAlreadyActive = sunderOverlap,
            maxSunderStacks = maxSunderStacks,
            positiveRageCastEvents = positiveRageCastSpend,
            battleShoutObserved = seenBattleShout,
            stanceTransitions = stanceTransitions,
            combatStanceEvents = combatStanceEvents,
            postCombatStanceEvents = postCombatStanceEvents,
            combatDefensiveSwingWindows = combatDefensiveSwingWindows,
            combatBattleSwingWindows = combatBattleSwingWindows,
            queues = queued, strikes = strikes,
            unqueues = unqueues, paidNextSwingRage = paid,
            lastThree = first,
        }, ""))

    assert.are.equal(0, result.errors)
    assert.are.equal(0, result.raises)
    assert.is_true(swingWindows >= 3,
        "need three actual incoming swing transitions to check final fallback")
    assert.is_true(accepted >= 2, "Warrior priority accepted fewer than two actions")
    if level < 10 then
        assert.is_nil(result.pressedBy.sunder_armor)
        assert.is_nil(result.pressedBy.revenge)
        assert.is_nil(result.pressedBy.shield_block)
    end
    if level < 14 then assert.is_nil(result.pressedBy.revenge) end
    if level < 16 then assert.is_nil(result.pressedBy.shield_block) end
    if level < 28 then assert.is_nil(result.pressedBy.shield_wall) end
    for _, key in ipairs({ "heroic_strike", "cleave" }) do
        assert.is_true((strikes[key] or 0) + (unqueues[key] or 0)
            <= (queued[key] or 0),
            "next-swing outcomes outnumber accepted queue for " .. key)
    end
    if profile == "current" then
        assert.are.same({}, result.refused,
            "Current source-world cast refused after low-level fallback")
        assert.are.equal(0, repeats,
            "Current displayed one immediately-ready action for three world swings without accepting it")
        assert.is_nil(result.pressedBy.shield_block)
        assert.is_nil(result.pressedBy.shield_wall)
        if attackers == 1 then
            assert.is_true(sunderOverlap <= 1,
                "single-target nonboss Sunder reapplied repeatedly during its existing debuff")
        end
    end
end

describe("Warrior Protection source-native Sunder/stance and next-swing final-tail matrix v0.8.5", function()
    for _, level in ipairs({ 9, 10, 12, 14, 16, 28 }) do
        for _, attackers in ipairs({ 1, 2 }) do
            for _, profile in ipairs({ "current", "shipped" }) do
                it(profile .. " L" .. level .. " " .. attackers .. " hostile attackers",
                    function() warriorProtSunder(profile, level, attackers) end)
            end
        end
    end
end)
