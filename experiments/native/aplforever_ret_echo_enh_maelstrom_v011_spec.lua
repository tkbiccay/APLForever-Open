-- Breadth #22–23: Paladin Ret real Seal Echo stack/twist effects;
-- Shaman Enhancement real Maelstrom Weapon stacking and instant Lightning Bolt.
-- Published Hekili Forever v0.11.0 / zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b
-- Full shipped reference vs original protected Current, source World truth,
-- no addon/source/APL edits or synthetic proc/resource injection.
local loop=require("Game.harness.loop")
local pal=assert(require("Forever.helpers.paladin_world").Retribution)
local sham=assert(require("Forever.helpers.shaman_world").Enhancement)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local apl={
  ret=read("roles/Paladin/Current/APL_Paladin_Retribution_v1.2_Draft.txt"),
  enh=read("roles/Shaman/Current/APL_Shaman_Enhancement_v1.0_Draft.txt"),
}
-- Full standalone unselected solo v1.1 recorded after actual 8/8 source PASS;
-- byte-exact complete stored Candidate must match this one-line hypothesis.
local old="actions+=/call_action_list,name=support_totems,if=target.is_boss|active_enemies>=3"
local new="actions+=/windfury_totem,if=action.windfury_totem.known&!totem.air.up&combat>0&active_enemies<3&!target.is_boss&mana.pct_lo>=20\n"..old
local occurrences=0
local alt=apl.enh:gsub("actions%+=/call_action_list,name=support_totems,[^\n]+",function(line)
  assert.are.equal(old,line,"exact protected Enhancement support call changed")
  occurrences=occurrences+1
  return new
end)
assert.are.equal(1,occurrences,"the complete solo candidate should add only one new action")
assert.is_truthy(alt:find("actions.final_fallback+=/earth_shock",1,true))
local stored=read("roles/Shaman/Candidates/APL_Shaman_Enhancement_v1.1_Draft.txt")
assert.are.equal(alt,stored,"saved full standalone v1.1 differs from native validated one-line hypothesis")
apl.enhCandidate=stored
local function run(kind,profile,seed,pct,durationOverride)
  local stock=kind=="ret" and pal or sham
  local world=setmetatable({
    power=stock.WORLD.max*pct,
    mobHealth=1000000000,
    distance=4,
  },{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile=="current" or profile=="candidate" then
    assert.is_true(profile~="candidate" or kind=="enh",
      "candidate belongs to Shaman Enhancement only")
    local spec=kind=="ret" and "Paladin_Retribution" or "Shaman_Enhancement"
    local source=profile=="candidate" and apl.enhCandidate or apl[kind]
    local lists,warnings=H.Hekili:ImportSimcAPL(spec,
      "APLForever-Breadth-Echo-Maelstrom-v011-"..kind.."-"..profile,source,C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_table(lists.final_fallback)
    if kind=="ret" then
      for _,name in ipairs({"crusader_open","seals","aoe","major_cooldowns"}) do
        assert.is_table(lists[name],"missing Ret full "..name)
      end
    else
      for _,name in ipairs({"weapon_upkeep","support_totems","fire_totems",
        "aoe","major_cooldowns","mana_recovery"}) do
        assert.is_table(lists[name],"missing Enh full "..name)
      end
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),
        "disabled imported list "..name)
    end
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false
  toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  toggles.interrupts.value=false
  if toggles.movement then toggles.movement.value=false end
  local A=H.Hekili.Class.auras
  local function id(key)
    return A[key] and A[key].id or nil
  end
  local cmd=id("seal_of_command")
  local rig=id("seal_of_righteousness")
  local echoCmd=id("echo_of_command")
  local echoRig=id("echo_of_righteousness")
  local mw=id("maelstrom_weapon")
  local castIds=H.Hekili.Class.abilities
  local castKey=kind=="ret" and "judgement" or "lightning_bolt"
  local goalId=H.ns.VirtualState.KnownID(castIds[castKey].id)
  local stats={twists=0,boltsWith5=0,instantBolts=0,boltsPaid=0,
    rejected=0,paidRejects=0,totemCasts=0,totemCost=0,trace=0,example=""}
  local hook=false
  local duration=durationOverride or (kind=="ret" and 125 or 135)
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(w)
      if hook then return end
      local old=w.W.press
      w.W.press=function(player,key,resolved)
        local t=w.W.t
        local before=player.power
        local active=player.auras or {}
        local preCmd=cmd and active[cmd]~=nil
        local preRig=rig and active[rig]~=nil
        local mwAura=mw and active[mw]
        local preStacks=mwAura and mwAura.stacks or 0
        local ok,reason=old(player,key,resolved)
        if player==w.us and t>=loop.PULL then
          stats.trace=stats.trace+1
          if ok then
            if kind=="ret" and
              ((key=="seal_of_righteousness" and preCmd)
                or (key=="seal_of_command" and preRig)) then
              stats.twists=stats.twists+1
            end
            if kind=="enh" and key=="windfury_totem" then
              stats.totemCasts=stats.totemCasts+1
              stats.totemCost=stats.totemCost+(resolved.cost or 0)
            end
            if kind=="enh" and key=="lightning_bolt" then
              if preStacks>=5 then stats.boltsWith5=stats.boltsWith5+1 end
              if (resolved.cast or 0)<=0.001 then stats.instantBolts=stats.instantBolts+1 end
              stats.boltsPaid=stats.boltsPaid+(resolved.cost or 0)
            end
          else
            stats.rejected=stats.rejected+1
            if reason=="cost" or tostring(reason):find("requires:",1,true) then
              stats.paidRejects=stats.paidRejects+1
            end
            if stats.example=="" then
              stats.example=("t=%.3f key=%s why=%s cost=%s mana=%.3f"):format(
                t,tostring(key),tostring(reason),
                tostring(resolved.cost),before)
            end
          end
        end
        return ok,reason
      end
      hook=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local by=rr.pressedBy or {}
  local refused=0
  for reason,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("ECHO_MAELSTROM_REFUSED kind=%s profile=%s seed=%d mana=%.2f reason=%s count=%d"):format(
      kind,profile,seed,pct,tostring(reason),n))
  end
  assert.are.equal(refused,stats.rejected,"native hook/reported refusal mismatch")
  local trueEchoCmd,trueEchoRig,fullEchoCmd,fullEchoRig=0,0,0,0
  local maxCmd,maxRig=0,0
  local mwApplies,mwFull,mwGone,maxMw=0,0,0,0
  local totemAir,windfuryStrikes=0,0
  local judgements=0
  local lastMw=0
  local mwGoneAfterFull=0
  for _,e in ipairs(rr.W.truth) do
    if e.kind=="aura" and e.dst==rr.us then
      if e.aura==echoCmd then
        if (e.stacks or 0)>0 then
          trueEchoCmd=trueEchoCmd+1
          maxCmd=math.max(maxCmd,e.stacks)
          if e.stacks>=3 then fullEchoCmd=fullEchoCmd+1 end
        end
      elseif e.aura==echoRig then
        if (e.stacks or 0)>0 then
          trueEchoRig=trueEchoRig+1
          maxRig=math.max(maxRig,e.stacks)
          if e.stacks>=1 then fullEchoRig=fullEchoRig+1 end
        end
      elseif e.aura==mw then
        if (e.stacks or 0)>0 then
          mwApplies=mwApplies+1
          maxMw=math.max(maxMw,e.stacks)
          if e.stacks>=5 then mwFull=mwFull+1 end
          lastMw=e.stacks
        else
          mwGone=mwGone+1
          if lastMw>=5 then mwGoneAfterFull=mwGoneAfterFull+1 end
          lastMw=0
        end
      end
    end
    if e.kind=="totem" and e.src==rr.us and e.slot==4
      and (e.start or 0)>0 then totemAir=totemAir+1 end
    if e.kind=="cast" and e.src==rr.us and e.spell==goalId then
      judgements=judgements+1
    end
    if kind=="enh" and e.kind=="spell" and e.src==rr.us
      and (e.amount==300 or e.amount==600) and e.school==1 then
      windfuryStrikes=windfuryStrikes+1
    end
  end
  local later=0
  local found=false
  for i=1,rr.combat do
    local x=rr.pressed[i]
    if kind=="ret" and (x=="seal_of_command" or x=="seal_of_righteousness"
      or x=="seal_of_the_crusader") then
      found=true
    elseif kind=="enh" and (x=="stormstrike" or x=="flame_shock") then
      found=true
    elseif found and type(x)=="string" then
      later=later+1
    end
  end
  if kind=="ret" then
    print(("RET_ECHO_TRUTH profile=%s seed=%d manaPct=%.2f accepted=%d refused=%d badCostOrRequires=%d cmdEchoEvents=%d maxCmdEcho=%d cmdAt3=%d rigEchoEvents=%d maxRigEcho=%d rightAt1=%d realSealTwists=%d actualJudgementCasts=%d later=%d example=%s"):format(
      profile,seed,pct,rr.presses,refused,stats.paidRejects,
      trueEchoCmd,maxCmd,fullEchoCmd,trueEchoRig,maxRig,fullEchoRig,
      stats.twists,judgements,later,stats.example))
  else
    print(("ENH_MAELSTROM_TRUTH profile=%s seed=%d manaPct=%.2f accepted=%d refused=%d badCostOrRequires=%d mwAuraEvents=%d mwMax=%d mwStack5Events=%d mwGone=%d mwGoneAfter5=%d boltWith5=%d instantBolts=%d boltCostTotal=%.2f actualBoltCasts=%d airTotems=%d wfStrikes=%d wfTotemCasts=%d wfTotemPaid=%.1f later=%d example=%s"):format(
      profile,seed,pct,rr.presses,refused,stats.paidRejects,
      mwApplies,maxMw,mwFull,mwGone,mwGoneAfterFull,
      stats.boltsWith5,stats.instantBolts,stats.boltsPaid,
      judgements,totemAir,windfuryStrikes,stats.totemCasts,stats.totemCost,later,stats.example))
  end
  return {accepted=rr.presses,refused=refused,bad=stats.paidRejects,
    twists=stats.twists,echoMax=maxCmd,rigMax=maxRig,
    echoEvents=trueEchoCmd,judgement=judgements,airTotems=totemAir,
    mwMax=maxMw,mwFull=mwFull,mwGoneAfterFull=mwGoneAfterFull,
    bolt5=stats.boltsWith5,instant=stats.instantBolts,
    wfStrikes=windfuryStrikes,totemCost=stats.totemCost,totemCasts=stats.totemCasts,
    later=later}
end
describe("Breadth #22 Ret source Echo gain/real seal twist separate from earlier cast-only seal test",function()
  for _,seed in ipairs({30417,30437}) do
    for _,pct in ipairs({1,0.25}) do
      it(("seed %d true initial Mana %.2f shipped vs full Current"):format(seed,pct),function()
        local shipped=run("ret","shipped",seed,pct)
        local current=run("ret","current",seed,pct)
        assert.is_true(shipped.accepted>=3)
        assert.is_true(current.accepted>=3)
        assert.is_true(current.later>=3)
        assert.are.equal(0,current.bad,"Ret refused a source-unusable or unaffordable action")
        assert.is_true(current.echoMax>=3 and current.rigMax>=1,
          "published source actual Echo/Seal stack never accumulated")
        assert.is_true(current.twists>=1,"Ret did not execute any real two-Seal twist")
        assert.is_true(current.judgement>=1,"Ret did not cast source-truth Judgement")
        -- First diagnostics collect whether source genuinely produces
        -- 3-stack Echo and two-seal twists, rather than assert a desired win.
        print(("RET_ECHO_PAIR seed=%d pct=%.2f shippedEcho=%d/%d currentEcho=%d/%d shippedTwists=%d currentTwists=%d currentJudgements=%d currentBad=%d"):format(
          seed,pct,shipped.echoMax,shipped.rigMax,
          current.echoMax,current.rigMax,shipped.twists,current.twists,
          current.judgement,current.bad))
      end)
    end
  end
end)
describe("Breadth #23 Enh genuine five-stack Maelstrom and Lightning Bolt source effect",function()
  for _,seed in ipairs({30417,30437}) do
    for _,pct in ipairs({1,0.25,0.05}) do
      it(("seed %d true initial Mana %.2f shipped vs complete Current/candidate"):format(seed,pct),function()
        local shipped=run("enh","shipped",seed,pct)
        local current=run("enh","current",seed,pct)
        local candidate=run("enh","candidate",seed,pct)
        assert.are.equal(0,current.bad,"protected Enhancement source old regression")
        assert.are.equal(0,candidate.bad,"full solo-totem candidate refused cost or eligibility")
        assert.are.equal(0,current.airTotems,
          "prior Current solo zero-air-totem negative control changed")
        if pct>=0.25 then
          assert.is_true(shipped.accepted>=3)
          assert.is_true(current.accepted>=3 and candidate.accepted>=3)
          assert.is_true(current.later>=3 and candidate.later>=3)
          assert.is_true(current.mwMax>=5 and candidate.mwMax>=5,
            "source Maelstrom never reached five real stacks")
          assert.is_true(current.bolt5>=1 and candidate.bolt5>=1,
            "a real source five-stack Lightning Bolt is missing")
          assert.are.equal(current.bolt5,current.instant,
            "current five-stack source Bolts not all instant")
          assert.are.equal(candidate.bolt5,candidate.instant,
            "candidate five-stack source Bolts not all instant")
          assert.is_true(shipped.airTotems>=1,
            "source shipped Windfury air totem negative control vanished")
          assert.is_true(candidate.airTotems>=1,
            "source candidate never kept Windfury Totem at normal/quarter Mana")
          assert.is_true(candidate.wfStrikes>=1,
            "source candidate Windfury air totem never triggered any real bonus strike")
          assert.is_true(candidate.totemCasts>=1 and candidate.totemCost>0,
            "model did not debit a true totem Mana cost")
        end
        print(("ENH_MAELSTROM_PAIR seed=%d pct=%.2f shippedMax=%d currentMax=%d candMax=%d currentAt5=%d currentBolt5=%d candidateBolt5=%d curAir=%d candidateAir=%d candidateWF=%d paidWF=%.1f currentInstant=%d candidateInstant=%d candidateBad=%d"):format(
          seed,pct,shipped.mwMax,current.mwMax,candidate.mwMax,
          current.mwFull,current.bolt5,candidate.bolt5,
          current.airTotems,candidate.airTotems,candidate.wfStrikes,candidate.totemCost,
          current.instant,candidate.instant,candidate.bad))
      end)
    end
  end
end)


describe("Enhancement short outdoor pull decision gate is separate from long sustained source procs",function()
  for _,seed in ipairs({30417,30437}) do
    it(("20-second single-target high-Mana source seed %d"):format(seed),function()
      local shipped=run("enh","shipped",seed,1,20)
      local current=run("enh","current",seed,1,20)
      local candidate=run("enh","candidate",seed,1,20)
      assert.are.equal(0,current.bad)
      assert.are.equal(0,candidate.bad)
      assert.are.equal(0,current.airTotems)
      assert.is_true(candidate.totemCasts<=1,
        "candidate is placing multiple expensive solo air totems in one short pull")
      assert.is_true(candidate.totemCost<=250,
        "short pull unexpectedly pays more than one real 250-Mana Windfury Totem")
      print(("ENH_SHORT_PULL_TRADEOFF seed=%d secs=20 shippedWF=%d currentWF=%d candidateWF=%d candidateTotemMana=%.1f candidateTotems=%d currentAccepted=%d candidateAccepted=%d isDpsProof=NO"):format(
        seed,shipped.wfStrikes,current.wfStrikes,candidate.wfStrikes,
        candidate.totemCost,candidate.totemCasts,
        current.accepted,candidate.accepted))
    end)
  end
end)
