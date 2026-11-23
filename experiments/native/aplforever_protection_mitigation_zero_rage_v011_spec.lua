-- APLForever breadth independent hypothesis #16: Paladin Protection Holy Shield
-- source ACTUAL charge consumption under incoming blocks (not aura cast only);
-- #17: Warrior Protection TRUE starting 0 Rage including final/repeated fallback.
-- Published Forever v0.11.0 SHA 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- All shipped / protected Current / full unselected candidate original files.
local loop=require("Game.harness.loop")
local fake=require("Game.State.helpers.fake_api")
local pal=require("Forever.helpers.paladin_world").Protection
local war=require("Forever.helpers.warrior_world").Protection
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"))
  local v=assert(f:read("*a"));f:close();return v
end
local pcur=read("roles/Paladin/Current/APL_Paladin_Protection_Tank_v1.0_Draft.txt")
local pcan=read("roles/Paladin/Candidates/APL_Paladin_Protection_v1.1_Draft.txt")
local wcur=read("roles/Warrior/Current/APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt")
local wcan=read("roles/Warrior/Candidates/APL_Warrior_Protection_v1.1_Draft.txt")
local function setup(C,kind,profile)
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local text=kind=="paladin" and (profile=="current" and pcur or pcan)
      or (profile=="current" and wcur or wcan)
    local a=kind=="paladin" and "Paladin_Protection" or "Warrior_Protection"
    local lists,warnings=H.Hekili:ImportSimcAPL(a,
      "APLForever-Protected-Breadth-v011-"..kind..profile,text,C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.precombat)
    assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),
        kind.." full list inactive "..name)
    end
    assert.are.same({},H.errors)
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.minor_cooldowns.value=false
  t.interrupts.value=false
  if t.movement then t.movement.value=false end
  return L,H
end
local function palRun(profile,seed,defensives)
  local world=setmetatable({
    distance=4,attackers=2,mobPeriod=1.8,mobHealth=1000000000,
    power=pal.WORLD.max,targetLevel=60,
  },{__index=pal.WORLD})
  local C=setmetatable({WORLD=world},{__index=pal})
  -- Published v0.11 engine Facade caches UnitThreatSituation at load; inject
  -- a controlled true threat BEFORE creating the source world, never later.
  local saved=fake.new
  fake.new=function(...)
    local api,ctl=saved(...)
    ctl.role="DAMAGER" -- retail tank-role assignment cannot drive aggro gate
    api.UnitThreatSituation=function(unit)
      if unit=="player" then return 3 end
    end
    return api,ctl
  end
  local ok,L,H=pcall(function()
    local l,h=setup(C,"paladin",profile);return l,h
  end)
  fake.new=saved
  assert.is_true(ok,tostring(L))
  H.ctl.inGroup=true
  H.ctl.groupMembers=2
  assert.are.equal("DAMAGER",H.ctl.role)
  H.Hekili.DB.profile.toggles.defensives.value=defensives
  local rr=loop.run(L,seed,{duration=68},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local by=rr.pressedBy or {}
  local shield=by.holy_shield or 0
  local auraId=assert(H.Hekili.Class.auras.holy_shield).id
  local applied,spent,emptied,blocked,mobSwings=0,0,0,0,0
  for _,e in ipairs(rr.W.truth) do
    if e.kind=="aura" and e.aura==auraId
      and e.dst and e.dst.guid==rr.us.guid then
      if e.stacks==4 then applied=applied+1
      elseif e.stacks and e.stacks>0 and e.stacks<4 then spent=spent+1
      elseif e.stacks==0 then emptied=emptied+1 end
    end
    if e.kind=="swing" and e.src and e.src.kind=="mob"
      and e.dst and e.dst.guid==rr.us.guid then
      mobSwings=mobSwings+1
      if e.act=="BLOCK" then blocked=blocked+1 end
    end
  end
  local post=0;local found=false
  for i=1,rr.combat or 0 do
    if rr.pressed[i]=="holy_shield" then found=true
    elseif found and type(rr.pressed[i])=="string"
      and rr.pressed[i]~="holy_shield" then post=post+1 end
  end
  local refused=0
  for why,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("SHIELD_CHARGES_REFUSED profile=%s seed=%d def=%s why=%s n=%d"):format(
      profile,seed,tostring(defensives),tostring(why),n))
  end
  print(("PAL_BLOCK_V011 profile=%s seed=%d def=%s cast=%d aura4=%d auraSpends=%d aura0=%d incoming=%d blocked=%d later=%d accepted=%d refused=%d"):format(
    profile,seed,tostring(defensives),shield,applied,spent,emptied,
    mobSwings,blocked,post,rr.presses,refused))
  if profile=="candidate" then
    assert.are.equal(0,refused,"candidate source refused real action")
    assert.is_true(rr.presses>=5)
    assert.is_true(mobSwings>=3,"fixture lacked real incoming attacks")
    assert.is_true(shield>=1,"source tank shield never activated while actually threatened")
    assert.is_true(applied>=1,"Holy Shield had no true source aura")
    assert.is_true(post>=3,"must accept three follow-on real actions")
    assert.is_true(spent>=1,
      "Holy Shield charges never changed despite modelled incoming attacks")
    assert.is_true(blocked>=spent,
      "charge consumed with no matching incoming source BLOCK event")
  end
  return {shield=shield,applied=applied,spent=spent,blocks=blocked,
    accepted=rr.presses,refused=refused}
end
local OF={revenge=true,shield_slam=true,thunder_clap=true,
    sunder_armor=true,rend=true,bloodthirst=true,mortal_strike=true,
    victory_rush=true,heroic_strike=true,cleave=true}
local function warriorRun(profile,seed,rage)
  local world=setmetatable({
    power=rage,attackers=2,distance=4,mobHealth=1000000000
  },{__index=war.WORLD})
  local C=setmetatable({WORLD=world},{__index=war})
  local L,H=setup(C,"warrior",profile)
  H.Hekili.DB.profile.toggles.defensives.value=false
  local rr=loop.run(L,seed,{duration=85},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local by=rr.pressedBy or {}
  local offensive=0
  for key in pairs(OF) do offensive=offensive+(by[key] or 0) end
  local later=0
  local began=false
  for i=1,rr.combat or 0 do
    local k=rr.pressed[i]
    if OF[k] then
      if began then later=later+1 else began=true end
    end
  end
  local refused,cost=0,0
  for why,n in pairs(rr.refused or {}) do
    refused=refused+n
    if why=="cost" then cost=cost+n end
    print(("PROT_RAGE0_REFUSED profile=%s seed=%d rage0=%d why=%s n=%d"):format(
      profile,seed,rage,tostring(why),n))
  end
  print(("PROT_RAGE0_V011 profile=%s seed=%d rage0=%d accepted=%d offensive=%d later=%d trueRageEnd=%.3f rejected=%d cost=%d revenge=%d shield=%d"):format(
    profile,seed,rage,rr.presses,offensive,later,rr.us.power,
    refused,cost,by.revenge or 0,by.shield_block or 0))
  if profile=="candidate" then
    assert.is_true(rr.presses>=4,"zero-rage did not recover into accepted casts")
    assert.is_true(offensive>=3,"zero-rage did not reach 3 real offensive actions")
    assert.is_true(later>=2,"last fallbacks did not advance after first attack")
    assert.are.equal(0,cost,"candidate repeated unaffordable attack at 0 Rage")
    assert.are.equal(0,refused,"candidate source refused an action")
  end
  return {accepted=rr.presses,offensive=offensive,later=later,
    refused=refused,cost=cost}
end
describe("Breadth #16 Paladin Protection actual shield BLOCK charge accounting",function()
  for _,seed in ipairs({30417,30437}) do
    for _,def in ipairs({false,true}) do
      it(("seed%d Defensives %s complete default/Current/Candidate"):format(
        seed,tostring(def)),function()
        local shipped=palRun("shipped",seed,def)
        local current=palRun("current",seed,def)
        local candidate=palRun("candidate",seed,def)
        assert.are.equal(0,current.shield*(def and 0 or 1),
          "protected Current changed its OFF shield gating")
        if not def then
          assert.is_true(candidate.shield>current.shield,
            "candidate lost routine mitigation with native Defensives OFF")
        end
        print(("PAL_BLOCK_PAIR seed=%d def=%s shipped=%d current=%d candidate=%d"):format(
          seed,tostring(def),shipped.shield,current.shield,candidate.shield))
      end)
    end
  end
end)
describe("Breadth #17 Warrior Protection genuine zero and tiny starting Rage",function()
  for _,seed in ipairs({30461,30479}) do
    for _,rage in ipairs({0,5}) do
      it(("seed%d initial Rage%d complete shipped/Current/Candidate"):format(
        seed,rage),function()
        local shipped=warriorRun("shipped",seed,rage)
        local current=warriorRun("current",seed,rage)
        local candidate=warriorRun("candidate",seed,rage)
        assert.is_true(shipped.accepted>=3,"shipped no source action")
        assert.is_true(current.accepted>=3,"Current zero-rage no action")
        print(("PROT_RAGE0_PAIR seed=%d rage0=%d shipped=%d current=%d candidate=%d"):format(
          seed,rage,shipped.accepted,current.accepted,candidate.accepted))
      end)
    end
  end
end)
