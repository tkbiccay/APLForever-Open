-- Controlled source-native combat progression: manually imposed Prowl event at pull.
-- Stock Feral world lacks Ravage/Pounce. Adapter uses registered IDs/cost/auras and
-- zero-damage outcome rows for these openers, no invented DPS/stun simulation.
local loop=require("Game.harness.loop")
local druid=require("Forever.helpers.druid_loop_world")
local stock=druid.Feral
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"));local s=assert(f:read("*a"));f:close();return s
end
local apl={
 current=read("roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt"),
 prior=read("roles/Druid/Candidates/APL_Druid_Feral_v1.5_Draft.txt"),
 new=read("roles/Druid/Candidates/APL_Druid_Feral_v1.6_Draft.txt")
}
local originalCharacter=stock.character
local oldEffects={}
local ids={prowl=5215,ravage=6785,pounce=9005}
local function enter(W,e)
  W.applyAura(e,5215,3600,1,1)
  W.emit({kind="stealthed",src=e,on=true})
end
local function leave(W,e)
  if e.auras[5215] then
    e.auras[5215]=nil
    W.emit({kind="aura",dst=e,aura=5215,stacks=0,expires=0,duration=0})
    W.emit({kind="stealthed",src=e,on=false})
  end
end
local function adapt(case)
  for k,id in pairs(ids) do assert.is_nil(druid.MAP[k]);stock.IDS[k]={id} end
  druid.MAP.prowl={effect=enter}
  local function opener(key)
    return {points=1,requires=function(_,e) return e.auras[5215]~=nil,"not prowled" end,
      effect=function(W,e,_,X)
        leave(W,e)
        -- W.hit outcome rows do not carry a spell ID. Capture the returned
        -- truth event at the exact adapter invocation, not a nearby hit.
        local old=e.target.avoid.miss
        if case.outcome then e.target.avoid.miss=case.outcome=="MISS" and 1 or 0 end
        local result=W.hit(e,e.target,0,1,"miss")
        e.target.avoid.miss=old
        e.aplforeverOpenerOutcomes=e.aplforeverOpenerOutcomes or {}
        e.aplforeverOpenerOutcomes[#e.aplforeverOpenerOutcomes+1]={key=key,event=result}
        if key=="pounce" and result.act=="WOUND" then
          local a,b=assert(X.aura.pounce),assert(X.aura.pounce_bleed)
          assert.are.equal(9005,a.id);assert.are.equal(9007,b.id);assert.are.equal(18,b.duration)
          W.applyAura(e.target,a.id,a.duration,1,a.max_stack)
          W.applyAura(e.target,b.id,b.duration,1,b.max_stack)
        end
      end}
  end
  druid.MAP.ravage=opener("ravage");druid.MAP.pounce=opener("pounce")
  for _,key in ipairs({"claw","shred","rake","rip","ferocious_bite","faerie_fire"}) do
    local m=assert(druid.MAP[key])
    local f=m.effect;oldEffects[key]=f
    m.effect=function(W,e,p,X)
      leave(W,e);if f then f(W,e,p,X) end
    end
  end
  stock.character=function()
    local c=originalCharacter()
    for k,id in pairs(ids) do
      stock.IDS[k]={id}
      if k=="prowl" or k=="pounce" or case.ravage then
        c.known[#c.known+1]=id
        c.ranges[id]=k=="prowl" and {0,0} or {0,5}
      end
    end
    return c
  end
end
local function restore()
  stock.character=originalCharacter
  for k in pairs(ids) do stock.IDS[k]=nil;druid.MAP[k]=nil end
  for k,f in pairs(oldEffects) do druid.MAP[k].effect=f end
  oldEffects={}
end
local function trial(profile,case)
  local obs={}
  for k,v in pairs(stock.OBSERVE) do obs[k]=v end
  obs.notTargeted=true
  local C=setmetatable({SCENARIO="game",OBSERVE=obs,WORLD=setmetatable({
    distance=case.distance or 4,power=case.energy or 100,mobHealth=1000000000,
    noMelee=true,attackers=0,
    script=function(W,us)
      stock.WORLD.script(W,us)
      -- Precombat can spend Energy even when WORLD.power was 100.
      -- Establish the manual-Prowl boundary using real world resource events.
      W.gain(us,(case.energy or 100)-us.power)
      W.emit({kind="gain",src=us,pt=4,cost=W.res(us,4)})
      us.aplforeverPullEnergy=us.power
      enter(W,us)
      W.moveTo(us,case.distance or 4)
      if case.distance then W.at(W.t+4,function() W.moveTo(us,4) end) end
      if case.breakStealth then W.at(W.t+1,function() leave(W,us) end) end
    end
  },{__index=stock.WORLD})},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  assert.are.equal(case.ravage==true,H.Hekili.State:IsKnown("ravage"))
  assert.is_true(H.Hekili.State:IsKnown("pounce"))
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Feral","APLForever-stealth-casts-"..profile,apl[profile],C.PACK)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.minor_cooldowns.value=false;t.defensives.value=false
  t.interrupts.value=false;t.movement.value=false
  local installed=false
  local attempts,follow,raw,stealthSamples,farSamples,early,short=0,0,0,0,0,0,0
  local first,openerTime,openerEnergy="none",-1,-1
  local openerCP,openerCost,openerAct=-1,-1,"none"
  local rr=loop.run(L,case.seed,{duration=35,on=function(w,_,time)
    if not installed then
      installed=true
      local press=w.W.press
      w.W.press=function(e,key,p)
        if e~=w.us then return press(e,key,p) end
        if key=="ravage" or key=="pounce" or key=="claw" or key=="shred" or key=="rake" or key=="rip" or key=="ferocious_bite" then p.range={0,5} end
        local prowled=e.auras[5215]~=nil
        local mana=e.power
        local cpBefore=w.W.res(e,4)
        local ok,why=press(e,key,p)
        if w.W.t>=loop.PULL then
          if not ok then raw=raw+1;print("FERAL_STEALTH_REFUSAL",profile,case.name,w.W.t,key,why,mana,p.cost or 0)
          elseif prowled and key~="prowl" then
            attempts=attempts+1
            if first=="none" then
              first=key;openerTime=w.W.t;openerEnergy=mana
              openerCP=w.W.res(e,4)-cpBefore;openerCost=p.cost or 0
              local events=e.aplforeverOpenerOutcomes or {}
              if #events>0 then openerAct=events[#events].event.act end
            end
            if w.W.distance>5 then early=early+1 end
            if mana+1e-6<(p.cost or 0) then short=short+1 end
          elseif first~="none" and key~="prowl" and not e.stopped then follow=follow+1 end
        end
        return ok,why
      end
    end
    if time>loop.PULL+0.4 and not w.us.stopped then
      if w.us.auras[5215] then stealthSamples=stealthSamples+1 end
      if (case.distance or 4)>5 and time<loop.PULL+4 then
        assert.are.equal(case.distance,H.ctl.distance.target)
        farSamples=farSamples+1
      end
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  local c=rr.pressedBy or {};local rawTotal=0;for _,v in pairs(rr.refused or {}) do rawTotal=rawTotal+v end
  local gains,breaks,casts,landed,missed,bleed=0,0,0,0,0,0
  for _,ev in ipairs(rr.W.truth) do
    if ev.t>=loop.PULL then
      if ev.kind=="stealthed" and ev.on==false then breaks=breaks+1 end
      if ev.src==rr.us and (ev.spell==6785 or ev.spell==9005) then
        if ev.kind=="cast" then casts=casts+1 end
      end
      if ev.src==rr.us and ev.kind=="gain" and ev.pt==4 and (ev.rage or 0)>0 then gains=gains+ev.rage end
      if ev.kind=="aura" and ev.aura==9007 and (ev.stacks or 0)>0 then bleed=bleed+1 end
    end
  end
  for _,row in ipairs(rr.us.aplforeverOpenerOutcomes or {}) do
    if row.event.t>=loop.PULL then
      if row.event.act=="WOUND" then landed=landed+1 else missed=missed+1 end
    end
  end
  assert.are.equal(case.energy or 100,rr.us.aplforeverPullEnergy,"actual pull Energy control")
  print("FERAL_STEALTH_OPENER_TRUTH",profile,case.name,case.seed,rr.us.aplforeverPullEnergy,openerEnergy,openerCost,openerAct,openerCP)
  print(("FERAL_STEALTH_CAST profile=%s case=%s seed=%d first=%s time=%.2f energy=%.2f attempts=%d casts=%d landed=%d missed=%d bleed=%d cpGains=%d breaks=%d follow=%d raw=%d tracedRaw=%d stealthSamples=%d farSamples=%d early=%d short=%d total=%d"):format(
    profile,case.name,case.seed,first,openerTime,openerEnergy,attempts,casts,landed,missed,bleed,gains,breaks,follow,rawTotal,raw,stealthSamples,farSamples,early,short,rr.presses))
  if profile=="new" then
    assert.are.equal(0,rawTotal,"raw refusal including final fallback")
    assert.are.equal(0,c.prowl or 0,"automatic Prowl")
    assert.are.equal(0,early);assert.are.equal(0,short)
    if case.breakStealth then
      assert.is_true(breaks>=1);assert.is_true(rr.presses>=3)
    else
      assert.are.equal(case.expected or (case.ravage and "ravage" or "pounce"),first)
      assert.are.equal(1,attempts);assert.are.equal(1,casts)
      assert.are.equal(1,landed+missed);assert.are.equal(1,breaks)
      assert.is_true(follow>=3,"no three accepted actions after opener")
      if case.distance then assert.is_true(farSamples>3);assert.is_true(openerTime>=loop.PULL+4) end
      if first=="pounce" then assert.are.equal(landed,bleed) else assert.are.equal(0,bleed) end
      assert.are.equal(landed,openerCP,"combo point must follow actual opener outcome")
      if case.outcome then assert.are.equal(case.outcome,openerAct) end
    end
  end
end
describe("Feral v1.6 source-native cast progression with explicit Prowl event",function()
  after_each(restore)
  for _,case in ipairs({
    {name="ravage",ravage=true,seed=30417,outcome="WOUND"},
    {name="ravage_second",ravage=true,seed=30437,outcome="WOUND"},
    {name="ravage_miss",ravage=true,seed=30417,outcome="MISS"},
    {name="pounce",ravage=false,seed=30417,outcome="WOUND"},
    {name="pounce_second",ravage=false,seed=30437,outcome="WOUND"},
    {name="pounce_miss",ravage=false,seed=30417,outcome="MISS"},
    {name="pounce_cost_window",ravage=true,energy=53,expected="pounce",seed=30417,outcome="WOUND"},
    {name="approach",ravage=true,distance=12,seed=30417},
    {name="low_energy",ravage=true,energy=0,expected="pounce",seed=30417,outcome="WOUND"},
    {name="manual_break",ravage=true,distance=12,breakStealth=true,seed=30417}
  }) do
    it(case.name,function()
      adapt(case)
      trial("shipped",case);trial("current",case);trial("prior",case);trial("new",case)
    end)
  end
end)
