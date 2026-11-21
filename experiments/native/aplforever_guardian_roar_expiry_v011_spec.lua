-- P0 Guardian v0.11.0: sustained source-native 30s Roar refresh and
-- final repeated-fallback; distinct from first-Roar proof in PR #58.
-- No fake Rage, spells, auras, health, damage or threat results; only
-- explicit fake client threat/role/group input as in published PR #58.
-- Complete shipped default, exact v1.0 working rollback, v1.5 unselected.
local loop=require("Game.harness.loop")
local fake=require("Game.State.helpers.fake_api")
local stock=assert(require("Forever.helpers.druid_loop_world").Guardian)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local paths={
    working="roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt",
    candidate="roles/Druid/Candidates/APL_Druid_Guardian_v1.5_Draft.txt",
}
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=assert(f:read("*a"));f:close();return s
end
local function worldFor(threat,distance)
    local C=setmetatable({
        SCENARIO="game",
        WORLD=setmetatable({
            distance=distance,targetLevel=60,attackers=2,mobHealth=1000000000,
        },{__index=stock.WORLD})
    },{__index=stock})
    local old=fake.new
    fake.new=function(...)
        local api,ctl=old(...)
        ctl.role="DAMAGER" -- client may report DAMAGE even with Guardian active
        api.UnitThreatSituation=function(u)
            if u=="player" then return threat and 3 or 0 end
            return nil
        end
        return api,ctl
    end
    local ok,L=pcall(loop.new,C)
    fake.new=old
    assert.is_true(ok,tostring(L))
    return L,C
end
local function install(H,C,profile)
    if profile=="shipped" then return end
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Druid_Guardian","APLForever-Guardian-Roar-Expiry",
        read(paths[profile]),C.PACK)
    for _,n in ipairs({"precombat","default","mitigation","damage",
                      "keep_up","rage_dump"}) do
        assert.is_table(lists[n],"full APL missing "..n)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,k),"inactive "..k)
    end
    assert.are.same({},H.errors)
end
local function one(profile,seed,threat,distance,seconds)
    local L,C=worldFor(threat,distance)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    install(H,C,profile)
    H.ctl.inGroup=true
    H.ctl.groupMembers=2
    local t=H.Hekili.DB.profile.toggles
    t.cooldowns.value=false
    t.defensives.value=false
    t.movement.value=false
    local foundRoarTimes={}
    local seenCombatSlots={}
    local maxRageLo=0
    local mobs=0
    local truthCursor=0
    local tailEvents={}
    local earliest=nil
    local actionSequence={}
    local lowRageTicks=0
    local hasRoarAura=false
    local sawAuraGone=false
    local rr=loop.run(L,seed,{
        duration=seconds,
        on=function(w,_,time)
            if w.combat<=0 then return end
            for idx=truthCursor+1,#w.W.truth do
                local e=w.W.truth[idx]
                if e.kind=="swing" and e.src and e.src.kind=="mob"
                    and e.dst and e.dst.guid==w.us.guid then
                    mobs=mobs+1
                end
            end
            truthCursor=#w.W.truth
            local power=H.ns.VirtualState.Power(1,H.ctl.now)
            local lo=power and power.lo or 0
            maxRageLo=math.max(maxRageLo,lo)
            if lo<10 then lowRageTicks=lowRageTicks+1 end
            local debuff=H.Hekili.State.debuff.demoralizing_roar
            if debuff.up then hasRoarAura=true
            elseif hasRoarAura then sawAuraGone=true end
            if not seenCombatSlots[w.combat] then
                local a=w.pressed[w.combat]
                if type(a)=="string" then
                    seenCombatSlots[w.combat]=true
                    actionSequence[#actionSequence+1]=a
                    if a=="demoralizing_roar" then
                        foundRoarTimes[#foundRoarTimes+1]=time
                        if not earliest then earliest=#actionSequence end
                    end
                end
            end
            if #tailEvents<3 and lo<10 and mobs>=3 then
                local rec=H.Hekili.Engine.Output.Primary
                local first=rec and rec.recs and rec.recs[1]
                tailEvents[#tailEvents+1]={
                    time=time,
                    world=#w.W.truth,
                    action=w.ours[w.combat],
                    wait=first and first.wait
                }
            end
        end
    },{{H=H}})
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.is_true(mobs>=3,"source world did not actually swing at Bear")
    assert.are.equal(threat,H.Hekili.State.aggro)
    local n=rr.pressedBy or {}
    if profile=="candidate" then
        assert.are.same({},rr.refused,
            "full candidate source-refused a ranged/cost action")
        assert.are.equal(0,n.barkskin or 0,
            "native Defensives OFF should never call Barkskin")
        assert.are.equal(0,n.elunes_light or 0,
            "native Major OFF should never call Elune's Light")
        local last=-1e10
        for _,time in ipairs(foundRoarTimes) do
            assert.is_true(time-last>=29.0,
                "Demoralising Roar source-accepted before own 30s debuff expires")
            last=time
        end
        if threat and distance<=5 then
            assert.is_true(#foundRoarTimes>=2,
                "full v1.5 never refreshed a naturally expired 30s Roar")
            assert.is_true(sawAuraGone,
                "the released source never observed an expiry window")
        else
            assert.are.equal(0,#foundRoarTimes,
                "candidate Roar without threat or outside melee reach")
        end
    end
    local follow={}
    if earliest then
        for i=earliest+1,math.min(#actionSequence,earliest+8) do
            follow[#follow+1]=actionSequence[i]
            if #follow==3 then break end
        end
        if profile=="candidate" then
            assert.are.equal(3,#follow,
                "first Roar missing three subsequent real accepted actions")
            for _,a in ipairs(follow) do
                assert.is_true(a~="demoralizing_roar",
                    "repeated Roar instead of legal post-upkeep actions")
            end
        end
    end
    local refused=0
    for _,v in pairs(rr.refused or {}) do refused=refused+v end
    local times={}
    for _,v in ipairs(foundRoarTimes) do times[#times+1]=("%.2f"):format(v) end
    print(("GUARDIAN_ROAR_EXPIRY_V011 profile=%s seed=%d threat=%s yd=%d duration=%d accepted=%d refused=%d roar=%d times=%s maxRageLo=%.2f lowRageTicks=%d swung=%d auraObserved=%s auraExpired=%s follow=%s truth=%d"):format(
        profile,seed,tostring(threat),distance,seconds,rr.presses,
        refused,n.demoralizing_roar or 0,table.concat(times,","),
        maxRageLo,lowRageTicks,mobs,tostring(hasRoarAura),
        tostring(sawAuraGone),table.concat(follow,","),#rr.W.truth))
    return {accepted=rr.presses,refused=refused,roar=n.demoralizing_roar or 0,
            times=foundRoarTimes,mobs=mobs,lowRageTicks=lowRageTicks}
end
local function compare(seed,threat,distance,seconds)
    local shipped=one("shipped",seed,threat,distance,seconds)
    local working=one("working",seed,threat,distance,seconds)
    local candidate=one("candidate",seed,threat,distance,seconds)
    print(("GUARDIAN_ROAR_EXPIRY_COMPARE seed=%d threat=%s yd=%d shipped=%d/%d/%d working=%d/%d/%d v15=%d/%d/%d"):format(
        seed,tostring(threat),distance,
        shipped.accepted,shipped.refused,shipped.roar,
        working.accepted,working.refused,working.roar,
        candidate.accepted,candidate.refused,candidate.roar))
    return candidate,working,shipped
end
describe("Guardian published v0.11 long natural Roar reapply and negative guards",function()
    for _,seed in ipairs({30417,30418}) do
        it(("grouped DAMAGER role, actual client threat, 110s seed %d"):format(seed),function()
            local c=compare(seed,true,4,110)
            assert.is_true(c.roar>=2)
        end)
    end
    it("grouped DAMAGER no threat: no wasted Roar despite 110s of combat",function()
        local c=compare(30417,false,4,110)
        assert.are.equal(0,c.roar)
    end)
    it("grouped threat but 6yd: source range cannot cast Roar",function()
        local c=compare(30417,true,6,58)
        assert.are.equal(0,c.roar)
    end)
end)
