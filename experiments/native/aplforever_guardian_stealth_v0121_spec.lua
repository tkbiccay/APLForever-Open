-- First guardian stealth gate: full profiles, controlled observed forms, recommendations only.
local headless=require("Game.harness.headless")
local fake=require("Game.State.helpers.fake_api")
local druid=require("Forever.helpers.druid_loop_world")
local C=druid.Guardian
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"));local s=assert(f:read("*a"));f:close();return s
end
local current=read("roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt")
local prior=read("roles/Druid/Candidates/APL_Druid_Guardian_v1.6_Draft.txt")
local feral=read("roles/Druid/Current/APL_Druid_Feral_v1.6_Draft.txt")
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
local stored=read("roles/Druid/Candidates/APL_Druid_Guardian_v1.7_Draft.txt")
assert.are.equal(alternative,stored,"stored exact alternative bytes")
local packs={current=current,prior=prior,alternative=stored}
local openerKeys={ravage=true,pounce=true,shred=true,claw=true}
local function trial(profile,case)
  local char=C.character()
  local cat=druid.Feral.character()
  local known={}
  for _,id in ipairs(char.known) do known[id]=true end
  local function learn(id,range)
    if not known[id] then char.known[#char.known+1]=id;known[id]=true end
    char.ranges=char.ranges or {};char.ranges[id]=range
  end
  for _,k in ipairs({"claw","shred"}) do
    for _,id in ipairs(druid.Feral.IDS[k]) do learn(id,{0,5}) end
  end
  learn(5215,{0,0})
  if case.ravage then learn(6785,{0,5}) end
  if case.pounce then learn(9005,{0,5}) end
  if case.cat then
    char.form=cat.form
    char.power={type=3,token="ENERGY",max=100,value=case.energy or 100}
  else
    char.power={type=1,token="RAGE",max=100,value=40}
  end
  -- Shifts consume Mana even when the displayed power is Energy or Rage.
  -- Seed the off-form pool before login; do not inject a simulated APL state.
  local mana=case.mana==nil and 2584 or case.mana
  local oldNew=fake.new
  fake.new=function(...)
    local api,ctl=oldNew(...)
    ctl.powerMax[0]=2584;ctl.power[0]=mana
    ctl.regen[0]={0,0}
    return api,ctl
  end
  local ok,H=pcall(headless.new,{character=char,pack=C.PACK,scenario="game"})
  fake.new=oldNew
  assert.is_true(ok,tostring(H))
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Guardian","APLForever-Guardian-stealth-"..profile,packs[profile],C.PACK)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    for _,k in ipairs({"precombat","default"}) do assert.is_table(lists[k]) end
    if profile=="alternative" then assert.is_table(lists.stealth);assert.are.equal(4,#lists.stealth) end
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.cooldowns.override=false;t.cooldowns.infusion=false
  t.minor_cooldowns.value=false;t.minor_cooldowns.override=false
  t.defensives.value=false;t.movement.value=false;t.interrupts.value=false
  H.ctl.combat=case.combat==true
  H.ctl.inGroup=case.group==true;H.ctl.groupMembers=case.group and 2 or 0
  H.ctl.exists.target=true;H.ctl.inRange.target=true;H.ctl.distance.target=case.range or 4
  H.ctl.level.target=60;H.ctl.stealthed=case.stealth==true
  H.ctl.exists.targettarget=true;H.ctl.unitIs.targettarget=case.targeting and "player" or nil
  H.ctl.power[3]=case.energy or 100
  H.ctl.power[1]=40
  H.Fire("PLAYER_TARGET_CHANGED");H.Fire("UPDATE_SHAPESHIFT_FORM");H.Fire("UPDATE_STEALTH")
  H.Fire("UNIT_POWER_UPDATE","player",case.cat and "ENERGY" or "RAGE")
  H.Fire("UNIT_POWER_UPDATE","player","MANA")
  H.Fire("SPELL_UPDATE_USABLE")
  assert.is_true(H.Hekili.Engine.Subscribe("Primary",function() end))
  local picks={};local start=H.ctl.now
  for i=1,3 do
    local ok,err=headless.cycle(H,start+i*0.2)
    assert.is_true(ok,tostring(err));assert.are.same({},H.errors)
    local out=H.Hekili.Engine.Output.Primary
    local rec=out.count>0 and out.recs[1] or nil
    local pick=rec and rec.actionName or "NO_ACTION"
    H.Hekili.State.reset("Primary",true)
    local S=H.Hekili.State
    assert.is_true(S.action.bear_form.known,"Bear unlock absent")
    if case.cat then
      print("GUARDIAN_SHIFT_MANA",profile,case.name,i,S.mana.lo,S.action.bear_form.cost)
      if mana>0 then assert.is_true(S.mana.lo>=S.action.bear_form.cost,"shift funding control absent")
      else assert.is_true(S.mana.lo<S.action.bear_form.cost,"short shift control absent") end
    end
    assert.are.equal(case.cat==true,S.buff.cat_form.up,"Cat observation")
    assert.are.equal(case.cat~=true,S.buff.bear_form.up,"Bear observation")
    assert.are.equal(case.group==true,S.group,"group observation")
    assert.are.equal(case.stealth==true and case.cat==true,S.buff.prowl.up,"Prowl observation")
    assert.are.equal((case.range or 4)<=5,S.target.within5,"range observation")
    assert.are.equal(case.targeting==true,S.target.is_targeting_player,"target observation")
    assert.are.equal(case.ravage==true,S.action.ravage.known)
    assert.are.equal(case.pounce==true,S.action.pounce.known)
    if profile=="alternative" and openerKeys[pick] then
      assert.is_true((rec.floors.energy or 0)+1e-6>=rec.cost)
      if rec.time<=0.05 then assert.is_true(S.energy.lo+1e-6>=rec.cost) end
      if case.energy==0 then
        assert.is_true(rec.time>0.05,"ready while short")
        pick="WAIT"
      end
    end
    picks[i]=pick
    print(("GUARDIAN_STEALTH profile=%s case=%s sample=%d cat=%s prowl=%s group=%s energy=%.2f pick=%s"):format(
      profile,case.name,i,tostring(S.buff.cat_form.up),tostring(S.buff.prowl.up),tostring(S.group),S.energy.lo,pick))
  end
  if profile=="alternative" and case.transition then
    H.ctl.stealthed=false;H.ctl.combat=true
    H.Fire("UPDATE_STEALTH");H.Fire("PLAYER_REGEN_DISABLED")
    local ok,err=headless.cycle(H,start+1.4);assert.is_true(ok,tostring(err))
    local out=H.Hekili.Engine.Output.Primary
    local pick=out.count>0 and out.recs[1].actionName or "NO_ACTION"
    H.Hekili.State.reset("Primary",true)
    assert.is_false(H.Hekili.State.buff.prowl.up)
    local S=H.Hekili.State
    print("GUARDIAN_SHIFT_RETURN",case.name,pick,S.mana.lo,S.action.bear_form.cost)
    if mana>0 then
      assert.is_true(S.mana.lo>=S.action.bear_form.cost,"transition funding lost")
      assert.are.equal("bear_form",pick,"tank transition failed")
    else
      assert.are_not.equal("bear_form",pick,"unfunded shift")
      assert.is_falsy(openerKeys[pick],"stealth opener after loss")
    end
    print("GUARDIAN_STEALTH_RETURN",case.name,pick)
  end
  return picks
end
describe("Guardian v0.12.1 solo Prowl exception; existing tank behaviour preserved",function()
  for _,case in ipairs({
    {name="solo_ravage",cat=true,stealth=true,ravage=true,pounce=true,expected="ravage",transition=true},
    {name="solo_pounce",cat=true,stealth=true,pounce=true,expected="pounce"},
    {name="solo_ravage_no_mana",cat=true,stealth=true,ravage=true,pounce=true,mana=0,expected="ravage",transition=true},
    {name="solo_early",cat=true,stealth=true,expected="shred"},
    {name="solo_targeting",cat=true,stealth=true,ravage=true,pounce=true,targeting=true,expected="claw"},
    {name="solo_approach",cat=true,stealth=true,ravage=true,pounce=true,range=12,expected="NO_ACTION"},
    {name="solo_zero",cat=true,stealth=true,ravage=true,pounce=true,energy=0,expected="WAIT"},
    {name="solo_combat_prowl",cat=true,stealth=true,combat=true,ravage=true,pounce=true,expected="ravage"},
    {name="group_cat_prowl",cat=true,stealth=true,group=true,ravage=true,pounce=true},
    {name="group_bear",group=true,combat=true,targeting=true},
    {name="solo_bear",combat=true,targeting=true},
    {name="normal_cat",cat=true,combat=true,ravage=true,pounce=true},
    {name="precombat_bear"}
  }) do
    it(case.name,function()
      trial("shipped",case);trial("current",case)
      local old=trial("prior",case);local new=trial("alternative",case)
      if case.expected then for _,pick in ipairs(new) do assert.are.equal(case.expected,pick) end
      else
        assert.are.same(old,new,"tank or group recommendation changed")
        if case.cat then for _,pick in ipairs(new) do assert.are.equal("bear_form",pick,"funded ordinary/group Cat must return to Bear") end end
        for _,pick in ipairs(new) do assert.is_falsy(openerKeys[pick],"unexpected Cat attack") end
      end
      for _,pick in ipairs(new) do assert.are_not.equal("prowl",pick,"automatic Prowl") end
    end)
  end
end)
