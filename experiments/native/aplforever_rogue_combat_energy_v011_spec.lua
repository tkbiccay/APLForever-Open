-- v0.11.0 Rogue Combat breadth: shipped vs immutable Current, source-native only.
-- Hypothesis: low starting Energy still permits three legal follow-on actions,
-- without repeated unaffordable recommendations or Major OFF violations.
-- This world does not prove damage, real-client energy timing or threat.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.rogue_world").Combat)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Rogue/Current/APL_Rogue_Combat_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local function run(profile,seed,energy,duration)
  local world=setmetatable({power=energy,mobHealth=1000000000},{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Rogue_Combat",
      "APLForever-Rogue-Combat-Breadth",current,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","final_fallback"}) do
      assert.is_table(lists[name],"missing complete list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),name)
    end
    assert.are.same({},H.errors)
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.minor_cooldowns.value=false
  t.defensives.value=false
  local rr=loop.run(L,seed,{duration=duration},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for reason,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("ROGUE_COMBAT_REFUSED profile=%s seed=%d energy=%d reason=%s count=%d"):format(
      profile,seed,energy,tostring(reason),n))
  end
  local m=rr.pressedBy or {}
  local combat={}
  for i=1,rr.combat do
    if type(rr.pressed[i])=="string" then combat[#combat+1]=rr.pressed[i] end
  end
  local follow=math.max(0,#combat-1)
  print(("ROGUE_COMBAT_V011 profile=%s seed=%d energy=%d accepted=%d combat=%d follow=%d refused=%d sinister=%d slice=%d evis=%d blade=%d rush=%d"):format(
    profile,seed,energy,rr.presses,#combat,follow,refused,
    m.sinister_strike or 0,m.slice_and_dice or 0,m.eviscerate or 0,
    m.blade_flurry or 0,m.adrenaline_rush or 0))
  return {accepted=rr.presses,combat=#combat,follow=follow,refused=refused,
    major=(m.blade_flurry or 0)+(m.adrenaline_rush or 0),
    slice=m.slice_and_dice or 0,finisher=m.eviscerate or 0,
    sinister=m.sinister_strike or 0}
end
describe("Rogue Combat v0.11 complete source-native energy/fallback",function()
  for _,seed in ipairs({30417,30437}) do
    it("normal Energy with deliberate Major OFF seed "..seed,function()
      local shipped=run("shipped",seed,100,75)
      local candidate=run("current",seed,100,75)
      assert.is_true(shipped.combat>=3,"shipped did not advance")
      assert.is_true(candidate.combat>=4,"Current lost three follow-on accepted actions")
      assert.is_true(candidate.follow>=3)
      assert.are.equal(0,candidate.major,"Current violated native Major OFF")
      assert.are.equal(0,candidate.refused,"Current repeated source-refused recommendation")
    end)
    it("low initial Energy and natural regen seed "..seed,function()
      local shipped=run("shipped",seed,25,100)
      local candidate=run("current",seed,25,100)
      assert.is_true(shipped.combat>=3,"shipped low Energy did not advance")
      assert.is_true(candidate.combat>=4,"Current low Energy lost follow-on actions")
      assert.is_true(candidate.follow>=3)
      assert.are.equal(0,candidate.major)
      assert.are.equal(0,candidate.refused,"Current repeatedly recommended unaffordable action")
    end)
  end
end)
