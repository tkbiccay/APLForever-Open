-- Guardian role-independent Roar: threat safety / client-role diagnostic.
-- Native Hekili Forever v0.10.0 published source only.
-- This fixture controls the *client-reported* role/threat BEFORE Hekili
-- captures UnitThreatSituation in its Facade. Actual dungeon visibility,
-- mitigation, survival and player threat are NOT proved.
-- Every profile imports the EXACT complete Guardian v1.4 APL except ONE
-- in-memory timing/role condition substitution. No full APL source is edited.
local loop = require("Game.harness.loop")
local fake = require("Game.State.helpers.fake_api")
local druid = require("Forever.helpers.druid_loop_world")
local stock = assert(druid.Guardian)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local file = assert(io.open(root .. "/roles/Druid/Candidates/APL_Druid_Guardian_v1.4_Draft.txt", "rb"))
local source = assert(file:read("*a"))
file:close()

local original = "((group&tanking&time>=5)|(target.is_boss&time>=4)|(solo&tanking&time>=12))"
local unguarded = "((group&time>=5)|(target.is_boss&time>=4)|(solo&time>=12))"
local guarded = "aggro&((group&time>=5)|(target.is_boss&time>=4)|(solo&time>=12))"
local function variant(name)
    if name == "v1.4" then return source end
    if name == "v1.5" then
        local f = assert(io.open(root .. "/roles/Druid/Candidates/APL_Druid_Guardian_v1.5_Draft.txt", "rb"))
        local full = assert(f:read("*a"))
        f:close()
        assert.are.equal(variant("aggro-guard"), full,
            "stored standalone v1.5 != exact source-native experimental design")
        return full
    end
    local result = name == "role-free" and unguarded or guarded
    assert.is_true(name == "role-free" or name == "aggro-guard")
    local at = assert(source:find(original, 1, true))
    assert.is_nil(source:find(original, at + #original, true))
    return source:sub(1, at-1) .. result .. source:sub(at+#original)
end

local function newScenario(role, threat)
    local content = setmetatable({
        SCENARIO = "game", -- NEVER use sim=true Roar maintenance to assert no-checkbox play
        WORLD = setmetatable({
            distance=4, targetLevel=60, attackers=2, mobHealth=1000000000,
        }, { __index=stock.WORLD }),
    }, { __index=stock })
    local originalNew = fake.new
    fake.new = function(...)
        local api, ctl = originalNew(...)
        -- Published GetSpecializationInfo returns ctl.role; this must be
        -- set before the current source initialises the pseudo-specialisation.
        ctl.role = role
        -- Published State.lua captures the source client API at load.
        api.UnitThreatSituation = function(unit)
            if unit == "player" then return threat and 3 or 0 end
            return nil
        end
        return api,ctl
    end
    local ok, L = pcall(function() return loop.new(content) end)
    fake.new = originalNew
    assert.is_true(ok, tostring(L))
    return L
end

local function run(name, role, threat, group, seconds)
    local L = newScenario(role,threat)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    assert.are.equal(role,H.ctl.role)
    assert.are.equal(role == "TANK",H.Hekili.State.role.tank)
    local imported,warnings = H.Hekili:ImportSimcAPL(
        "Druid_Guardian", "Guardian-Threat-Experiment",variant(name),stock.PACK)
    assert.is_table(imported)
    assert.is_table(imported.precombat)
    assert.is_table(imported.default)
    assert.is_table(imported.mitigation)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[stock.PACK].lists=imported
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for list in pairs(imported) do
        assert.is_true(H.Hekili:IsListActive(stock.PACK,list), "inactive "..list)
    end
    assert.are.same({},H.errors)
    H.ctl.inGroup=group
    H.ctl.groupMembers=group and 2 or 0
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local rr=loop.run(L,30417,{duration=seconds},{{H=H}})
    assert.are.equal(0,rr.raises)
    assert.are.equal(0,rr.errors)
    assert.are.same({},rr.refused)
    assert.is_true(rr.presses>=3)
    assert.is_true(#rr.W.truth>3)
    assert.are.equal(threat,H.Hekili.State.aggro)
    assert.are.equal(role == "TANK" and threat,H.Hekili.State.tanking)
    assert.are.equal(0,(rr.pressedBy or {}).barkskin or 0,
        "OFF Defensives must prevent source Barkskin")
    if ((rr.pressedBy or {}).demoralizing_roar or 0) > 0 then
        local casts = assert(rr.combatCasts, "missing actual accepted combat history")
        local first
        for i, action in ipairs(casts) do
            if action == "demoralizing_roar" then first = i; break end
        end
        assert.is_truthy(first, "Roar was not in accepted source actions")
        assert.is_true(#casts >= first+3,
            "need three real accepted post-Roar actions, not merely a first icon")
        for i=1,3 do
            assert.is_true(casts[first+i] ~= "demoralizing_roar",
                "repeated Roar immediately after an accepted cast")
        end
    end
    local n=(rr.pressedBy or {}).demoralizing_roar or 0
    print(("GUARDIAN_THREAT_V010 profile=%s role=%s group=%s source_client_aggro=%s tanking=%s accepted=%d roar=%d refused=0 source_events=%d"):format(
        name,role,tostring(group),tostring(threat),
        tostring(H.Hekili.State.tanking),rr.presses,n,#rr.W.truth))
    return {roar=n,accepted=rr.presses}
end

describe("Guardian v0.10.0 controlled-role and source-visible threat safety", function()
    it("DAMAGER client, group, no observed threat: role-free unsafe Roar, aggro guard abstains",function()
        local prev=run("v1.4","DAMAGER",false,true,38)
        local unguarded=run("role-free","DAMAGER",false,true,38)
        local guarded=run("v1.5","DAMAGER",false,true,38)
        assert.are.equal(0,prev.roar)
        assert.is_true(unguarded.roar>=1,
            "old role-free comparator changed, re-evaluate false-positive")
        assert.are.equal(0,guarded.roar,
            "client reports no aggro; role-free tank upkeep must not force Roar")
    end)
    it("DAMAGER client, group, observed threat: aggro guard restores one legal Roar",function()
        local baseline=run("v1.4","DAMAGER",true,true,38)
        local guarded=run("v1.5","DAMAGER",true,true,38)
        assert.are.equal(0,baseline.roar)
        assert.is_true(guarded.roar>=1)
        assert.is_true(guarded.roar<=2,"inappropriate repeated Roar in 38s")
    end)
    it("TANK-role client with threat: original v1.4 and aggro guard both reach Roar",function()
        local baseline=run("v1.4","TANK",true,true,38)
        local guarded=run("v1.5","TANK",true,true,38)
        assert.is_true(baseline.roar>=1,
            "source fake client role TANK still cannot satisfy original tanking")
        assert.is_true(guarded.roar>=1)
        assert.is_true(guarded.roar<=2)
    end)
    it("TANK-role client without threat must not maintain Roar",function()
        assert.are.equal(0,run("v1.4","TANK",false,true,38).roar)
        assert.are.equal(0,run("v1.5","TANK",false,true,38).roar)
    end)
    it("short solo with threat: role-independent aggro guard avoids Roar",function()
        assert.are.equal(0,run("v1.5","DAMAGER",true,false,9).roar)
    end)
end)
