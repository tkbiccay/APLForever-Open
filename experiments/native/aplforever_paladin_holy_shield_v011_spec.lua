-- Source-native Protection Paladin self-contained Holy Shield. Forever v0.11.0 only.
-- Full original v1.0, complete Draft v1.1 and shipped reference, identical world.
local loop = require("Game.harness.loop")
local fake = require("Game.State.helpers.fake_api")
local stock = require("Forever.helpers.paladin_world").Protection
local root = assert(os.getenv("APLFOREVER_ROOT"))
local function read(p)
    local f = assert(io.open(root.."/"..p,"rb"))
    local s = assert(f:read("*a")); f:close()
    return s
end
local original = read("roles/Paladin/Current/APL_Paladin_Protection_Tank_v1.0_Draft.txt")
local candidate = read("roles/Paladin/Candidates/APL_Paladin_Protection_Tank_v1.1_Draft.txt")
local prior = "actions+=/holy_shield,if=toggle.defensives&!buff.holy_shield.up"
local guard = "actions+=/holy_shield,if=action.holy_shield.known&combat>0&aggro&!buff.holy_shield.up&mana.lo>=action.holy_shield.cost&gcd.remains<=0&(group|active_enemies>=2|target.is_boss|time>=10)"
local at = assert(original:find(prior,1,true))
assert.is_nil(original:find(prior,at+#prior,true))
assert.are.equal(original:sub(1,at-1)..guard..original:sub(at+#prior),candidate,
    "new full candidate differs outside one verified Holy Shield line")
local function run(profile, threat, group, seconds, defend)
    local content = setmetatable({
        WORLD = setmetatable({distance=4,attackers=group and 2 or 1,
            mobHealth=1e9,targetLevel=60},{__index=stock.WORLD}),
    },{__index=stock})
    local saved = fake.new
    fake.new = function(...)
        local api,ctl = saved(...)
        ctl.role = "DAMAGER"
        api.UnitThreatSituation = function(unit)
            if unit=="player" then return threat and 3 or 0 end
            return nil
        end
        return api,ctl
    end
    local ok,L=pcall(loop.new,content)
    fake.new=saved
    assert.is_true(ok,tostring(L))
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.is_true(H.Hekili.State:IsKnown("holy_shield"))
    if profile~="shipped" then
        local lists,warnings=H.Hekili:ImportSimcAPL("Paladin_Protection",
            "APLForever",profile=="v1.0" and original or candidate,content.PACK)
        assert.is_table(lists); assert.is_table(lists.default)
        assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
        assert.is_falsy((warnings or ""):find("Unknown key",1,true))
        H.Hekili.DB.profile.packs[content.PACK].lists=lists
        H.Hekili:LoadScripts(); H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(content.PACK,name))
        end
        assert.are.same({},H.errors)
    end
    H.ctl.inGroup=group
    H.ctl.groupMembers=group and 2 or 0
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.defensives.value=defend
    H.Hekili.DB.profile.toggles.movement.value=false
    local rr=loop.run(L,30417,{duration=seconds},{{H=H}})
    local n=(rr.pressedBy or {}).holy_shield or 0
    local auraID=H.Hekili.Class.auras.holy_shield.id
    local aura=0
    for _,e in ipairs(rr.W.truth) do
        if e.kind=="aura" and e.aura==auraID
            and e.dst and e.dst.guid==rr.us.guid
            and (e.stacks or 0)>0 then aura=aura+1 end
    end
    local post=0
    if n>0 then
        local first
        for i=1,rr.combat do
            if rr.pressed[i]=="holy_shield" then first=i;break end
        end
        assert.is_truthy(first,"no record for accepted Holy Shield")
        for i=first+1,rr.combat do
            if type(rr.pressed[i])=="string" then
                assert.is_true(rr.pressed[i]~="holy_shield",
                    "repeated shield before three accepted post-casts")
                post=post+1
                if post==3 then break end
            end
        end
    end
    print(("PROT_HS_V011 profile=%s aggro=%s group=%s defend=%s accepted_hs=%d aura=%d next3=%d accepted=%d refused=%s mana=%.1f"):format(
        profile,tostring(threat),tostring(group),tostring(defend),
        n,aura,post,rr.presses,tostring(next(rr.refused)~=nil),rr.us.power))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.are.same({},rr.refused)
    if n>0 then
        assert.is_true(aura>=1,"no source-true Holy Shield aura")
        assert.are.equal(3,post,"missing three subsequent actual accepted actions")
    end
    return n
end
describe("Protection Paladin routine Holy Shield v0.11.0",function()
    it("shipped default with Defensives OFF still applies Holy Shield",function()
        assert.is_true(run("shipped",true,true,38,false)>=1)
    end)
    it("protected v1.0 with Defensives OFF never recommends Holy Shield",function()
        assert.are.equal(0,run("v1.0",true,true,38,false))
    end)
    it("complete v1.1 with Defensives OFF uses shield and continues",function()
        assert.is_true(run("v1.1",true,true,38,false)>=1)
    end)
    it("complete v1.1 with Defensives ON also uses shield",function()
        assert.is_true(run("v1.1",true,true,38,true)>=1)
    end)
    it("no threat: does not demand upkeep in group",function()
        assert.are.equal(0,run("v1.1",false,true,28,false))
    end)
    it("short solo mob: avoids early shield",function()
        assert.are.equal(0,run("v1.1",true,false,8,false))
    end)
end)
