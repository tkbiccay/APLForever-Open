-- Issue #30, v0.8.6: Warrior Protection Defensives ON/OFF, natural source Rage.
-- Test-only; never edit, replace or promote any protected APL.
-- The source world models Shield Block's cast and aura, NOT verified
-- real damage prevented, threat, healer load or faithful block charges.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local root = assert(os.getenv("APLFOREVER_ROOT"))

local function read(path)
    local f = assert(io.open(path, "rb"))
    local data = f:read("*a")
    f:close()
    return data
end

local function current()
    local chosen
    for _, row in ipairs(manifest) do
        if row.apl_name == "Warrior_Protection" then
            assert.is_nil(chosen, "duplicate protection source-native revision")
            chosen = row
        end
    end
    assert.is_table(chosen)
    assert.are.equal("v1.0", chosen.revision)
    assert.are.equal("roles/Warrior/Current/APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt",
        chosen.apl_file)
    return chosen
end

local function importCurrent(H, C, entry)
    local lists, warnings = H.Hekili:ImportSimcAPL(
        entry.apl_name, "APLForever", read(root .. "/" .. entry.apl_file), C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_true(#lists.default > 0)
    assert.is_table(lists.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[C.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK, name), name)
    end
    assert.are.same({}, H.errors)
end

local function runCase(profile, defensives, level, attackers)
    local C = require("Forever.helpers.protection_gate").content(level)
    C.WORLD = setmetatable({
        mobHealth = 1000000000, attackers = attackers,
        mobDamage = { 2, 3 }, mobPeriod = 2,
    }, { __index = C.WORLD })
    local L = loop.new(C)
    local H = L.us
    local entry = current()
    assert.are.same({}, H.loadErrors)
    if profile == "current" then importCurrent(H, C, entry) end
    local toggles = H.Hekili.DB.profile.toggles
    toggles.defensives.value = defensives
    toggles.cooldowns.value = false
    toggles.movement.value = false
    local S = H.Hekili.State
    assert.is_true(S:IsKnown("shield_block"))
    assert.is_true(S:IsKnown("revenge"))
    assert.is_true(S:IsKnown("defensive_stance"))
    assert.are.equal(2, L.form)

    local shield = assert(H.Hekili.Class.abilities.shield_block)
    local shieldAura = assert(H.Hekili.Class.auras.shield_block)
    local shieldSpell = H.ns.VirtualState.KnownID(shield.id)
    local cursor, previousSwing = 0, nil
    local swings, avoids, blockAuraApplied, blockAuraTicks = 0, 0, 0, 0
    local blockCasts, blockPaid, blockSpent = 0, 0, 0
    local revengeCasts, revengeSpent, revengeOutsideWindow = 0, 0, 0
    local lastAvoid, accepted, repeated, unknownPresses = nil, 0, 0, 0
    local minRage, maxRage, lowRageSwings = math.huge, -math.huge, 0
    local since, first = {}, {}
    local result = loop.run(L, 30417, {
        duration = 48,
        on = function(r, _, t)
            local pressed = r.pressed[r.combat]
            if pressed then
                accepted = accepted + 1
                since[pressed] = (since[pressed] or 0) + 1
                if not S:IsKnown(pressed) then unknownPresses = unknownPresses + 1 end
            end
            minRage = math.min(minRage, r.us.power)
            maxRage = math.max(maxRage, r.us.power)
            if r.us.auras[shieldAura.id] then
                blockAuraTicks = blockAuraTicks + 1
            end
            local freshSwing = false
            for i = cursor + 1, #r.W.truth do
                local ev = r.W.truth[i]
                if ev.kind == "aura" and ev.dst == r.us
                    and ev.aura == shieldAura.id and (ev.stacks or 0) > 0 then
                    blockAuraApplied = blockAuraApplied + 1
                end
                if ev.kind == "cast" and ev.src == r.us then
                    if ev.spell == shieldSpell then
                        blockCasts = blockCasts + 1
                        if (ev.cost or 0) > 0 then
                            blockPaid = blockPaid + 1
                            blockSpent = blockSpent + ev.cost
                        end
                    elseif ev.spell == H.ns.VirtualState.KnownID(
                        H.Hekili.Class.abilities.revenge.id) then
                        revengeCasts = revengeCasts + 1
                        revengeSpent = revengeSpent + (ev.cost or 0)
                    end
                end
                if ev.kind == "swing" and ev.dst == r.us and
                    (ev.act == "DODGE" or ev.act == "PARRY" or ev.act == "BLOCK") then
                    lastAvoid = ev.t
                    avoids = avoids + 1
                end
                if ev.kind == "swing" and ev.src and ev.src.kind == "mob"
                    and ev.dst == r.us and ev.t ~= previousSwing then
                    previousSwing = ev.t
                    freshSwing = true
                    swings = swings + 1
                end
            end
            cursor = #r.W.truth
            -- Match the proven native progression observer: settle all new
            -- truth swings before validating a Revenge pressed this tick.
            -- The accepted action may follow an avoid in the same batch.
            if pressed == "revenge" and
                (not lastAvoid or t - lastAvoid > 5) then
                revengeOutsideWindow = revengeOutsideWindow + 1
            end
            if freshSwing then
                if r.us.power < shield.spend then lowRageSwings = lowRageSwings + 1 end
                local output = H.Hekili.Engine.Output.Primary
                local rec = output.count > 0 and output.recs[1] or {}
                local sample = {
                    name = rec.actionName or "NO_ACTION", wait = rec.wait, since = since,
                    t = t, rage = r.us.power,
                }
                first[#first + 1] = sample
                if #first > 3 then table.remove(first, 1) end
                since = {}
                if #first == 3 then
                    local a, b, c = first[1], first[2], first[3]
                    if a.name ~= "NO_ACTION" and a.name == b.name
                        and b.name == c.name and (a.wait or 0) <= 0.05
                        and (b.wait or 0) <= 0.05 and (c.wait or 0) <= 0.05
                        and (b.since[a.name] or 0) == 0
                        and (c.since[a.name] or 0) == 0 then
                        repeated = repeated + 1
                    end
                end
            end
        end,
    }, { { H = H } })

    print("WARRIOR_PROT_DEFENSIVES_V086 " .. profile
        .. " " .. (defensives and "ON" or "OFF") .. " L" .. level
        .. " attackers=" .. attackers .. " " .. pretty.write({
            seed = 30417, source = "v0.8.6",
            hash = profile == "current" and entry.sha256 or "shipped",
            presses = result.pressedBy, refused = result.refused,
            errors = result.errors, raises = result.raises,
            swings = swings, avoidWindows = avoids, accepted = accepted,
            shieldBlockCastEvents = blockCasts,
            shieldBlockPaidCasts = blockPaid, shieldBlockRageCost = blockSpent,
            sourceBuffApplied = blockAuraApplied, sourceBuffObservedTicks = blockAuraTicks,
            revengeCastEvents = revengeCasts, revengeRageCost = revengeSpent,
            revengeOutsideAvoidWindow = revengeOutsideWindow,
            minRage = minRage, maxRage = maxRage, lowRageSwings = lowRageSwings,
            unknownAccepted = unknownPresses, repeatedReady = repeated,
            lastThree = first,
        }, ""))

    assert.are.equal(0, result.errors)
    assert.are.equal(0, result.raises)
    assert.is_true(swings >= 3, "need three genuine hostile world swings")
    assert.is_true(accepted >= 2, "world has no meaningful source-accepted actions")
    assert.are.same({}, result.refused, "source refused cast")
    assert.are.equal(0, unknownPresses, "unknown rank was accepted")
    assert.are.equal(0, revengeOutsideWindow, "Revenge outside source avoid window")
    assert.are.equal(0, repeated, "three ready same icons after real swings, no accepted cast")
    assert.are.equal(result.pressedBy.shield_block or 0, blockCasts,
        "Shield Block press not reconciled to real source cast events")
    assert.are.equal(blockCasts, blockPaid,
        "Shield Block cast did not pay real Rage in source")
    if blockCasts > 0 then
        assert.is_true(blockSpent > 0)
        assert.is_true(blockAuraApplied > 0)
        assert.is_true(blockAuraTicks > 0)
    end
    if profile == "current" and not defensives then
        assert.is_nil(result.pressedBy.shield_block,
            "protected custom shield block broke Defensives OFF")
        assert.are.equal(0, blockAuraApplied)
    end
    -- Source-world Shield Block application is a true aura event, not
    -- proof of charges consumed or prevented damage. No positive survival
    -- assertion is made from these counters.
end

describe("Warrior Protection source-native Shield Block Defensives on/off v0.8.6", function()
    for _, level in ipairs({ 16, 30, 60 }) do
        for _, attackers in ipairs({ 1, 2 }) do
            for _, profile in ipairs({ "current", "shipped" }) do
                for _, defensives in ipairs({ false, true }) do
                    it(profile .. " L" .. level .. " attackers=" .. attackers ..
                        " defensives=" .. tostring(defensives), function()
                            runCase(profile, defensives, level, attackers)
                        end)
                end
            end
        end
    end
end)
