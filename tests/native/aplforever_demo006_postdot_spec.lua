-- DEMO-006: source-native post-DoT Mana-starvation and repeated Life Tap probe.
-- This tests recommendations/presses, NOT real Life Tap health safety:
-- tagged warlock_world.lua does not implement the health payment.
-- All DoTs must be genuinely applied by source-world presses first.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local stock = require("Forever.helpers.warlock_world").Demonology
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function getEntry(revision)
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Warlock_Demonology" and entry.revision == revision then
            return entry
        end
    end
    error("Missing protected Demonology revision " .. tostring(revision))
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
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name), name)
    end
    assert.are.same({}, H.errors)
end

local PACKS = {
    { name = "reported-working-v1.0", revision = "v1.0" },
    { name = "archived-default-v0.8", revision = "v0.8" },
    { name = "shipped-v0.8.3", revision = nil },
}
local SEEDS = { 30417, 30418, 30419 }

describe("DEMO-006 actual DoT upkeep then artificial Mana starvation", function()
    for _, seed in ipairs(SEEDS) do
        for _, p in ipairs(PACKS) do
            local label = p.name .. "/seed" .. seed
            it("observes three source-event-advanced post-DoT decisions: " .. label, function()
                local content = setmetatable({
                    WORLD = setmetatable({
                        power = stock.WORLD.max,
                        mobDamage = { 1, 2 }, mobPeriod = 1.5,
                        mobHealth = 1e9,
                    }, { __index = stock.WORLD }),
                }, { __index = stock })
                local L = loop.new(content)
                local H = L.us
                if p.revision then install(H, content, getEntry(p.revision)) end
                H.Hekili.DB.profile.toggles.cooldowns.value = false
                H.Hekili.DB.profile.toggles.defensives.value = false
                local corrId = assert(H.Hekili.Class.auras.corruption).id
                local immoId = assert(H.Hekili.Class.auras.immolate).id
                local started, startTime, drained, sawCorr, sawImmo = false, nil, false, false, false
                local cursor, lastRealCast, tapsWithDots, consecutiveTaps = 0, nil, 0, 0
                local samples, actualPresses, eventsAfterDrain = {}, {}, 0
                local run = loop.run(L, seed, {
                    duration = 43,
                    on = function(r, _, t)
                        local eventCount = 0
                        for i = cursor + 1, #r.W.truth do
                            local ev = r.W.truth[i]
                            if ev.kind == "swing" or ev.kind == "spell"
                              or ev.kind == "cast" or ev.kind == "aura" then
                                eventCount = eventCount + 1
                            end
                        end
                        cursor = #r.W.truth

                        local tgt = r.us.target
                        local co = tgt and tgt.auras[corrId]
                        local im = tgt and tgt.auras[immoId]
                        local corrUp = co and co.stacks > 0 and co.expires > r.W.t
                        local immoUp = im and im.stacks > 0 and im.expires > r.W.t
                        sawCorr = sawCorr or not not corrUp
                        sawImmo = sawImmo or not not immoUp

                        if not started and t >= 3.2 and corrUp and immoUp then
                            started, startTime = true, t
                        end
                        if started and not drained and r.us.power > r.us.powerMax * 0.1 then
                            -- One controlled artificial Mana spend, via the exact
                            -- source-world resource event. No imaginary Life Tap safety.
                            local delta = r.us.power - r.us.powerMax * 0.1
                            r.W.gain(r.us, -delta)
                            drained = true
                        end

                        local press = r.pressed[r.combat]
                        if drained and press then
                            actualPresses[#actualPresses + 1] = {
                                t = t, action = press, afterMana = r.us.power,
                                corr = not not corrUp, immolate = not not immoUp,
                            }
                            if corrUp and immoUp and press == "life_tap" then
                                tapsWithDots = tapsWithDots + 1
                                consecutiveTaps = lastRealCast == "life_tap" and consecutiveTaps + 1 or 1
                            elseif press then
                                consecutiveTaps = 0
                            end
                            lastRealCast = press
                        end

                        if drained and t >= startTime + 0.4 and eventCount > 0
                          and #samples < 3 and corrUp and immoUp then
                            local out = H.Hekili.Engine.Output.Primary
                            local rec = out.count > 0 and out.recs[1] or {}
                            local belief = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                            samples[#samples + 1] = {
                                t = t, action = rec.actionName or "NO_ACTION",
                                wait = rec.wait, press = press,
                                healthTruth = r.us.health, manaTruth = r.us.power,
                                beliefLow = belief.lo, beliefEst = belief.est, beliefHigh = belief.hi,
                                corruptionRemaining = co.expires - r.W.t,
                                immolateRemaining = im.expires - r.W.t,
                                sourceEvents = eventCount,
                            }
                            eventsAfterDrain = eventsAfterDrain + eventCount
                        end
                    end,
                }, { { H = H } })

                print("DEMO006_POSTDOT " .. label .. " " .. pretty.write({
                    source = "v0.8.3", seed = seed, label = label,
                    dotUpkeep = { corruption = sawCorr, immolate = sawImmo },
                    started = started, startTime = startTime,
                    manaDrain = drained, sourceEventsAfterDrain = eventsAfterDrain,
                    samples = samples, postDrainPresses = actualPresses,
                    tapsWhileBothDotsUp = tapsWithDots,
                    acceptedBy = run.pressedBy, refused = run.refused,
                    raises = run.raises, errors = run.errors,
                    finalMana = run.us.power, finalHealth = run.us.health,
                }, ""))
                assert.is_true(sawCorr and sawImmo and started,
                    "DoTs must be genuinely applied before the starvation probe")
                assert.is_true(drained, "source-native artificial Mana drain not reached")
                assert.are.equal(3, #samples, "need 3 world-event-advanced decisions while both DoTs are active")
                assert.are.equal(0, run.raises)
                assert.are.equal(0, run.errors)
                if p.revision == "v1.0" then
                    assert.is_nil(run.pressedBy.life_tap,
                        "protected reported-working v1.0 must never cast Life Tap")
                end
                -- World health is not a Life Tap price model. Never assert safety.
            end)
        end
    end
end)
