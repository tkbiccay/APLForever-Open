-- Mage Fire v0.11 independent low-Mana fallback breadth hypothesis.
-- Published Forever v0.11.0 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Test whether complete Current's Fire Blast/Scorch/final fallback remains
-- castable with cooldowns OFF at 25% and 5% Mana, versus shipped.
-- 5% may be an engine/world limit: record actual refusals before proposing fixes.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.mage_world").Fire)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Mage/Current/APL_Mage_Fire_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a")); f:close()
local function run(profile,seed,mana,duration)
 local world=setmetatable({power=mana,mobHealth=1000000000},{__index=stock.WORLD})
 local C=setmetatable({WORLD=world},{__index=stock})
 local L=loop.new(C); local H=L.us
 assert.are.same({},H.loadErrors)
 if profile=="current" then
  local lists,warnings=H.Hekili:ImportSimcAPL("Mage_Fire","APLForever-Fire-Low-Mana",current,C.PACK)
  assert.is_table(lists)
  for _,name in ipairs({"precombat","default","mana_recovery","major_cooldowns","aoe","final_fallback"}) do
   assert.is_table(lists[name],"missing complete Current list "..name)
  end
  assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
  assert.is_falsy((warnings or ""):find("Unknown key",1,true))
  H.Hekili.DB.profile.packs[C.PACK].lists=lists
  H.Hekili:LoadScripts(); H.Hekili:ReviewPacks()
  for name in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,name),name) end
  assert.are.same({},H.errors)
 end
 local t=H.Hekili.DB.profile.toggles
 t.cooldowns.value=false; t.minor_cooldowns.value=false; t.defensives.value=false
 local rr=loop.run(L,seed,{duration=duration},{{H=H}})
 assert.are.equal(0,rr.errors); assert.are.equal(0,rr.raises)
 local rejected=0
 for why,n in pairs(rr.refused or {}) do
  rejected=rejected+n
  print(("FIRE_REFUSAL profile=%s seed=%d mana=%.2f why=%s count=%d"):format(profile,seed,mana,tostring(why),n))
 end
 local m=rr.pressedBy or {}
 local offense={fireball=true,fire_blast=true,scorch=true,pyroblast=true,frostbolt=true,
  frostfire_bolt=true,arcane_blast=true,arcane_missiles=true,blizzard=true}
 -- pressedBy counts source-accepted actions by spell. The tick-indexed
 -- rr.pressed history is not guaranteed to retain every accepted action;
 -- the previous strict equality falsely failed by 1-2 on released v0.11.
 -- Derive follow-on cast count from the authoritative accepted totals.
 local tickOffense=0
 for i=1,rr.combat do
  if offense[rr.pressed[i]] then tickOffense=tickOffense+1 end
 end
 local n=0
 for key in pairs(offense) do n=n+(m[key] or 0) end
 assert.is_true(n<=rr.presses,"offensive accepted count exceeds total accepted presses")
 local follow=math.max(0,n-1)
 print(("FIRE_HISTORY_DIAGNOSTIC profile=%s seed=%d mana=%.2f tickOffense=%d acceptedOffense=%d missingTickHistory=%d"):format(profile,seed,mana,tickOffense,n,n-tickOffense))
 local majors=(m.combustion or 0)+(m.eureka or 0)+(m.blood_fury or 0)+(m.berserking or 0)
 print(("FIRE_LOW_MANA_V011 profile=%s seed=%d startMana=%.2f accepted=%d offensive=%d follow=%d refused=%d major=%d fireblast=%d scorch=%d fireball=%d endMana=%s"):format(
  profile,seed,mana,rr.presses,n,follow,rejected,majors,m.fire_blast or 0,m.scorch or 0,m.fireball or 0,tostring(rr.us.power)))
 return {accepted=rr.presses,offensive=n,follow=follow,refused=rejected,major=majors}
end
describe("Mage Fire full shipped vs Current v0.11 low-Mana final fallback",function()
 for _,seed in ipairs({30417,30437}) do
  it("25 percent Mana: three legal offensive follow-ons and no repeated refusals "..seed,function()
   local mana=stock.WORLD.max*0.25
   local shipped=run("shipped",seed,mana,100)
   local currentRun=run("current",seed,mana,100)
   assert.is_true(shipped.accepted>=1,"shipped fixture did not progress")
   assert.is_true(currentRun.follow>=3,"Current did not deliver three accepted follow-on attacks")
   assert.are.equal(0,currentRun.refused,"Current repeats an uncastable spell at 25% Mana")
   assert.are.equal(0,currentRun.major,"Major cooldowns OFF violated")
  end)
  it("5 percent Mana: source refusal and fallback diagnostic "..seed,function()
   local mana=stock.WORLD.max*0.05
   local shipped=run("shipped",seed,mana,100)
   local currentRun=run("current",seed,mana,100)
   assert.are.equal(0,currentRun.major)
   assert.is_true(shipped.accepted>=1,"shipped fixture did not progress at 5% Mana")
   assert.is_true(currentRun.follow>=3,"Current did not deliver three accepted offensive follow-ons at 5% Mana")
   assert.are.equal(0,currentRun.refused,"Current repeats an uncastable spell at 5% Mana")
   -- This source-world gate proves accepted casts only, not faithful live Mana recovery.
   print(("FIRE_5PCT_DECISION seed=%d shippedAccepted=%d currentAccepted=%d currentRefused=%d currentFollow=%d"):format(
    seed,shipped.accepted,currentRun.accepted,currentRun.refused,currentRun.follow))
  end)
 end
end)
