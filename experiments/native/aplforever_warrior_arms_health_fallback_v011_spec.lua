-- Warrior Arms: published v0.11.0 compiler/health-risk isolation plus
-- complete shipped vs exact protected Current v1.0 vs unselected full v1.1.
-- Health cost of Bloodrage is NOT subtracted by published source combat world.
-- Do not treat removing health.pct from its guard as a safe real-client fix.
local loop=require("Game.harness.loop")
local base=require("Forever.helpers.warrior_world")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local files={
  current="roles/Warrior/Current/APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt",
  candidate="roles/Warrior/Candidates/APL_Warrior_Arms_v1.1_Draft.txt"
}
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local old,new=read(files.current),read(files.candidate)
local suspect="actions.precombat+=/bloodrage,use_off_gcd=1,if=action.bloodrage.known&toggle.minor_cooldowns&target.is_boss&health.pct>=95&rage.lo<=10&!buff.bloodrage.up"
assert.is_truthy(old:find(suspect,1,true))
local at=assert(old:find(suspect,1,true))
assert.are.equal("\n",old:sub(at+#suspect,at+#suspect),
  "exact removed precombat line must end in newline")
local removed=old:sub(1,at-1)..old:sub(at+#suspect+1)
assert.are.equal(new,removed,
  "v1.1 must be EXACT v1.0 minus just one health-cost action line")
assert.is_nil(new:find("health.pct",1,true))
assert.is_nil(new:find("bloodrage",1,true))
local offensive={mortal_strike=true,slam=true,overpower=true,execute=true,
  heroic_strike=true,cleave=true,spearing_strike=true,whirlwind=true,
  sunder_armor=true,rend=true,thunder_clap=true,victory_rush=true}
local major={recklessness=true,death_wish=true,blood_fury=true,
  berserking=true,eureka=true,elunes_light=true,sweeping_strikes=true}
local function run(profile,seed,initialRage,minor,duration)
  local world=setmetatable({power=initialRage,mobHealth=1000000000},
    {__index=base.WORLD})
  local C=setmetatable({WORLD=world},{__index=base})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  assert.are.equal("Arms (wowsims.com)",C.PACK)
  local compile=0
  if profile~="shipped" then
    local text=profile=="current" and old or new
    local lists,warnings=H.Hekili:ImportSimcAPL(
      "Warrior_Arms","APLForever-Arms-v011-"..profile,text,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","defensive_cures",
      "minor_cooldowns","stance_control","major_cooldowns",
      "cleave_and_aoe","rend_upkeep","utility","rage_dump"}) do
      assert.is_table(lists[name],"full imported list absent: "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),
        "inactive full list "..name.." in "..profile)
    end
    compile=#H.errors
    for _,error in ipairs(H.errors) do
      print(("ARMS_COMPILER profile=%s detail=%s"):format(
        profile,tostring(error):sub(1,260)))
    end
    assert.are.equal(profile=="current" and 1 or 0,compile,
      "changed compiler fault count on exact published release")
  else
    assert.are.same({},H.errors)
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.minor_cooldowns.value=minor
  t.defensives.value=false
  t.interrupts.value=false
  if t.movement then t.movement.value=false end
  local observed,refusedEvents={},{}
  local installed=false
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(sim)
      if installed then return end
      local prior=sim.W.press
      sim.W.press=function(p,key,resolved)
        local time=sim.W.t
        local rage=p.power
        local ok,why=prior(p,key,resolved)
        if p==sim.us and time>=loop.PULL and type(key)=="string" then
          if ok then
            observed[#observed+1]={t=time,k=key,rage=rage}
          else
            refusedEvents[#refusedEvents+1]={
              t=time,k=key,rage=rage,reason=tostring(why)}
          end
        end
        return ok,why
      end
      installed=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local counts=rr.pressedBy or {}
  local nOff,nMajor=0,0
  for key in pairs(offensive) do nOff=nOff+(counts[key] or 0) end
  for key in pairs(major) do nMajor=nMajor+(counts[key] or 0) end
  local nRef,nCost=0,0
  for reason,n in pairs(rr.refused or {}) do
    nRef=nRef+n
    if reason=="cost" then nCost=nCost+n end
  end
  for _,a in ipairs(refusedEvents) do
    print(("ARMS_REFUSED profile=%s seed=%d rage0=%.0f minor=%s t=%.17g key=%s rage=%.5f reason=%s"):format(
      profile,seed,initialRage,tostring(minor),a.t,a.k,a.rage,a.reason))
  end
  local followOns=0
  local seenFirst=false
  for _,a in ipairs(observed) do
    if offensive[a.k] then
      if seenFirst then followOns=followOns+1 end
      seenFirst=true
    end
  end
  print(("ARMS_V011 profile=%s seed=%d rage0=%.0f minor=%s accepted=%d offensive=%d followOns=%d compiler=%d refused=%d cost=%d bloodrage=%d major=%d mortal=%d slam=%d rend=%d"):format(
    profile,seed,initialRage,tostring(minor),rr.presses,nOff,followOns,
    compile,nRef,nCost,counts.bloodrage or 0,nMajor,
    counts.mortal_strike or 0,counts.slam or 0,counts.rend or 0))
  return {accepted=rr.presses,offensive=nOff,followOns=followOns,
    compiler=compile,refused=nRef,cost=nCost,bloodrage=counts.bloodrage or 0,
    major=nMajor}
end
describe("Arms v0.11 published source: health compiler and safe final fallback",function()
  for _,seed in ipairs({30417,30437}) do
    for _,rage in ipairs({25,90}) do
      for _,minor in ipairs({false,true}) do
        it(("seed %d initial Rage %d Minor %s"):format(
            seed,rage,tostring(minor)),function()
          local stock=run("shipped",seed,rage,minor,75)
          local current=run("current",seed,rage,minor,75)
          local candidate=run("candidate",seed,rage,minor,75)
          assert.are.equal(1,current.compiler)
          assert.are.equal(0,candidate.compiler)
          assert.is_true(stock.accepted>=3)
          assert.is_true(current.accepted>=3,
            "protected Current did not advance over source compiler defect")
          assert.is_true(candidate.accepted>=3)
          assert.is_true(candidate.offensive>=3)
          assert.is_true(candidate.followOns>=2,
            "post-upkeep complete Candidate never executes repeated offence")
          assert.are.equal(0,candidate.refused,
            "new v1.1 repeated source-refused an actual attack")
          assert.are.equal(0,candidate.cost,
            "new v1.1 suggested an unaffordable action")
          assert.are.equal(0,candidate.bloodrage,
            "new Candidate accidentally enabled the unmodelled HP conversion")
          assert.are.equal(0,candidate.major,
            "new Candidate violated user's Major OFF")
        end)
      end
    end
  end
end)
