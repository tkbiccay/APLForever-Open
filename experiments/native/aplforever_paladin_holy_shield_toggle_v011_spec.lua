-- Published v0.11.0 source-world, test-only complete Paladin Protection APL.
-- Hypothesis: optional Defensives OFF hides routine Holy Shield in protected
-- v1.0; isolate whether a known-and-missing-buff guard is source-castable.
-- Earlier bounded aggro/Mana guard returned 0 casts versus shipped 3;
-- this deliberately isolates predicate gating without claiming safe production logic.
-- No candidate is stored or promoted by this experiment.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.paladin_world").Protection)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local path=root.."/roles/Paladin/Current/APL_Paladin_Protection_Tank_v1.0_Draft.txt"
local f=assert(io.open(path,"rb"))
local original=assert(f:read("*a"));f:close()
local needle="holy_shield,if=toggle.defensives&!buff.holy_shield.up"
local replacement="holy_shield,if=action.holy_shield.known&!buff.holy_shield.up"
assert(original:find(needle,1,true),"protected original gate changed")
local candidate,n=original:gsub("holy_shield,if=toggle%.defensives&!buff%.holy_shield%.up",replacement)
assert(n==1,"expected exactly one test-only Holy Shield guard")
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
    return holy
end
describe("Paladin Protection routine Holy Shield vs optional Defensives OFF",function()
    it("compare shipped, exact Current and full in-memory bounded alternative",function()
        local shipped=run("shipped",nil)
        local current=run("current",original)
        local guarded=run("test-only-guard",candidate)
        print(("PALADIN_HOLY_SHIELD_COMPARE shipped=%d current=%d guarded=%d"):format(shipped,current,guarded))
        assert.are.equal(0,current,"Current should not cast toggle-gated Holy Shield with Defensives OFF")
        -- A positive result must show actual source-accepted casts, not only import.
        assert.is_true(guarded>current,"minimal known/buff guard failed to restore accepted Holy Shield")
    end)
end)
