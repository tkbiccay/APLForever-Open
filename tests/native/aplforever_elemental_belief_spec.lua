local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local stock = require("Forever.helpers.shaman_world").Elemental
local root = assert(os.getenv("APLFOREVER_ROOT"))

local function compare(label, apl, expectedFirst)
    local mana = stock.WORLD.max * 0.28
    local content = setmetatable({
        WORLD = setmetatable({ power = mana }, { __index = stock.WORLD }),
        character = function()
            local c = stock.character()
            c.power.value = mana
            return c
        end,
        -- The boot value is a plain fake-client read. Let the native observer
        -- make it secret on the combat transition, as in the Shaman contract.
        OBSERVE = setmetatable({ plainPower = { [0] = "ooc" } }, { __index = stock.OBSERVE }),
    }, { __index = stock })
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    if apl then
        local lists, warnings = H.Hekili:ImportSimcAPL("Shaman_Elemental", "APLForever", apl, content.PACK)
        assert.is_table(lists)
        assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
        H.Hekili.DB.profile.packs[content.PACK].lists = lists
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(content.PACK, name), name)
        end
    end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    local state, vs = H.Hekili.State, H.ns.VirtualState
    local procID = assert(H.Hekili.Class.auras.clearcasting.id)
    local shockID = assert(H.Hekili.Class.auras.flame_shock.id)
    assert.is_true(state:IsKnown("chain_lightning"))
    local seeded, first, decisions = false, nil, {}
    local refusals, delivered = {}, {}
    local fire = H.Fire
    H.Fire = function(event, unit, ...)
        if unit == "player" and (event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_POWER_FREQUENT") then
            local _, spell = ...
            delivered[#delivered + 1] = { t = H.ctl.now, event = event, spell = spell,
                exposedMana = H.ctl.power[L.power.type] }
        end
        return fire(event, unit, ...)
    end
    local run = loop.run(L, 30417, {
        duration = 30,
        on = function(r, _, t)
            local target = r.us.target
            if not seeded and t >= 3 and target and target.auras[shockID] then
                local power = vs.Power(L.power.type, H.ctl.now)
                if power.lo >= stock.WORLD.max * 0.35 then return end
                r.W.applyAura(r.us, procID, H.Hekili.Class.auras.clearcasting.duration)
                seeded = true
                local press = r.W.press
                r.W.press = function(player, key, resolved)
                    if player ~= r.us then return press(player, key, resolved) end
                    local out = H.Hekili.Engine.Output.Primary
                    local rec = out.count > 0 and out.recs[1] or {}
                    local p = vs.Power(L.power.type, H.ctl.now)
                    local aura = player.auras[procID]
                    local chain = content.resolve("chain_lightning", H)
                    local usable, why = state:IsUsable("chain_lightning")
                    local row = { t = r.W.t, action = rec.actionName, wait = rec.wait, key = key,
                        script = rec.script, mana = player.power, lo = p.lo, estimate = p.est, hi = p.hi,
                        pctLo = state.mana.pct_lo, charge = aura and aura.stacks or 0,
                        engineProc = not not vs.Aura("player", procID, H.ctl.now),
                        engineCost = state.action.chain_lightning.cost, worldCost = chain.cost,
                        chainUsable = usable, reason = why,
                        chainCooldownUntil = player.cdUntil.chain_lightning,
                        cooldownUntil = player.cdUntil[key], gcdUntil = player.gcdUntil,
                        exposedMana = H.ctl.power[L.power.type], spell = resolved.spell,
                        shockUp = not not player.target.auras[shockID] }
                    local ok, refusal = press(player, key, resolved)
                    row.accepted, row.refusal = ok, refusal
                    row.afterMana, row.pressCost = player.power, resolved.cost
                    local after = player.auras[procID]
                    row.afterCharge = after and after.stacks or 0
                    if refusal == "cost" and #refusals < 3 then
                        row.selectedUsable, row.selectedReason = state:IsUsable(key)
                        row.recentTruth = {}
                        for i = #r.W.truth, 1, -1 do
                            local e = r.W.truth[i]
                            if e.src == player and e.kind == "cast" then
                                row.recentTruth[#row.recentTruth + 1] = {
                                    t = e.t, spell = e.spell, cost = e.cost, power = e.power,
                                }
                                if #row.recentTruth == 3 then break end
                            end
                        end
                        row.clientEvents = {}
                        for i = math.max(1, #delivered - 5), #delivered do
                            row.clientEvents[#row.clientEvents + 1] = delivered[i]
                        end
                        refusals[#refusals + 1] = row
                    end
                    if #decisions < 6 then decisions[#decisions + 1] = row end
                    if not first then first = row end
                    return ok, refusal
                end
            end
        end,
    }, { { H = H } })
    local completions = {}
    for _, e in ipairs(run.W.truth) do
        if e.src == run.us and first and e.t >= first.t and #completions < 24
            and (e.kind == "cast" or e.kind == "gain" or e.kind == "aura" or e.kind == "spend") then
            completions[#completions + 1] = { t = e.t, kind = e.kind, spell = e.spell,
                aura = e.aura, stacks = e.stacks, amount = e.amount }
        end
    end
    print("ELEMENTAL_BELIEF " .. label .. " " .. pretty.write({ initialMana = mana, seeded = seeded,
        decisions = decisions, completions = completions, refused = run.refused, accepted = run.pressedBy }, ""))
    for i, row in ipairs(refusals) do
        print("ELEMENTAL_REFUSAL " .. label .. " " .. i .. " " .. pretty.write(row, ""))
    end
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    assert.is_true(seeded, "no low-belief state after real Flame Shock")
    assert.is_table(first, "no post-upkeep decision after proc")
    assert.is_true(first.shockUp and first.charge > 0 and first.engineProc)
    assert.is_nil(first.exposedMana, "numeric boot Mana leaked into combat")
    assert.is_true(first.pctLo < 35, "actual APL Mana lower bound did not reach threshold")
    assert.are.equal(0, first.worldCost)
    assert.are.equal(0, first.engineCost)
    assert.is_true(first.chainUsable, tostring(first.reason))
    assert.is_true((first.chainCooldownUntil or 0) <= first.t)
    assert.is_true(first.accepted)
    assert.are.equal(expectedFirst, first.action)
    assert.are.equal(expectedFirst, first.key)
    assert.are.equal(0, first.pressCost)
    assert.is_true(#decisions >= 3, "fewer than three post-upkeep press decisions")
    return run.refused
end

describe("Elemental v0.8.3 low-belief Clearcasting", function()
    it("compares the protected APL, shipped pack and single guard hypothesis", function()
        local f = assert(io.open(root .. "/roles/Shaman/Current/APL_Shaman_Elemental_v1.0_Draft.txt", "rb"))
        local raw = f:read("*a")
        f:close()
        local customRefused = compare("custom", raw, "lightning_bolt")
        local shippedOK, shippedResult = pcall(compare, "shipped", nil, "lightning_bolt")
        local variant, replacements = raw:gsub("buff%.clearcasting%.up&mana%.pct_lo>=35&", "buff.clearcasting.up&")
        assert.are.equal(1, replacements)
        local hypothesisOK, hypothesisResult = pcall(compare, "ST-gate-hypothesis", variant, "chain_lightning")
        assert.is_true(shippedOK, tostring(shippedResult))
        assert.is_true(hypothesisOK, tostring(hypothesisResult))
        assert.are.same({ custom = {}, shipped = {}, hypothesis = {} }, {
            custom = customRefused, shipped = shippedResult, hypothesis = hypothesisResult,
        })
    end)
end)
