-- BM v0.11.0 Hawk guardians: accepted-cast replenishment and real model cap.
-- Full shipped vs protected Current v1.1 vs unselected v1.4.
-- The real Forever engine models cap=2 and 18-second expiries in belief;
-- native source-world does NOT observe a genuine spawned pet or its damage.
-- No fake guardian summons / forced power / manual count or source patch.
local loop=require("Game.harness.loop")
local stock=require("Forever.helpers.hunter_world").BeastMasteryTurret
local root=assert(os.getenv("APLFOREVER_ROOT"))
local files={
    current="roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt",
    candidate="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt",
}
local function read(p)
    local f=assert(io.open(root.."/"..p,"rb"))
    local s=assert(f:read("*a"));f:close();return s
end
local function newWorld(distance)
    return setmetatable({
        SCENARIO="game",
        WORLD=setmetatable({distance=distance,mobHealth=1000000000},
            {__index=stock.WORLD}),
    },{__index=stock})
end
local function install(H,C,profile)
    if profile=="shipped" then return end
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery","APLForever-BM-Guardian-Expiry",
        read(files[profile]),C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.precombat)
    assert.is_table(lists.default)
    assert.is_table(lists.melee)
    assert.is_table(lists.major_cooldowns)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,k),"list not active: "..k)
    end
    assert.are.same({},H.errors)
end
local function run(profile,distance,seed)
    local C=newWorld(distance)
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    install(H,C,profile)
    local toggles=H.Hekili.DB.profile.toggles
    toggles.cooldowns.value=false
    toggles.defensives.value=false
    toggles.movement.value=false
    local model=assert(H.Hekili.Class.pets.hawk,
        "published Hunter source no longer registers Hawk guardian")
    assert.are.equal(2,model.cap)
    assert.are.equal(18,model.duration)
    local slot=assert(model.slot,"no real registered facade guardian slots")
    assert.is_true(slot>=6,"the five real WoW totems cannot be guardian slots")
    local seen={hawks={},sample=0,max=0,atCap=0,seenZeroAfter=0,
        countMismatch=0,expiryExamples={},countAtCast={},sentinel=0,
        first=0,sourceEvents=0}
    local lastCount=0
    local rr=loop.run(L,seed,{
        duration=72,
        on=function(w,_,t)
            if w.combat<=0 then return end
            local S=H.Hekili.State
            local q=S.query_time or H.ctl.now
            local count=S.pet.hawk.count
            assert.is_true(type(count)=="number" and count>=0 and count<=2,
                "source facade guardian count outside published cap 0..2")
            local occupancy=0
            for index=slot,slot+1 do
                local key,start,dur,expires=H.ns.VirtualState.Guardian(index)
                assert.are.equal("hawk",key)
                if dur>0 and expires>q then occupancy=occupancy+1 end
                if dur>0 and expires<=q and #seen.expiryExamples<3 then
                    seen.expiryExamples[#seen.expiryExamples+1]=
                        ("slot=%d start=%.2f dur=%.2f q=%.2f"):format(index,start,dur,q)
                end
            end
            if occupancy~=count then seen.countMismatch=seen.countMismatch+1 end
            seen.sample=seen.sample+1
            seen.max=math.max(seen.max,count)
            if count==2 then seen.atCap=seen.atCap+1 end
            if lastCount>0 and count==0 then
                seen.seenZeroAfter=seen.seenZeroAfter+1
            end
            local pressed=w.pressed[w.combat]
            if pressed=="summon_hawk" then
                seen.hawks[#seen.hawks+1]=t
                if #seen.countAtCast<8 then
                    seen.countAtCast[#seen.countAtCast+1]=
                        ("%.1f/count=%d/slot=%d"):format(t,count,occupancy)
                end
            end
            lastCount=count
        end
    },{{H=H}})
    local refused=0
    for _,n in pairs(rr.refused or {}) do refused=refused+n end
    local by=rr.pressedBy or {}
    local expired=table.concat(seen.expiryExamples,";")
    local early,earlySamples=0,{}
    for i=3,#seen.hawks do
        local dt=seen.hawks[i]-seen.hawks[i-2]
        if dt<17.8 then
            early=early+1
            if #earlySamples<4 then
                earlySamples[#earlySamples+1]=
                    ("new=%.1f since-oldest=%.1f"):format(seen.hawks[i],dt)
            end
        end
    end
    print(("BM_HAWK_V011 profile=%s distance=%d seed=%d accepted=%d refused=%d hawk=%d earlyReplacements=%d earlySamples=%s maxCount=%d atCapTicks=%d countMismatch=%d zeroAfterActive=%d samples=%d manaEnd=%.1f hawkPresses=%s expiry=%s events=%d"):format(
        profile,distance,seed,rr.presses,refused,by.summon_hawk or 0,
        early,table.concat(earlySamples,"|"),seen.max,seen.atCap,seen.countMismatch,seen.seenZeroAfter,
        seen.sample,rr.us.power or -1,table.concat(seen.countAtCast,"|"),
        expired,#rr.W.truth))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.is_true(rr.presses>=2 and #rr.W.truth>=3)
    -- The source itself, not a mocked Hawk unit, supplies cap/duration/count.
    if profile~="shipped" then
        assert.are.same({},rr.refused,
            "published source refused full imported custom action")
    end
    if profile=="candidate" then
        assert.are.equal(0,seen.countMismatch,
            "belief count differs from its own source guardian expiry slots")
        -- A third cast while two guardians are still inside their native 18s
        -- lifetime replaces a guardian early. Compare true accepted cast times,
        -- not icon polls (the world does not model guardian attacks).
        assert.are.equal(0,early,
            "candidate replaced still-live source-model guardian before 18s expiry")
        assert.is_true(seen.max>=2 and seen.atCap>=2,
            "source model never reached a positive two-guardian capped period")
    end
    return {by=by,accepted=rr.presses,refused=refused,
        early=early,seen=seen}
end

describe("Hunter BM v0.11 registered 18s/cap2 Hawk guardian / repeated cast",function()
    for _,distance in ipairs({6,12}) do
        for _,seed in ipairs({30417,30418}) do
            it(("match full shipped / Current / Candidate at %dy seed %d"):format(distance,seed),function()
                local shipped=run("shipped",distance,seed)
                local current=run("current",distance,seed)
                local candidate=run("candidate",distance,seed)
                if distance==6 then
                    assert.are.equal(0,current.by.summon_hawk or 0)
                    assert.is_true((candidate.by.summon_hawk or 0)>=2,
                        "candidate did not use legal source 6yd Hawk")
                    for _,key in ipairs({"arcane_shot","aimed_shot",
                        "multi_shot","serpent_sting"}) do
                        assert.are.equal(0,candidate.by[key] or 0,
                            "candidate accepted 8-35yd shot at 6yd: "..key)
                    end
                else
                    assert.is_true(shipped.early>=1,
                        "published shipped HHA no longer replaces an unexpired modelled Hawk: re-evaluate baseline")
                    assert.are.equal(0,current.early)
                    assert.are.equal(0,candidate.early)
                    assert.are.same(current.by,candidate.by,
                        "v1.4 changed the whole normal 12yd full-file rotation")
                    assert.are.equal(current.accepted,candidate.accepted)
                end
                print(("BM_HAWK_COMPARE distance=%d seed=%d shipped=%d/%d current=%d/%d v14=%d/%d"):format(
                    distance,seed,shipped.accepted,shipped.refused,
                    current.accepted,current.refused,
                    candidate.accepted,candidate.refused))
            end)
        end
    end
end)
