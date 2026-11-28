-- Source-native Hunter BM v0.11.0 three consecutive fights on one addon boot.
-- Ported carefully from the historic v0.8.3 three-fight gate. No source
-- pet arrival, fake bonus cast, numerical DPS, or gameplay proof.
local loop = require("Game.harness.loop")
local hunter = require("Forever.helpers.hunter_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local stock = assert(hunter.BeastMasteryTurret,"published v0.11.0 BM turret fixture missing")
local content = setmetatable({
    WORLD = setmetatable({distance=12,mobHealth=1000000000},
        {__index=stock.WORLD}),
},{__index=stock})
local files = {
    ["current-v1.1"] = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.1_Draft.txt",
    ["candidate-v1.2"] = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt",
}
local function sortedCounts(counts)
    local keys={}
    for k in pairs(counts or {}) do keys[#keys+1]=k end
    table.sort(keys)
    local parts={}
    for _,k in ipairs(keys) do
        parts[#parts+1]=k.."="..tostring(counts[k])
    end
    return table.concat(parts,",")
end
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local data=assert(f:read("*a"));f:close()
    return data
end
local function import(H,profile)
    local path=assert(files[profile],"no unknown source role imported")
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery","APLForever-Three-Fights",read(path),content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    local pack=assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK,name),name)
    end
    assert.are.same({},H.errors)
end
local function run(profile)
    local L=loop.new(content)
    local H=L.us
    assert.are.same({},H.loadErrors)
    if profile~="shipped" then import(H,profile) end
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local total={fights=0,hawks=0,arcane=0,presses=0}
    for fight=1,3 do
        local tail,firstHawk={},nil
        local result=loop.run(L,30417+fight,{
            duration=35,
            on=function(r,_,t)
                local press=r.pressed[r.combat]
                if press and press=="summon_hawk" then firstHawk=firstHawk or r.combat end
                if press and firstHawk and r.combat>firstHawk and #tail<4 then
                    tail[#tail+1]=press
                end
            end
        },{{H=H}})
        local pressed=result.pressedBy or {}
        local hawk=pressed.summon_hawk or 0
        local arcane=pressed.arcane_shot or 0
        print(("BM_3FIGHTS_V011 profile=%s fight=%d hawk=%d arcane=%d accepted=%d refused=%s errors=%d raises=%d post_hawk=%s world_t=%.2f counts=%s mana_end=%.2f"):format(
            profile,fight,hawk,arcane,result.presses,
            tostring(next(result.refused)~=nil),result.errors,result.raises,
            table.concat(tail,","),result.W.t,sortedCounts(pressed),result.us.power))
        assert.are.equal(0,result.errors,"source world errors")
        assert.are.equal(0,result.raises,"Lua engine raises")
        assert.are.same({},result.refused,"source refused a recommendation after session reset")
        assert.is_true(result.presses>=3,"no useful accepted actions in 35-second pull")
        assert.is_true(result.combat>=20,"no meaningful combat progression")
        assert.is_true(hawk>=1,"lost source-accepted Hawk on one of three pulls")
        assert.is_true(#tail>=3,"no 3 accepted post-Hawk actions on this fight")
        total.fights=total.fights+1
        total.hawks=total.hawks+hawk
        total.arcane=total.arcane+arcane
        total.presses=total.presses+result.presses
    end
    assert.are.equal(3,total.fights)
    print(("BM_3FIGHTS_V011_TOTAL profile=%s hawks=%d arcane=%d accepted=%d"):format(
        profile,total.hawks,total.arcane,total.presses))
    return total
end
describe("Hunter BM v0.11.0 three fights, exact complete APLs and no reload",function()
    for _,profile in ipairs({"shipped","current-v1.1","candidate-v1.2"}) do
        it(profile.." accepts Hawk, has 3 post-Hawk casts and zero refusals in each fight",function()
            run(profile)
        end)
    end
end)
