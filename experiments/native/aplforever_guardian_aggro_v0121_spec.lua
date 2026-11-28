-- Hekili Forever v0.12.1: P0 Guardian's real source-client aggro guard.
-- Re-run the previous v0.10 positive/negative role experiment on the CURRENT
-- published release.  Compare shipped, exact reported-working v1.0, full
-- unselected v1.6.  No fake Rage/casts/health; the ONLY controlled states
-- are client-reported pseudo-role, threat and group; they are NOT gameplay.
local loop = require("Game.harness.loop")
local fake = require("Game.State.helpers.fake_api")
local guardian = require("Forever.helpers.druid_loop_world")
local stock = assert(guardian.Guardian)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local files = {
    working = "roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt",
    candidate = "roles/Druid/Candidates/APL_Druid_Guardian_v1.6_Draft.txt",
}
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=assert(f:read("*a"));f:close();return s
end
local function newWorld(role, threat)
    local C=setmetatable({
        SCENARIO="game", -- OFF default for the inherited working APL setting
        WORLD=setmetatable({
            distance=4, targetLevel=60, attackers=2,
            mobHealth=1000000000,
        },{__index=stock.WORLD}),
    },{__index=stock})
    local saved=fake.new
    fake.new=function(...)
        local api,ctl=saved(...)
        ctl.role=role
        api.UnitThreatSituation=function(unit)
            if unit=="player" then return threat and 3 or 0 end
            return nil
        end
        return api,ctl
    end
    local ok,L=pcall(loop.new,C)
    fake.new=saved -- never leak the client-control override into another test
    assert.is_true(ok,tostring(L))
    return L,C
end
local function install(H,C,profile)
    if profile=="shipped" then return end
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Druid_Guardian","APLForever-V0121-Roar",
        read(files[profile]),C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_table(lists.mitigation)
    assert.is_table(lists.damage)
    assert.is_table(lists.rage_dump)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for k in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,k),"inactive "..k)
    end
    assert.are.same({},H.errors)
end
local function one(profile,role,threat,group,seconds)
    local L,C=newWorld(role,threat)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    assert.are.equal(role,H.ctl.role)
    -- Activation.lua:123-138: the declared Guardian tree role overrides
    -- the client's pseudo-specialisation role. Keep the client control real.
    assert.is_true(H.Hekili.State.role.tank,"Guardian declared tank role not observed")
    print("GUARDIAN_ROLE_V0121",role,tostring(H.Hekili.State.role.tank))
    install(H,C,profile)
    H.ctl.inGroup=group
    H.ctl.groupMembers=group and 2 or 0
    local toggles=H.Hekili.DB.profile.toggles
    toggles.cooldowns.value=false
    toggles.defensives.value=false
    toggles.movement.value=false

    local mobSwings,maxRageLo=0,0
    local cursor=0
    local rr=loop.run(L,30417,{
        duration=seconds,
        on=function(world,_,time)
            if world.combat<=0 then return end
            for i=cursor+1,#world.W.truth do
                local e=world.W.truth[i]
                if e.kind=="swing" and e.src and e.src.kind=="mob"
                    and e.dst and e.dst.guid==world.us.guid then
                    mobSwings=mobSwings+1
                end
            end
            cursor=#world.W.truth
            local belief=H.ns.VirtualState.Power(1,H.ctl.now)
            maxRageLo=math.max(maxRageLo,belief and belief.lo or 0)
        end,
    },{{H=H}})
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    if profile=="candidate" then
        assert.are.same({},rr.refused,
            "full v1.6 recommended a source-refused cast")
    end
    assert.is_true(rr.presses>=3,"source did not accept three actions")
    assert.is_true(mobSwings>=3,"no three real enemy swings")
    assert.are.equal(threat,H.Hekili.State.aggro)
    assert.are.equal(threat,H.Hekili.State.tanking)
    local by=rr.pressedBy or {}
    if profile=="candidate" then
        assert.are.equal(0,by.barkskin or 0,
            "Defensives OFF must keep Barkskin disabled")
        assert.are.equal(0,by.elunes_light or 0,
            "Major cooldowns OFF must keep Elune's Light disabled")
    end

    local n=by.demoralizing_roar or 0
    local follow={}
    if n>0 then
        local first=nil
        for i=1,rr.combat do
            if rr.pressed[i]=="demoralizing_roar" then first=i;break end
        end
        assert.is_truthy(first,"reported source Roar without accepted press")
        for i=first+1,rr.combat do
            local act=rr.pressed[i]
            if type(act)=="string" then
                follow[#follow+1]=act
                if #follow>=3 then break end
            end
        end
        if profile=="candidate" then
            assert.are.equal(3,#follow,
                "full v1.6 did not follow first Roar with three actual source casts")
            for _,act in ipairs(follow) do
                assert.is_true(act~="demoralizing_roar",
                    "repeated unnecessary Roar during immediate post-upkeep fallback")
            end
        end
    end
    local refused=0
    for _,amount in pairs(rr.refused or {}) do refused=refused+amount end
    print(("GUARDIAN_AGGRO_V0121 profile=%s role=%s group=%s threat=%s s=%d accepted=%d refused=%d roar=%d firstpost=%s mobSwings=%d maxRageLo=%.2f trueFinalRage=%.2f events=%d"):format(
        profile,role,tostring(group),tostring(threat),seconds,
        rr.presses,refused,n,table.concat(follow,","),
        mobSwings,maxRageLo,rr.us.power or -1,#rr.W.truth))
    return {roar=n,accepted=rr.presses,refused=refused,
        maxRageLo=maxRageLo,follow=follow}
end
local function compare(role,threat,group,seconds)
    local shipped=one("shipped",role,threat,group,seconds)
    local working=one("working",role,threat,group,seconds)
    local candidate=one("candidate",role,threat,group,seconds)
    print(("GUARDIAN_AGGRO_COMPARE role=%s threat=%s group=%s shippedRoar=%d workingRoar=%d v16Roar=%d shippedAccepted=%d workingAccepted=%d v15Accepted=%d"):format(
        role,tostring(threat),tostring(group),
        shipped.roar,working.roar,candidate.roar,
        shipped.accepted,working.accepted,candidate.accepted))
    return candidate,working,shipped
end

describe("P0 Guardian: v0.12.1 full-file Roar aggro, false-positive and fallback",function()
    it("DAMAGER grouped, no client threat: candidate must not waste Rage on Roar",function()
        local c=compare("DAMAGER",false,true,38)
        assert.are.equal(0,c.roar)
    end)
    it("DAMAGER grouped, real client threat: v1.6 still reaches Roar despite role",function()
        local c=compare("DAMAGER",true,true,38)
        assert.is_true(c.roar>=1 and c.roar<=2,
            "role-independent upkeep failed or overcast in current release")
    end)
    it("TANK role grouped with threat: v1.6 conservatively casts Roar",function()
        local c=compare("TANK",true,true,38)
        assert.is_true(c.roar>=1 and c.roar<=2)
    end)
    it("TANK role grouped without threat: do not cast Roar",function()
        local c=compare("TANK",false,true,38)
        assert.are.equal(0,c.roar)
    end)
    it("short solo fight: avoid consuming Rage on early upkeep",function()
        local c=compare("DAMAGER",true,false,9)
        assert.are.equal(0,c.roar)
    end)
end)
