-- Proposed breadth #31: real released engine recommendation safety at unknown player health.
-- v0.12.1; synthetic client API observation controls only, NOT live health or cast proof.
-- Warrior world Bloodrage models Rage and aura, not its player health cost.
local headless=require("Game.harness.headless")
local fake=require("Game.State.helpers.fake_api")
local C=require("Forever.helpers.warrior_world")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Warrior/Current/APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt","rb"))
local current=assert(f:read("*a"));f:close()
local guarded,n=current:gsub("actions%.precombat%+=/bloodrage,use_off_gcd=1,if=",
    "actions.precombat+=/bloodrage,use_off_gcd=1,if=health.known&")
assert.are.equal(1,n,"one exact precombat Bloodrage guard only")
local function trial(profile,mode,minor,boss)
    local character=C.character()
    local old=fake.new
    fake.new=function(...)
        local api,ctl=old(...)
        local classify=api.UnitClassification
        api.UnitClassification=function(unit)
            if unit=="target" and boss then return "worldboss" end
            return classify(unit)
        end
        return api,ctl
    end
    local ok,H=pcall(headless.new,{character=character,pack=C.PACK})
    fake.new=old
    assert.is_true(ok,tostring(H))
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    if profile~="shipped" then
        local lists,warnings=H.Hekili:ImportSimcAPL("Warrior_Arms","APLForever-health-"..profile,
            profile=="current" and current or guarded,C.PACK)
        assert.is_table(lists.default);assert.is_table(lists.precombat)
        assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
        assert.is_falsy((warnings or ""):find("Unknown key",1,true))
        H.Hekili.DB.profile.packs[C.PACK].lists=lists
        H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
        for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
    end
    assert.are.same({},H.errors)
    local t=H.Hekili.DB.profile.toggles
    t.cooldowns.value=false;t.minor_cooldowns.value=minor;t.defensives.value=false
    t.movement.value=false;t.interrupts.value=false
    H.ctl.combat=false
    H.ctl.exists.target=true;H.ctl.inRange.target=true;H.ctl.distance.target=4
    H.ctl.level.target=boss and -1 or 60
    H.ctl.power[1]=0
    H.ctl.healthPlain=mode~="unknown"
    H.ctl.healthMax=1000;H.ctl.health=mode=="low" and 500 or 1000
    H.Fire("PLAYER_TARGET_CHANGED")
    H.Fire("UNIT_POWER_UPDATE","player","RAGE")
    H.Fire("SPELL_UPDATE_USABLE")
    assert.is_true(H.Hekili.Engine.Subscribe("Primary",function() end))
    assert.is_true(H.Hekili.State:IsKnown("bloodrage"),"fixture lacks Bloodrage")
    local picks,reads={},{}
    local start=H.ctl.now
    for i=1,3 do
        local worked,err=headless.cycle(H,start+i*1.65)
        assert.is_true(worked,tostring(err));assert.are.same({},H.errors)
        local out=H.Hekili.Engine.Output.Primary
        picks[i]=out.count>0 and out.recs[1].actionName or "NO_ACTION"
        H.Hekili.State.reset("Primary",true)
        local S=H.Hekili.State
        local known,pct=S.health.known,S.health.pct
        assert.are.equal(mode~="unknown",known,"health observation control not exercised")
        assert.are.equal(boss,S.target.is_boss,"boss control not exercised")
        assert.is_true(S.rage.lo<=10,"Rage gate not exercised")
        assert.is_true(math.abs(pct-(mode=="low" and 50 or 100))<1,"unexpected source health reading")
        reads[i]=string.format("%s/%.2f/%.2f",tostring(known),pct,S.rage.lo)
    end
    print(("ARMS_HEALTH_V0121 profile=%s mode=%s minor=%s boss=%s reads=%s firstIcons=%s scope=CLIENT_CONTROL_NO_CAST"):format(
        profile,mode,tostring(minor),tostring(boss),table.concat(reads,"|"),table.concat(picks,",")))
    return picks
end
local function excludes(picks)
    for _,key in ipairs(picks) do assert.are_not.equal("bloodrage",key,"repeated inappropriate Bloodrage recommendation") end
end
describe("Arms v0.12.1 full precombat Bloodrage unknown-health safety",function()
    for _,case in ipairs({
        {"unknown",true,true},{"high",true,true},{"low",true,true},
        {"high",false,true},{"high",true,false}
    }) do
        local mode,minor,boss=case[1],case[2],case[3]
        it(mode.." minor="..tostring(minor).." boss="..tostring(boss),function()
            local shipped=trial("shipped",mode,minor,boss)
            local old=trial("current",mode,minor,boss)
            local new=trial("guarded",mode,minor,boss)
            if mode=="unknown" then
                assert.are.equal("bloodrage",old[1],"historical risk not reproduced")
                excludes(new)
            elseif mode=="high" and minor and boss then
                assert.are.equal("bloodrage",old[1],"positive precombat opportunity not exercised")
                assert.are.same(old,new,"guard unexpectedly removes known-safe health opportunity")
            else
                excludes(old);excludes(new)
            end
        end)
    end
end)
