-- FIRST new unit in user-authorised 50 breadth experiments.
-- Published Hekili Forever v0.11.0 exact pin: 86b739cbc4e6afbcbc693c3790ee81197fc6234b
-- Independent hypothesis: Combat's low-energy stale-Stealth Garrote problem
-- transfers (or does not) to Assassination; don't infer from Combat alone.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.rogue_world").Assassination)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Rogue/Current/APL_Rogue_Assassination_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local old="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&(buff.stealth.up|buff.vanish.up|buff.ghostly_strike_next.up)"
local new="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&((!combat&buff.stealth.up)|buff.vanish.up|buff.ghostly_strike_next.up)"
local escaped=old:gsub("([^%w])","%%%1")
local hypothesis,n=current:gsub(escaped,new)
assert.are.equal(1,n,"precise original Assassination opener changed; do not guess fix")
local fc=assert(io.open(root.."/roles/Rogue/Candidates/APL_Rogue_Assassination_v1.1_Draft.txt","rb"))
local guarded=assert(fc:read("*a"));fc:close()
assert.are.equal(hypothesis,guarded,
 "stored complete v1.1 Draft differs from exact validated one-line guard")
local function run(profile,seed,energy,duration)
 local world=setmetatable({power=energy,mobHealth=1000000000},{__index=stock.WORLD})
 local C=setmetatable({WORLD=world},{__index=stock})
 local L=loop.new(C); local H=L.us
 assert.are.same({},H.loadErrors)
 if profile~="shipped" then
  local apl=profile=="current" and current or guarded
  local lists,warnings=H.Hekili:ImportSimcAPL("Rogue_Assassination",
   "APLForever-Assassination-Stealth-Breadth",apl,C.PACK)
  assert.is_table(lists)
  for _,name in ipairs({"precombat","default","opener","major_cooldowns","final_fallback"}) do
   assert.is_table(lists[name],"missing complete Assassination list "..name)
  end
  assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
  assert.is_falsy((warnings or ""):find("Unknown key",1,true))
  H.Hekili.DB.profile.packs[C.PACK].lists=lists
  H.Hekili:LoadScripts()
  H.Hekili:ReviewPacks()
  for name in pairs(lists) do
   assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
  end
  assert.are.same({},H.errors)
 end
 local toggle=H.Hekili.DB.profile.toggles
 toggle.cooldowns.value=false
 toggle.minor_cooldowns.value=false
 toggle.defensives.value=false
 local refusals={},false
 local hookInstalled=false
 local rr=loop.run(L,seed,{
  duration=duration,
  on=function(w)
   if hookInstalled then return end
   local original=w.W.press
   w.W.press=function(player,key,resolved)
    local t=w.W.t
    local ok,why=original(player,key,resolved)
    if player==w.us and not ok and t>=loop.PULL and #refusals<8 then
     refusals[#refusals+1]={key=key,reason=why,t=t,cost=resolved and resolved.cost,power=player.power}
    end
    return ok,why
   end
   hookInstalled=true
  end,
 },{{H=H}})
 assert.are.equal(0,rr.errors)
 assert.are.equal(0,rr.raises)
 local rejected=0
 for reason,count in pairs(rr.refused or {}) do
  rejected=rejected+count
  print(("ASSASSINATION_REJECT_V011 profile=%s seed=%d startEnergy=%d reason=%s count=%d"):format(
   profile,seed,energy,tostring(reason),count))
 end
 for i,e in ipairs(refusals) do
  print(("ASSASSINATION_TRACE_V011 profile=%s seed=%d startEnergy=%d idx=%d t=%.3f action=%s cause=%s power=%.1f cost=%s"):format(
   profile,seed,energy,i,e.t,tostring(e.key),tostring(e.reason),
   tonumber(e.power) or -1,tostring(e.cost)))
 end
 local m=rr.pressedBy or {}
 local accepted={}
 for i=1,rr.combat do
  if type(rr.pressed[i])=="string" then accepted[#accepted+1]=rr.pressed[i] end
 end
 local major=(m.cold_blood or 0)+(m.adrenaline_rush or 0)+(m.blade_flurry or 0)
  +(m.eureka or 0)+(m.blood_fury or 0)+(m.elunes_light or 0)+(m.berserking or 0)
 print(("ASSASSINATION_BREADTH_V011 profile=%s seed=%d startEnergy=%d accepted=%d combat=%d follow=%d refused=%d garrote=%d mutilate=%d sinister=%d eviscerate=%d snd=%d majors=%d next=%s"):format(
  profile,seed,energy,rr.presses,#accepted,math.max(0,#accepted-1),
  rejected,m.garrote or 0,m.mutilate or 0,m.sinister_strike or 0,
  m.eviscerate or 0,m.slice_and_dice or 0,major,
  table.concat({accepted[2] or "-",accepted[3] or "-",accepted[4] or "-"},",")))
 return {presses=rr.presses,combat=#accepted,follow=math.max(0,#accepted-1),
  refused=rejected,major=major,garrote=m.garrote or 0,mut=m.mutilate or 0}
end
describe("Rogue Assassination full v0.11 Stealth transfer and resource fallback",function()
 for _,seed in ipairs({30417,30437}) do
  it("100 starting Energy shipped vs original vs protected guard hypothesis "..seed,function()
   local shipped=run("shipped",seed,100,75)
   local currentRun=run("current",seed,100,75)
   local guardedRun=run("guarded",seed,100,75)
   assert.is_true(shipped.combat>=4,"published shipped unable to advance")
   assert.is_true(currentRun.combat>=4,"original Current failed regular full-Energy combat")
   assert.are.equal(currentRun.presses,guardedRun.presses,
    "guard changed previously healthy normal Energy profile")
   assert.is_true(guardedRun.follow>=3,"guarded APL fails three accepted actions")
   assert.are.equal(0,guardedRun.major)
   assert.are.equal(0,guardedRun.refused,"guarded test refused a regular opener action")
  end)
  it("25 starting Energy repeat-refusal and legal later casts "..seed,function()
   local shipped=run("shipped",seed,25,100)
   local currentRun=run("current",seed,25,100)
   local guardedRun=run("guarded",seed,25,100)
   assert.is_true(shipped.combat>=3,"shipped low Energy source world stalled")
   assert.is_true(guardedRun.combat>=4 and guardedRun.follow>=3,
    "guarded hypothesis failed three genuine accepted combat follow-on actions")
   assert.are.equal(0,guardedRun.major)
   assert.are.equal(0,guardedRun.refused,
    "guarded hypothesis still repeats source-unusable Garrote or filler")
   -- Do not assert the Combat symptom occurs in Assassination. We must
   -- independently observe if Current is stuck or healthy in this class.
   assert.are.equal(501,currentRun.refused,
    "original protected Current no longer reproduces source Stealth refusal; re-evaluate comparator")
   assert.are.equal(0,currentRun.combat,
    "original Current unexpectedly advances in low Energy; re-evaluate")
   if currentRun.refused>0 then
    assert.is_true(guardedRun.combat>currentRun.combat,
     "guarded change did not recover stalled combat; re-evaluate root cause")
   end
  end)
 end
end)
