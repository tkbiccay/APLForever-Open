-- Hunter Marksmanship Forever v0.11 source-native full combat/fallback breadth.
-- Prior v1.1 pet checks tested icons only; here we test accepted spell casts.
-- Hunter uses Mana in published Forever, NOT Focus. Distances 7yd are
-- diagnostic only: fixture range fidelity and live client still unverified.
local loop=require("Game.harness.loop")
local hunter=require("Forever.helpers.hunter_world")
local stock=assert(hunter.MarksmanshipTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=assert(f:read("*a")); f:close();return s
end
local current=read("roles/Hunter/Current/APL_Hunter_Marksmanship_DPS_v1.0_Draft.txt")
local candidate=read("roles/Hunter/Candidates/APL_Hunter_Marksmanship_v1.1_Draft.txt")
local function one(profile,seed,mana,distance,duration)
 local world=setmetatable({
  power=mana or stock.WORLD.power,
  distance=distance,
  mobHealth=1000000000,
 },{__index=stock.WORLD})
 local C=setmetatable({WORLD=world},{__index=stock})
 local L=loop.new(C); local H=L.us
 assert.are.same({},H.loadErrors)
 if profile~="shipped" then
  local s=profile=="current" and current or candidate
  local lists,warnings=H.Hekili:ImportSimcAPL("Hunter_Marksmanship",
   "APLForever-MM-Source-Fallback",s,C.PACK)
  assert.is_table(lists)
  for _,name in ipairs({"precombat","default","melee","ranged","aoe","major_cooldowns"}) do
   assert.is_table(lists[name],"missing full source APL list "..name)
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
 local toggle=H.Hekili.DB.profile.toggles
 toggle.cooldowns.value=false
 toggle.minor_cooldowns.value=false
 toggle.defensives.value=false
 toggle.movement.value=false
 local rr=loop.run(L,seed,{duration=duration},{{H=H}})
 assert.are.equal(0,rr.errors)
 assert.are.equal(0,rr.raises)
 local refused=0
 for reason,n in pairs(rr.refused or {}) do
  refused=refused+n
  print(("MM_REFUSED profile=%s seed=%d mana=%.1f distance=%d reason=%s count=%d"):format(
   profile,seed,world.power,distance,tostring(reason),n))
 end
 local m=rr.pressedBy or {}
 local offensiveNames={
   sniper_shot=true,serpent_sting=true,aimed_shot=true,multi_shot=true,
   arcane_shot=true,summon_hawk=true,raptor_strike=true,
   mongoose_bite=true,strider_kick=true,
 }
 local offensive,follow,first={},0,nil
 for i=1,rr.combat do
  local spell=rr.pressed[i]
  if offensiveNames[spell] then
   offensive[#offensive+1]=spell
   if #offensive==1 then first=spell else follow=follow+1 end
  end
 end
 local major=(m.rapid_fire or 0)+(m.blood_fury or 0)
  +(m.berserking or 0)+(m.elunes_light or 0)
 print(("MM_BREADTH_V011 profile=%s seed=%d startMana=%.1f yd=%d accepted=%d refused=%d offensive=%d afterFirst=%d major=%d manaEnd=%.2f first=%s next=%s"):format(
   profile,seed,world.power,distance,rr.presses,refused,
   #offensive,follow,major,rr.us.power,
   tostring(first),table.concat({offensive[2] or "-",offensive[3] or "-",
      offensive[4] or "-"},",")))
 return {accepted=rr.presses,refused=refused,offensive=#offensive,
  follow=follow,major=major,counts=m}
end
describe("Forever v0.11 MM full-profile low-Mana and ranged dead-zone breadth",function()
 for _,seed in ipairs({30417,30437}) do
  it("normal 12yd ranged rotation, native Major OFF seed "..seed,function()
   local shipped=one("shipped",seed,nil,12,70)
   local base=one("current",seed,nil,12,70)
   local cand=one("candidate",seed,nil,12,70)
   assert.is_true(shipped.accepted>=3,"shipped source world never advances")
   for _,x in ipairs({base,cand}) do
    assert.is_true(x.offensive>=4,"no first plus three genuine offensive follow-ons")
    assert.is_true(x.follow>=3)
    assert.are.equal(0,x.refused,"source-refused normal action")
    assert.are.equal(0,x.major,"Major OFF violated")
   end
   assert.are.equal(base.accepted,cand.accepted,
    "pet upkeep-only v1.1 changed combat progression with normal pet out")
  end)
  it("25-percent initial Mana at 12yd, no repeated unavailable fallback seed "..seed,function()
   local mana=stock.WORLD.max*0.25
   local shipped=one("shipped",seed,mana,12,95)
   local base=one("current",seed,mana,12,95)
   local cand=one("candidate",seed,mana,12,95)
   assert.is_true(shipped.accepted>=3,"shipped low Mana is untestable")
   for _,x in ipairs({base,cand}) do
    assert.is_true(x.offensive>=4,"low Mana fails three genuine follow-on offensive casts")
    assert.are.equal(0,x.refused,"low Mana source refused/repeated recommendation")
    assert.are.equal(0,x.major)
   end
  end)
  it("diagnose 7yd: verify no invented real-client range conclusion seed "..seed,function()
   local shipped=one("shipped",seed,nil,7,30)
   local base=one("current",seed,nil,7,30)
   local cand=one("candidate",seed,nil,7,30)
   print(("MM_RANGE_DIAG_V011 seed=%d distance=7 shipped=%d/%d current=%d/%d candidate=%d/%d real_client=NOT_TESTED"):format(
    seed,shipped.accepted,shipped.refused,base.accepted,base.refused,
    cand.accepted,cand.refused))
   assert.is_true(base.accepted>=0 and cand.accepted>=0)
  end)
 end
end)
