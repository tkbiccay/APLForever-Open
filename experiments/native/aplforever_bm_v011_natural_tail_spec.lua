-- BM natural-Mana final-tail check at EXACT Hekili Forever v0.11.0.
-- Full shipped and protected Current v1.1 vs unselected full Draft v1.4.
-- Reuse the v0.9.0 actual source-world three-event checkpoint method;
-- this is NOT a DPS, pet-health, autoshot-clipping or gameplay simulator.
local loop = require("Game.harness.loop")
local hunter = require("Forever.helpers.hunter_world")
local C = assert(hunter.BeastMasteryTurret)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local files = {
    working_ref = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.1_Draft.txt",
    candidate = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt",
}
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local code=assert(f:read("*a"))
    f:close()
    return code
end
local function install(H,name)
    if name=="shipped" then return end
    local lists, warnings=H.Hekili:ImportSimcAPL("Hunter_BeastMastery",
        "APLForever-BM-Tail",read(files[name]),C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
    assert.are.same({},H.errors)
end
local function one(name,seed)
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    install(H,name)
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local lowThreshold=200 -- same historical v0.9.0 band, not a fabricated Mana value
    local samples,firstLow,minTrueMana={},nil,math.huge
    local lastTime,lastEvents=-math.huge,-1
    local acceptedLow,lowPresses={},0
    local run=loop.run(L,seed,{
        duration=210,
        on=function(world,steps,t)
            if world.combat<=0 then return end
            local mana=world.us.power
            if mana<minTrueMana then minTrueMana=mana end
            if mana>lowThreshold then return end
            if not firstLow then firstLow=t end
            local act=world.pressed[world.combat]
            if act then
                acceptedLow[act]=(acceptedLow[act] or 0)+1
                lowPresses=lowPresses+1
            end
            local count=#world.W.truth
            if #samples<3 and count>lastEvents and t-lastTime>=0.8 then
                local out=H.Hekili.Engine.Output.Primary
                local rec=out and out.recs[1] or nil
                samples[#samples+1]={
                    t=t,tick=world.combat,events=count,first=world.ours[world.combat] or "NO_ACTION",
                    wait=rec and rec.wait or 0,mana=mana,accepted=act,
                }
                lastTime,lastEvents=t,count
            end
        end,
    },{{H=H}})
    local refuses=0
    for _,n in pairs(run.refused or {}) do refuses=refuses+n end
    print(("BM_V011_NATURAL_TAIL profile=%s seed=%d accepted=%d totalRefused=%d firstLow=%s minTrueMana=%.2f lowPresses=%d samples=%d events=%d"):format(
        name,seed,run.presses,refuses,tostring(firstLow),minTrueMana,
        lowPresses,#samples,#run.W.truth))
    for i,s in ipairs(samples) do
        print(("BM_V011_LOW profile=%s seed=%d sample=%d t=%.2f tick=%d events=%d recommendation=%s wait=%.2f trueMana=%.2f accepted=%s"):format(
            name,seed,i,s.t,s.tick,s.events,s.first,s.wait or -1,s.mana,tostring(s.accepted)))
    end
    assert.are.equal(0,run.errors)
    assert.are.equal(0,run.raises)
    assert.is_true(run.presses>=3,"no true source-accepted combat actions")
    if name~="shipped" then
        assert.are.same({},run.refused,"protected custom has new real cast refusal")
    else
        -- Shipped is a comparator, never launder a source refusal into a
        -- passing assertion for a custom APL. Record its full raw count.
    end
    assert.is_not_nil(firstLow,"test failed to reach naturally low Mana")
    assert.are.equal(3,#samples,
        "low-Mana final fallback was not checked on 3 event-advanced world states")
    assert.is_true(lowPresses>=3,
        "the world must actually accept at least 3 legal later actions after entering low Mana")
    assert.is_true(samples[1].t<samples[2].t and samples[2].t<samples[3].t)
    assert.is_true(samples[1].events<samples[2].events
        and samples[2].events<samples[3].events)
    local a,b,c=samples[1],samples[2],samples[3]
    local repeated=a.first~="NO_ACTION" and a.first==b.first and b.first==c.first
        and (a.wait or 0)<=0.05 and (b.wait or 0)<=0.05
        and (c.wait or 0)<=0.05
    if repeated and name~="shipped" then
        local legal=0
        for tick=a.tick,c.tick do
            if run.pressed[tick]==a.first then legal=legal+1 end
        end
        assert.is_true(legal>0,
            "same immediately ready fallback repeated across world events with NO accepted press")
    end
    return {pressed=run.presses,refuses=refuses,firstLow=firstLow,
        minTrueMana=minTrueMana,samples=samples,acceptedAfterLow=lowPresses}
end
describe("BM v0.11.0 natural 210-second full final/fallback tail",function()
    for _,seed in ipairs({30417,30418,30419}) do
        it("seed "..seed.." shipped vs v1.1 vs full v1.4",function()
            local shipped=one("shipped",seed)
            local old=one("working_ref",seed)
            local next=one("candidate",seed)
            print(("BM_V011_COMPARISON seed=%d shipped=%d/%d current_v11=%d/%d draft_v14=%d/%d"):format(
                seed,shipped.pressed,shipped.refuses,
                old.pressed,old.refuses,next.pressed,next.refuses))
            assert.are.equal(0,next.refuses)
        end)
    end
end)
