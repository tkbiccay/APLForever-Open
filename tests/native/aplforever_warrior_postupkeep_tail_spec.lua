-- Issue #30: actual source-native post-upkeep, low-Rage fallback decisions.
-- No fabricated spell casts, talent kits, haste or Lua WoW client APIs.
-- The *only* intervention is a clearly labelled external Rage drain after
-- Battle Shout and Sunder have genuinely been applied by the driver.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local gate = require("Forever.helpers.protection_gate")

local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function selectedWarrior()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Warrior_Protection" then return entry end
    end
    error("Cannot find protected Warrior_Protection")
end

local function install(H, content)
    local entry = selectedWarrior()
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
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name), name)
    end
    assert.are.same({}, H.errors)
    return entry
end

local CASES = {}
for _, seed in ipairs({ 30417, 30418, 30419 }) do
    CASES[#CASES + 1] = { level = 10, attackers = 1, seed = seed }
    CASES[#CASES + 1] = { level = 14, attackers = 2, seed = seed }
end

describe("Warrior Protection post-upkeep source-native Rage exhaustion", function()
    for _, c in ipairs(CASES) do
        for _, custom in ipairs({ true, false }) do
            local name = "level" .. c.level .. "-" .. c.attackers .. "mob/seed" .. c.seed .. "/" .. (custom and "custom" or "shipped")
            it("records three real post-upkeep swing decisions: " .. name, function()
                local stock = gate.content(c.level)
                local content = setmetatable({
                    WORLD = setmetatable({
                        power = 100, attackers = c.attackers,
                        noMelee = true, mobPeriod = 2.25,
                        mobDamage = { 2, 3 }, mobHealth = 100000,
                    }, { __index = stock.WORLD }),
                }, { __index = stock })
                local L = loop.new(content)
                local H = L.us
                local entry = custom and install(H, content) or selectedWarrior()
                H.Hekili.DB.profile.toggles.cooldowns.value = false
                H.Hekili.DB.profile.toggles.defensives.value = false
                H.Hekili.DB.profile.toggles.movement.value = false

                local shoutId = assert(H.Hekili.Class.auras.battle_shout).id
                local sunderId = assert(H.Hekili.Class.auras.sunder_armor).id
                local cursor, started, startTime, drains, sawShout, sawSunder = 0, false, nil, 0, false, false
                local samples, danger = {}, {}
                local run = loop.run(L, c.seed, {
                    duration = 55,
                    on = function(r, _, t)
                        local freshEnemySwing = false
                        local realEvents = {}
                        for i = cursor + 1, #r.W.truth do
                            local ev = r.W.truth[i]
                            if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                              and ev.dst and ev.dst.guid == r.us.guid then
                                freshEnemySwing = true
                                realEvents[#realEvents + 1] = { t = ev.t, act = ev.act }
                            end
                        end
                        cursor = #r.W.truth
                        local target = r.us.target
                        local shout = r.us.auras[shoutId]
                        local sunder = target and target.auras[sunderId]
                        local shoutUp = shout and (shout.stacks or 0)>0 and shout.expires > r.W.t
                        local sunderUp = sunder and (sunder.stacks or 0)>0 and sunder.expires > r.W.t
                        sawShout = sawShout or not not shoutUp
                        sawSunder = sawSunder or not not sunderUp

                        if not started and t >= 3.2 and shoutUp and sunderUp then
                            started, startTime = true, t
                        end
                        if started and shoutUp and sunderUp and t >= startTime + 0.4 and freshEnemySwing
                          and #samples < 3 then
                            local output = H.Hekili.Engine.Output.Primary
                            local rec = output.count > 0 and output.recs[1] or {}
                            local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                            local press = r.pressed[r.combat]
                            samples[#samples + 1] = {
                                t = t, action = rec.actionName or "NO_ACTION",
                                wait = rec.wait, press = press,
                                worldRageBeforeDrain = r.us.power,
                                low = belief.lo, estimate = belief.est, high = belief.hi,
                                swings = realEvents, sunderStacks = sunder.stacks,
                                shoutStacks = shout.stacks,
                            }
                            if rec.actionName and (rec.wait or 0) <= 0.05 and not press then
                                danger[#danger + 1] = {
                                    action = rec.actionName, t = t,
                                    reason = "ready icon with no same-poll press; examine GCD/driver",
                                }
                            end
                        end
                        -- External stress stimulus: after genuine upkeep, extinguish Rage
                        -- through the registered world event stream. No game APL edits.
                        if started and r.us.power > 0 then
                            r.W.gain(r.us, -r.us.power)
                            drains = drains + 1
                        end
                    end,
                }, { { H = H } })
                print("PROT_AFTER_UPKEEP " .. name .. " " .. pretty.write({
                    source = "v0.8.3", revision = custom and entry.revision or "shipped",
                    started = started, startTime = startTime, sawShout = sawShout,
                    sawSunder = sawSunder, drains = drains, samples = samples,
                    possibleReadyNoPress = danger,
                    pressed = run.pressedBy, refused = run.refused,
                    attempts = run.attempts, successes = run.presses,
                    raises = run.raises, errors = run.errors,
                }, ""))
                assert.is_true(sawShout, "real Battle Shout never applied")
                assert.is_true(sawSunder, "real Sunder never applied")
                assert.is_true(started, "source-world never reached both upkeep auras")
                assert.is_true(drains > 0, "Rage starvation was never applied")
                assert.is_true((run.pressedBy.battle_shout or 0) > 0,
                    "Battle Shout must have been a real successful cast, not a seeded aura")
                assert.is_true((run.pressedBy.sunder_armor or 0) > 0,
                    "Sunder must have been a real successful cast, not a seeded aura")
                assert.are.equal(3, #samples, "need three *different incoming swing* checkpoints after upkeep")
                assert.are.equal(0, #danger,
                    "first icon showed immediately ready but was not pressed: investigate GCD/castability")
                for _, sample in ipairs(samples) do
                    assert.is_true(sample.action == "NO_ACTION" or (sample.wait or 0) > 0 or
                        (sample.press ~= false and sample.press ~= nil),
                        "repeated immediately actionable but unpressed fallback after Rage exhaustion")
                end
                assert.are.same({}, run.refused, "a recommendation was refused by the source world")
                assert.are.equal(0, run.raises)
                assert.are.equal(0, run.errors)
            end)
        end
    end
end)
