-- Published v0.11.0 source-world, test-only complete Paladin Protection APL.
-- Hypothesis: optional Defensives OFF hides routine Holy Shield in protected
-- v1.0; isolate whether a known-and-missing-buff guard is source-castable.
-- Prior source-native: shipped 3, Current 0, minimal 4, combined bounded 0.
-- Isolate each of combat, aggro and conservative Mana guards independently.
-- These are diagnostic complete in-memory variants, not deployable candidates.
-- No protected APL or selection is modified.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.paladin_world").Protection)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local path=root.."/roles/Paladin/Current/APL_Paladin_Protection_Tank_v1.0_Draft.txt"
local f=assert(io.open(path,"rb"))
local original=assert(f:read("*a"));f:close()
local needle="holy_shield,if=toggle.defensives&!buff.holy_shield.up"
local base="action.holy_shield.known&!buff.holy_shield.up"
local variants={
    minimal=base,
    combat=base.."&combat>0",
    aggro=base.."&aggro",
    mana=base.."&mana.lo>=action.holy_shield.cost",
    bounded=base.."&combat>0&aggro&mana.lo>=action.holy_shield.cost",
}
local function variant(condition)
    local candidate,n=original:gsub("holy_shield,if=toggle%.defensives&!buff%.holy_shield%.up",
        "holy_shield,if="..condition)
    assert(n==1,"expected exactly one test-only Holy Shield guard")
    return candidate
end
local function run(name,text)
    local L=loop.new(stock)
    local H=L.us
    assert.are.same({},H.loadErrors)
    if text then
        local lists,warnings=H.Hekili:ImportSimcAPL("Paladin_Protection","APLForever-HolyShield-Source-Gate",text,stock.PACK)
        assert.is_table(lists)
        assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
        assert.is_falsy((warnings or ""):find("Unknown key",1,true))
        H.Hekili.DB.profile.packs[stock.PACK].lists=lists
        H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
        assert.are.same({},H.errors,"full APL source import errors")
    end
    local toggles=H.Hekili.DB.profile.toggles
    toggles.defensives.value=false
    toggles.cooldowns.value=false
    toggles.minor_cooldowns.value=false
    local rr=loop.run(L,30417,{duration=75},{{H=H}})
    local refused=0
    for _,count in pairs(rr.refused or {}) do refused=refused+count end
    local holy=(rr.pressedBy or {}).holy_shield or 0
    print(("PALADIN_HOLY_SHIELD profile=%s holy=%d accepted=%d refused=%d errors=%d raises=%d"):format(
        name,holy,rr.presses,refused,rr.errors,rr.raises))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.is_true(rr.presses>=3,"three genuine accepted actions required")
    if text then assert.are.same({},rr.refused,"custom profile cast refusal") end
    return holy,rr.presses
end
describe("Paladin Protection independent Holy Shield eligibility predicates",function()
    it("compare shipped, protected Current and each isolated predicate",function()
        local shipped=run("shipped",nil)
        local current=run("current",original)
        assert.are.equal(0,current,"protected toggle-gated baseline changed")
        local observed={}
        for _,name in ipairs({"minimal","combat","aggro","mana","bounded"}) do
            observed[name]=run(name,variant(variants[name]))
        end
        print(("PALADIN_HOLY_SHIELD_PREDICATES shipped=%d current=%d minimal=%d combat=%d aggro=%d mana=%d bounded=%d"):format(
            shipped,current,observed.minimal,observed.combat,observed.aggro,observed.mana,observed.bounded))
        assert.is_true(observed.minimal>current,"known positive control stopped casting")
        -- A guard returning zero is a genuine negative, not a CI failure.
        -- Preserve exact counts for deciding which condition needs source inspection.
    end)
end)
