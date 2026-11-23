-- Warrior Fury v0.11.0 distinct source-native Bloodthirst near 30 Rage,
-- selected Current vs archived known-bad v1.1 vs unselected v1.2 vs shipped.
-- Published zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- No APL selection/approval; damage, real enemy count and threat NOT proved.
local loop=require("Game.harness.loop")
local gate=require("Forever.helpers.fury_gate")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local paths={
  current="roles/Warrior/Current/APL_Warrior_Fury_DPS_v1.0_Draft.txt",
  archived="roles/Warrior/Archive/APL_Warrior_Fury_v1.1_Draft.txt",
  candidate="roles/Warrior/Candidates/APL_Warrior_Fury_v1.2_Draft.txt"
}
local data={}
for name,path in pairs(paths) do
  local f=assert(io.open(root.."/"..path,"rb"))
  data[name]=assert(f:read("*a"))
  f:close()
end
assert.is_truthy(data.archived:find("rage.lo>=action.bloodthirst.cost",1,true))
assert.is_truthy(data.candidate:find("rage.lo>=action.bloodthirst.cost+5",1,true))
assert.is_nil(data.current:find("toggle.movement",1,true),
  "selected protected Current unexpectedly added Movement guard")
assert.is_truthy(data.candidate:find("toggle.movement",1,true))
local offensive={bloodthirst=true,whirlwind=true,overpower=true,slam=true,
  heroic_strike=true,cleave=true,execute=true,thunder_clap=true,rend=true,
  sunder_armor=true,spearing_strike=true,victory_rush=true}
local majors={blood_fury=true,berserking=true,eureka=true,elunes_light=true,
  recklessness=true,death_wish=true,sweeping_strikes=true}
local function one(profile,level,seed,startRage,attackers,duration)
  local base=gate.content(level)
  assert.are.equal("Fury (wowsims.com)",base.PACK,
    "must load actual Fury shipped pack, never inherited Arms")
  local W=setmetatable({power=startRage,attackers=attackers,mobHealth=1000000000},
    {__index=base.WORLD})
  local C=setmetatable({WORLD=W},{__index=base})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL(
      "Warrior_Fury","APLForever-Fury-v011-"..profile,data[profile],C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","interrupts","engage",
      "defensives","reactive_stances","stance_recovery","upkeep",
      "minor_cooldowns","major_cooldowns","pack_mitigation",
      "aoe","single_target","boss_armor","rage_dumps","final_fallback"}) do
      assert.is_table(lists[name],name.." absent in complete "..profile)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),
        "inactive "..name.." in "..profile)
    end
    assert.are.same({},H.errors)
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false
  toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  toggles.interrupts.value=false
  if toggles.movement then toggles.movement.value=false end
  local acceptedEvents,failedEvents={},{}
  local installed=false
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(run)
      if installed then return end
      local previous=run.W.press
      run.W.press=function(player,key,p)
        local t=run.W.t
        local rage=player.power
        local castRemainder=(player.castUntil or 0)-t
        local ok,why=previous(player,key,p)
        if player==run.us and t>=loop.PULL and type(key)=="string" then
          if ok then
            acceptedEvents[#acceptedEvents+1]={t=t,key=key,rage=rage}
          else
            failedEvents[#failedEvents+1]={t=t,key=key,rage=rage,
              reason=why,castRemainder=castRemainder}
          end
        end
        return ok,why
      end
      installed=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused,cost=0,0
  for why,n in pairs(rr.refused or {}) do
    refused=refused+n
    if why=="cost" then cost=cost+n end
  end
  for _,e in ipairs(failedEvents) do
    print(("FURY_REFUSED profile=%s level=%d seed=%d rage0=%d attackers=%d t=%.17g key=%s trueRage=%.5f reason=%s castRemainder=%.17g"):format(
      profile,level,seed,startRage,attackers,e.t,e.key,e.rage,
      tostring(e.reason),e.castRemainder))
  end
  local counted=rr.pressedBy or {}
  local blood=counted.bloodthirst or 0
  local offence,major,charge=0,0,0
  for name in pairs(offensive) do offence=offence+(counted[name] or 0) end
  for name in pairs(majors) do major=major+(counted[name] or 0) end
  charge=(counted.charge or 0)+(counted.intercept or 0)
  local followOn=0
  local seenUpkeep=false
  for _,e in ipairs(acceptedEvents) do
    if e.key=="battle_shout" or e.key=="berserker_stance" then
      seenUpkeep=true
    elseif seenUpkeep and offensive[e.key] then
      followOn=followOn+1
    end
  end
  local traceFirst={}
  for i=1,math.min(12,#acceptedEvents) do
    local e=acceptedEvents[i]
    traceFirst[#traceFirst+1]=e.key
  end
  print(("FURY_V011 profile=%s level=%d seed=%d startRage=%d attackers=%d accepted=%d offensive=%d bloodthirst=%d rawRefused=%d costRefused=%d majors=%d movement=%d observedPostUpkeep=%d first=%s"):format(
    profile,level,seed,startRage,attackers,rr.presses,offence,blood,
    refused,cost,major,charge,followOn,table.concat(traceFirst,",")))
  return {accepted=rr.presses,offensive=offence,blood=blood,
    refused=refused,cost=cost,majors=major,movement=charge,
    followOn=followOn,failed=failedEvents}
end
describe("Fury published v0.11 Rage and full fallback; safe unselected v1.2",function()
  for _,seed in ipairs({30417,30437}) do
    for _,scenario in ipairs({
      {60,25,2,80}, -- historically failed near 30 in two-attacker Fury
      {60,90,1,70}, -- high-Rage controls and natural spending
      {24,25,1,55}, -- lower kit/unlocks and slow resource progression
    }) do
      local level,rage,attackers,duration=unpack(scenario)
      it(("level %d rage %d attackers %d seed %d"):format(
          level,rage,attackers,seed),function()
        local results={}
        for _,profile in ipairs({"shipped","current","archived","candidate"}) do
          results[profile]=one(profile,level,seed,rage,attackers,duration)
        end
        local cur,old,new=results.current,results.archived,results.candidate
        assert.is_true(cur.accepted>=3,"Current fails progression")
        assert.is_true(new.accepted>=3,"Candidate fails progression")
        assert.is_true(new.offensive>=2,"Candidate fails meaningful combat")
        assert.are.equal(0,new.cost,"Candidate source-refused due to cost")
        assert.are.equal(0,cur.cost,"Current unexpectedly cost-refused")
        assert.are.equal(0,new.majors,"Candidate broke major cooldown OFF")
        assert.are.equal(0,cur.majors,"Current broke major cooldown OFF")
        assert.are.equal(0,new.movement,"Candidate violated Movement OFF")
        if level==60 then
          assert.is_true(cur.blood>=1,"Current never cast trained Bloodthirst")
          assert.is_true(new.blood>=1,"Candidate never cast trained Bloodthirst")
        else
          assert.are.equal(0,new.blood,"lower-level unlocked Bloodthirst improperly")
        end
        -- Preserve the expected-bad archived profile even if its old v0.8.6
        -- cost failure no longer reproduces under changed v0.11 combat timing.
        print(("FURY_COMPARATOR level=%d seed=%d rage=%d attackers=%d oldCost=%d newCost=%d currentCost=%d shippedCost=%d"):format(
          level,seed,rage,attackers,old.cost,new.cost,cur.cost,results.shipped.cost))
      end)
    end
  end
end)
