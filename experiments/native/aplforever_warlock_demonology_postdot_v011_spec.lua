-- DEMO-006 cross-release source-native regression. Published Hekili Forever
-- v0.11.0 pin 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Full shipped/Current ReportedWorking v1.0. Never treat source Life Tap as
-- safe; the released Warlock world restores Mana WITHOUT player health debit.
-- Instrument actual W.press acceptance chronology instead of rr.pressed ticks.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.warlock_world").Demonology)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt","rb"))
local working=assert(f:read("*a"));f:close()
assert.is_nil(working:find("life_tap",1,true),
 "reported-working APL unexpectedly contains Life Tap; DEMO-006 baseline changed")
local dotKeys={corruption=true,immolate=true,bane_of_agony=true,bane_of_doom=true}
local offence={shadow_bolt=true,searing_pain=true,immolate=true,corruption=true,
 bane_of_agony=true,bane_of_doom=true,soul_fire=true,rain_of_fire=true,incinerate=true}
local function one(profile,seed,initial,duration)
 local W=setmetatable({distance=25,power=initial,mobHealth=1000000000},
  {__index=stock.WORLD})
 local C=setmetatable({WORLD=W},{__index=stock})
 local L=loop.new(C);local H=L.us
 assert.are.same({},H.loadErrors)
 assert.are.same({},H.Hekili.Class.loadErrors or {})
 if profile=="working" then
   local lists,warnings=H.Hekili:ImportSimcAPL("Warlock_Demonology",
     "APLForever-Demo-006-Work",working,C.PACK)
   assert.is_table(lists)
   for _,name in ipairs({"precombat","default","banes","curses","brand","aoe","cooldowns"}) do
     assert.is_table(lists[name],"missing full reported-working APL list "..name)
   end
   assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
   assert.is_falsy((warnings or ""):find("Unknown key",1,true))
   H.Hekili.DB.profile.packs[C.PACK].lists=lists
   H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
   for name in pairs(lists) do
     assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
   end
   assert.are.same({},H.errors)
 end
 local toggles=H.Hekili.DB.profile.toggles
 toggles.cooldowns.value=false
 toggles.minor_cooldowns.value=false
 toggles.defensives.value=false
 local events,failed,installed={},{},false
 local rr=loop.run(L,seed,{
   duration=duration,
   on=function(w)
     if installed then return end
     local previous=w.W.press
     w.W.press=function(player,key,resolved)
       local timestamp=w.W.t
       local remaining=math.max(0,(player.castUntil or 0)-timestamp)
       local success,reason=previous(player,key,resolved)
       if player==w.us and timestamp>=loop.PULL and type(key)=="string" then
         if success then
           events[#events+1]={t=timestamp,key=key}
         elseif #failed<10 then
           failed[#failed+1]={t=timestamp,key=key,reason=reason,
             castRemain=remaining,mana=player.power,cost=resolved and resolved.cost}
         end
       end
       return success,reason
     end
     installed=true
   end,
 },{{H=H}})
 assert.are.equal(0,rr.errors)
 assert.are.equal(0,rr.raises)
 for i,e in ipairs(failed) do
   print(("DEMO_PRESS_REFUSAL_V011 profile=%s seed=%d startMana=%.1f i=%d t=%.12f spell=%s reason=%s castRemain=%.12f mana=%.2f cost=%s"):format(
      profile,seed,initial,i,e.t,tostring(e.key),tostring(e.reason),
      e.castRemain,tonumber(e.mana) or -1,tostring(e.cost)))
 end
 local m=rr.pressedBy or {}
 local refused=0
 for why,n in pairs(rr.refused or {}) do
   refused=refused+n
   print(("DEMO_REFUSED_V011 profile=%s seed=%d startMana=%.1f reason=%s count=%d"):format(
     profile,seed,initial,tostring(why),n))
 end
 local boundary,unsafe=0,0
 for _,e in ipairs(failed) do
   -- Published World.press uses strict t < castUntil with no float epsilon.
   -- Only permit an exact Bane-of-Agony cast-END collision as a separately
   -- counted source-world timing artefact; never excuse true cast overlap,
   -- Mana/GCD/cooldown/target refusals or repeated unsafe fallback.
   if e.reason=="casting" and e.key=="bane_of_agony"
       and e.castRemain>0 and e.castRemain<=1e-7 then
     boundary=boundary+1
   else
     unsafe=unsafe+1
   end
 end
 assert.are.equal(refused,#failed,
   "not every source-refused action was captured for independent classification")
 print(("DEMO_BOUNDARY_V011 profile=%s seed=%d startMana=%.1f refused=%d castEndOnly=%d unsafe=%d"):format(
   profile,seed,initial,refused,boundary,unsafe))
 local seenDot=false
 local later={}
 local traceOffence,sourceDots=0,0
 for _,ev in ipairs(events) do
   if offence[ev.key] then traceOffence=traceOffence+1 end
   if dotKeys[ev.key] then
     sourceDots=sourceDots+1
     seenDot=true
   elseif seenDot and #later<3 then
     later[#later+1]=ev.key
   end
 end
 local totalOffence=0
 for key in pairs(offence) do totalOffence=totalOffence+(m[key] or 0) end
 local sourceTap=m.life_tap or 0
 local majors=(m.blood_fury or 0)+(m.berserking or 0)+(m.eureka or 0)
 print(("DEMO_POSTDOT_V011 profile=%s seed=%d startMana=%.1f accepted=%d refused=%d dot=%d offence=%d eventOffence=%d events=%d afterDot=%d tap=%d major=%d manaEnd=%.1f healthEnd=%s next=%s"):format(
   profile,seed,initial,rr.presses,refused,sourceDots,totalOffence,
   traceOffence,#events,#later,sourceTap,majors,rr.us.power,
   tostring(rr.us.health),table.concat(later,",")))
 -- rr.pressedBy is the source's authoritative accepted counter; ordered hook
 -- is additional independent evidence, never fabricate timeline from ticks.
 assert.is_true(traceOffence<=totalOffence,"press trace has more accepted offence than world count")
 return {accepted=rr.presses,refused=refused,unsafe=unsafe,boundary=boundary,
   dot=sourceDots,postDot=#later,offence=totalOffence,tap=sourceTap,
   major=majors,eventCount=#events}
end
describe("Demonology DEMO-006 source v0.11 shipped vs protected reported-working",function()
 for _,seed in ipairs({30417,30437}) do
   it("normal Mana 25yd full DoT and three actual post-upkeep accepts "..seed,function()
     local shipped=one("shipped",seed,stock.WORLD.max,75)
     local workingResult=one("working",seed,stock.WORLD.max,75)
     assert.is_true(shipped.accepted>=3,"shipped fixture does not progress")
     assert.is_true(workingResult.dot>=1,"working misses all source-world DoTs")
     assert.is_true(workingResult.postDot>=3,
       "working did not make three genuinely accepted later actions after upkeep")
     assert.are.equal(0,workingResult.tap,"working recommended Life Tap unexpectedly")
     assert.are.equal(0,workingResult.unsafe,
       "working has genuinely uncastable action, not source cast-end rounding")
     assert.is_true(workingResult.boundary<=1,
       "repeated cast-END boundary collisions warrant separate investigation")
     assert.are.equal(0,workingResult.major,"working ignored native Major OFF")
   end)
   it("25 percent Mana with player-health debit UNMODELLED "..seed,function()
     local shipped=one("shipped",seed,stock.WORLD.max*.25,95)
     local workingResult=one("working",seed,stock.WORLD.max*.25,95)
     assert.is_true(shipped.accepted>=1)
     assert.is_true(workingResult.dot>=1,"no legal low-Mana DoT")
     assert.is_true(workingResult.postDot>=3,
       "no 3 genuinely accepted post-DoT actions with low Mana")
     assert.are.equal(0,workingResult.tap,
       "working attempted a Life Tap whose health is not modelled")
     assert.are.equal(0,workingResult.refused,
       "repeated refused low-Mana recommendation: inspect full chain")
     assert.are.equal(0,workingResult.major)
   end)
   it("5 percent Mana diagnostic: no invented health-safe Life Tap proof "..seed,function()
     local shipped=one("shipped",seed,stock.WORLD.max*.05,45)
     local workingResult=one("working",seed,stock.WORLD.max*.05,45)
     -- Severe Mana may not fund DoTs or 3 follow-ons. Safety: never
     -- accept a repeated refused action or any unmodelled-health Life Tap.
     assert.are.equal(0,workingResult.tap)
     assert.are.equal(0,workingResult.refused)
     assert.are.equal(0,workingResult.major)
     print(("DEMO_5PCT_DECISION_V011 seed=%d shipped_tap=%d shipped_accepted=%d working_tap=%d working_accepted=%d three_followons=NOT_ASSUMED health_debit=NOT_MODELLED"):format(
       seed,shipped.tap,shipped.accepted,workingResult.tap,workingResult.accepted))
   end)
 end
end)
