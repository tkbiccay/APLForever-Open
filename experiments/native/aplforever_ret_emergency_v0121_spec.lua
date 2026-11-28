-- #36: class-backed emergency Divine Shield experiment; no immunity/threat-drop simulation.
local loop=require("Game.harness.loop")
local fake=require("Game.State.helpers.fake_api")
local paladin=require("Forever.helpers.paladin_world")
local stock=assert(paladin.Retribution)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Paladin/Current/APL_Paladin_Retribution_v1.2_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local line="actions=divine_shield,if=health.known&health.pct<=20&toggle.defensives&combat>0&!group&aggro&action.divine_shield.known&!buff.forbearance.up&!buff.divine_shield.up&gcd.remains<=0"
local alt,n=current:gsub("actions=call_action_list,name=crusader_open",line.."\nactions+=/call_action_list,name=crusader_open")
assert.are.equal(1,n)
local original=stock.character
local id=642
local function adapt()
  assert.is_nil(paladin.MAP.divine_shield)
  -- Only the registered rank-1 aura/Forbearance effects; not real immunity.
  paladin.MAP.divine_shield={effect=function(W,e,_,X)
    local a=assert(X.aura.divine_shield)
    local b=assert(X.aura.forbearance)
    assert.are.equal(id,a.id);assert.are.equal(25771,b.id)
    assert.are.equal(60,b.duration)
    W.applyAura(e,a.id,10,1,a.max_stack)
    W.applyAura(e,b.id,b.duration,1,b.max_stack)
    e.cdUntil.divine_protection=W.t+300
  end,requires=function(_,e,X)
    return not e.auras[X.aura.forbearance.id],"forbearance"
  end}
  stock.character=function()
    local c=original();c.known[#c.known+1]=id;stock.IDS.divine_shield={id};return c
  end
end
local function restore()
  stock.character=original;stock.IDS.divine_shield=nil;paladin.MAP.divine_shield=nil
end
local function trial(profile,case)
  local obs={}
  for k,v in pairs(stock.OBSERVE) do obs[k]=v end
  obs.bands=false;obs.notTargeted=false
  local C=setmetatable({SCENARIO="game",OBSERVE=obs,WORLD=setmetatable({
    mobHealth=1000000000,distance=4,attackers=1,
    buffs=case.forbearance and {{25771,60}} or {},
    script=function(W,us) stock.WORLD.script(W,us);W.moveTo(us,4) end
  },{__index=stock.WORLD})},{__index=stock})
  local old=fake.new
  fake.new=function(...)
    local api,ctl=old(...)
    local hp,max=api.UnitHealth,api.UnitHealthMax
    api.UnitHealth=function(unit)
      if unit=="player" then
        if case.health=="unknown" then return fake.SECRET end
        return case.health=="low" and 150 or 1000
      end
      return hp(unit)
    end
    api.UnitHealthMax=function(unit)
      if unit=="player" then return 1000 end
      return max(unit)
    end
    api.UnitThreatSituation=function(unit)
      if unit=="player" then return case.threat and 3 or 0 end
    end
    return api,ctl
  end
  local ok,L=pcall(loop.new,C);fake.new=old
  assert.is_true(ok,tostring(L))
  local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  local a=assert(H.Hekili.Class.abilities.divine_shield)
  assert.are.equal(id,a.id);assert.are.equal("defensives",a.toggle)
  assert.are.equal("spell",a.gcd);assert.is_true(H.Hekili.State:IsKnown("divine_shield"))
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Paladin_Retribution","APLForever-Ret-emergency-"..profile,
      profile=="current" and current or alt,C.PACK)
    for _,k in ipairs({"precombat","default","crusader_open","seals","major_cooldowns","aoe","final_fallback"}) do assert.is_table(lists[k]) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  H.ctl.inGroup=case.group==true;H.ctl.groupMembers=case.group and 2 or 0
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.minor_cooldowns.value=false;t.defensives.value=case.enabled
  t.defensives.separate=case.separate==true;t.interrupts.value=false;t.movement.value=false
  local accepted,raw,terminal,follow,seen,known,display,fbSeen=0,0,0,0,0,0,0,0
  local firstShield=false
  local installed=false
  local minHealth,maxHealth=100,0
  local rr=loop.run(L,case.seed,{duration=38,on=function(w,_,time)
    if not installed then
      installed=true
      local press=w.W.press
      w.W.press=function(e,key,p)
        if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
        local stop=e.stopped==true
        local ok,why=press(e,key,p)
        if not ok then
          raw=raw+1;if stop then terminal=terminal+1 end
          print("RET_EMERGENCY_REFUSAL",profile,case.name,w.W.t,key,why,tostring(stop))
        elseif not stop then
          accepted=accepted+1
          if key=="divine_shield" then firstShield=true
          elseif firstShield then follow=follow+1 end
        end
        return ok,why
      end
    end
    if time>loop.PULL+1 and not w.us.stopped then
      local hp=H.ns.VirtualState.Health("player",H.ctl.now)
      local isKnown=H.ns.VirtualStateInternal.HealthKnown()
      seen=seen+1;if isKnown then known=known+1 end
      minHealth=math.min(minHealth,hp.est*100);maxHealth=math.max(maxHealth,hp.est*100)
      if w.us.auras[25771] then fbSeen=fbSeen+1 end
      local out=H.Hekili.Engine.Output.Defensives
      if out and out.count>0 and out.recs[1].actionName=="divine_shield" then display=display+1 end
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.is_true(seen>3)
  assert.are.equal(case.health=="unknown" and 0 or seen,known)
  local pct=case.health=="low" and 15 or 100
  assert.is_true(math.abs(minHealth-pct)<1 and math.abs(maxHealth-pct)<1,"health observation not exercised")
  if case.forbearance then assert.is_true(fbSeen>3,"pre-existing Forbearance absent") end
  local casts,auras,fb=0,0,0
  for _,ev in ipairs(rr.W.truth) do
    if ev.src==rr.us and ev.kind=="cast" and ev.spell==id then casts=casts+1 end
    if ev.dst==rr.us and ev.kind=="aura" and (ev.stacks or 0)>0 and ev.t>=loop.PULL then
      if ev.aura==id then auras=auras+1 elseif ev.aura==25771 then fb=fb+1 end
    end
  end
  local count=0;for _,v in pairs(rr.refused or {}) do count=count+v end
  assert.are.equal(count,raw);assert.are.equal(casts,auras)
  if not case.forbearance then assert.are.equal(casts,fb) end
  print(("RET_EMERGENCY_V0121 profile=%s case=%s seed=%d known=%d/%d pct=%.1f/%.1f accepted=%d raw=%d terminal=%d shield=%d aura=%d forbearance=%d display=%d follow=%d"):format(
    profile,case.name,case.seed,known,seen,minHealth,maxHealth,accepted,raw,terminal,casts,auras,fb,display,follow))
  if profile=="alternative" then
    assert.are.equal(0,raw,"alternative raw refusal")
    assert.is_true(accepted>=3,"rotation stalled")
    if casts>0 then assert.is_true(follow>=3,"no three accepted follow-ons") end
  end
  return {casts=casts,display=display,accepted=accepted}
end
describe("Ret v0.12.1 solo critical-health emergency shield",function()
  before_each(adapt);after_each(restore)
  for _,case in ipairs({
    {name="low_solo",health="low",threat=true,enabled=true,seed=30417,positive=true},
    {name="low_solo_second",health="low",threat=true,enabled=true,seed=30437,positive=true},
    {name="high_solo",health="high",threat=true,enabled=true,seed=30417},
    {name="unknown_solo",health="unknown",threat=true,enabled=true,seed=30417},
    {name="low_no_threat",health="low",threat=false,enabled=true,seed=30417},
    {name="low_group",health="low",threat=true,group=true,enabled=true,seed=30417},
    {name="low_off",health="low",threat=true,enabled=false,seed=30417},
    {name="low_forbearance",health="low",threat=true,enabled=true,forbearance=true,seed=30417},
    {name="low_separate",health="low",threat=true,enabled=true,separate=true,seed=30417,positive=true},
    {name="low_separate_off",health="low",threat=true,enabled=false,separate=true,seed=30417},
  }) do
    it(case.name,function()
      trial("shipped",case)
      local old=trial("current",case)
      local new=trial("alternative",case)
      assert.are.equal(0,old.casts);assert.are.equal(0,old.display)
      if case.separate then
        assert.are.equal(0,new.casts)
        if case.positive then assert.is_true(new.display>0) else assert.are.equal(0,new.display) end
      else
        assert.are.equal(case.positive and 1 or 0,new.casts)
      end
    end)
  end
end)
