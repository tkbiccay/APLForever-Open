-- Proposed #32: isolated low-known-health solo Barkskin eligibility.
-- v0.12.1 released engine, controlled API reads; NOT real incoming mitigation.
local loop=require("Game.harness.loop")
local fake=require("Game.State.helpers.fake_api")
local druid=require("Forever.helpers.druid_loop_world")
local stock=assert(druid.Feral)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local apl={
  current=read("roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt"),
  candidate=read("roles/Druid/Candidates/APL_Druid_Feral_v1.4_Draft.txt")
}
local before="&(group|active_enemies>=2)&!buff.barkskin.up"
local after="&((group|active_enemies>=2)|(health.known&health.pct<=65))&!buff.barkskin.up"
local n
apl.health,n=apl.candidate:gsub(before:gsub("([^%w])","%%%1"),function() return after end)
assert.are.equal(1,n,"only the existing Barkskin eligibility branch may change")
local stored=read("roles/Druid/Candidates/APL_Druid_Feral_v1.5_Draft.txt")
assert.are.equal(apl.health,stored,"complete stored Draft differs from measured hypothesis")
apl.health=stored
local id=22812
local original=stock.character
local function adapt()
  assert.is_nil(druid.MAP.barkskin)
  druid.MAP.barkskin={effect=function(W,e,_,X)
    local a=assert(X.aura.barkskin)
    assert.are.equal(id,a.id);assert.are.equal(15,a.duration)
    W.applyAura(e,a.id,a.duration,1,a.max_stack)
  end}
  stock.character=function()
    local c=original()
    c.known[#c.known+1]=id
    stock.IDS.barkskin={id}
    return c
  end
end
local function restore()
  stock.character=original
  stock.IDS.barkskin=nil
  druid.MAP.barkskin=nil
end
local function trial(profile,case)
  local obs={}
  for k,v in pairs(stock.OBSERVE) do obs[k]=v end
  obs.bands=false;obs.notTargeted=false
  local C=setmetatable({SCENARIO="game",OBSERVE=obs,WORLD=setmetatable({
    distance=4,attackers=1,mobHealth=1000000000
  },{__index=stock.WORLD})},{__index=stock})
  local old=fake.new
  fake.new=function(...)
    local api,ctl=old(...)
    local health,max=api.UnitHealth,api.UnitHealthMax
    api.UnitHealth=function(unit)
      if unit=="player" then
        if case.health=="unknown" then return fake.SECRET end
        return case.health=="low" and 600 or 1000
      end
      return health(unit)
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
  local bark=assert(H.Hekili.Class.abilities.barkskin)
  assert.are.equal(id,bark.id);assert.are.equal("defensives",bark.toggle)
  assert.are.equal(60,bark.cooldown);assert.are.equal("spell",bark.gcd)
  assert.is_true(H.Hekili.State:IsKnown("barkskin"))
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Feral","APLForever-Feral-health-"..profile,apl[profile],C.PACK)
    for _,k in ipairs({"precombat","default","cat","cat_melee","bear","defensives","finish","builders","caster"}) do assert.is_table(lists[k]) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  H.ctl.inGroup=case.group;H.ctl.groupMembers=case.group and 2 or 0
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.minor_cooldowns.value=false
  t.defensives.value=case.enabled;t.defensives.separate=case.separate==true
  t.movement.value=false;t.interrupts.value=false
  local samples,knownSamples,displayTicks=0,0,0
  local minHealth,maxHealth=100,0
  local accepted,activeRefused,terminalRefused,terminalAccepted=0,0,0,0
  local follow,firstBark=0,false
  local installed=false
  local rr=loop.run(L,case.seed,{duration=38,on=function(w,_,time)
    if not installed then
      installed=true
      local press=w.W.press
      w.W.press=function(e,key,p)
        if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
        local stop=e.stopped==true
        local ok,why=press(e,key,p)
        if not ok then
          if stop then terminalRefused=terminalRefused+1 else activeRefused=activeRefused+1 end
          print("FERAL_HEALTH_REFUSAL",profile,case.name,w.W.t,key,why,tostring(stop))
        elseif stop then terminalAccepted=terminalAccepted+1
        else
          accepted=accepted+1
          if key=="barkskin" then firstBark=true
          elseif firstBark then follow=follow+1 end
        end
        return ok,why
      end
    end
    if w.combat>0 and not w.us.stopped then
      local belief=H.ns.VirtualState.Health("player",H.ctl.now)
      local known=H.ns.VirtualStateInternal.HealthKnown()
      samples=samples+1
      if known then knownSamples=knownSamples+1 end
      minHealth=math.min(minHealth,belief.est*100)
      maxHealth=math.max(maxHealth,belief.est*100)
      local out=H.Hekili.Engine.Output.Defensives
      if out and out.count>0 and out.recs[1].actionName=="barkskin" then displayTicks=displayTicks+1 end
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.is_true(samples>3)
  assert.are.equal(case.health=="unknown" and 0 or samples,knownSamples,"actual health reader control must be exercised")
  local pct=case.health=="low" and 60 or 100
  assert.is_true(math.abs(minHealth-pct)<1 and math.abs(maxHealth-pct)<1,"unexpected observed health fraction")
  local casts,auras=0,0
  for _,ev in ipairs(rr.W.truth) do
    if ev.src==rr.us and ev.kind=="cast" and ev.spell==id then casts=casts+1
    elseif ev.dst==rr.us and ev.kind=="aura" and ev.aura==id and ev.stacks>0 then auras=auras+1 end
  end
  local raw=0;for _,v in pairs(rr.refused or {}) do raw=raw+v end
  assert.are.equal(raw,activeRefused+terminalRefused,"raw refusal count must match")
  assert.are.equal(casts,auras)
  assert.are.equal(casts,(rr.pressedBy or {}).barkskin or 0)
  print(("FERAL_HEALTH_V0121 case=%s profile=%s seed=%d known=%d/%d pct=%.1f/%.1f threat=%s group=%s enabled=%s separate=%s accepted=%d raw=%d activeRefused=%d terminalRefused=%d terminalAccepted=%d barkskin=%d aura=%d displayTicks=%d follow=%d"):format(
    case.name,profile,case.seed,knownSamples,samples,minHealth,maxHealth,tostring(case.threat),tostring(case.group),tostring(case.enabled),tostring(case.separate==true),accepted,raw,activeRefused,terminalRefused,terminalAccepted,casts,auras,displayTicks,follow))
  if profile=="health" or profile=="candidate" then
    assert.are.equal(0,raw,"new or protected candidate refused action")
    assert.is_true(accepted>=3,"rotation failed to progress")
    if casts>0 then assert.is_true(follow>=3,"no three accepted actions after Barkskin") end
  end
  return {casts=casts,display=displayTicks,accepted=accepted}
end
describe("Feral v0.12.1 health-aware Barkskin solo extension",function()
  before_each(adapt);after_each(restore)
  for _,case in ipairs({
    {name="low_solo",health="low",threat=true,group=false,enabled=true,seed=30417,positive=true},
    {name="low_solo_second",health="low",threat=true,group=false,enabled=true,seed=30437,positive=true},
    {name="unknown_solo",health="unknown",threat=true,group=false,enabled=true,seed=30417},
    {name="high_solo",health="high",threat=true,group=false,enabled=true,seed=30417},
    {name="low_no_threat",health="low",threat=false,group=false,enabled=true,seed=30417},
    {name="low_toggle_off",health="low",threat=true,group=false,enabled=false,seed=30417},
    {name="high_group",health="high",threat=true,group=true,enabled=true,seed=30417,positive=true,baseline=true},
    {name="unknown_group",health="unknown",threat=true,group=true,enabled=true,seed=30417,positive=true,baseline=true},
    {name="low_separate",health="low",threat=true,group=false,enabled=true,separate=true,seed=30417,positive=true},
    {name="low_separate_off",health="low",threat=true,group=false,enabled=false,separate=true,seed=30417},
  }) do
    it(case.name,function()
      trial("shipped",case);trial("current",case)
      local old=trial("candidate",case)
      local new=trial("health",case)
      if case.separate then
        assert.are.equal(0,old.casts);assert.are.equal(0,new.casts)
        assert.are.equal(0,old.display)
        if case.positive then assert.is_true(new.display>0) else assert.are.equal(0,new.display) end
      else
        assert.are.equal(case.baseline and 1 or 0,old.casts,"existing eligibility control changed")
        assert.are.equal(case.positive and 1 or 0,new.casts,"experimental eligibility not exercised")
      end
    end)
  end
end)
