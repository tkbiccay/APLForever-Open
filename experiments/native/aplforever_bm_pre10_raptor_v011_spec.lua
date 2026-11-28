-- Forever v0.11.0 P0 BM pre-10: source-native Raptor Strike melee coverage.
-- TEST-ONLY source-kit extension, not a new APL, pet or invented spell.
-- Published learn_hunter: Raptor Strike 2973 at level 1. Hunter.lua already
-- registers ranks and queued swing; hunter_world.MAP has queue/price/hit;
-- BM Turret's WoWSims kit omits it. ws.content kit option adds source action.
local loop=require("Game.harness.loop")
local ws=require("Forever.helpers.wowsims")
local stock=assert(require("Forever.helpers.hunter_world").BeastMasteryTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local learn=ws.learn("HUNTER")
local levels={1,4,6,9}
local distances={4,6,12}
local files={
    current="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.1_Draft.txt",
    candidate="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt"
}
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=assert(f:read("*a"));f:close();return s
end
local function contentAt(level,distance,addRaptor)
    assert.are.equal(1,learn[2973],"published Raptor level-one row changed")
    local C=ws.content(stock,{
        pack=stock.PACK,level=level,learn=learn,
        kit=addRaptor and {"raptor_strike"} or {},
        talents=ws.header("hunter_beast_mastery_turret").talents,
        race=ws.race("hunter_beast_mastery_turret"),
        gear=level==60 and ws.gear("hunter_beast_mastery_turret") or nil,
    })
    C.WORLD=setmetatable({
        level=level,distance=distance,mobHealth=1000000000,
    },{__index=C.WORLD})
    return C
end
local function install(H,C,profile)
    if profile=="shipped" then return end
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery","APLForever-BM-Raptor-Level1",
        read(files[profile]),C.PACK)
    for _,name in ipairs({"precombat","default","melee","major_cooldowns"}) do
        assert.is_table(lists[name],"missing full source list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
    end
    assert.are.same({},H.errors)
end
local function one(profile,level,distance,addRaptor)
    local C=contentAt(level,distance,addRaptor)
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    install(H,C,profile)
    local toggles=H.Hekili.DB.profile.toggles
    toggles.cooldowns.value=false
    toggles.defensives.value=false
    toggles.movement.value=false
    local known=H.Hekili.State:IsKnown("raptor_strike")
    assert.are.equal(addRaptor,known,
        "test-only source kit did not expose learned Raptor")
    assert.are.equal(level>=4,H.Hekili.State:IsKnown("serpent_sting"))
    assert.are.equal(level>=6,H.Hekili.State:IsKnown("arcane_shot"))
    assert.is_false(H.Hekili.State:IsKnown("summon_hawk"))
    local rr=loop.run(L,30417,{duration=42},{{H=H}})
    local by=rr.pressedBy or {}
    local raptor=by.raptor_strike or 0
    local refused=0
    for _,n in pairs(rr.refused or {}) do refused=refused+n end
    local sourceID=H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.raptor_strike.id)
    local queued,struck,unqueued,paid,swings=0,0,0,0,0
    for _,e in ipairs(rr.W.truth) do
        if e.src==rr.us and (e.kind=="swing" or e.kind=="strike") then
            swings=swings+1
        end
        if e.src==rr.us and e.spell==sourceID then
            if e.kind=="queue" then queued=queued+1 end
            if e.kind=="strike" then
                struck=struck+1;paid=paid+(e.cost or 0)
            end
            if e.kind=="unqueue" then unqueued=unqueued+1 end
        end
    end
    print(("BM_PRE10_RAPTOR_V011 profile=%s level=%d yd=%d augmented=%s known=%s accepted=%d refused=%d raptor=%d queue=%d strike=%d unqueue=%d strikeMana=%.1f swings=%d arcane=%d sting=%d truth=%d"):format(
        profile,level,distance,tostring(addRaptor),tostring(known),
        rr.presses,refused,raptor,queued,struck,unqueued,paid,swings,
        by.arcane_shot or 0,by.serpent_sting or 0,#rr.W.truth))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.is_true(#rr.W.truth>=3,"no true source-world progression")
    assert.is_true(rr.presses>=1,"published source accepted no setup")
    if profile~="shipped" then
        assert.are.same({},rr.refused,
            "custom full source refused a range/cost/queued Raptor cast")
    end
    if distance>5 then assert.are.equal(0,raptor,"Raptor cast outside 5yd") end
    if distance<8 then
        for _,action in ipairs({"arcane_shot","serpent_sting","aimed_shot","multi_shot"}) do
            assert.are.equal(0,by[action] or 0,
                "illegal ranged source cast under 8yd: "..action)
        end
    end
    return {n=rr.presses,by=by,refused=refused,raptor=raptor,
            queued=queued,struck=struck,paid=paid,swings=swings}
end
describe("P0 Hunter v0.11 pre-10 source Raptor kit: all 3 full APLs",function()
    for _,level in ipairs(levels) do
        for _,distance in ipairs(distances) do
            it(("level %d at %d yd, shipped / Current / v1.4"):format(level,distance),function()
                local shipped=one("shipped",level,distance,true)
                local current=one("current",level,distance,true)
                local v14=one("candidate",level,distance,true)
                if distance==4 then
                    local without=one("candidate",level,distance,false)
                    assert.are.equal(0,without.raptor)
                    assert.is_true(v14.raptor>=1,
                        "full BM candidate's melee Raptor was not source-accepted")
                    assert.is_true(v14.queued>=v14.struck,
                        "source struck more Raptor attacks than it queued")
                    assert.is_true(v14.struck>=1,
                        "accepted icon/queue without true next-swing strike")
                    assert.is_true(v14.paid>0,
                        "Raptor paid no source Mana at the actual strike")
                    assert.is_true(v14.swings>=3,
                        "no true mainhand swings to resolve next-swing")
                    assert.is_true(v14.n>without.n,
                        "source-proven new kit had no accepted combat improvement")
                elseif distance==6 then
                    assert.are.equal(0,v14.raptor)
                    assert.are.equal(0,current.raptor)
                    -- Intentional 5-8yd dead-zone; no invented ranged/melee filler.
                else
                    assert.are.equal(current.n,v14.n,
                        "source kit extension altered existing 12yd comparison")
                    assert.are.same(current.by,v14.by)
                end
                print(("BM_PRE10_RAPTOR_COMPARE level=%d yd=%d shipped=%d/%d current=%d/%d v14=%d/%d"):format(
                    level,distance,shipped.n,shipped.refused,
                    current.n,current.refused,v14.n,v14.refused))
            end)
        end
    end
end)
