-- Full stored v1.6: controlled client observations, not actual casts.
local headless=require("Game.harness.headless")
local C=assert(require("Forever.helpers.druid_loop_world").Feral)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"));local s=assert(f:read("*a"));f:close();return s
end
local apl={current=read("roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt"),
 prior=read("roles/Druid/Candidates/APL_Druid_Feral_v1.5_Draft.txt"),new=read("roles/Druid/Candidates/APL_Druid_Feral_v1.6_Draft.txt")}
local openers={ravage=true,pounce=true,shred=true,claw=true}
local function trial(profile,case)
  local character=C.character()
  local function learn(id)
    character.known[#character.known+1]=id
    character.ranges=character.ranges or {};character.ranges[id]={0,5}
  end
  learn(5215);character.ranges[5215]={0,0}
  if case.ravage then learn(6785) end
  if case.pounce then learn(9005) end
  if case.noShred then
    local ids={};for _,id in ipairs(C.IDS.shred) do ids[id]=true end
    local known={};for _,id in ipairs(character.known) do if not ids[id] then known[#known+1]=id end end
    character.known=known
  end
  local H=headless.new({character=character,pack=C.PACK,scenario="game"})
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Feral","APLForever-Feral-stealth-"..profile,apl[profile],C.PACK)
    for _,k in ipairs({"precombat","default","cat","cat_melee","bear","defensives","finish","builders","caster"}) do assert.is_table(lists[k]) end
    if profile=="new" then assert.is_table(lists.stealth);assert.are.equal(4,#lists.stealth) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.minor_cooldowns.value=false;t.defensives.value=false
  t.movement.value=false;t.interrupts.value=false
  H.ctl.combat=case.combat==true
  H.ctl.exists.target=true;H.ctl.inRange.target=true;H.ctl.distance.target=case.range
  H.ctl.level.target=60;H.ctl.stealthed=case.stealth
  H.ctl.exists.targettarget=true;H.ctl.unitIs.targettarget=case.targeting and "player" or nil
  H.ctl.power[3]=case.energy
  H.Fire("PLAYER_TARGET_CHANGED");H.Fire("UPDATE_SHAPESHIFT_FORM");H.Fire("UPDATE_STEALTH")
  H.Fire("UNIT_POWER_UPDATE","player","ENERGY");H.Fire("SPELL_UPDATE_USABLE")
  assert.is_true(H.Hekili.Engine.Subscribe("Primary",function() end))
  local picks={};local start=H.ctl.now
  for i=1,3 do
    local worked,err=headless.cycle(H,start+i*0.2)
    assert.is_true(worked,tostring(err));assert.are.same({},H.errors)
    local out=H.Hekili.Engine.Output.Primary
    picks[i]=out.count>0 and out.recs[1].actionName or "NO_ACTION"
    H.Hekili.State.reset("Primary",true)
    local S=H.Hekili.State
    assert.is_true(S.buff.cat_form.up,"cat control absent")
    assert.are.equal(case.stealth,S.buff.prowl.up,"stealth control absent")
    assert.are.equal(case.range<=5,S.target.within5,"range control absent")
    assert.are.equal(case.targeting==true,S.target.is_targeting_player,"targeting control absent")
    assert.are.equal(case.ravage==true,S.action.ravage.known)
    assert.are.equal(case.pounce==true,S.action.pounce.known)
    if case.noShred then assert.is_false(S.action.shred.known) end
    if case.energy==0 then assert.is_true(S.energy.lo<20,"energy control absent") end
    if profile=="new" and case.stealth and openers[picks[i]] then
      assert.is_true(S.energy.lo>=S.action[picks[i]].cost,"unaffordable opener")
    end
    print(("FERAL_STEALTH_ICON profile=%s case=%s sample=%d prowl=%s in5=%s targeting=%s energy=%.2f pick=%s"):format(profile,case.name,i,tostring(S.buff.prowl.up),tostring(S.target.within5),tostring(S.target.is_targeting_player),S.energy.lo,picks[i]))
  end
  if profile=="new" and case.transition then
    H.ctl.stealthed=false;H.ctl.combat=true
    H.Fire("UPDATE_STEALTH");H.Fire("PLAYER_REGEN_DISABLED")
    local worked,err=headless.cycle(H,start+1.4)
    assert.is_true(worked,tostring(err))
    local out=H.Hekili.Engine.Output.Primary
    local pick=out.count>0 and out.recs[1].actionName or "NO_ACTION"
    H.Hekili.State.reset("Primary",true)
    assert.is_false(H.Hekili.State.buff.prowl.up)
    assert.are_not.equal("ravage",pick);assert.are_not.equal("pounce",pick)
    assert.are_not.equal("NO_ACTION",pick,"no return to normal recommendations")
    print("FERAL_STEALTH_TRANSITION",case.name,pick)
  end
  return picks
end
describe("Feral v0.12.1 stored stealth recommendation coverage",function()
  for _,case in ipairs({
    {name="ravage_ooc",stealth=true,range=4,energy=100,ravage=true,pounce=true,expected="ravage",transition=true},
    {name="ravage_combat",stealth=true,combat=true,range=4,energy=100,ravage=true,pounce=true,expected="ravage"},
    {name="pounce_available",stealth=true,range=4,energy=100,pounce=true,expected="pounce"},
    {name="early_shred",stealth=true,range=4,energy=100,expected="shred"},
    {name="early_claw",stealth=true,range=4,energy=100,noShred=true,expected="claw"},
    {name="targeting_claw",stealth=true,range=4,energy=100,ravage=true,pounce=true,targeting=true,expected="claw"},
    {name="outside",stealth=true,range=12,energy=100,ravage=true,pounce=true,expected="NO_ACTION"},
    {name="zero_energy",stealth=true,range=4,energy=0,ravage=true,pounce=true,expected="NO_ACTION"},
    {name="normal",stealth=false,combat=true,range=4,energy=100,ravage=true,pounce=true},
    {name="normal_targeting",stealth=false,combat=true,range=4,energy=100,ravage=true,pounce=true,targeting=true}
  }) do
    it(case.name,function()
      trial("shipped",case);trial("current",case)
      local old=trial("prior",case);local new=trial("new",case)
      if case.expected then
        for _,p in ipairs(new) do assert.are.equal(case.expected,p) end
        if case.expected~="NO_ACTION" then
          for _,p in ipairs(old) do assert.are.equal("NO_ACTION",p,"missing old opener not reproduced") end
        end
      else assert.are.same(old,new,"non-stealth behaviour changed") end
      for _,p in ipairs(new) do assert.are_not.equal("prowl",p,"automatic Prowl") end
    end)
  end
end)
