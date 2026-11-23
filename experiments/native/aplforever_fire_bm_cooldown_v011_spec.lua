-- 50-unit breadth: independent units #14 Fire Combustion after Scorch,
-- and #15 P0 Hunter BM Rapid Fire/pet BW with complete v1.4 check.
-- Released Hekili Forever v0.11 source SHA 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- No original/current APL modifications, fake damage or in-game claims.
local loop=require("Game.harness.loop")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local specs={
  {
    id="Mage_Fire", key="Fire", base=require("Forever.helpers.mage_world").Fire,
    current="roles/Mage/Current/APL_Mage_Fire_v1.0_Draft.txt",
    candidate="roles/Mage/Candidates/APL_Mage_Fire_v1.1_Draft.txt",
    lists={"precombat","default","mana_recovery","major_cooldowns","aoe","final_fallback"},
    cooldown="combustion", distance=25,
    offensive={scorch=true,fire_blast=true,fireball=true,
      frostfire_bolt=true,pyroblast=true,arcane_blast=true,
      arcane_missiles=true,blizzard=true,frostbolt=true},
  },
  {
    id="Hunter_BeastMastery", key="BM",
    base=require("Forever.helpers.hunter_world").BeastMasteryTurret,
    current="roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt",
    candidate="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt",
    lists={"precombat","default","melee","major_cooldowns"},
    cooldown="rapid_fire", extra="bestial_wrath", distance=12,
    offensive={arcane_shot=true,aimed_shot=true,multi_shot=true,
      summon_hawk=true,serpent_sting=true,raptor_strike=true,
      mongoose_bite=true,strider_kick=true},
  },
}
local function read(p)
  local f=assert(io.open(root.."/"..p,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
for _,spec in ipairs(specs) do
  spec.apls={current=read(spec.current)}
  if spec.candidate then
    spec.apls.candidate=read(spec.candidate)
    assert.is_truthy(spec.apls.candidate:find(spec.cooldown,1,true))
  end
  if spec.key=="Fire" then
    local a="actions+=/scorch,focus=2,if="
    local b="actions.final_fallback+=/scorch,if=action.scorch.known"
    assert.is_truthy(spec.apls.current:find(a,1,true))
    assert.is_truthy(spec.apls.candidate:find(
      b.."&mana.lo>=action.scorch.cost+20",1,true))
    assert.is_truthy(spec.apls.candidate:find(
      "executing&mana.lo>=action.scorch.cost+20",1,true))
    assert.is_nil(spec.apls.current:find(
      "mana.lo>=action.scorch.cost",1,true))
  end
  assert.is_truthy(spec.apls.current:find(spec.cooldown,1,true))
  assert.is_truthy(spec.apls.current:find("toggle.cooldowns",1,true))
end
local function one(spec,profile,seed,percent,cds)
  local base=spec.base
  local max=base.WORLD.max
  assert.is_true(type(max)=="number" and max>0)
  local initial=max*percent/100
  local w=setmetatable({
    power=initial,distance=spec.distance,targetLevel=-1,
    mobHealth=1000000000,
  },{__index=base.WORLD})
  local C=setmetatable({WORLD=w},{__index=base})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  assert.is_table(C.IDS[spec.cooldown],
    spec.key.." released fixture lacks supported "..spec.cooldown)
  if spec.extra then
    assert.is_table(C.IDS[spec.extra])
    assert.is_true(C.WORLD.pet.up,
      "BM only tests published starting healthy present pet")
  end
  assert.is_truthy(C.PACK:find(" (wowsims.com)",1,true))
  if profile~="shipped" then
    local apl=assert(spec.apls[profile])
    local lists,warnings=H.Hekili:ImportSimcAPL(
      spec.id,"APLForever-Breadth-Fire-BM-v011-"..profile,apl,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs(spec.lists) do
      assert.is_table(lists[name],spec.key.." missing complete "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),
        spec.key.." inactive "..name)
    end
    assert.are.same({},H.errors)
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=cds
  t.minor_cooldowns.value=false
  t.defensives.value=false
  t.interrupts.value=false
  if t.movement then t.movement.value=false end
  local accepted,refusals,installed={},{},false
  local rr=loop.run(L,seed,{
    duration=percent==100 and 90 or 105,
    on=function(run)
      if installed then return end
      local prev=run.W.press
      run.W.press=function(player,key,resolved)
        local at=run.W.t
        local before=(player.castUntil or 0)-at
        local mana=player.power
        local belief=H.Hekili.State.mana
        local beliefLo=type(belief)=="table" and belief.lo or nil
        local shownCost=resolved and resolved.cost or nil
        local ok,reason=prev(player,key,resolved)
        if player==run.us and at>=loop.PULL and type(key)=="string" then
          if ok then accepted[#accepted+1]={t=at,key=key,mana=mana}
          else refusals[#refusals+1]={t=at,key=key,mana=mana,
            reason=reason,castRem=before,
            beliefLo=beliefLo,sourceCost=shownCost} end
        end
        return ok,reason
      end
      installed=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused,substantive,boundary=0,0,0
  for why,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("BREADTH_CD_REFUSED_SUM role=%s profile=%s seed=%d pct=%d cooldowns=%s reason=%s n=%d"):format(
      spec.key,profile,seed,percent,tostring(cds),tostring(why),n))
  end
  for _,r in ipairs(refusals) do
    local eps=r.reason=="casting" and r.castRem>0
      and r.castRem<=1e-7
    if eps then boundary=boundary+1 else substantive=substantive+1 end
    print(("BREADTH_CD_REFUSED role=%s profile=%s seed=%d pct=%d cds=%s t=%.17g key=%s reason=%s mana=%.3f beliefLo=%s resolvedCost=%s castRemain=%.17g epsilon=%s"):format(
      spec.key,profile,seed,percent,tostring(cds),r.t,r.key,
      tostring(r.reason),r.mana,tostring(r.beliefLo),
      tostring(r.sourceCost),r.castRem,tostring(eps)))
  end
  local by=rr.pressedBy or {}
  local offense=0
  for key in pairs(spec.offensive) do offense=offense+(by[key] or 0) end
  local followed=0
  local seen=false
  for _,x in ipairs(accepted) do
    if spec.offensive[x.key] then
      if seen then followed=followed+1 else seen=true end
    end
  end
  local primary=by[spec.cooldown] or 0
  local extra=spec.extra and (by[spec.extra] or 0) or 0
  print(("BREADTH_CD_14_15 role=%s profile=%s seed=%d mana=%d cd=%s accepted=%d offensive=%d later=%d %s=%d extra=%d scorch=%d aimed=%d hawk=%d refused=%d substantive=%d boundary=%d manaEnd=%.2f"):format(
    spec.key,profile,seed,percent,tostring(cds),rr.presses,offense,
    followed,spec.cooldown,primary,extra,by.scorch or 0,
    by.aimed_shot or 0,by.summon_hawk or 0,refused,
    substantive,boundary,rr.us.power))
  return {accepted=rr.presses,offense=offense,later=followed,
    primary=primary,extra=extra,scorch=by.scorch or 0,
    refused=refused,substantive=substantive,boundary=boundary,
    traced=#refusals,aimed=by.aimed_shot or 0}
end
describe("Two independent published Forever v0.11 cooldown and filler breadth units",function()
  for _,spec in ipairs(specs) do
    for _,seed in ipairs({30417,30437}) do
      for _,percent in ipairs({100,25}) do
        it(("%s seed%d %d%% Mana real cooldown OFF/ON"):format(
          spec.key,seed,percent),function()
          local profiles=spec.candidate and {"shipped","current","candidate"}
            or {"shipped","current"}
          local got={}
          for _,profile in ipairs(profiles) do
            got[profile]={off=one(spec,profile,seed,percent,false),
              on=one(spec,profile,seed,percent,true)}
          end
          local cur=got.current
          for _,record in ipairs({cur.off,cur.on}) do
            assert.is_true(record.accepted>=3)
            assert.is_true(record.offense>=3,
              spec.key.." stopped offering genuine offensive fallback")
            assert.is_true(record.later>=3,
              spec.key.." lacks three genuinely accepted later offences")
            if not (spec.key=="Fire" and seed==30417 and percent==100
              and record==cur.on) then
              assert.are.equal(0,record.substantive,
                "unexplained Current source cost/GCD/range refusal")
            end
            assert.is_true(record.boundary<=2,
              "repeated near-boundary cast scheduling needs investigation")
            assert.are.equal(record.refused,record.traced,
              "source refusal event hook missing an attempt")
          end
          assert.are.equal(0,cur.off.primary,
            spec.key.." violated Major Cooldowns OFF")
          assert.is_true(cur.on.primary>=1,
            spec.key.." failed to cast source-known cooldown with ON")
          if spec.key=="Fire" then
            assert.are.equal(seed==30417 and percent==100 and 1 or 0,
              cur.on.substantive,
              "baseline Fire Scorch late genuine cost refusal changed")
          end
          if got.candidate then
            for _,which in ipairs({"off","on"}) do
              local revised=got.candidate[which]
              assert.is_true(revised.accepted>=3)
              assert.is_true(revised.offense>=3)
              assert.is_true(revised.later>=3,
                "new full Candidate lost three accepted follow-ons")
              assert.are.equal(0,revised.substantive,
                "new full Candidate has real refused action")
              assert.is_true(revised.boundary<=2)
            end
            assert.are.equal(0,got.candidate.off.primary)
            assert.is_true(got.candidate.on.primary>=1)
          end
          if spec.extra then
            assert.are.equal(0,cur.off.extra,
              "BM Bestial Wrath violated Major OFF")
            assert.is_true(cur.on.extra>=1,
              "BM pet-out did not source-cast Bestial Wrath with ON")
            for _,which in ipairs({"off","on"}) do
              local candidate=got.candidate[which]
              assert.are.equal(cur[which].accepted,candidate.accepted,
                "normal known-pet v1.4 unexpectedly differs from protected Current")
              assert.are.equal(cur[which].aimed,candidate.aimed,
                "normal known-pet v1.4 changed accepted Aimed Shots")
            end
          else
            assert.is_true(cur.on.scorch>=3,
              "Fire never builds observed Scorch setup before Combustion")
            assert.is_true(got.candidate.on.scorch>=3,
              "Fire Candidate skipped Scorch upkeep")
          end
          print(("BREADTH_CD_PAIR role=%s seed=%d mana=%d currentOFF=%d currentON=%d shippedOFF=%d shippedON=%d"):format(
            spec.key,seed,percent,cur.off.primary,cur.on.primary,
            got.shipped.off.primary,got.shipped.on.primary))
        end)
      end
    end
  end
end)
