-- 50 breadth: independent Rogue Subtlety Ghostly Strike next Garrote
-- and P0 Guardian actual Maul queue/strike with true 0/50 carried-in Rage.
-- Published Hekili Forever 0.11.0 SHA 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Complete default, original protected Current and complete new/old APL comparators.
-- No source/ability fabrication, in-game/DPS claim, promoted file or direct resource gains.
local loop=require("Game.harness.loop")
local rogue=assert(require("Forever.helpers.rogue_world").Subtlety)
local guardian=assert(require("Forever.helpers.druid_loop_world").Guardian)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local rcur=read("roles/Rogue/Current/APL_Rogue_Subtlety_v1.0_Draft.txt")
local gcur=read("roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt")
local gcan=read("roles/Druid/Candidates/APL_Druid_Guardian_v1.6_Draft.txt")
local old="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&(buff.stealth.up|buff.vanish.up|buff.ghostly_strike_next.up)"
local new="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&((!combat&buff.stealth.up)|buff.vanish.up|buff.ghostly_strike_next.up)"
local n=0
local rguard=rcur:gsub("actions%.opener=garrote[^\n]+",function(line)
  n=n+1
  assert.are.equal(old,line,"protected current opener changed")
  return new
end)
assert.are.equal(1,n)
assert.is_truthy(rcur:find("actions.final_fallback+=/hemorrhage",1,true))
assert.is_truthy(gcan:find("actions.rage_dump+=/maul",1,true))
local function content(stock,rage,attackers)
  local world=setmetatable({
    power=rage,attackers=attackers,distance=4,mobHealth=1000000000
  },{__index=stock.WORLD})
  return setmetatable({WORLD=world},{__index=stock})
end
local function run(kind,profile,seed,power)
  local isR=kind=="rogue"
  local stock=isR and rogue or guardian
  local C=content(stock,power,isR and 1 or 3)
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local apl
    if isR then apl=profile=="current" and rcur or rguard
    else apl=profile=="current" and gcur or gcan end
    local spec=isR and "Rogue_Subtlety" or "Druid_Guardian"
    local lists,warnings=H.Hekili:ImportSimcAPL(spec,
      "APLForever-Breadth-NextGate-v011-"..profile,apl,C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    if isR then
      for _,p in ipairs({"opener","final_fallback","major_cooldowns"}) do
        assert.is_table(lists[p])
      end
    else
      for _,p in ipairs({"damage","mitigation","rage_dump","defensive_cooldowns"}) do
        assert.is_table(lists[p],"missing Guardian complete "..p)
      end
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({},H.errors,"full APL compiler error")
    for key in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,key),"inactive "..key)
    end
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.minor_cooldowns.value=false
  t.defensives.value=false;t.interrupts.value=false
  if t.movement then t.movement.value=false end
  local accepted,rejected={},{}
  local hook=false
  local trace={maxTrue=0,maxLo=0,lo35=0,mobSwings=0,truthCursor=0}
  local rr=loop.run(L,seed,{
    duration=isR and (power==0 and 115 or 105) or 85,
    on=function(w)
      if not hook then
        local original=w.W.press
        w.W.press=function(player,key,resolved)
          local at=w.W.t
          local before=player.power
          local ok,reason=original(player,key,resolved)
          if player==w.us and at>=loop.PULL and type(key)=="string" then
            if ok then
              accepted[#accepted+1]={at=at,key=key,resource=before}
            else
              rejected[#rejected+1]={at=at,key=key,reason=reason,power=before,
                cost=resolved and resolved.cost}
            end
          end
          return ok,reason
        end
        hook=true
      end
      if not isR then
        local p=w.us.power
        trace.maxTrue=math.max(trace.maxTrue,p)
        local belief=H.ns.VirtualState.Power(L.power.type,H.ctl.now)
        local lo=belief and belief.lo or 0
        trace.maxLo=math.max(trace.maxLo,lo)
        if lo>=35 then trace.lo35=trace.lo35+1 end
        for i=trace.truthCursor+1,#w.W.truth do
          local ev=w.W.truth[i]
          if ev.kind=="swing" and ev.src and ev.src.kind=="mob"
            and ev.dst and ev.dst.guid==w.us.guid then
            trace.mobSwings=trace.mobSwings+1
          end
        end
        trace.truthCursor=#w.W.truth
      end
    end,
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for why,count in pairs(rr.refused or {}) do
    refused=refused+count
    print(("BREADTH_REFUSED role=%s profile=%s seed=%d start=%d why=%s n=%d"):format(
      kind,profile,seed,power,tostring(why),count))
  end
  for i,v in ipairs(rejected) do
    if i>5 then break end
    print(("BREADTH_REFUSED_EXAMPLE role=%s profile=%s seed=%d start=%d t=%.3f action=%s reason=%s truth=%.1f cost=%s"):format(
      kind,profile,seed,power,v.at,v.key,tostring(v.reason),v.power,tostring(v.cost)))
  end
  local by=rr.pressedBy or {}
  if isR then
    local ghost,garrote,ghostToGarrote=0,0,0
    local eligibleAuras,consumedAuras=0,0
    local auraId=assert(H.Hekili.Class.auras.ghostly_strike_next).id
    for _,ev in ipairs(rr.W.truth) do
      if ev.kind=="aura" and ev.aura==auraId
        and ev.dst and ev.dst.guid==rr.us.guid then
        if (ev.stacks or 0)>0 then eligibleAuras=eligibleAuras+1
        else consumedAuras=consumedAuras+1 end
      end
    end
    local latestGhost=nil
    for _,x in ipairs(accepted) do
      if x.key=="ghostly_strike" then
        ghost=ghost+1
        latestGhost=x.at
      elseif x.key=="garrote" then
        garrote=garrote+1
        if latestGhost and x.at-latestGhost<=7.01 then
          ghostToGarrote=ghostToGarrote+1
        end
      end
    end
    local otherOff=(by.hemorrhage or 0)+(by.sinister_strike or 0)
      +(by.eviscerate or 0)+(by.shank or 0)
      +(by.ghostly_strike or 0)
    print(("SUB_GHOST_BREADTH role=%s profile=%s seed=%d startEnergy=%d accepted=%d garrote=%d ghostly=%d ghostFollowGarrote=%d procAuras=%d procGone=%d otherOff=%d rejected=%d"):format(
      kind,profile,seed,power,rr.presses,garrote,ghost,ghostToGarrote,
      eligibleAuras,consumedAuras,otherOff,refused))
    return {accepted=rr.presses,refused=refused,
      garrote=garrote,ghost=ghost,chain=ghostToGarrote,auras=eligibleAuras,
      consumed=consumedAuras,other=otherOff}
  else
    local maulId=H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.maul.id)
    local queue,strike,unqueue,cost=0,0,0,0
    for _,ev in ipairs(rr.W.truth) do
      if ev.src==rr.us and ev.spell==maulId then
        if ev.kind=="queue" then queue=queue+1 end
        if ev.kind=="strike" then strike=strike+1;cost=cost+(ev.cost or 0) end
        if ev.kind=="unqueue" then unqueue=unqueue+1 end
      end
    end
    local attack=(by.primal_bite or 0)+(by.swipe_bear or 0)
      +(by.lacerate or 0)+(by.faerie_fire or 0)
    print(("GUARDIAN_RAGE_BREADTH role=%s profile=%s seed=%d initialRage=%d maxTrue=%.3f maxLo=%.3f lower35ticks=%d mobSwings=%d maulQueue=%d maulStrike=%d maulUnqueue=%d maulPaid=%.2f core=%d accepted=%d rejected=%d"):format(
      kind,profile,seed,power,trace.maxTrue,trace.maxLo,trace.lo35,
      trace.mobSwings,queue,strike,unqueue,cost,attack,rr.presses,refused))
    return {accepted=rr.presses,refused=refused,core=attack,
      queue=queue,strike=strike,unqueue=unqueue,paid=cost,
      maxLo=trace.maxLo,lo35=trace.lo35,mobs=trace.mobSwings}
  end
end
describe("Independent Rogue Subtlety Ghostly-to-Garrote source-true chain",function()
  for _,seed in ipairs({30417,30437}) do
    for _,start in ipairs({0,100}) do
      it(("source seed %d real starting Energy %d"):format(seed,start),function()
        local shipped=run("rogue","shipped",seed,start)
        local current=run("rogue","current",seed,start)
        local guarded=run("rogue","guarded",seed,start)
        assert.is_true(shipped.accepted>=4)
        assert.is_true(guarded.accepted>=4)
        assert.is_true(guarded.other>=3)
        assert.are.equal(0,guarded.refused,"proposed protected source guard still refused")
        assert.is_true(guarded.auras>=1,
          "released World Ghostly Strike next-Garrote aura never applied")
        assert.is_true(guarded.ghost>=1,
          "no real source Ghostly Strike press after dropping stealth")
        print(("SUB_GHOST_PAIR seed=%d energy=%d shipped=%d current=%d/%d guarded=%d/%d ghostchain=%d"):format(
          seed,start,shipped.accepted,current.accepted,current.refused,
          guarded.accepted,guarded.refused,guarded.chain))
      end)
    end
  end
end)
describe("P0 Guardian published source real starting Rage and Maul queue/strike",function()
  for _,seed in ipairs({30417,30437}) do
    for _,rage in ipairs({0,50}) do
      it(("source seed %d true initial Rage %d"):format(seed,rage),function()
        local shipped=run("guardian","shipped",seed,rage)
        local working=run("guardian","current",seed,rage)
        local candidate=run("guardian","candidate",seed,rage)
        assert.is_true(shipped.accepted>=3)
        assert.is_true(working.accepted>=3)
        assert.is_true(candidate.accepted>=3)
        assert.is_true(candidate.mobs>=3)
        assert.is_true(candidate.core>=3)
        assert.are.equal(0,candidate.refused,"new source world rejected v1.6")
        assert.is_true(candidate.queue>=candidate.strike,
          "actual Maul strikes without enqueued source Maul")
        if candidate.strike>0 then
          assert.is_true(candidate.paid>0,"actual Maul strike paid no true Rage")
        end
        print(("GUARDIAN_RAGE_PAIR seed=%d rage=%d shipped=%d working=%d cand=%d queue=%d strikes=%d lo35=%d"):format(
          seed,rage,shipped.accepted,working.accepted,candidate.accepted,
          candidate.queue,candidate.strike,candidate.lo35))
      end)
    end
  end
end)
