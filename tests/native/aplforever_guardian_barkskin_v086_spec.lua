-- v0.8.6 Guardian defensive coverage counterfactual: NO shipped or protected APL changes.
-- Explicit source-class Barkskin registration + same source-world aura effect.
-- Since upstream druid_loop_world excludes Barkskin from the Guardian kit and
-- MAP, this probe extends only its development-time fixture. It is NOT a
-- test of real damage reduction, player health or live mitigation.
local loop = require("Game.harness.loop")
local ws = require("Forever.helpers.wowsims")
local druid = require("Forever.helpers.druid_loop_world")
local stock = druid.Guardian
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

-- Source: Druid.lua v0.8.6 Registers barkskin id=22812, GCD=spell,
-- cooldown=60, startsCombat=false, toggle=defensives, applyBuff on cast.
-- Source learn_druid.lua: [22812]=44. Original world omits its action.
local BARKSKIN = 22812
local m = druid.MAP
assert.is_nil(m.barkskin, "upstream Barkskin world fixture unexpectedly changed")
m.barkskin = {
    effect = function(W, e, _, X)
        local a = assert(X.aura.barkskin)
        W.applyAura(e, a.id, a.duration)
    end,
}
stock.IDS.barkskin = { BARKSKIN }

local learn = setmetatable({
    [417141] = math.huge,
    [1328617] = math.huge,
    [1328616] = 34,
}, { __index = ws.learn("DRUID") })

local function profiles()
    local out = { { name = "shipped" } }
    for _, e in ipairs(manifest) do
        if e.apl_name == "Druid_Guardian" then
            out[#out + 1] = { name = e.revision, entry = e }
        end
    end
    assert.are.equal(5, #out, "expected shipped + Guardian v1.0, v1.1, v1.2 and v1.3")
    assert.are.equal("v1.3", out[5].name)
    out[#out + 1] = { name = "v1.1-test-only-barkskin", entry = out[3].entry, experimental = true }
    assert.are.equal("v1.1", out[3].name)
    assert.are.equal("v1.2", out[4].name)
    return out
end

local function importedSource(e, experimental)
    local f = assert(io.open(root .. "/" .. e.apl_file, "rb"))
    local source = assert(f:read("*a"))
    f:close()
    if experimental then
        -- Add only one complete internally defined branch to the FULL
        -- original v1.1 in memory; the original file/hash is immutable.
        -- Apply Barkskin after Demoralising Roar but before general upkeep.
        local before = "actions+=/call_action_list,name=mitigation,if=toggle.defensives&buff.bear_form.up"
        local after = before .. "\nactions+=/call_action_list,name=defensive_cooldowns,if=toggle.defensives&buff.bear_form.up"
        local count = 0
        source, count = source:gsub(before:gsub("([^%w])", "%%%1"), function() return after end)
        assert.are.equal(1, count, "no unique mitigation line to extend")
        source = source .. "actions.defensive_cooldowns=barkskin,if=toggle.defensives&action.barkskin.known&action.barkskin.ready&buff.bear_form.up&!buff.barkskin.up&target.within5\n"
    end
    return source
end

local function examine(profile, level, on)
    local content = ws.content(stock, {
        pack = stock.PACK, level = level, learn = learn,
        talents = ws.header("druid_guardian").talents,
        race = ws.race("druid_guardian"), gear = ws.gear("druid_guardian"),
    })
    -- The original source Guardian fixture omitted Barkskin as a known
    -- spell. Add precisely the verified real level-44 spellbook unlock.
    local original = content.character
    content.character = function()
        local c = original()
        if level >= 44 then
            c.known[#c.known + 1] = BARKSKIN
        end
        return c
    end
    content.WORLD.attackers = 2
    content.WORLD.mobHealth = 1000000000
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    if profile.entry then
        local source = importedSource(profile.entry, profile.experimental)
        local lists, warnings = H.Hekili:ImportSimcAPL(profile.entry.apl_name, "APLForever", source, content.PACK)
        assert.is_table(lists)
        assert.is_table(lists.default)
        assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
        local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
        pack.lists = lists
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(content.PACK, name), "inactive internal list: " .. name)
        end
        assert.are.same({}, H.errors)
    end
    local toggles = H.Hekili.DB.profile.toggles
    toggles.defensives.value = on
    toggles.cooldowns.value = false
    toggles.movement.value = false
    assert.are.equal(level >= 44, H.Hekili.State:IsKnown("barkskin"),
        "real source trainer-level Barkskin unlock")
    local barkskinAura = assert(H.Hekili.Class.auras.barkskin).id
    local applied = 0
    local acceptedTotal, acceptedRoar = 0, 0
    local run = loop.run(L, 30417, {
        duration = 38,
        on = function(r)
            if r.pressed[r.combat] then acceptedTotal = acceptedTotal + 1 end
        end,
    }, { { H = H } })

    for _, ev in ipairs(run.W.truth) do
        if ev.kind == "aura" and ev.aura == barkskinAura and ev.dst == run.us
            and (ev.stacks or 0) > 0 then
            applied = applied + 1
        end
    end
    local barkskin = (run.pressedBy or {}).barkskin or 0
    local roar = (run.pressedBy or {}).demoralizing_roar or 0
    print(("GUARDIAN_BARKSKIN_V086 profile=%s level=%d defensives=%s barkskin=%d aura=%d roar=%d accepted=%d"):format(
        profile.name, level, tostring(on), barkskin, applied, roar, acceptedTotal))
    assert.are.equal(0, run.errors, "source engine errors")
    assert.are.equal(0, run.raises, "source engine raises")
    assert.are.same({}, run.refused, "source refused an actual recommended action")
    assert.is_true(acceptedTotal >= 2, "non-vacuous native combat progression required")
    assert.are.equal(barkskin, applied, "source-accepted Barkskin did not apply real registered aura")
    if not on or level < 44 then
        assert.are.equal(0, barkskin, "Barkskin must obey Defensives and source unlock")
    end
    if (profile.experimental or profile.name == "v1.2" or profile.name == "v1.3") and on and level >= 44 then
        assert.is_true(barkskin >= 1, "new branch never cast known ready Barkskin with Defensives ON")
        assert.is_true(roar >= 1, "Barkskin must not silently eliminate actual Roar upkeep")
    end
    return { barkskin = barkskin, roar = roar, applied = applied, acceptedTotal = acceptedTotal }
end

describe("Guardian Barkskin APL-first source coverage at v0.8.6", function()
    local p = profiles()
    for _, profile in ipairs(p) do
        for _, on in ipairs({ false, true }) do
            it(profile.name .. " level60 Defensives " .. tostring(on), function()
                examine(profile, 60, on)
            end)
        end
    end
    for _, level in ipairs({ 43, 44 }) do
        it("test-only branch real Barkskin unlock level " .. level, function()
            examine(p[6], level, true)
        end)
    end
    it("exact v1.2 standalone matches the in-memory v1.1+branch action counts", function()
        local actual = examine(p[4], 60, true)
        local proposed = examine(p[6], 60, true)
        assert.are.same(proposed, actual)
    end)
end)
