-- Issue #30 / DEMO-006: tagged Forever low-level spell unlocks and fallback.
-- Source-derived DB2 learn levels and level-adapted Wowsims content, NOT an
-- invented class kit. Level-60 Mana pool/regen and pet are retained by the
-- donor source world, so this is NOT a realistic low-level Mana/HP simulation.
local loop = require("Game.harness.loop")
local ws = require("Forever.helpers.wowsims")
local base = require("Forever.helpers.warlock_world").Demonology
local pretty = require("pl.pretty")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local learn = ws.learn("WARLOCK")
local levels = { 1, 4, 6, 10, 17, 18, 20 }
local seeds = { 30417, 30419 }

local function selected()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Warlock_Demonology" and entry.revision == "v1.0" then
            return entry
        end
    end
    error("Exact DEMO-006 reported-working baseline absent from manifest")
end

local function install(H, content)
    local entry = selected()
    local file = assert(io.open(root .. "/" .. entry.apl_file, "rb"))
    local apl = assert(file:read("*a"))
    file:close()
    local lists, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", apl, content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    H.Hekili.DB.profile.packs[content.PACK].lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.is_true(H.Hekili:IsListActive(content.PACK, "default"))
    assert.are.same({}, H.errors)
end

local function bracket(level)
    local source = ws.content(base, {
        pack = base.PACK,
        level = level,
        talents = ws.header("warlock_demonology").talents,
        learn = learn,
        race = ws.race("warlock_demonology"),
    })
    return setmetatable({
        WORLD = setmetatable({
            level = level,
            power = source.WORLD.max,
            noMelee = true,
            mobHealth = 1e9,
            mobPeriod = 1.5,
            mobDamage = { 1, 2 },
        }, { __index = source.WORLD }),
    }, { __index = source })
end

describe("DEMO-006 registered Warlock 1-20 unlock and fallback boundaries", function()
    for _, level in ipairs(levels) do
        for _, seed in ipairs(seeds) do
            for _, custom in ipairs({ true, false }) do
                local label = ("L%d/seed%d/%s"):format(level, seed, custom and "custom" or "shipped")
                it("observes actual aura upkeep then Mana-starved fallback " .. label, function()
                    local content = bracket(level)
                    local L = loop.new(content)
                    local H = L.us
                    if custom then install(H, content) end
                    H.Hekili.DB.profile.toggles.cooldowns.value = false
                    H.Hekili.DB.profile.toggles.defensives.value = false
                    local S = H.Hekili.State
                    assert.is_true(S:IsKnown("shadow_bolt"), "Shadow Bolt must be known at level 1")
                    assert.is_true(S:IsKnown("immolate"), "Immolate must be known at level 1")
                    assert.are.equal(level >= 4, S:IsKnown("corruption"), "Corruption unlock")
                    assert.are.equal(level >= 6, S:IsKnown("life_tap"), "Life Tap unlock")
                    assert.are.equal(level >= 8, S:IsKnown("bane_of_agony"), "Bane of Agony unlock")
                    assert.are.equal(level >= 18, S:IsKnown("searing_pain"), "Searing Pain unlock")

                    local immolateId = assert(H.Hekili.Class.auras.immolate).id
                    local corruptionId = assert(H.Hekili.Class.auras.corruption).id
                    local started, drained, begin, cursor = false, false, nil, 0
                    local achieved = { immolate = false, corruption = false }
                    local samples, after = {}, {}
                    local readyNoPress, lastEventTime = 0, -1
                    local run = loop.run(L, seed, {
                        duration = 48,
                        on = function(r, _, t)
                            local newWorldEvent = false
                            for i = cursor + 1, #r.W.truth do
                                local ev = r.W.truth[i]
                                if ev.kind == "swing" or ev.kind == "aura"
                                  or ev.kind == "cast" or ev.kind == "spell" then
                                    newWorldEvent = true
                                end
                            end
                            cursor = #r.W.truth
                            local target = r.us.target
                            local im = target and target.auras[immolateId]
                            local co = target and target.auras[corruptionId]
                            local imUp = im and (im.stacks or 0) > 0
                              and im.expires > r.W.t
                            local coUp = co and (co.stacks or 0) > 0
                              and co.expires > r.W.t
                            achieved.immolate = achieved.immolate or not not imUp
                            achieved.corruption = achieved.corruption or not not coUp
                            local upkeep = imUp and (level < 4 or coUp)
                            if not started and t > 3 and upkeep then
                                started, begin = true, t
                            end
                            if started and not drained and r.us.power > 0 then
                                -- External testing stimulus after *actual* world
                                -- casts have applied the unlocked upkeep auras.
                                r.W.gain(r.us, -r.us.power)
                                drained = true
                            end
                            local press = r.pressed[r.combat]
                            if drained and press then
                                after[#after + 1] = { t = t, key = press, mana = r.us.power }
                            end
                            if drained and newWorldEvent and upkeep and t >= begin + 0.4
                              and #samples < 3 and r.W.t > lastEventTime then
                                lastEventTime = r.W.t
                                local output = H.Hekili.Engine.Output.Primary
                                local rec = output.count > 0 and output.recs[1] or {}
                                local mana = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                                samples[#samples + 1] = {
                                    t = t, action = rec.actionName or "NO_ACTION",
                                    wait = rec.wait, press = press,
                                    truth = r.us.power,
                                    low = mana.lo, est = mana.est, high = mana.hi,
                                    immolate = not not imUp, corruption = not not coUp,
                                }
                                if rec.actionName and (rec.wait or 0) <= 0.05 and not press then
                                    readyNoPress = readyNoPress + 1
                                end
                            end
                        end,
                    }, { { H = H } })
                    print("DEMO006_LOWLEVEL " .. label .. " " .. pretty.write({
                        level = level, seed = seed,
                        pack = custom and "reported-working-v1.0" or "shipped-v0.8.3",
                        started = started, drained = drained,
                        achieved = achieved, samples = samples,
                        afterDrain = after, readyNoPress = readyNoPress,
                        pressed = run.pressedBy, refused = run.refused,
                        raises = run.raises, errors = run.errors,
                    }, ""))
                    assert.are.equal(0, run.raises)
                    assert.are.equal(0, run.errors)
                    -- The reported-working APL is the strict safety gate.
                    -- The default is a diagnostic comparator. Its failures
                    -- must remain visible as Failed / Not Run, not silently
                    -- treated as a passing low-level fallback test.
                    if custom then
                        assert.is_true(achieved.immolate, "Custom never naturally applied Immolate")
                        if level >= 4 then
                            assert.is_true(achieved.corruption,
                                "Custom never naturally applied unlocked Corruption")
                        end
                        assert.is_true(started and drained,
                            "Custom did not reach its post-upkeep Mana exhaustion")
                        assert.are.equal(3, #samples,
                            "Custom lacks three distinct event-advanced post-upkeep checks")
                        assert.are.same({}, run.refused,
                            "Protected custom APL caused a world refusal")
                    else
                        local state
                        if not started or not drained or #samples < 3 then
                            state = "NOT_RUN_POST_UPKEEP: default did not cast both unlocked DoTs"
                        elseif next(run.refused) ~= nil then
                            state = "FAILED_CAST_ACCEPTANCE: " .. pretty.write(run.refused, "")
                        else
                            state = "OBSERVED"
                        end
                        print("DEMO006_SHIPPED_DIAGNOSTIC " .. label .. " " .. state)
                    end
                    if level < 18 then
                        assert.is_nil(run.pressedBy.searing_pain,
                            "Searing Pain cast before level 18")
                    end
                    if level < 6 then
                        assert.is_nil(run.pressedBy.life_tap,
                            "Life Tap cast before level 6")
                    end
                    if level < 4 then
                        assert.is_nil(run.pressedBy.corruption,
                            "Corruption cast before level 4")
                    end
                    if custom then
                        assert.is_nil(run.pressedBy.life_tap,
                            "Reported-working v1.0 must not cast Life Tap")
                    end
                    -- Never infer real health cost or accurate low-level regen.
                end)
            end
        end
    end
end)
