-- First guardian stealth gate: full profiles, controlled observed forms, recommendations only.
local loop=require("Game.harness.loop")
local druid=require("Forever.helpers.druid_loop_world")
local C=druid.Guardian
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"));local s=assert(f:read("*a"));f:close();return s
end
local current=read("roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt")
local prior=read("roles/Druid/Candidates/APL_Druid_Guardian_v1.6_Draft.txt")
local feral=read("roles/Druid/Candidates/APL_Druid_Feral_v1.6_Draft.txt")
local gate="buff.cat_form.up&buff.prowl.up&!group"
local safe="!("..gate..")"
local opener=assert(feral:match("(actions%.stealth=.-)\n\n"))
local lines={}
local n=0
-- Preserve each original condition in parentheses, gate only the top-level
-- tank entry points. Do not rely on called-list fallthrough/termination.
for line in prior:gmatch("[^\n]+") do
  if line:match("^actions%.precombat[%+=]") or line:match("^actions[%+=]") then
    local a,b=line:match("^(.-),if=(.*)$")
    if a then line=a..",if="..safe.."&("..b..")" else line=line..",if="..safe end
    if line:match("^actions%.precombat=") then
      lines[#lines+1]="actions.precombat=call_action_list,name=stealth,if="..gate.."&target.within5"
      line=line:gsub("^actions%.precombat=","actions.precombat+=/",1)
    elseif line:match("^actions=") then
      lines[#lines+1]="actions=call_action_list,name=stealth,if="..gate.."&target.within5"
      line=line:gsub("^actions=","actions+=/",1)
    end
    n=n+1
  end
  lines[#lines+1]=line
end
assert.are.equal(13,n,"unexpected number of tank entry lines")
local alternative=table.concat(lines,"\n").."\n"..opener.."\n"
local packs={current=current,prior=prior,alternative=alternative}
local openerKeys={ravage=true,pounce=true,shred=true,claw=true}
-- Independent controlled cast gate. Source Guardian resolver normally has no
-- off-form pools: explicitly supply native costs for these test-only pools.
local originalCharacter=C.character
local ids={prowl=5215,ravage=6785,pounce=9005}
local function leave(W,e)
  if e.auras[5215] then
    e.auras[5215]=nil
    W.emit({kind="aura",dst=e,aura=5215,stacks=0,expires=0,duration=0})
    W.emit({kind="stealthed",src=e,on=false})
  end
end
local function enter(W,e)
  W.applyAura(e,5215,3600,1,1)
  W.emit({kind="stealthed",src=e,on=true})
end
local bearEffect
local function adapt(case)
  for k,id in pairs(ids) do assert.is_nil(druid.MAP[k]);C.IDS[k]={id} end
  druid.MAP.prowl={effect=enter}
  for _,key in ipairs({"ravage","pounce"}) do
    druid.MAP[key]={points=1,requires=function(_,e) return e.auras[5215]~=nil,"not prowled" end,
      effect=function(W,e,_,X)
        leave(W,e)
        local old=e.target.avoid.miss
        e.target.avoid.miss=case.miss and 1 or 0
        local result=W.hit(e,e.target,0,1,"miss")
        e.target.avoid.miss=old
        e.stealthOutcome=result.act
        if key=="pounce" and result.act=="WOUND" then
          local a,b=assert(X.aura.pounce),assert(X.aura.pounce_bleed)
          W.applyAura(e.target,a.id,a.duration,1,a.max_stack)
          W.applyAura(e.target,b.id,b.duration,1,b.max_stack)
        end
      end}
  end
  bearEffect=druid.MAP.bear_form.effect
  druid.MAP.bear_form.effect=function(W,e,p,X)
    leave(W,e);if bearEffect then bearEffect(W,e,p,X) end
  end
  C.character=function()
    local c=originalCharacter()
    for k,id in pairs(ids) do
      C.IDS[k]={id}
      if k~="ravage" or case.ravage then
        c.known[#c.known+1]=id
        c.ranges=c.ranges or {};c.ranges[id]=k=="prowl" and {0,0} or {0,5}
      end
    end
    return c
  end
end
local function restore()
  C.character=originalCharacter
  for k in pairs(ids) do C.IDS[k]=nil;druid.MAP[k]=nil end
  druid.MAP.bear_form.effect=bearEffect
end
local function trial(profile,case)
  local obs={}
  for k,v in pairs(C.OBSERVE) do obs[k]=v end
  obs.powerMax=true;obs.plainPower={[0]="always",[3]="always",[4]="always"}
  obs.notTargeted=case.stealth==true
  local catForm=druid.Feral.character().form
  local G=setmetatable({OBSERVE=obs,SCENARIO="game",WORLD=setmetatable({
    power=40,res={[0]={cur=2584,max=2584},[3]={cur=100,max=100},[4]={cur=0,max=5}},
    regen={[3]=10},distance=case.distance or 4,attackers=1,mobHealth=1e9,targetLevel=60,
    script=function(W,us)
      C.WORLD.script(W,us)
      if case.stealth then
        W.setForm(us,catForm)
        for pt,n in pairs({[0]=2584,[3]=100,[4]=0}) do
          local d=n-W.res(us,pt)
          W.emit({kind="gain",src=us,pt=pt,rage=math.max(0,d),cost=math.max(0,-d)})
        end
        enter(W,us)
      end
      W.moveTo(us,case.distance or 4)
      if case.distance then W.at(W.t+4,function() W.moveTo(us,4) end) end
      if case.manualBreak then W.at(W.t+1,function() leave(W,us) end) end
    end
  },{__index=C.WORLD})},{__index=C})
  G.resolve=function(key,H)
    local p=C.resolve(key,H)
    local a=H.Hekili.Class.abilities[key]
    if a.spendType=="mana" or a.spendType=="energy" then
      p.pt=a.spendType=="mana" and 0 or 3
      p.cost=H.Hekili.State.action[key].cost
      assert.is_number(p.cost)
    end
    if key=="ravage" or key=="pounce" then p.range={0,5} end
    return p
  end
  local L=loop.new(G);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Guardian","APLForever-Guardian-stealth-cast-"..profile,packs[profile],G.PACK)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[G.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(G.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  H.ctl.inGroup=case.group==true;H.ctl.groupMembers=case.group and 2 or 0
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.cooldowns.override=false;t.cooldowns.infusion=false
  t.minor_cooldowns.value=false;t.minor_cooldowns.override=false
  t.defensives.value=false;t.interrupts.value=false;t.movement.value=false
  local installed=false
  local v={raw=0,openers=0,shift=0,follow=0,early=0,auto=0,shiftCost=0,shiftDebit=0,cp=-1,first="none",outcome="none",far=0,offence=0}
  local rr=loop.run(L,case.seed,{duration=70,on=function(w,_,time)
    if time>loop.PULL+0.4 and case.distance and time<loop.PULL+4 then
      assert.are.equal(case.distance,H.ctl.distance.target)
      v.far=v.far+1
    end
    if installed then return end
    installed=true
    local press=w.W.press
    w.W.press=function(e,key,p)
      if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
      local prowled=e.auras[5215]~=nil
      local mana,cp=w.W.res(e,0),w.W.res(e,4)
      local ok,why=press(e,key,p)
      if not ok then
        v.raw=v.raw+1;print("GUARDIAN_STEALTH_REFUSAL",profile,case.name,w.W.t,key,why,mana,p.cost)
      elseif not e.stopped then
        if key=="prowl" then v.auto=v.auto+1 end
        if key=="ravage" or key=="pounce" then
          assert.is_true(prowled)
          v.openers=v.openers+1;v.first=key;v.cp=w.W.res(e,4)-cp;v.outcome=e.stealthOutcome
          if w.W.distance>5 then v.early=v.early+1 end
        elseif key=="bear_form" then
          v.shift=v.shift+1;v.shiftCost=p.cost;v.shiftDebit=mana-w.W.res(e,0)
          assert.is_true(p.cost>0,"test-only shift cost not exercised")
          assert.are.equal(p.cost,v.shiftDebit)
        elseif key=="primal_bite" or key=="lacerate" or key=="swipe_bear" or key=="faerie_fire" or key=="maul" then
          v.offence=v.offence+1
          if v.shift>0 then v.follow=v.follow+1 end
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
  assert.are.equal(raw,v.raw)
  local breaks,bleed=0,0
  for _,ev in ipairs(rr.W.truth) do
    if ev.t>=loop.PULL then
      if ev.kind=="stealthed" and ev.on==false then breaks=breaks+1 end
      if ev.kind=="aura" and ev.aura==9007 and (ev.stacks or 0)>0 then bleed=bleed+1 end
    end
  end
  v.counts=rr.pressedBy or {}
  print(("GUARDIAN_STEALTH_CAST profile=%s case=%s seed=%d opener=%s casts=%d cp=%d outcome=%s bleed=%d breaks=%d shifts=%d shiftCost=%.2f shiftDebit=%.2f follow=%d offence=%d raw=%d auto=%d far=%d early=%d"):format(
    profile,case.name,case.seed,v.first,v.openers,v.cp,v.outcome,bleed,breaks,v.shift,v.shiftCost,v.shiftDebit,v.follow,v.offence,v.raw,v.auto,v.far,v.early))
  if profile=="alternative" then
    assert.are.equal(0,v.raw);assert.are.equal(0,v.auto);assert.are.equal(0,v.early)
    if case.stealth and not case.group and not case.manualBreak then
      assert.are.equal(1,v.openers);assert.are.equal(case.ravage and "ravage" or "pounce",v.first)
      assert.are.equal(case.miss and "MISS" or "WOUND",v.outcome)
      assert.are.equal(case.miss and 0 or 1,v.cp)
      assert.are.equal((not case.ravage and not case.miss) and 1 or 0,bleed)
      if case.distance then assert.is_true(v.far>3) end
    else assert.are.equal(0,v.openers) end
    if case.stealth then
      assert.are.equal(1,breaks);assert.are.equal(1,v.shift)
      assert.is_true(v.follow>=3,"no three Bear follow-ons")
    else assert.is_true(v.offence>=3) end
  end
  return v
end
describe("Guardian v0.12.1 controlled opener to paid Bear shift",function()
  after_each(restore)
  for _,case in ipairs({
    {name="ravage",stealth=true,ravage=true,seed=30417},
    {name="ravage_miss",stealth=true,ravage=true,miss=true,seed=30437},
    {name="pounce",stealth=true,seed=30417},
    {name="pounce_miss",stealth=true,miss=true,seed=30437},
    {name="approach",stealth=true,ravage=true,distance=12,seed=30417},
    {name="manual_loss",stealth=true,ravage=true,distance=12,manualBreak=true,seed=30417},
    {name="group_cat",stealth=true,ravage=true,group=true,seed=30417},
    {name="normal_bear",seed=30417},
    {name="group_bear",group=true,seed=30437}
  }) do
    it(case.name,function()
      adapt(case)
      trial("shipped",case);trial("current",case)
      local old=trial("prior",case);local new=trial("alternative",case)
      if not case.stealth or case.group then assert.are.same(old.counts,new.counts,"tank profile regression") end
    end)
  end
end)
