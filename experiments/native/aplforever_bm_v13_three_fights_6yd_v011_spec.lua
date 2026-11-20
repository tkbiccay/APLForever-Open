-- Source-native Hunter BM v1.3 P0: 6yd/35s/3 fights on ONE addon boot.
-- Exact published Forever v0.11.0. No runtime pet spawn, pet damage,
-- numeric DPS, synthetic combat Mana, fake source presses or gameplay proof.
local loop=require("Game.harness.loop")
local hunter=require("Forever.helpers.hunter_world")
local stock=assert(hunter.BeastMasteryTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local paths={
 ["v1.2"]="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt",
 ["v1.3"]="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.3_Draft.txt",
}
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local value=assert(f:read("*a"));f:close();return value
end
local function exercise(profile)
    local content=setmetatable({
        WORLD=setmetatable({distance=6,mobHealth=1000000000},
            {__index=stock.WORLD}),
    },{__index=stock})
    local L=loop.new(content)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    local imported,warnings=H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery","APLForever-6yd-ThreeFights",read(paths[profile]),content.PACK)
    assert.is_table(imported);assert.is_table(imported.default)
    assert.is_table(imported.major_cooldowns)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[content.PACK].lists=imported
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for list in pairs(imported) do
        assert.is_true(H.Hekili:IsListActive(content.PACK,list),"inactive "..list)
    end
    assert.are.same({},H.errors)
    assert.is_true(H.Hekili.State:IsKnown("bestial_wrath"))
    local toggles=H.Hekili.DB.profile.toggles
    toggles.cooldowns.value=true
    toggles.defensives.value=false
    toggles.movement.value=false
    local result={}
    for fight=1,3 do
        local rr=loop.run(L,30417+fight,{duration=35},{{H=H}})
        local casts=rr.pressedBy or {}
        local firstHawk
        for i=1,rr.combat do
            if rr.pressed[i]=="summon_hawk" then firstHawk=i;break end
        end
        assert.is_truthy(firstHawk,"no actual source-accepted Hawk")
        local following={}
        for i=firstHawk+1,rr.combat do
            if type(rr.pressed[i])=="string" then
                following[#following+1]=rr.pressed[i]
                if #following==3 then break end
            end
        end
        local nHawk=casts.summon_hawk or 0
        local bw=casts.bestial_wrath or 0
        print(("BM_V13_6YD_THREEFIGHTS profile=%s fight=%d hawks=%d bw=%d rapid=%d accepted=%d next_three=%s mana_end=%.2f refused=%s world_events=%d"):format(
            profile,fight,nHawk,bw,casts.rapid_fire or 0,rr.presses,
            table.concat(following,","),rr.us.power,
            tostring(next(rr.refused)~=nil),#rr.W.truth))
        assert.are.equal(0,rr.errors,"native source error")
        assert.are.equal(0,rr.raises,"native source Lua raise")
        assert.are.same({},rr.refused,"refused real source press on a re-used addon boot")
        assert.is_true(rr.presses>=3 and #rr.W.truth>3,"no meaningful fight")
        assert.is_true(nHawk>=1,"lost source-accepted Hawk on repeated pull")
        assert.are.equal(3,#following,"must accept three post-Hawk actions")
        for _,key in ipairs({"serpent_sting","arcane_shot","aimed_shot","multi_shot","rapid_fire"}) do
            assert.are.equal(0,casts[key] or 0,"illegal six-yard ranged shot/cooldown")
        end
        result[#result+1]={hawk=nHawk,bw=bw,accepted=rr.presses}
    end
    assert.are.equal(3,#result)
    return result
end
describe("Hunter BM v0.11.0 independent Bestial Wrath across 3 successive six-yard fights",function()
    it("source-accepted v1.2 reference and v1.3 candidate progress and never refuse",function()
        local a=exercise("v1.2")
        local b=exercise("v1.3")
        assert.are.equal(0,a[1].bw,"original v1.2 range gate changed")
        assert.is_true(b[1].bw>=1,"v1.3 fails its sourced cooldown fix on first fight")
        for i=1,3 do
            assert.is_true(b[i].hawk>=a[i].hawk,
                "v1.3 lost a Hawk cast on same addon boot fight "..i)
            assert.is_true(b[i].accepted>=a[i].accepted,
                "new cooldown architecture stalled accepted progression")
        end
    end)
end)

-- Unlike the three-pull world (which resets fake Mana and spell cooldown
-- on every loop.run), this ONE uninterrupted fight tests a true elapsed
-- cooldown interval in the published v0.11.0 source engine.
local function continuous(profile)
    local content=setmetatable({
        WORLD=setmetatable({distance=6,mobHealth=1000000000},
            {__index=stock.WORLD}),
    },{__index=stock})
    local L=loop.new(content)
    local H=L.us
    assert.are.same({},H.loadErrors)
    local parsed,warnings=H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery","APLForever-145s-BW-Cooldown",read(paths[profile]),content.PACK)
    assert.is_table(parsed);assert.is_table(parsed.default)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[content.PACK].lists=parsed
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
    H.Hekili.DB.profile.toggles.cooldowns.value=true
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local times={}
    local rr=loop.run(L,30417,{
        duration=145,
        on=function(r,_,t)
            if r.combat>0 and r.pressed[r.combat]=="bestial_wrath" then
                times[#times+1]=t
            end
        end,
    },{{H=H}})
    local cast=rr.pressedBy or {}
    local bw=cast.bestial_wrath or 0
    print(("BM_V13_6YD_CONTINUOUS profile=%s duration=145 accepted=%d bw=%d bw_times=%s hawks=%d rapid=%d mana_final=%.2f source_events=%d refused=%s"):format(
        profile,rr.presses,bw,table.concat(times,","),
        cast.summon_hawk or 0,cast.rapid_fire or 0,
        rr.us.power,#rr.W.truth,tostring(next(rr.refused)~=nil)))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.are.same({},rr.refused)
    assert.are.equal(bw,#times,"off-GCD BW presses missing from source clock")
    assert.is_true(rr.presses>=6 and (cast.summon_hawk or 0)>=4,
        "no source-accepted long-fight Hawk/resource progression")
    for _,key in ipairs({"serpent_sting","arcane_shot","aimed_shot","multi_shot","rapid_fire"}) do
        assert.are.equal(0,cast[key] or 0,"unusable ranged spell accepted at six yards")
    end
    for i=2,#times do
        assert.is_true(times[i]-times[i-1]>=119.9,
            "Bestial Wrath repeated before its actual source 120s cooldown")
    end
    return {bw=bw,times=times,hawk=cast.summon_hawk or 0,accepted=rr.presses}
end
describe("BM source cooldown durability across one continuous real 145-second 6yd fight",function()
    it("restored Bestial Wrath respects its 120s CD and does not harm Hawk progression",function()
        local baseline=continuous("v1.2")
        local candidate=continuous("v1.3")
        assert.are.equal(0,baseline.bw,"old 6yd range block disappeared")
        assert.is_true(candidate.bw>=1 and candidate.bw<=2,
            "source cooldown omitted or repeated too often")
        assert.is_true(candidate.hawk>=baseline.hawk,
            "candidate loses source-accepted Hawks in natural long fight")
    end)
end)
