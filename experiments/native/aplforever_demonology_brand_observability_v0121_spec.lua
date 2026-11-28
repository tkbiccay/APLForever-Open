-- DEMO-006: actual released Brand application and explicitly synthetic
-- hidden-charge stress. No production rotation changes or simulated damage claim.
local loop=require("Game.harness.loop")
local module=require("Forever.helpers.warlock_world")
local stock=assert(module.Demonology)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt","rb"))
local working=assert(f:read("*a"));f:close()
assert.is_nil(working:find("life_tap",1,true))
local brand,talent=1293696,1293695
describe("Released Searing Pain Brand application effect",function()
 for _,rank in ipairs({0,1,2,3}) do
  for _,hit in ipairs({"WOUND","MISS"}) do
   it(("rank %d %s"):format(rank,hit),function()
    local target={auras={}}
    local X={aura={demonic_brand={id=brand,duration=10,max_stack=6}}}
    local H={ctl={traits={defs={talent},nodes={{activeRank=rank}}}}}
    local calls=0
    local W={hit=function() return {act=hit} end,
      applyAura=function(dst,id,duration,n,maxStacks)
       calls=calls+1;assert.are.equal(target,dst);assert.are.equal(brand,id)
       assert.are.equal(10,duration);assert.are.equal(6,maxStacks)
       dst.auras[id]={stacks=n}
      end}
    module.MAP.searing_pain.effect(W,{target=target},{},X,H)
    if rank>0 and hit=="WOUND" then
     assert.are.equal(1,calls);assert.are.equal(2*rank,target.auras[brand].stacks)
    else assert.are.equal(0,calls);assert.is_nil(target.auras[brand]) end
   end)
  end
 end
end)
-- Test-only truth perturbation. The released harness does not generate pet
-- damage events. A controlled landed/missed marker is not a measured hit rate.
-- No writes to H, virtual state or player damage/resource values.
local function consume(W,e,landed,v)
 local a=e.target and e.target.auras[brand]
 if not e.pet or not e.pet.up or not a or a.expires<=W.t then return end
 if not landed then v.missed=v.missed+1;return end
 assert.is_true(a.stacks>0)
 a.stacks=a.stacks-1;v.consumed=v.consumed+1
 if a.stacks==0 then
  e.target.auras[brand]=nil;v.depleted=v.depleted+1
  W.emit({kind="aura",dst=e.target,aura=brand,stacks=0,expires=0,duration=0})
 else
  W.emit({kind="aura",dst=e.target,aura=brand,stacks=a.stacks,expires=a.expires,duration=a.duration})
 end
end
describe("Synthetic charge-consumption control (not released pet simulation)",function()
 it("miss and unavailable pet preserve charges; depletion preserves original expiry until removal",function()
  local e={pet={up=true},target={auras={[brand]={stacks=2,expires=10,duration=10}}}}
  local v={missed=0,consumed=0,depleted=0}
  local emitted={}
  local W={t=3,emit=function(ev) emitted[#emitted+1]=ev end}
  consume(W,e,false,v);assert.are.equal(2,e.target.auras[brand].stacks)
  e.pet.up=false;consume(W,e,true,v);assert.are.equal(2,e.target.auras[brand].stacks)
  e.pet.up=true;consume(W,e,true,v);assert.are.equal(1,e.target.auras[brand].stacks)
  assert.are.equal(10,e.target.auras[brand].expires);assert.are.equal(10,emitted[1].expires)
  consume(W,e,true,v);assert.is_nil(e.target.auras[brand]);assert.are.equal(0,emitted[2].stacks)
  assert.are.same({1,2,1},{v.missed,v.consumed,v.depleted})
 end)
end)
local offence={shadow_bolt=true,searing_pain=true,immolate=true,corruption=true,bane_of_agony=true,
 bane_of_doom=true,soul_fire=true,rain_of_fire=true,incinerate=true}
local dots={immolate=true,corruption=true,bane_of_agony=true,bane_of_doom=true}
local function trial(profile,seed,pct,stress)
 local initial=stock.WORLD.max*pct
 local v={consumed=0,depleted=0,missed=0,truthUp=0,beliefUp=0,falseUp=0,falseDown=0,samples=0,
  refresh=0,raw=0,epsilon=0,offence=0,follow=0,cost=0,rangeSamples=0}
 local C=setmetatable({WORLD=setmetatable({power=initial,mobHealth=1e9,distance=25,attackers=1,
 script=function(W,e)
  stock.WORLD.script(W,e);W.moveTo(e,25)
  if stress then
   -- Deliberately fixed controlled events: 3 landed markers then a miss,
   -- 1 second apart; not a real imp cadence or damage model.
   local i=0
   local function step()
    i=i+1;consume(W,e,i%4~=0,v)
    W.at(W.t+1,step)
   end
   W.at(loop.PULL+2,step)
  end
 end},{__index=stock.WORLD})},{__index=stock})
 local L=loop.new(C);local H=L.us
 assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
 assert.are.equal(brand,H.Hekili.Class.auras.demonic_brand.id)
 if profile=="working" then
  local lists,warnings=H.Hekili:ImportSimcAPL("Warlock_Demonology","APLForever-DEMO006-Brand",working,C.PACK)
  for _,k in ipairs({"precombat","default","banes","curses","brand","aoe","cooldowns"}) do assert.is_table(lists[k]) end
  assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
  assert.is_falsy((warnings or ""):find("Unknown key",1,true))
  H.Hekili.DB.profile.packs[C.PACK].lists=lists
  H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
  for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
 end
 assert.are.same({},H.errors)
 local t=H.Hekili.DB.profile.toggles
 t.cooldowns.value=false;t.cooldowns.override=false;t.cooldowns.infusion=false
 t.minor_cooldowns.value=false;t.minor_cooldowns.override=false
 t.defensives.value=false;t.interrupts.value=false;t.movement.value=false
 local installed,seenDot=false,false
 local rr=loop.run(L,seed,{duration=60,on=function(w,_,time)
  if time>loop.PULL+1 and not w.us.stopped then
   assert.are.equal(25,H.ctl.distance.target);v.rangeSamples=v.rangeSamples+1
   local a=w.us.target and w.us.target.auras[brand]
   local truth=a~=nil and a.expires>w.W.t
   local believed=H.ns.VirtualState.Aura("target",brand,H.ctl.now)~=nil
   v.samples=v.samples+1
   if truth then v.truthUp=v.truthUp+1 end
   if believed then v.beliefUp=v.beliefUp+1 end
   if believed and not truth then v.falseUp=v.falseUp+1 end
   if truth and not believed then v.falseDown=v.falseDown+1 end
  end
  if installed then return end;installed=true
  local press=w.W.press
  w.W.press=function(e,key,p)
   if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
   local left=(e.castUntil or 0)-w.W.t
   local ok,why=press(e,key,p)
   if not ok then
    v.raw=v.raw+1
    -- Previously independently observed v0.11 Bane at t=31 only; new
    -- released-source overlaps are raw failures until independently checked.
    if key=="bane_of_agony" and why=="casting" and left>0 and left<=1e-7
      and math.abs(w.W.t-31)<1e-8 then v.epsilon=v.epsilon+1 end
    print("DEMO_BRAND_REFUSAL",profile,seed,pct,tostring(stress),w.W.t,key,why,left)
   elseif not e.stopped and offence[key] then
    v.offence=v.offence+1;v.cost=v.cost+(p.cost or 0)
    if seenDot then v.follow=v.follow+1 end
    if dots[key] then seenDot=true end
   end
   return ok,why
  end
 end},{{H=H}})
 assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
 assert.is_true(math.abs(initial-rr.us.power0)<1e-6);assert.is_true(v.rangeSamples>3)
 local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
 assert.are.equal(raw,v.raw,"raw trace incomplete")
 local c=rr.pressedBy or {};v.tap=c.life_tap or 0;v.pain=c.searing_pain or 0;v.endMana=rr.us.power
 v.major=(c.use_items or 0)+(c.eureka or 0)+(c.blood_fury or 0)+(c.berserking or 0)
 print("DEMO_BRAND_RESULT",profile,seed,pct,tostring(stress),v.samples,v.truthUp,v.beliefUp,v.falseUp,v.falseDown,
  v.consumed,v.depleted,v.missed,v.pain,v.offence,v.follow,v.cost,v.endMana,v.raw,v.epsilon,v.tap,v.major)
 if profile=="working" then
  assert.are.equal(0,v.tap);assert.are.equal(0,v.major);assert.are.equal(0,v.raw-v.epsilon)
  assert.is_true(v.epsilon<=1);assert.is_true(v.offence>=3);assert.is_true(v.follow>=3)
 end
 if not stress then assert.are.same({0,0,0},{v.consumed,v.depleted,v.missed}) end
 return v
end
describe("DEMO-006 full shipped and protected working against hidden-charge stress",function()
 local depletion=0
 for _,seed in ipairs({30417,30437,30461}) do
  for _,pct in ipairs({1,0.25}) do
   it(("seed %d Mana %.2f"):format(seed,pct),function()
    for _,profile in ipairs({"shipped","working"}) do
     local old=trial(profile,seed,pct,false)
     local stress=trial(profile,seed,pct,true)
     if pct==1 and profile=="working" then depletion=depletion+stress.depleted end
     print("DEMO_BRAND_MATCH",profile,seed,pct,old.falseUp,stress.falseUp,old.falseDown,stress.falseDown,
      old.pain,stress.pain,old.offence,stress.offence,old.endMana,stress.endMana)
    end
   end)
  end
 end
 it("actual synthetic depletion exercised in protected full-Mana world",function()
  assert.is_true(depletion>0,"stress never depleted an actual Brand: blocked")
 end)
end)
