-- Warrior Protection Shield Block as source-observed routine tank maintenance.
-- Complete protected v1.0 in memory only; no new APL selected or stored.
-- Hekili Forever v0.11.0. World measures actual casts/auras; no survival gain.
local loop=require("Game.harness.loop")
local fake=require("Game.State.helpers.fake_api")
local protection=require("Forever.helpers.protection_gate")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Warrior/Current/APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt","rb"))
local old=assert(f:read("*a"));f:close()
local from="actions+=/call_action_list,name=survival,if=toggle.defensives&combat>0"
local to="actions+=/call_action_list,name=survival,if=combat>0&aggro&(group|active_enemies>=2|target.is_boss|time>=10)"
local pos=assert(old:find(from,1,true))
assert.is_nil(old:find(from,pos+#from,true))
local alternative=old:sub(1,pos-1)..to..old:sub(pos+#from)
local candidateFile=assert(io.open(root.."/roles/Warrior/Candidates/APL_Warrior_Protection_v1.1_Draft.txt","rb"))
local candidateSource=assert(candidateFile:read("*a"));candidateFile:close()
assert.are.equal(alternative,candidateSource,
    "full v1.1 must equal the one-condition version of protected v1.0")
local function case(profile,defend,threat,group,seconds,level)
    local C=protection.content(level or 60)
    C.WORLD=setmetatable({
        mobHealth=1000000000,attackers=group and 2 or 1,
        mobDamage={2,3},mobPeriod=2,
    },{__index=C.WORLD})
    local saved=fake.new
    fake.new=function(...)
        local api,ctl=saved(...)
        ctl.role="DAMAGER"
        api.UnitThreatSituation=function(unit)
            if unit=="player" then return threat and 3 or 0 end
            return nil
        end
        return api,ctl
    end
    local ok,L=pcall(loop.new,C)
    fake.new=saved
    assert.is_true(ok,tostring(L))
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.is_true(H.Hekili.State:IsKnown("shield_block"))
    assert.is_true(H.Hekili.State:IsKnown("revenge"))
    if profile~="shipped" then
        local apl=profile=="current" and old or candidateSource
        local lists,warnings=H.Hekili:ImportSimcAPL("Warrior_Protection",
            "APLForever",apl,C.PACK)
        assert.is_table(lists)
        assert.is_table(lists.default)
        assert.is_table(lists.survival)
        assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
        assert.is_falsy((warnings or ""):find("Unknown key",1,true))
        H.Hekili.DB.profile.packs[C.PACK].lists=lists
        H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(C.PACK,name),name)
        end
        assert.are.same({},H.errors)
    end
    H.ctl.inGroup=group
    H.ctl.groupMembers=group and 2 or 0
    H.Hekili.DB.profile.toggles.defensives.value=defend
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local cursor, acceptedSince, lastThree, repeatedReady=0,{},{},0
    local rr=loop.run(L,30417,{
        duration=seconds,
        on=function(r,_,t)
            local pressed=r.pressed[r.combat]
            if pressed then acceptedSince[pressed]=(acceptedSince[pressed] or 0)+1 end
            local fresh=false
            for i=cursor+1,#r.W.truth do
                local ev=r.W.truth[i]
                if ev.kind=="swing" and ev.src and ev.src.kind=="mob"
                    and ev.dst==r.us then fresh=true end
            end
            cursor=#r.W.truth
            if fresh then
                local out=H.Hekili.Engine.Output.Primary
                local rec=out.count>0 and out.recs[1] or {}
                local name=rec.actionName or "NO_ACTION"
                lastThree[#lastThree+1]={
                    name=name,wait=rec.wait,since=acceptedSince,t=t
                }
                if #lastThree>3 then table.remove(lastThree,1) end
                acceptedSince={}
                if #lastThree==3 then
                    local a,b,c=lastThree[1],lastThree[2],lastThree[3]
                    if a.name~="NO_ACTION" and a.name==b.name and
                        b.name==c.name and
                        (a.wait or 0)<=0.05 and (b.wait or 0)<=0.05
                        and (c.wait or 0)<=0.05 and
                        (b.since[a.name] or 0)==0 and
                        (c.since[a.name] or 0)==0 then
                        repeatedReady=repeatedReady+1
                    end
                end
            end
        end
    },{{H=H}})
    local n=(rr.pressedBy or {}).shield_block or 0
    local revenge=(rr.pressedBy or {}).revenge or 0
    local id=H.Hekili.Class.auras.shield_block.id
    local aura,swing,post=0,0,0
    local casts={}
    local paidRage=0
    local shieldID=H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.shield_block.id)
    for _,e in ipairs(rr.W.truth) do
        if e.kind=="aura" and e.aura==id and e.dst==rr.us and
            (e.stacks or 0)>0 then aura=aura+1 end
        if e.kind=="swing" and e.src and e.src.kind=="mob" and
            e.dst==rr.us then swing=swing+1 end
        if e.kind=="cast" and e.src==rr.us and e.spell==shieldID then
            casts[#casts+1]=e.t
            assert.is_true((e.cost or 0)>0,"source-true Shield Block spent no Rage")
            paidRage=paidRage+e.cost
        end
    end
    assert.are.equal(n,#casts,"count every source-true Shield Block cast")
    for i=2,#casts do
        assert.is_true(casts[i]-casts[i-1]>=4.95,
            "actual Shield Block was re-cast before source 5s cooldown")
    end
    if n>0 then
        local first
        for i=1,rr.combat do
            if rr.pressed[i]=="shield_block" then first=i;break end
        end
        assert.is_truthy(first,"actual Shield Block press missing")
        for i=first+1,rr.combat do
            if rr.pressed[i] then
                -- Off-GCD Shield Block can legally recur after its true
                -- 5-second cooldown before 3 other GCDs at every level,
                -- not only in shipped. Exact source cast interval above is
                -- the real anti-spam gate, rather than a GCD-count proxy.
                if rr.pressed[i]~="shield_block" then
                    post=post+1
                    if post==3 then break end
                end
            end
        end
        assert.is_true(post>=3,"no three accepted subsequent actions")
    end
    print(("WARRIOR_BLOCK_V011 profile=%s level=%d threat=%s group=%s defend=%s accepted_block=%d revenge=%d aura=%d paid_rage=%d swings=%d repeated=%d presses=%d refused=%s rage_end=%.1f"):format(
        profile,level or 60,tostring(threat),tostring(group),tostring(defend),
        n,revenge,aura,paidRage,swing,repeatedReady,rr.presses,tostring(next(rr.refused)~=nil),rr.us.power))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.are.same({},rr.refused,"material source refusal")
    assert.are.equal(0,repeatedReady,
        "same immediately-ready suggestion repeated across three natural enemy swings without accepted press")
    -- Accepted post-block presses are a stricter *custom* criterion; source
    -- timing and mana/rage, not identical GCD counts, adjudicate shipped.
    assert.is_true(swing>=3,"no genuinely advanced enemy swings")
    if n>0 then assert.is_true(aura>0,"block cast did not create source aura") end
    return n
end
describe("Warrior Protection v0.11.0 full APL Shield Block autonomy hypothesis",function()
    it("official shipped default with Defensives OFF accepts Shield Block",function()
        assert.is_true(case("shipped",false,true,true,48)>=1)
    end)
    it("protected Current v1.0 cannot Shield Block with Defensives OFF",function()
        assert.are.equal(0,case("current",false,true,true,48))
    end)
    it("full one-condition counterfactual restores source-accepted Shield Block OFF",function()
        assert.is_true(case("candidate",false,true,true,48)>=1)
    end)
    it("same full counterfactual can block when Defensives ON",function()
        assert.is_true(case("candidate",true,true,true,48)>=1)
    end)
    it("no source-reported threat means no routine Shield Block",function()
        assert.are.equal(0,case("candidate",false,false,true,24))
    end)
    it("short solo source threat does not waste pre-10-second Shield Block",function()
        assert.are.equal(0,case("candidate",false,true,false,8))
    end)
    it("long solo threat allows a real Shield Block if source Rage permits",function()
        local n=case("candidate",false,true,false,48)
        print("WARRIOR_BLOCK_V011 long_solo_source_accepted="..n)
    end)
    for _,level in ipairs({16,30}) do
        it("level "..level.." two attackers with source-known abilities and zero refusals",function()
            local n=case("candidate",false,true,true,48,level)
            print("WARRIOR_BLOCK_V011 lower_level="..level.." accepted_block="..n)
        end)
    end
end)
