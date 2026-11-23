-- APLForever 50-unit campaign #04 hypothesis: published Forever Survival
-- melee world really knows melee attacks, unlike MarksmanshipTurret.
-- Shipped vs exact protected Current v1.0 vs full unselected Candidate v1.1.
-- Source 0.11.0 pin: zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b.
local loop=require("Game.harness.loop")
local hunter=require("Forever.helpers.hunter_world")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"));local s=assert(f:read("*a"));f:close();return s
end
local original=read("roles/Hunter/Current/APL_Hunter_Survival_DPS_v1.0_Draft.txt")
local candidate=read("roles/Hunter/Candidates/APL_Hunter_Survival_v1.1_Draft.txt")
local meleeAttack={raptor_strike=true, mongoose_bite=true,strider_kick=true,wing_clip=true}
local rangedAttack={arcane_shot=true,multi_shot=true,serpent_sting=true,aimed_shot=true}
local offense={raptor_strike=true, mongoose_bite=true,strider_kick=true,wing_clip=true,
  arcane_shot=true,multi_shot=true,serpent_sting=true,aimed_shot=true,
  immolation_trap=true}
local function one(profile,seed,dist,low,duration)
 local Cbase=dist==5 and hunter.SurvivalMelee or hunter.SurvivalMeleeRanged
 -- Only survival melee's published source world knows melee abilities;
 -- ranged variation has the identical kit/talents and an actual ranged weapon.
 local initial=(Cbase.WORLD.max or 3915)*(low and 0.25 or 1)
 local W=setmetatable({power=initial,distance=dist,mobHealth=1e9},{__index=Cbase.WORLD})
 local C=setmetatable({WORLD=W},{__index=Cbase})
 local L=loop.new(C);local H=L.us
 assert.are.same({},H.loadErrors)
 if profile~="shipped" then
  local s=profile=="current" and original or candidate
  local lists,warnings=H.Hekili:ImportSimcAPL("Hunter_Survival",
      "APLForever-Survival-Breadth-50",s,C.PACK)
  assert.is_table(lists)
  for _,name in ipairs({"precombat","default","major_cooldowns","melee","ranged"}) do
   assert.is_table(lists[name],"missing entire full APL list "..name)
  end
  assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
  assert.is_falsy((warnings or ""):find("Unknown key",1,true))
  H.Hekili.DB.profile.packs[C.PACK].lists=lists
  H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
  for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  assert.are.same({},H.errors)
 end
 local t=H.Hekili.DB.profile.toggles
 t.cooldowns.value=false;t.minor_cooldowns.value=false
 t.defensives.value=false;t.movement.value=false
 local rr=loop.run(L,seed,{duration=duration},{{H=H}})
 assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
 local refused=0
 for why,n in pairs(rr.refused or {}) do
  refused=refused+n
  print(("SV_REFUSED_V011 profile=%s seed=%d distance=%d lowMana=%s reason=%s count=%d"):format(
   profile,seed,dist,tostring(low),tostring(why),n))
 end
 local m=rr.pressedBy or {};local attacks,ranged,melee=0,0,0
 for key in pairs(offense) do attacks=attacks+(m[key] or 0) end
 for key in pairs(rangedAttack) do ranged=ranged+(m[key] or 0) end
 for key in pairs(meleeAttack) do melee=melee+(m[key] or 0) end
 local major=(m.rapid_fire or 0)+(m.berserking or 0)
  +(m.blood_fury or 0)+(m.elunes_light or 0)
 print(("SV_BREADTH_V011 profile=%s seed=%d yd=%d startMana=%.1f accepted=%d refused=%d attack=%d follow=%d melee=%d ranged=%d major=%d manaEnd=%.1f raptor=%d strider=%d arcane=%d serpent=%d"):format(
  profile,seed,dist,initial,rr.presses,refused,attacks,
  math.max(0,attacks-1),melee,ranged,major,rr.us.power,
  m.raptor_strike or 0,m.strider_kick or 0,m.arcane_shot or 0,m.serpent_sting or 0))
 assert.is_true(attacks<=rr.presses,"accepted attack count exceeded accepted presses")
 return {accepted=rr.presses,refused=refused,attack=attacks,
  melee=melee,ranged=ranged,follow=math.max(0,attacks-1),
  major=major}
end
describe("Forever v0.11 Survival melee-knowing source: range and Mana fallback",function()
 for _,seed in ipairs({30417,30437}) do
  it("5yd positive melee-attack and three accepted follow-ons "..seed,function()
   local shipped=one("shipped",seed,5,false,55)
   local current=one("current",seed,5,false,55)
   local candidateRun=one("candidate",seed,5,false,55)
   assert.is_true(shipped.accepted>=3,"shipped fixture failed")
   for _,v in ipairs({current,candidateRun}) do
    assert.is_true(v.melee>=1,"true melee-capable Survival kit produced no legal melee attack")
    assert.is_true(v.follow>=3,"no three actual accepted offensive follow-ons at 5yd")
    assert.are.equal(0,v.refused,"Current/Candidate melee action was source refused")
    assert.are.equal(0,v.major,"native Major OFF violated")
   end
   assert.are.equal(current.accepted,candidateRun.accepted,
    "pet recovery-only candidate unexpectedly altered normal 5yd accepted progression")
  end)
  it("11yd positive ranged-kit three legal follow-ons "..seed,function()
   local shipped=one("shipped",seed,11,false,55)
   local current=one("current",seed,11,false,55)
   local candidateRun=one("candidate",seed,11,false,55)
   assert.is_true(shipped.accepted>=3,"shipped ranged fixture failed")
   for _,v in ipairs({current,candidateRun}) do
    assert.is_true(v.ranged>=4,"11yd ranged kit failed first + three accepted ranged actions")
    assert.are.equal(0,v.refused,"source refused legal ranged action")
    assert.are.equal(0,v.major)
   end
   assert.are.equal(current.accepted,candidateRun.accepted)
  end)
  it("7yd true source melee/ranged dead zone: diagnose without fabrication "..seed,function()
   local shipped=one("shipped",seed,7,false,30)
   local current=one("current",seed,7,false,30)
   local candidateRun=one("candidate",seed,7,false,30)
   print(("SV_DEADZONE_V011 seed=%d shipped=%d/%d current=%d/%d candidate=%d/%d sourceClient=NOT_LIVE"):format(
     seed,shipped.accepted,shipped.refused,
     current.accepted,current.refused,candidateRun.accepted,candidateRun.refused))
   assert.are.equal(0,current.refused,"Current repeats a range-refused attack at 7yd")
   assert.are.equal(0,candidateRun.refused,"Candidate repeats a range-refused attack at 7yd")
   assert.are.equal(0,current.major);assert.are.equal(0,candidateRun.major)
  end)
  it("25 percent Mana at melee 5yd: accepted next actions and no resource refusals "..seed,function()
   local shipped=one("shipped",seed,5,true,95)
   local current=one("current",seed,5,true,95)
   local candidateRun=one("candidate",seed,5,true,95)
   assert.is_true(shipped.accepted>=1,"shipped low-Mana fixture untestable")
   for _,v in ipairs({current,candidateRun}) do
    assert.is_true(v.follow>=3,"low Mana melee failed three accepted later attacks")
    assert.are.equal(0,v.refused,"repeated unaffordable low-Mana melee cast")
    assert.are.equal(0,v.major)
   end
  end)
 end
end)
