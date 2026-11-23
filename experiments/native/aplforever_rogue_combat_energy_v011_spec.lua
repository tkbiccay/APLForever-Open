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
  if profile=="current" or profile=="guarded" then
    local apl=current
    if profile=="guarded" then
      local old="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&(buff.stealth.up|buff.vanish.up|buff.ghostly_strike_next.up)"
      local new="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&((!combat&buff.stealth.up)|buff.vanish.up|buff.ghostly_strike_next.up)"
      local n
      apl,n=apl:gsub(old:gsub("([^%w])","%%%1"),new)
      assert.are.equal(1,n,"original Current Garrote opener guard changed unexpectedly")
    end
    local lists,warnings=H.Hekili:ImportSimcAPL("Rogue_Combat",
      "APLForever-Rogue-Combat-Breadth",apl,C.PACK)
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
  local trace,hookInstalled={},false
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(w)
      if hookInstalled then return end
      local raw=w.W.press
      w.W.press=function(player,key,resolved)
        local t0=w.W.t
        local ok,why=raw(player,key,resolved)
        if player==w.us and not ok and t0>=loop.PULL and #trace<7 then
          trace[#trace+1]={key=key,reason=why,t=t0,
            energy=player.power, cost=resolved and resolved.cost}
        end
        return ok,why
      end
      hookInstalled=true
    end,
  },{{H=H}})
  for i,e in ipairs(trace) do
    print(("ROGUE_TRACE profile=%s seed=%d energy=%d idx=%d t=%.2f key=%s reason=%s energyWorld=%.2f cost=%s"):format(
      profile,seed,energy,i,e.t,tostring(e.key),tostring(e.reason),
      tonumber(e.energy) or -1,tostring(e.cost)))
  end
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
      local guarded=run("guarded",seed,100,75)
      assert.are.equal(0,guarded.refused,"one-guard in-memory candidate regressed normal Energy")
      assert.is_true(guarded.follow>=3)
      assert.are.equal(0,guarded.major)
    end)
    it("low initial Energy and natural regen seed "..seed,function()
      local shipped=run("shipped",seed,25,100)
      local currentRun=run("current",seed,25,100)
      local guarded=run("guarded",seed,25,100)
      assert.is_true(shipped.combat>=3,"shipped low Energy did not advance")
      assert.are.equal(501,currentRun.refused,
        "original protected Current low-Energy symptom changed; re-investigate")
      assert.are.equal(0,currentRun.combat,
        "original Current unexpectedly advanced; re-investigate")
      assert.is_true(guarded.combat>=4,
        "in-memory guarded candidate lost three legal low-Energy follow-on actions")
      assert.is_true(guarded.follow>=3)
      assert.are.equal(0,guarded.major)
      assert.are.equal(0,guarded.refused,
        "in-memory guard failed to prevent rejected Garrote recommendations")
    end)
  end
end)
