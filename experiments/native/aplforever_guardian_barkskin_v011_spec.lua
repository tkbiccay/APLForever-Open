-- P0 Guardian v0.11: test-only Barkskin class-backed native source adapter.
-- Stock WoWSims Guardian world omits Barkskin from BOTH kit and MAP.
-- The RELEASED class spells: Barkskin ID22812, 60s CD, 15s aura,
-- GCD=spell, native toggle="defensives"; source W.applyAura is generic.
-- No production addon, APL, simulated mitigation, health or fake spell IDs.
local loop=require("Game.harness.loop")
local ws=require("Forever.helpers.wowsims")
local helper=require("Forever.helpers.druid_loop_world")
local fake=require("Game.State.helpers.fake_api")
local stock=assert(helper.Guardian)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local paths={
  working="roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt",
  candidate="roles/Druid/Candidates/APL_Druid_Guardian_v1.5_Draft.txt"
}
local BARKSKIN_ID=22812
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local function worldFor(threat,distance)
  local C=ws.content(stock,{pack=stock.PACK,level=60,kit={"barkskin"}})
  C.SCENARIO="game"
  C.WORLD=setmetatable({
    distance=distance,attackers=2,targetLevel=60,
    mobHealth=1000000000,
  },{__index=C.WORLD})
  local old=fake.new
  fake.new=function(...)
    local api,ctl=old(...)
    ctl.role="DAMAGER"
    api.UnitThreatSituation=function(unit)
      if unit=="player" then return threat and 3 or 0 end
      return nil
    end
    return api,ctl
  end
  local ok,L=pcall(loop.new,C)
  fake.new=old
  assert.is_true(ok,tostring(L))
  return L,C
end
local function install(H,C,name)
  if name=="shipped" then return end
  local original=read(paths[name] or paths.candidate)
  if name=="guarded" then
    -- Test-only alternate complete APL, one verified in-memory condition.
    -- Preserve every actual Candidate byte: only test whether the released
    -- gcd.remains field can prevent repeated Barkskin GCD refusals.
    local changed,n=original:gsub(
      "actions%.defensive_cooldowns=barkskin,if=[^\n]+",
      function(line) return line.."&gcd.remains=0" end)
    assert.are.equal(1,n,"source v1.5 Barkskin fallback line changed")
    original=changed
  end
  local lists,warnings=H.Hekili:ImportSimcAPL(
    "Druid_Guardian","APLForever-Guardian-Barkskin-Source-Only",
    original,C.PACK)
  for _,key in ipairs({"precombat","default","damage","mitigation",
                        "defensive_cooldowns","rage_dump"}) do
    if key=="defensive_cooldowns" and name=="working" then
      -- Exact protected working does not define a Barkskin action list.
    else
      assert.is_table(lists[key],"whole profile missing "..key)
    end
  end
  assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
  assert.is_falsy((warnings or ""):find("Unknown key",1,true))
  H.Hekili.DB.profile.packs[C.PACK].lists=lists
  H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
  for key in pairs(lists) do
    assert.is_true(H.Hekili:IsListActive(C.PACK,key),
      "inactive complete APL source list "..key)
  end
  assert.are.same({},H.errors)
end
-- Exactly the already-published class action and W.applyAura world primitive,
-- NOT a custom combat model or a new player spell/rotation in the addon.
local function adaptKit()
  assert.is_nil(helper.MAP.barkskin,
    "new published Barkskin MAP exists: remove fixture adapter and retest")
  assert.is_nil(stock.IDS.barkskin,
    "the published Guardian source kit now includes Barkskin: use it directly")
  helper.MAP.barkskin={
    effect=function(W,e,_,X)
      local a=assert(X.aura.barkskin,"released source Barkskin aura absent")
      assert.are.equal(BARKSKIN_ID,a.id)
      assert.are.equal(15,a.duration)
      W.applyAura(e,a.id,a.duration,1,a.max_stack)
    end
  }
  stock.IDS.barkskin={BARKSKIN_ID}
end
local function restore()
  helper.MAP.barkskin=nil
  stock.IDS.barkskin=nil
end
local function one(profile,seed,threat,distance,defensives,seconds)
  local L,C=worldFor(threat,distance)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  local abilities=H.Hekili.Class.abilities
  local a=assert(abilities.barkskin,"native Druid class lacks Barkskin")
  local aura=assert(H.Hekili.Class.auras.barkskin)
  assert.are.equal(BARKSKIN_ID,a.id)
  assert.are.equal("defensives",a.toggle)
  assert.are.equal(60,a.cooldown)
  assert.are.equal("spell",a.gcd)
  assert.are.equal(BARKSKIN_ID,aura.id)
  assert.are.equal(15,aura.duration)
  assert.is_true(H.Hekili.State:IsKnown("barkskin"),
    "published ws.content kit did not expose source-known Barkskin")
  install(H,C,profile)
  H.ctl.inGroup=true
  H.ctl.groupMembers=2
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.defensives.value=defensives
  t.movement.value=false
  local priorGcd=0
  local refusalTrace={}
  local rr=loop.run(L,seed,{
    duration=seconds,
    on=function(w,_,time)
      local n=w.refused.gcd or 0
      if n>priorGcd then
        if #refusalTrace<12 then
          local action=w.ours[w.combat]
          local accepted=w.pressed[w.combat]
          local rec=H.Hekili.Engine.Output.Primary
          local first=rec and rec.recs and rec.recs[1]
          local ahead=(w.us.gcdUntil or 0)-w.W.t
          refusalTrace[#refusalTrace+1]={
            t=time,action=action,accepted=accepted,
            ahead=ahead,wait=first and first.wait
          }
        end
      end
      priorGcd=n
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  for i,e in ipairs(refusalTrace) do
    print(("GUARDIAN_BARKSKIN_GCD_REFUSAL seed=%d profile=%s idx=%d t=%.2f action=%s accepted=%s worldGCDRemaining=%.3f recommendedWait=%s"):format(
      seed,profile,i,e.t,tostring(e.action),tostring(e.accepted),
      e.ahead,tostring(e.wait)))
  end
  local by=rr.pressedBy or {}
  local press,apply,expire={}, {}, {}
  for _,e in ipairs(rr.W.truth) do
    if e.src==rr.us and e.kind=="cast" and e.spell==BARKSKIN_ID then
      press[#press+1]=e.t
    elseif e.dst==rr.us and e.kind=="aura" and e.aura==BARKSKIN_ID then
      if e.stacks>0 then apply[#apply+1]=e.t
      else expire[#expire+1]=e.t end
    end
  end
  assert.are.equal(by.barkskin or 0,#press,
    "source counted different true Barkskin casts than actual accepted presses")
  assert.are.equal(#press,#apply,
    "self-Barkskin source casts must actually apply a buff")
  for i=1,#apply do
    assert.is_true(math.abs(apply[i]-press[i])<0.05,
      "Barkskin buff applied without source-accepted cast")
  end
  for i=2,#press do
    assert.is_true(press[i]-press[i-1]>=59,
      "Barkskin cast while its native 60s cooldown should not be ready")
  end
  for i=1,#expire do
    assert.is_true(expire[i]>=apply[i]+14.9,
      "Barkskin buff expired before native class duration")
  end
  if not defensives or distance>5 or (profile~="candidate" and profile~="guarded") then
    assert.are.equal(0,#press,
      "disabled/out-of-range or no Barkskin APL must not cast")
  elseif threat then
    assert.is_true(#press>=1,
      "defensive toggle ON, actual source-native Guardian never cast")
  end
  if (profile=="candidate" or profile=="guarded") and threat and distance<=5 and defensives then
    -- Really advance beyond an actual Barkskin cast. An off-GCD icon
    -- standing still is not a verified ongoing combat rotation.
    local tail={}
    local first=nil
    for idx=1,rr.combat do
      if rr.pressed[idx]=="barkskin" then first=idx;break end
    end
    assert.is_truthy(first,"no real Barkskin pressed")
    for idx=first+1,rr.combat do
      local key=rr.pressed[idx]
      if type(key)=="string" then
        tail[#tail+1]=key
        if #tail==3 then break end
      end
    end
    assert.are.equal(3,#tail,
      "no three accepted follow-on source actions after Barkskin")
    for _,key in ipairs(tail) do
      assert.is_true(key~="barkskin",
        "immediate duplicated native Barkskin recommendation")
    end
    print(("GUARDIAN_BARKSKIN_NEXT3 seed=%d first=%s"):format(
      seed,table.concat(tail,",")))
  end
  local refused=0
  for _,v in pairs(rr.refused or {}) do refused=refused+v end
  local ts={}
  for _,v in ipairs(press) do ts[#ts+1]=("%.2f"):format(v) end
  print(("GUARDIAN_BARKSKIN_V011 profile=%s seed=%d threat=%s yd=%d toggle=%s duration=%d accepted=%d refused=%d BarkskinCast=%d trueApplied=%d expiries=%d times=%s Roar=%d other=%d truth=%d"):format(
    profile,seed,tostring(threat),distance,tostring(defensives),seconds,
    rr.presses,refused,#press,#apply,#expire,table.concat(ts,","),
    by.demoralizing_roar or 0,rr.presses-#press,#rr.W.truth))
  if profile=="candidate" and seed==30417 and threat and distance==4 and defensives then
    -- Known negative: source recommendation wait=0 against GCD 0.5/0.3/0.1
    -- before its eventual true Barkskin cast. A passing expected-negative
    -- assertion is NOT a passing candidate castability/safety verdict.
    assert.are.equal(3,rr.refused.gcd or 0,
      "full original v1.5 GCD failure signature changed")
  elseif profile=="candidate" or profile=="guarded" then
    assert.are.same({},rr.refused,
      "source-refused full stored Candidate / test-only guard variant")
  end
  return {casts=#press,accepted=rr.presses,refused=refused,
          times=press,by=by}
end
local function compare(seed,threat,distance,defensives,seconds)
  local shipped=one("shipped",seed,threat,distance,defensives,seconds)
  local working=one("working",seed,threat,distance,defensives,seconds)
  local candidate=one("candidate",seed,threat,distance,defensives,seconds)
  local guarded=one("guarded",seed,threat,distance,defensives,seconds)
  print(("GUARDIAN_BARKSKIN_COMPARE seed=%d threat=%s yd=%d toggle=%s shipped=%d/%d/%d working=%d/%d/%d v15=%d/%d/%d inMemoryGcd=%d/%d/%d"):format(
    seed,tostring(threat),distance,tostring(defensives),
    shipped.accepted,shipped.refused,shipped.casts,
    working.accepted,working.refused,working.casts,
    candidate.accepted,candidate.refused,candidate.casts,
    guarded.accepted,guarded.refused,guarded.casts))
  if defensives and distance==4 and threat then
    assert.is_true(guarded.casts>=1,
      "in-memory guard must still produce real source Barkskin casts")
  end
  return candidate,working,shipped,guarded
end
describe("Guardian v0.11 class-backed test-only Barkskin native toggle and fallback",function()
  before_each(adaptKit)
  after_each(restore)
  it("actual source buff and cooldown with Defensives ON, true-threat 4yd seed A",function()
    local c=compare(30417,true,4,true,83)
    assert.is_true(c.casts>=1)
  end)
  it("repeat cooldown and genuine successful source aura seed B",function()
    local c=compare(30418,true,4,true,83)
    assert.is_true(c.casts>=1)
  end)
  it("native Defensives OFF prevents Barkskin, despite learned source spell",function()
    local c=compare(30417,true,4,false,83)
    assert.are.equal(0,c.casts)
  end)
  it("Defensives ON 6yd but melee-only APL guard correctly withholds Barkskin",function()
    local c=compare(30417,true,6,true,47)
    assert.are.equal(0,c.casts)
  end)
  it("Defensives ON and synthetic zero client threat: measure proactive use, not call it a proven save",function()
    local c=compare(30417,false,4,true,38)
    -- Do not assert an invented no-threat health or mitigation fact;
    -- source client no-threat != proof that no damage can reach player.
    assert.is_true(c.accepted>=3,"source combat did not advance")
  end)
end)
