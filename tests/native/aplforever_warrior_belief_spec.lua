-- Source-native Warrior Protection resource-belief and fallback investigation.
-- Observational tests: preserve custom v1.0 and the shipped priority as comparators.
-- Level boundaries, low Rage, recent/expired Revenge, Sunder upkeep, three
-- post-upkeep decisions when the world reaches them. No invented game API.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local gate = require("Forever.helpers.protection_gate")
local root = assert(os.getenv("APLFOREVER_ROOT"), "APLFOREVER_ROOT is required")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function warriorEntry()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Warrior_Protection" then return entry end
    end
    error("Warrior Protection missing from source-verified manifest")
end

local function install(H, content)
    local entry = warriorEntry()
    local file = assert(io.open(root .. "/" .. entry.apl_file, "rb"))
    local apl = assert(file:read("*a"))
    file:close()
    local imported, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", apl, content.PACK)
    assert.is_table(imported)
    assert.is_table(imported.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = imported
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(imported) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name), name)
    end
    assert.are.same({}, H.errors)
    return entry
end

local SCENARIOS = {
    { label = "level10-low-rage", level = 10, power = 0, attackers = 1,
      mobDamage = { 1, 1 }, mobPeriod = 3.5, duration = 60 },
    { label = "level14-low-rage-two-attackers", level = 14, power = 0, attackers = 2,
      mobDamage = { 1, 1 }, mobPeriod = 3.5, duration = 60 },
    { label = "level14-starved-no-white-swing", level = 14, power = 0, attackers = 2,
      mobDamage = { 3, 3 }, mobPeriod = 2.5, noMelee = true, duration = 55 },
    { label = "level14-moderate-rage", level = 14, power = 12, attackers = 1,
      mobDamage = { 10, 14 }, mobPeriod = 2.5, duration = 55 },
}

describe("Warrior Protection source-native belief and final fallback", function()
    for _, c in ipairs(SCENARIOS) do
        for _, custom in ipairs({ true, false }) do
            local label = c.label .. "/" .. (custom and "custom" or "shipped")
            it("observes " .. label .. " without inventing a mana/rage or cooldown read", function()
                local stock = gate.content(c.level)
                local content = setmetatable({
                    WORLD = setmetatable({
                        power = c.power, attackers = c.attackers,
                        mobDamage = c.mobDamage, mobPeriod = c.mobPeriod,
                        noMelee = c.noMelee, mobHealth = 100000,
                    }, { __index = stock.WORLD }),
                }, { __index = stock })
                local L = loop.new(content)
                local H = L.us
                local entry = custom and install(H, content) or warriorEntry()
                local toggles = H.Hekili.DB.profile.toggles
                toggles.cooldowns.value = false
                toggles.defensives.value = false
                toggles.movement.value = false

                local sunderID = assert(H.Hekili.Class.auras.sunder_armor).id
                local battleID = assert(H.Hekili.Class.auras.battle_shout).id
                local count = {
                    avoidance = 0, expiredWindow = 0, staleReadyRevenge = 0,
                    revengePresses = 0, redundantSunder = 0, sunderPresses = 0,
                    observedStateChanges = 0, postUpkeep = {}, postUpkeepDecisions = 0,
                    largeOverestimates = 0, refused = {},
                }
                local cursor, lastAvoid, lastExpired, priorSunder = 0, nil, nil, false
                local logCount = 0
                local run = loop.run(L, 30417, {
                    duration = c.duration,
                    on = function(r, _, t)
                        local changes = 0
                        local avoids = {}
                        for i = cursor + 1, #r.W.truth do
                            local e = r.W.truth[i]
                            if e.kind == "swing" and e.dst.guid == r.us.guid
                              and (e.act == "DODGE" or e.act == "PARRY" or e.act == "BLOCK") then
                                count.avoidance = count.avoidance + 1
                                lastAvoid = e.t
                                avoids[#avoids + 1] = { time = e.t, result = e.act }
                            end
                            if e.kind == "swing" or e.kind == "aura" or e.kind == "cast" then
                                changes = changes + 1
                            end
                        end
                        cursor = #r.W.truth
                        if t < 3 then return end
                        local output = H.Hekili.Engine.Output.Primary
                        local rec = output.count > 0 and output.recs[1] or {}
                        local press = r.pressed[r.combat]
                        local rage = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                        local sunder = r.us.target and r.us.target.auras[sunderID]
                        local sunderUp = sunder and (sunder.stacks or 0) > 0
                          and (sunder.expires == 0 or sunder.expires > r.W.t) or false
                        local shout = r.us.auras[battleID]
                        local shoutUp = shout and (shout.stacks or 0) > 0
                          and (shout.expires == 0 or shout.expires > r.W.t) or false
                        local windowExpiry = lastAvoid and lastAvoid + 5 or nil
                        local expired = windowExpiry and t > windowExpiry
                          and lastExpired ~= lastAvoid or false
                        if expired then
                            count.expiredWindow = count.expiredWindow + 1
                            lastExpired = lastAvoid
                        end
                        if rec.actionName == "revenge" and windowExpiry and t > windowExpiry then
                            count.staleReadyRevenge = count.staleReadyRevenge + 1
                        end
                        if press == "revenge" then
                            count.revengePresses = count.revengePresses + 1
                            assert.is_true(lastAvoid ~= nil and t - lastAvoid <= 5,
                                "Revenge cast outside a real avoidance window: " .. label)
                        end
                        if press == "sunder_armor" then
                            count.sunderPresses = count.sunderPresses + 1
                            if priorSunder then
                                count.redundantSunder = count.redundantSunder + 1
                            end
                        end
                        priorSunder = sunderUp
                        if changes > 0 or press then
                            count.observedStateChanges = count.observedStateChanges + 1
                        end
                        -- Count only state-advanced decisions after *both* upkeep effects
                        -- are on the world, not 3 successive, identical Hekili polling ticks.
                        if sunderUp and shoutUp and (changes > 0 or press)
                          and #count.postUpkeep < 3 then
                            count.postUpkeep[#count.postUpkeep + 1] = {
                                time = t, action = rec.actionName, press = press,
                                wait = rec.wait, rage = r.us.power, low = rage.lo,
                                estimate = rage.est, high = rage.hi,
                            }
                        end
                        if rage.est and rage.hi and rage.lo
                          and rage.lo <= r.us.power and rage.est > r.us.power + 15 then
                            count.largeOverestimates = count.largeOverestimates + 1
                        end
                        if (press or expired or #avoids > 0
                          or (rec.actionName == "revenge" and not lastAvoid))
                          and logCount < 32 then
                            logCount = logCount + 1
                            print("PROT_BELIEF_EVENT " .. label .. " " .. pretty.write({
                                t = t, press = press, recommended = rec.actionName,
                                script = rec.script, wait = rec.wait, future = rec.time,
                                belief = { lo = rage.lo, est = rage.est, hi = rage.hi },
                                worldRage = r.us.power, avoids = avoids,
                                windowExpiry = windowExpiry, sunderUp = sunderUp,
                                sunderStacks = sunder and sunder.stacks,
                                shoutUp = shoutUp, stateChanges = changes,
                            }, ""))
                        end
                    end,
                }, { { H = H } })
                assert.are.equal(0, run.errors)
                assert.are.equal(0, run.raises)
                assert.are.same({}, run.refused, "world rejected a recommended spell: " .. label)
                assert.is_true(run.combat > 0, "no combat simulated")
                assert.is_true(count.observedStateChanges > 0, "no state changes")
                if custom then
                    assert.are.equal(0, count.redundantSunder,
                        "custom Sunder fired while the nonboss debuff remained active")
                end
                -- A given RNG/priority combination need not roll an avoid.
                -- The no-white-swing fixture is the dedicated coverage gate:
                -- it still has incoming attacks that can generate legitimate Rage.
                if c.noMelee then
                    assert.is_true(count.avoidance > 0,
                        "no-white-swing Revenge fixture saw no real avoids")
                end
                if not c.noMelee then
                    assert.are.equal(3, #count.postUpkeep,
                        "expected three world-state-advanced post-upkeep checkpoints")
                else
                    local playerSwings = 0
                    for _, event in ipairs(run.W.truth) do
                        if event.kind == "swing" and event.src == run.us then
                            playerSwings = playerSwings + 1
                        end
                    end
                    assert.are.equal(0, playerSwings,
                        "no-white-swing world allowed player white attacks")
                    -- An accepted Revenge is safe if an actual enemy avoid
                    -- opened the window and W.press accepted its true cost.
                    -- The earlier assertions check every Revenge press was
                    -- within the window, and run.refused must remain empty.
                    if (run.pressedBy.revenge or 0) > 0 then
                        assert.is_true(count.avoidance > 0,
                            "Revenge was cast without a real avoid")
                        assert.are.equal(run.pressedBy.revenge, count.revengePresses)
                    end
                end
                print("PROT_BELIEF_RESULT " .. label .. " " .. pretty.write({
                    source = os.getenv("APLFOREVER_SOURCE_RELEASE") or "v0.8.3", revision = custom and entry.revision or "shipped",
                    sha256 = custom and entry.sha256 or "UPSTREAM",
                    scenario = c, observations = count,
                    pressed = run.pressedBy, refused = run.refused,
                    attempts = run.attempts, casts = run.presses,
                    combat = run.combat, endRage = run.us.power,
                }, ""))
            end)
        end
    end
end)
