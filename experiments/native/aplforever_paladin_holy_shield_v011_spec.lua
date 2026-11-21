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
local candidate = read("roles/Paladin/Candidates/APL_Paladin_Protection_v1.1_Draft.txt")
local prior = "actions+=/holy_shield,if=toggle.defensives&!buff.holy_shield.up"
local guard = "actions+=/holy_shield,if=action.holy_shield.known&combat>0&aggro&!buff.holy_shield.up&mana.lo>=action.holy_shield.cost&gcd.remains<=0&(group|active_enemies>=2|target.is_boss|time>=10)"
local at = assert(original:find(prior,1,true))
assert.is_nil(original:find(prior,at+#prior,true))
assert.are.equal(original:sub(1,at-1)..guard..original:sub(at+#prior),candidate,
    "new full candidate differs outside one verified Holy Shield line")
local function run(profile, threat, group, seconds, defend, lowMana)
    local content = setmetatable({
        WORLD = setmetatable({distance=4,attackers=group and 2 or 1,
            mobHealth=1e9,targetLevel=60,
            power=lowMana and stock.WORLD.max*0.55 or stock.WORLD.power,
            mobPeriod=lowMana and 2.0 or stock.WORLD.mobPeriod,
        },{__index=stock.WORLD}),
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
    local low = {first=nil, samples=0, accepted=0, checkpoints={}}
    local cursor=0
    local rr=loop.run(L,30417,{
        duration=seconds,
        on=function(r,_,t)
            if not lowMana or r.combat<=0 then return end
            local fresh=false
            for i=cursor+1,#r.W.truth do
                local ev=r.W.truth[i]
                if ev.kind=="swing" and ev.src and ev.src.kind=="mob"
                    and ev.dst and ev.dst.guid==r.us.guid then fresh=true end
            end
            cursor=#r.W.truth
            if r.us.power<=r.us.powerMax*0.25 then
                low.first=low.first or t
                if r.pressed[r.combat] then low.accepted=low.accepted+1 end
                if fresh and low.samples<3 then
                    low.samples=low.samples+1
                    local output=H.Hekili.Engine.Output.Primary
                    local rec=output and output.recs and output.recs[1]
                    low.checkpoints[#low.checkpoints+1]={
                        t=t, events=#r.W.truth,
                        suggested=r.ours[r.combat],
                        wait=rec and rec.wait or nil,
                        accepted=r.pressed[r.combat],
                    }
                end
            end
        end
    },{{H=H}})
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
    if lowMana then
        print(("PROT_LOW_MANA_V011 profile=%s first=%s swing_samples=%d accepted_after_low=%d end_mana=%.1f"):format(
            profile,tostring(low.first),low.samples,low.accepted,rr.us.power))
        assert.is_truthy(low.first,"natural 55% start never reached <=25% mana")
        assert.are.equal(3,low.samples,"no three true enemy swing checkpoints at <=25% mana")
        -- Guard the full reachable final fallback.  Three identical immediately
        -- ready recommendations with no accepted action while actual enemy
        -- swings advance are evidence of a repeated-unusable-icon failure.
        -- Nil wait is UNKNOWN, never silently interpreted as zero/ready.
        local allReady,allUnaccepted=true,true
        local previous
        for i,s in ipairs(low.checkpoints) do
            print(("PROT_LOW_MANA_TAIL profile=%s check=%d t=%.1f event=%d suggested=%s wait=%s accepted=%s"):format(
                profile,i,s.t,s.events,tostring(s.suggested),
                tostring(s.wait),tostring(s.accepted)))
            if s.suggested==nil or s.wait==nil or s.wait>0 then allReady=false end
            if s.accepted~=nil then allUnaccepted=false end
            if previous and previous~=s.suggested then allReady=false end
            previous=s.suggested
        end
        assert.is_false(allReady and allUnaccepted,
            "three identical ready-but-unaccepted final-fallback suggestions over real enemy swings")
    end
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
    it("long solo with actual threat can sustain shield after ten seconds",function()
        assert.is_true(run("v1.1",true,false,23,false)>=1)
    end)
    for _,profile in ipairs({"shipped","v1.0","v1.1"}) do
        it(profile.." real low-mana 95s with three true enemy swing checkpoints",function()
            run(profile,true,true,95,false,true)
        end)
    end
end)
