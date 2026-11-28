-- Full released-source Destruction rank boundary experiment. No production APL.
local loop=require("Game.harness.loop")
local module=require("Forever.helpers.warlock_world")
local stock=assert(module.Destruction)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Warlock/Current/APL_Warlock_Destruction_DPS_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local anchor="talent.shadow_and_flame.rank>0|debuff.immolate.remains<=3"
local at=assert(current:find(anchor,1,true))
assert.is_nil(current:find(anchor,at+#anchor,1,true))
local alternative=current:sub(1,at-1).."talent.shadow_and_flame.rank>=5|debuff.immolate.remains<=3"..current:sub(at+#anchor)
assert.is_nil(alternative:find("life_tap",1,true))
local talentID=426316
local immolateID=348
local offence={shadow_bolt=true,searing_pain=true,incinerate=true,immolate=true,corruption=true,
 bane_of_agony=true,bane_of_doom=true,conflagrate=true,shadowburn=true,rain_of_fire=true,soul_fire=true}
local function remaining(e,now)
 local a=e and e.auras[immolateID]
 return a and math.max(0,a.expires-now) or 0
end

-- Direct actual released world effect, with controlled hit/roll inputs.
-- This is an effect unit test, not a rotation, legal talent build or Belief test.
describe("Released Conflagrate consumption rank/outcome boundary",function()
 for _,rank in ipairs({0,1,4,5}) do
  for _,arm in ipairs({{hit="WOUND",roll=0.1},{hit="WOUND",roll=0.9},{hit="MISS",roll=0.1},{hit="MISS",roll=0.9}}) do
   it(("rank %d %s roll %.1f"):format(rank,arm.hit,arm.roll),function()
    local target={auras={[immolateID]={expires=15}},dots={immolate=true}}
    local e={target=target}
    local X={aura={immolate={id=immolateID}}}
    local H={ctl={traits={defs={talentID},nodes={{activeRank=rank}}}}}
    local rolls,drops=0,0
    local W={hit=function() return {act=arm.hit} end,
      rng={chance=function(p) rolls=rolls+1;assert.is_true(math.abs(p-0.2*rank)<1e-9);return arm.roll<p end},
      emit=function(ev) if ev.kind=="aura" and ev.aura==immolateID and ev.stacks==0 then drops=drops+1 end end}
    assert.is_true(module.MAP.conflagrate.requires(W,e,X))
    module.MAP.conflagrate.effect(W,e,{},X,H)
    local consumed=arm.hit=="WOUND" and arm.roll>=0.2*rank
    assert.are.equal(consumed,target.auras[immolateID]==nil)
    assert.are.equal(consumed,target.dots.immolate==nil)
    assert.are.equal(consumed and 1 or 0,drops)
    assert.are.equal(arm.hit=="WOUND" and 1 or 0,rolls)
   end)
  end
 end
end)

local function trial(profile,seed,rank,pct,duration)
 local initial=stock.WORLD.max*pct
 local v={early=0,earlyConsumed=0,landed=0,missed=0,consumed=0,retained=0,conflag=0,
  raw=0,epsilon=0,offence=0,follow=0,cost=0,immolate=0,fireTicks=0,rangeSamples=0}
 local C=setmetatable({WORLD=setmetatable({power=initial,distance=25,mobHealth=1e9,attackers=1,
 script=function(W,us) stock.WORLD.script(W,us);W.moveTo(us,25) end},{__index=stock.WORLD})},{__index=stock})
 -- Fixed level-60 stock character, perturb ONLY the talent rank. This is a
 -- controlled mechanic comparison, not a claimed legal level-35 build.
 C.character=function()
  local c=stock.character()
  local talents={}
  for id,n in pairs(c.talents) do talents[id]=n end
  talents[talentID]=rank>0 and rank or nil
  c.talents=talents
  return c
 end
 C.resolve=function(key,H)
  local p=stock.resolve(key,H)
  if key=="conflagrate" then
   local original=p.effect
   p.effect=function(W,e)
    local before=remaining(e.target,W.t)
    original(W,e)
    if e.kind=="player" or e.target and e.target.kind=="mob" then
     if W.t>=loop.PULL then
      local hit=e.lastHit and e.lastHit.act
      local removed=before>0 and remaining(e.target,W.t)==0
      v.conflag=v.conflag+1
      if before>3.000001 then v.early=v.early+1;if removed then v.earlyConsumed=v.earlyConsumed+1 end end
      if hit=="WOUND" then v.landed=v.landed+1;if removed then v.consumed=v.consumed+1 else v.retained=v.retained+1 end
      else v.missed=v.missed+1 end
      print("DESTRO_RANK_EFFECT",profile,seed,rank,pct,duration,W.t,before,tostring(hit),tostring(removed))
      if rank==5 or hit~="WOUND" then assert.is_false(removed,"actual source consumption inconsistent with rank/outcome") end
     end
    end
   end
  end
  return p
 end
 local L=loop.new(C);local H=L.us
 assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
 local traits=assert(H.ctl.traits);local actual=0
 for i,id in ipairs(traits.defs) do if id==talentID then actual=traits.nodes[i].activeRank end end
 assert.are.equal(rank,actual,"actual loaded talent rank")
 if profile~="shipped" then
  local lists,warnings=H.Hekili:ImportSimcAPL("Warlock_Destruction","APLForever-Destruction-rank-"..profile,
   profile=="current" and current or alternative,C.PACK)
  for _,k in ipairs({"precombat","default","boss_curse","aoe","minor_cooldowns","upkeep","major_cooldowns","instant_burst","final_fallback"}) do assert.is_table(lists[k]) end
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
 local installed,firstDot=false,false
 local rr=loop.run(L,seed,{duration=duration,on=function(w,_,time)
  if time>loop.PULL+1 and not w.us.stopped then assert.are.equal(25,H.ctl.distance.target);v.rangeSamples=v.rangeSamples+1 end
  if installed then return end;installed=true
  local press=w.W.press
  w.W.press=function(e,key,p)
   if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
   local castLeft=(e.castUntil or 0)-w.W.t
   local ok,why=press(e,key,p)
   if not ok then
    v.raw=v.raw+1
    if key=="conflagrate" and why=="casting" and castLeft>0 and castLeft<=1e-7 then v.epsilon=v.epsilon+1 end
    print("DESTRO_RANK_REFUSAL",profile,seed,rank,pct,duration,w.W.t,key,why,castLeft)
   elseif not e.stopped and offence[key] then
    v.offence=v.offence+1;v.cost=v.cost+(p.cost or 0)
    if firstDot then v.follow=v.follow+1 end
    if key=="immolate" or key=="corruption" or key=="bane_of_agony" then firstDot=true end
   end
   return ok,why
  end
 end},{{H=H}})
 assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
 assert.is_true(math.abs(initial-rr.us.power0)<1e-6)
 assert.is_true(v.rangeSamples>3)
 local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
 assert.are.equal(raw,v.raw,"raw trace incomplete")
 for _,ev in ipairs(rr.W.truth) do
  if ev.t>=loop.PULL and ev.kind=="aura" and ev.dst==rr.us.target and ev.aura==immolateID and (ev.stacks or 0)>0 then v.immolate=v.immolate+1 end
  if ev.t>=loop.PULL and ev.src==rr.us and ev.kind=="tick" and ev.dst==rr.us.target and ev.school==4 and (ev.amount or 0)>0 then v.fireTicks=v.fireTicks+1 end
 end
 local c=rr.pressedBy or {};v.tap=c.life_tap or 0;v.endMana=rr.us.power
 v.major=(c.use_items or 0)+(c.eureka or 0)+(c.blood_fury or 0)+(c.berserking or 0)
 v.minor=c.amplify_curse or 0
 print("DESTRO_RANK_RESULT",profile,seed,rank,pct,duration,v.conflag,v.early,v.earlyConsumed,v.landed,v.missed,v.consumed,v.retained,v.immolate,v.fireTicks,v.offence,v.follow,v.cost,v.endMana,v.raw,v.epsilon,v.tap,v.major,v.minor)
 if profile~="shipped" then
  assert.are.equal(0,v.tap);assert.are.equal(0,v.major);assert.are.equal(0,v.minor)
  assert.are.equal(0,v.raw-v.epsilon,"substantive refused action")
  assert.is_true(v.offence>=3,"final fallback failed")
  if duration>=60 then assert.is_true(v.follow>=3,"post-upkeep continuation failed") end
 end
 return v
end
describe("Destruction full profiles: rank 0/1/4/5 matched natural worlds",function()
 local exercised=0
 for _,seed in ipairs({30417,30437,30461}) do
  for _,rank in ipairs({0,1,4,5}) do
   it(("rank %d seed %d full Mana 60s"):format(rank,seed),function()
    trial("shipped",seed,rank,1,60)
    local old=trial("current",seed,rank,1,60)
    local new=trial("alternative",seed,rank,1,60)
    if rank==1 or rank==4 then exercised=exercised+old.early end
    if rank==0 or rank==5 then
     for _,k in ipairs({"conflag","early","consumed","fireTicks","offence","cost","endMana","raw"}) do assert.are.equal(old[k],new[k],"unchanged rank parity "..k) end
    end
    print("DESTRO_RANK_MATCH",seed,rank,1,60,old.early,new.early,old.earlyConsumed,new.earlyConsumed,old.fireTicks,new.fireTicks,old.offence,new.offence,old.cost,new.cost,old.endMana,new.endMana)
   end)
  end
 end
 it("natural partial-rank early opportunity actually exercised",function()
  assert.is_true(exercised>0,"no opportunity; experiment blocked not positive")
 end)
 for _,seed in ipairs({30417,30437,30461}) do
  for _,rank in ipairs({1,4}) do
   it(("rank %d seed %d quarter Mana 25s"):format(rank,seed),function()
    trial("shipped",seed,rank,0.25,25)
    local old=trial("current",seed,rank,0.25,25)
    local new=trial("alternative",seed,rank,0.25,25)
    print("DESTRO_RANK_MATCH",seed,rank,0.25,25,old.early,new.early,old.earlyConsumed,new.earlyConsumed,old.fireTicks,new.fireTicks,old.offence,new.offence,old.cost,new.cost,old.endMana,new.endMana)
   end)
  end
 end
end)
