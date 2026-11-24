-- Breadth #24/25: TRUE Frost Fingers-of-Frost proc+charge spending and
-- Rogue Combat real combo builders/finisher point spending, incl. short solo.
-- Hekili Forever v0.11.0 source 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Whole shipped/default vs exact protected Current; Rogue v1.1 unselected comparator.
-- No synthetic procs/hidden reads or substitution of Retail spell mechanics.
local loop=require("Game.harness.loop")
local Frost=assert(require("Forever.helpers.mage_world").Frost)
local Rogue=assert(require("Forever.helpers.rogue_world").Combat)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local apl={
  frost=read("roles/Mage/Current/APL_Mage_Frost_v1.0_Draft.txt"),
  rogue=read("roles/Rogue/Current/APL_Rogue_Combat_v1.0_Draft.txt"),
  rogueV11=read("roles/Rogue/Candidates/APL_Rogue_Combat_v1.1_Draft.txt"),
}
local function trial(kind,profile,seed,startPct,duration)
  local base=kind=="frost" and Frost or Rogue
  local world=setmetatable({
    power=base.WORLD.max*startPct,
    mobHealth=1000000000,
    distance=kind=="frost" and 25 or 4,
  },{__index=base.WORLD})
  local C=setmetatable({WORLD=world},{__index=base})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local payload=kind=="frost" and apl.frost or
      (profile=="candidate" and apl.rogueV11 or apl.rogue)
    local spec=kind=="frost" and "Mage_Frost" or "Rogue_Combat"
    local lists,warnings=H.Hekili:ImportSimcAPL(spec,
      "APLForever-Breadth-Frost-Rogue-v011-"..kind.."-"..profile,
      payload,C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_table(lists.final_fallback)
    if kind=="frost" then
      for _,name in ipairs({"defensives","mana_recovery","major_cooldowns","aoe"}) do
        assert.is_table(lists[name],"missing Frost original "..name)
      end
    else
      for _,name in ipairs({"opener","major_cooldowns"}) do
        assert.is_table(lists[name],"missing Rogue original "..name)
      end
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
    end
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.minor_cooldowns.value=false
  t.defensives.value=false
  t.interrupts.value=false
  if t.movement then t.movement.value=false end

  local A=H.Hekili.Class.auras
  local fof=kind=="frost" and assert(A.fingers_of_frost.id)
  local chill=kind=="frost" and assert(A.winters_chill.id)
  local snd=kind=="rogue" and assert(A.slice_and_dice.id)
  local comboPt=4 -- source rogue_world.lua: Enum.PowerType COMBO_POINTS
  local trace={
    attempted=0,refused=0,firstRefusal="",lancesOnFoF=0,
    rogueBuilder=0,rogueFinisher=0,rogueFinishAt3=0,
    rogueConsume=0,rogueMaxCP=0,rogueFinisherWrong=0,
    rogueAvoidedFinish=0,rogueExcess=0,fofMaxAtLance=0,
    terminalRefused=0,combatRefused=0,cpExamples={}
  }
  local started=false
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(w)
      if started then return end
      local old=w.W.press
      w.W.press=function(e,key,p)
        local time=w.W.t
        local relevant=e==w.us and time>=loop.PULL
        local beforePt=kind=="rogue" and w.W.res(e,comboPt) or 0
        local active=kind=="frost" and e.auras[fof] or nil
        local preFoF=active and active.stacks or 0
        local ok,why=old(e,key,p)
        if relevant then
          trace.attempted=trace.attempted+1
          if not ok then
            trace.refused=trace.refused+1
            if trace.firstRefusal=="" then
              trace.firstRefusal=("time=%.3f key=%s why=%s"):format(
                time,tostring(key),tostring(why))
            end
            if math.abs(time-(loop.PULL+duration))<=1e-6 and
              key=="garrote" and why=="requires:not stealthed" then
              trace.terminalRefused=trace.terminalRefused+1
            else
              trace.combatRefused=trace.combatRefused+1
            end
          else
            if kind=="frost" and key=="ice_lance" then
              if preFoF>0 then
                trace.lancesOnFoF=trace.lancesOnFoF+1
                trace.fofMaxAtLance=math.max(trace.fofMaxAtLance,preFoF)
              end
            end
            if kind=="rogue" then
              local afterPt=w.W.res(e,comboPt)
              trace.rogueMaxCP=math.max(trace.rogueMaxCP,beforePt,afterPt)
              if afterPt>5 or beforePt>5 then trace.rogueExcess=trace.rogueExcess+1 end
              if key=="sinister_strike" and afterPt>beforePt then
                trace.rogueBuilder=trace.rogueBuilder+1
              end
              if key=="eviscerate" then
                trace.rogueFinisher=trace.rogueFinisher+1
                if beforePt>=3 then trace.rogueFinishAt3=trace.rogueFinishAt3+1 end
                if beforePt>0 and afterPt==0 then
                  trace.rogueConsume=trace.rogueConsume+1
                elseif beforePt>0 and afterPt==beforePt
                  and e.lastHit and e.lastHit.act~="WOUND" then
                  -- Source world.W.effects explicitly keeps combo points
                  -- when Eviscerate is avoided.
                  trace.rogueAvoidedFinish=trace.rogueAvoidedFinish+1
                else
                  trace.rogueFinisherWrong=trace.rogueFinisherWrong+1
                end
                if #trace.cpExamples<4 then
                  trace.cpExamples[#trace.cpExamples+1]=beforePt..">"..afterPt
                end
              end
            end
          end
        end
        return ok,why
      end
      started=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local raw=0
  for reason,n in pairs(rr.refused or {}) do
    raw=raw+n
    print(("BREADTH_FROST_ROGUE_REFUSE kind=%s profile=%s seed=%d resource=%.2f duration=%d reason=%s count=%d"):format(
      kind,profile,seed,startPct,duration,tostring(reason),n))
  end
  assert.are.equal(raw,trace.refused,"instrumentation did not count all W.press declines")
  local auraFoF,fofMax,fofDrop,chillAuras,chillMax,iceSpells=0,0,0,0,0,0
  local trueSnd,sndExpires=0,0
  local comboEvents,comboSpends=0,0
  -- Published source W.hit emits kind=spell but NOT a spell ID.
  -- At 25 yards Cone of Cold is out of range; source Ice Lance
  -- resolves AMOUNT=300 or 600 on critical, unique among ranged kit.
  local lanceAmount=300
  for _,ev in ipairs(rr.W.truth) do
    if kind=="frost" then
      if ev.kind=="aura" and ev.dst==rr.us and ev.aura==fof then
        if (ev.stacks or 0)>0 then
          auraFoF=auraFoF+1
          fofMax=math.max(fofMax,ev.stacks)
        else fofDrop=fofDrop+1 end
      end
      if ev.kind=="aura" and ev.dst and ev.dst.kind=="mob"
        and ev.aura==chill and (ev.stacks or 0)>0 then
        chillAuras=chillAuras+1
        chillMax=math.max(chillMax,ev.stacks)
      end
      if ev.kind=="spell" and ev.src==rr.us and ev.dst
        and ev.dst.kind=="mob"
        and (ev.amount==lanceAmount or ev.amount==2*lanceAmount) then
          iceSpells=iceSpells+1
      end
    else
      if ev.kind=="aura" and ev.dst==rr.us and ev.aura==snd then
        if (ev.stacks or 0)>0 then trueSnd=trueSnd+1
        else sndExpires=sndExpires+1 end
      end
      if ev.src==rr.us and ev.pt==comboPt then
        if (ev.rage or 0)>0 then comboEvents=comboEvents+1 end
        if (ev.cost or 0)>0 then comboSpends=comboSpends+1 end
      end
    end
  end
  local count=rr.pressedBy or {}
  local later=0
  local phase=false
  for i=1,rr.combat do
    local key=rr.pressed[i]
    if (kind=="frost" and key=="frostbolt") or
       (kind=="rogue" and key=="sinister_strike") then
      phase=true
    elseif phase and type(key)=="string" then later=later+1 end
  end
  if kind=="frost" then
    print(("FROST_PROC_TRUTH profile=%s seed=%d manaPct=%.2f duration=%d accepted=%d refused=%d frostbolt=%d iceLance=%d lanceOnTrueFoF=%d realFoFAura=%d maxFoFStacks=%d realFoFDrops=%d trueChillAuras=%d maxChill=%d trueLanceHits=%d postBolt=%d firstRefusal=%s"):format(
      profile,seed,startPct,duration,rr.presses,raw,count.frostbolt or 0,
      count.ice_lance or 0,trace.lancesOnFoF,auraFoF,fofMax,fofDrop,
      chillAuras,chillMax,iceSpells,later,trace.firstRefusal))
  else
    print(("ROG_COMBO_TRUTH profile=%s seed=%d energyPct=%.2f duration=%d accepted=%d refused=%d sinister=%d generatedPoints=%d maxCP=%d evis=%d evisBefore3=%d actualSpentTo0=%d invalidFinish=%d avoidedFinish=%d cpAuraGain=%d cpAuraSpend=%d trueSliceAuras=%d trueSliceExpires=%d postBuilder=%d terminalGarroteRefused=%d inCombatRefused=%d example=%s firstRefusal=%s"):format(
      profile,seed,startPct,duration,rr.presses,raw,count.sinister_strike or 0,
      trace.rogueBuilder,trace.rogueMaxCP,trace.rogueFinisher,
      trace.rogueFinishAt3,trace.rogueConsume,trace.rogueFinisherWrong,
      trace.rogueAvoidedFinish,comboEvents,comboSpends,trueSnd,sndExpires,
      later,trace.terminalRefused,trace.combatRefused,
      table.concat(trace.cpExamples,","),trace.firstRefusal))
  end
  return {accepted=rr.presses,refused=raw,later=later,
    fof=auraFoF,fofMax=fofMax,fofDrop=fofDrop,
    frostbolt=count.frostbolt or 0,iceLances=count.ice_lance or 0,
    lancesOnFoF=trace.lancesOnFoF,chill=chillAuras,
    builders=trace.rogueBuilder,finishers=trace.rogueFinisher,
    spent=trace.rogueConsume,wrong=trace.rogueFinisherWrong,
    avoided=trace.rogueAvoidedFinish,terminal=trace.terminalRefused,
    inCombatRefused=trace.combatRefused,sourceLanceEffects=iceSpells,
    maxCp=trace.rogueMaxCP,excess=trace.rogueExcess,
    snd=trueSnd,comboEvents=comboEvents,comboSpends=comboSpends}
end

describe("Breadth #24 Frost actual Fingers-of-Frost grant/spend, not just legal Bolt",function()
  for _,seed in ipairs({30417,30437}) do
    for _,mana in ipairs({1,0.25,0.05}) do
      it(("seed %d true Mana %.2f whole shipped vs Current"):format(seed,mana),function()
        local shipped=trial("frost","shipped",seed,mana,100)
        local current=trial("frost","current",seed,mana,100)
        assert.is_true(shipped.accepted>=2)
        assert.is_true(current.accepted>=2)
        assert.are.equal(0,current.refused,"Frost Current source repeated unusable/too-expensive spell")
        if mana>=0.25 then
          assert.is_true(current.later>=3,
            "Frost medium/high Mana never cast three other later actions")
        else
          -- At 5% Mana legitimate Frostbolt repetition is legal fallback;
          -- zero later DIFFERENT actions is not a refused cast or stalled GCD.
          assert.is_true(current.frostbolt>=3,
            "Frost 5%-Mana source cannot sustain three legal filler Frostbolts")
        end
        if mana==1 then
          assert.is_true(current.fof>=1,"Frost has no actual native Fingers of Frost aura proc")
          assert.is_true(current.fofMax>=1,"Frost charge count source missing")
          assert.is_true(current.iceLances>=1,"Frost never accepted an Ice Lance")
          assert.is_true(current.lancesOnFoF>=1,
            "Ice Lance accepted without actual Fingers of Frost to spend")
          assert.is_true(current.chill>=1,"Frost did not actually apply Winters Chill")
          assert.is_true(current.sourceLanceEffects>=1,
            "Source actual unique 300/600 frost magic Ice Lance damage never landed")
        end
        print(("FROST_EFFECT_PAIR seed=%d manaPct=%.2f shippedFoF=%d curFoF=%d curLances=%d curLancesOnFoF=%d curChill=%d"):format(
          seed,mana,shipped.fof,current.fof,current.iceLances,
          current.lancesOnFoF,current.chill))
      end)
    end
  end
end)
describe("Breadth #25 Rogue Combat real builders/five-point spending and short-solo positive",function()
  for _,seed in ipairs({30417,30437}) do
    for _,energy in ipairs({1,0.25}) do
      it(("seed %d true Energy %.2f whole shipped, broken Current and full v1.1"):format(seed,energy),function()
        local shipped=trial("rogue","shipped",seed,energy,95)
        local current=trial("rogue","current",seed,energy,95)
        local candidate=trial("rogue","candidate",seed,energy,95)
        assert.is_true(shipped.accepted>=3)
        assert.is_true(candidate.accepted>=3)
        assert.are.equal(0,candidate.inCombatRefused,
          "Combat v1.1 refused a real during-fight recommended action")
        assert.is_true(candidate.terminal<=1,
          "Combat v1.1 repeatedly refused terminal stale Garrote; FAIL")
        assert.is_true(candidate.builders>=3,"candidate did not truly gain builder combo points")
        assert.is_true(candidate.finishers>=2,"candidate did not truly execute finishers")
        assert.is_true(candidate.spent>=2,"Eviscerate did not actually consume source combo points")
        assert.are.equal(0,candidate.wrong,
          "Eviscerate neither spent on landing nor legally retained points on avoid")
        assert.are.equal(candidate.finishers,candidate.spent+candidate.avoided,
          "Every accepted Eviscerate must spend on hit or retain on avoid")
        assert.are.equal(0,candidate.excess,"source combo points exceeded 5")
        assert.is_true(candidate.later>=3,"candidate lacked three follow-on legal actions")
        if energy==0.25 then
          assert.is_true(current.inCombatRefused>=10,
            "protected Current low-Energy repeated Garrote negative vanished")
        else
          -- High initial Energy never triggered the historical stale opener.
          assert.are.equal(0,current.inCombatRefused)
        end
        print(("ROG_COMBO_PAIR seed=%d energyPct=%.2f shippedFinished=%d curRefused=%d candidateFinished=%d candidateSpent=%d candidateRealBuilders=%d candidateRefused=%d"):format(
          seed,energy,shipped.finishers,current.refused,
          candidate.finishers,candidate.spent,candidate.builders,candidate.refused))
      end)
    end
    it(("20-second solo source real finisher seed %d"):format(seed),function()
      local shipped=trial("rogue","shipped",seed,1,20)
      local current=trial("rogue","current",seed,1,20)
      local candidate=trial("rogue","candidate",seed,1,20)
      assert.are.equal(0,candidate.inCombatRefused)
      assert.is_true(candidate.builders>=1)
      assert.is_true(candidate.later>=1)
      -- Full Energy naturally avoided old Garrote loop: parity control.
      assert.are.equal(0,current.inCombatRefused)
      print(("ROG_COMBO_SHORT seed=%d oldRefused=%d candidateBuilder=%d candidateFinish=%d candidateSpent=%d shippedFinish=%d"):format(
        seed,current.refused,candidate.builders,candidate.finishers,
        candidate.spent,shipped.finishers))
    end)
  end
end)
