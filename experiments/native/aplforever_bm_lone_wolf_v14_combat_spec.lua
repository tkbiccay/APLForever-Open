-- Hunter BM v1.4 full APL source-native non-Lone-Wolf combat equivalence.
-- v0.11.0 published world, live source-accepted casts and natural Mana.
-- Affected pet recovery is independently verified by the matching 6-case
-- v0.11 source client-state test; no accepted Call/Revive cast is claimed.
local loop=require("Game.harness.loop")
local hunter=require("Forever.helpers.hunter_world")
local C=assert(hunter.BeastMasteryTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=assert(f:read("*a"));f:close();return s
end
local files={
  v13="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.3_Draft.txt",
  v14="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt",
}
local function run(which,distance,major)
    local content=setmetatable({
       WORLD=setmetatable({distance=distance,mobHealth=1000000000},
           {__index=C.WORLD}),
    },{__index=C})
    local L=loop.new(content)
    local H=L.us
    assert.are.same({},H.loadErrors)
    local imported,warnings=H.Hekili:ImportSimcAPL("Hunter_BeastMastery",
        "APLForever-LoneWolf-v14",read(files[which]),C.PACK)
    assert.is_table(imported);assert.is_table(imported.default)
    assert.is_table(imported.precombat);assert.is_table(imported.major_cooldowns)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=imported
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(imported) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,k),"inactive "..k)
    end
    assert.are.same({},H.errors)
    H.Hekili.DB.profile.toggles.cooldowns.value=major
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    assert.is_false(H.Hekili.State.talent.lone_wolf.enabled,
        "published BM World expected no Lone Wolf talent")
    local rr=loop.run(L,30417,{duration=42},{{H=H}})
    local by=rr.pressedBy or {}
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.are.same({},rr.refused)
    assert.is_true(rr.presses>=3 and (by.summon_hawk or 0)>=1,
        "full BM candidate lost safe Hawk/three accepted action progression")
    local firstHawk,after=nil,0
    for i=1,rr.combat do
        if rr.pressed[i]=="summon_hawk" and not firstHawk then
            firstHawk=i
        elseif firstHawk and type(rr.pressed[i])=="string" then
            after=after+1
            if after==3 then break end
        end
    end
    assert.are.equal(3,after,"fewer than three actions after first accepted Hawk")
    if distance==6 then
        for _,key in ipairs({"arcane_shot","aimed_shot","multi_shot","serpent_sting","rapid_fire"}) do
            assert.are.equal(0,by[key] or 0,"illegal 6yd ranged action")
        end
    end
    if not major then assert.are.equal(0,by.bestial_wrath or 0) end
    print(("BM_V14_NORMAL_V011 which=%s distance=%d major=%s hawks=%d bw=%d rapid=%d accepted=%d mana=%.2f refused=%s"):format(
        which,distance,tostring(major),by.summon_hawk or 0,
        by.bestial_wrath or 0,by.rapid_fire or 0,
        rr.presses,rr.us.power,tostring(next(rr.refused)~=nil)))
    return {by=by,presses=rr.presses,mana=rr.us.power}
end
describe("Hunter BM full v1.4 unchanged non-Lone-Wolf source-world rotation",function()
    for _,distance in ipairs({6,12}) do
        for _,major in ipairs({true,false}) do
            it(distance.." yards Major="..tostring(major)..": v1.3 vs v1.4 identical accepted casts and Mana",function()
                local a=run("v13",distance,major)
                local b=run("v14",distance,major)
                assert.are.same(a.by,b.by,"Lone Wolf safety guard changed regular BM accepted casts")
                assert.are.equal(a.presses,b.presses)
                assert.is_true(math.abs(a.mana-b.mana)<0.0001,
                    "Lone Wolf guard unexpectedly changed normal BM resource tail")
            end)
        end
    end
end)
