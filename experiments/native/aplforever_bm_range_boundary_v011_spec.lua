-- Hunter BM v0.11 source-native exact 8yd/35yd boundary audit.
-- Full shipped, protected Current v1.1, full Draft v1.4 and a FULL APL
-- test-only in-memory variant replacing 4 coarse outside8 gates with
-- ability-specific IsSpellInRange. It is NOT a promoted / stored APL.
-- Spell range 8-35, Hawk 0-35 from published hunter_world.lua; native
-- LibRangeCheck provides brackets, and unknown spell range may fail open.
local loop = require("Game.harness.loop")
local stock = require("Forever.helpers.hunter_world").BeastMasteryTurret
local root = assert(os.getenv("APLFOREVER_ROOT"))
local files = {
    current = "roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt",
    v14 = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt",
}
local function read(path)
    local f = assert(io.open(root.."/"..path,"rb"))
    local s = assert(f:read("*a"));f:close();return s
end
local existing=read(files.v14)
local find="target.outside8&action."
local replaced,changes=existing:gsub(find,"action.")
assert.are.equal(4,changes,
    "v1.4 exact four ranged-shot outside8 guards have changed")
assert.is_truthy(replaced:find("action.summon_hawk.in_range&pet.hawk.count<2",1,true))
local function game(distance)
    return setmetatable({
        SCENARIO="game",
        WORLD=setmetatable({distance=distance,mobHealth=1000000000},
            {__index=stock.WORLD}),
    },{__index=stock})
end
local function install(H,C,profile)
    if profile=="shipped" then return end
    local source=profile=="range_only" and replaced or read(files[profile])
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery","APLForever-Range-Boundary",source,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"default","precombat","melee","major_cooldowns"}) do
        assert.is_table(lists[name])
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive full list "..name)
    end
    assert.are.same({},H.errors)
end
local function run(profile,distance)
    local C=game(distance)
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    install(H,C,profile)
    local toggles=H.Hekili.DB.profile.toggles
    toggles.cooldowns.value=false
    toggles.defensives.value=false
    toggles.movement.value=false
    local hint,probes=nil,0
    local rr=loop.run(L,30417,{
        duration=42,
        on=function(w,_,t)
            if w.combat>0 and not hint then
                local S=H.Hekili.State
                hint={
                    outside8=S.target.outside8,
                    arcaneRange=S.action.arcane_shot.in_range,
                    stingRange=S.action.serpent_sting.in_range,
                    hawkRange=S.action.summon_hawk.in_range,
                    minR=S.target.minR,maxR=S.target.maxR,
                }
            end
            probes=probes+1
        end,
    },{{H=H}})
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.is_true(#rr.W.truth>3,"no real source world progress")
    local by=rr.pressedBy or {}
    local refused=0
    for _,n in pairs(rr.refused or {}) do refused=refused+n end
    if profile~="shipped" then
        assert.are.same({},rr.refused,
            "full custom source-refused ranged/near-target ability")
        assert.are.equal(0,by.rapid_fire or 0,"Major OFF used Rapid Fire")
        assert.are.equal(0,by.bestial_wrath or 0,"Major OFF used Bestial Wrath")
    end
    -- No 8-35yd ranged attack is source-valid below 8 or above 35,
    -- regardless of the APL's belief and the shipped default's requests.
    if distance<8 or distance>35 then
        for _,key in ipairs({"arcane_shot","serpent_sting","aimed_shot","multi_shot"}) do
            assert.are.equal(0,by[key] or 0,"illegal accepted ranged action: "..key)
        end
    end
    if distance>35 then assert.are.equal(0,by.summon_hawk or 0) end
    local acceptedFirst={}
    for i=1,rr.combat do
        local x=rr.pressed[i]
        if type(x)=="string" and #acceptedFirst<5 then
            acceptedFirst[#acceptedFirst+1]=x
        end
    end
    print(("BM_RANGE_BOUNDARY_V011 profile=%s yd=%.2f bracket=[%.1f,%.1f] outside8=%s arcaneRange=%s stingRange=%s hawkRange=%s accepted=%d refused=%d arcane=%d sting=%d aimed=%d hawk=%d manaFinal=%.1f first=%s events=%d"):format(
        profile,distance,hint and hint.minR or -1,hint and hint.maxR or -1,
        tostring(hint and hint.outside8),
        tostring(hint and hint.arcaneRange),
        tostring(hint and hint.stingRange),
        tostring(hint and hint.hawkRange),
        rr.presses,refused,by.arcane_shot or 0,by.serpent_sting or 0,
        by.aimed_shot or 0,by.summon_hawk or 0,rr.us.power or -1,
        table.concat(acceptedFirst,","),#rr.W.truth))
    return {n=rr.presses,refused=refused,by=by,
        hint=hint,first=acceptedFirst}
end
describe("Hunter BM v0.11 full-file native range bracket and actual eligible spell boundary",function()
    for _,distance in ipairs({6,7.9,8,9,10,35,35.1}) do
        it(("released source at %.2f yards against full shipped/current/v1.4 and in-memory design"):format(distance),function()
            local shipped=run("shipped",distance)
            local current=run("current",distance)
            local candidate=run("v14",distance)
            local changed=run("range_only",distance)
            assert.are.equal(0,candidate.refused)
            assert.are.equal(0,changed.refused)
            if distance<8 or distance>35 then
                -- Do not regress the known uncastable dead-zone or far range.
                assert.are.equal(0,changed.by.arcane_shot or 0)
                assert.are.equal(0,changed.by.serpent_sting or 0)
                assert.are.equal(0,changed.by.aimed_shot or 0)
            end
            print(("BM_RANGE_COMPARE yd=%.2f shipped=%d/%d current=%d/%d v14=%d/%d inrangeOnly=%d/%d"):format(
                distance,shipped.n,shipped.refused,
                current.n,current.refused,candidate.n,candidate.refused,
                changed.n,changed.refused))
        end)
    end
end)
