-- Proposed #33: use the released LibTimeToDie estimator, never the true kill clock as an APL input.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.druid_loop_world").Balance)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Druid/Current/APL_Druid_Balance_DPS_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local guarded,n=current:gsub("actions%.upkeep=insect_swarm,focus=2,if=",
  "actions.upkeep=insect_swarm,focus=2,if=target.time_to_die>6&")
assert.are.equal(1,n)
-- Preserve instant Moonfire if Wrath cannot land in time or cannot be afforded.
-- Only defer it in the narrow known-time window where a legal filler exists.
local refined,m=guarded:gsub("actions%.upkeep%+=/moonfire,focus=2,if=",
  "actions.upkeep+=/moonfire,focus=2,if=(target.time_to_die>6|target.time_to_die<=action.wrath.cast|!action.wrath.known|mana.lo<action.wrath.cost)&")
assert.are.equal(1,m)
local offence={wrath=true,starfire=true,moonfire=true,insect_swarm=true,hurricane=true}
local function trial(profile,seed,case)
  local C=setmetatable({WORLD=setmetatable({
    power=case.mana,mobHealth=case.hp,distance=20
  },{__index=stock.WORLD})},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Balance","APLForever-Balance-TTD-"..profile,
      profile=="current" and current or profile=="guarded" and guarded or refined,C.PACK)
    for _,k in ipairs({"precombat","default","mana_recovery","major_cooldowns","aoe","upkeep","eclipse_spenders","final_fallback"}) do assert.is_table(lists[k]) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.minor_cooldowns.value=false;t.defensives.value=false
  t.interrupts.value=false;t.movement.value=false
  local a={active=0,offence=0,follow=0,raw=0,terminalRefused=0,terminalAccepted=0,
    insect=0,late=0,unknownInsect=0,insectCost=0,totalCost=0,moonfireCost=0,lateMoonfire=0,live=0,low=0,unknown=0,min=3600,
    firstMana=-1,firstTime=-1,firstKey="none"}
  local installed=false
  local rr=loop.run(L,seed,{duration=95,arm=case.arm,on=function(w,_,time)
    if not installed then
      installed=true
      local old=w.W.press
      w.W.press=function(e,key,p)
        if e~=w.us or w.W.t<loop.PULL then return old(e,key,p) end
        local stop=e.stopped==true
        local mana=e.power
        local estimate=H.Hekili:GetTTD("target")
        local ok,why=old(e,key,p)
        if not ok then
          a.raw=a.raw+1
          if stop then a.terminalRefused=a.terminalRefused+1 end
          print("BALANCE_TTD_REFUSAL",profile,case.name,seed,w.W.t,key,why,tostring(stop),estimate)
        elseif stop then a.terminalAccepted=a.terminalAccepted+1
        else
          a.active=a.active+1
          if a.firstMana<0 then a.firstMana=mana;a.firstTime=w.W.t;a.firstKey=key end
          if offence[key] then
            a.offence=a.offence+1
            a.totalCost=a.totalCost+(p.cost or 0)
            if key=="moonfire" then
              a.moonfireCost=a.moonfireCost+(p.cost or 0)
              if estimate<3600 and estimate<=6 then a.lateMoonfire=a.lateMoonfire+1 end
            end
            if a.offence>1 then a.follow=a.follow+1 end
          end
          if key=="insect_swarm" then
            a.insect=a.insect+1;a.insectCost=a.insectCost+(p.cost or 0)
            if estimate>=3600 then a.unknownInsect=a.unknownInsect+1
            elseif estimate<=6 then a.late=a.late+1 end
            print("BALANCE_TTD_INSECT",profile,case.name,seed,w.W.t,estimate,mana,p.cost or 0)
          end
        end
        return ok,why
      end
    end
    if time>=loop.PULL and not w.us.stopped then
      local v=H.Hekili:GetTTD("target")
      if v>=3600 then a.unknown=a.unknown+1
      else
        a.live=a.live+1;a.min=math.min(a.min,v)
        if v<=6 then a.low=a.low+1 end
      end
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.are.equal(case.mana,rr.us.power0)
  local raw=0;for _,v in pairs(rr.refused or {}) do raw=raw+v end
  assert.are.equal(raw,a.raw)
  local counts=rr.pressedBy or {}
  local id=assert(H.Hekili.Class.auras.insect_swarm.id)
  local applied=0
  for _,ev in ipairs(rr.W.truth) do
    if ev.kind=="aura" and ev.aura==id and ev.dst and ev.dst.kind=="mob" and (ev.stacks or 0)>0 then applied=applied+1 end
  end
  print(("BALANCE_TTD_V0121 profile=%s case=%s seed=%d arm=%s hp=%d mana0=%d firstMana=%.2f firstTime=%.3f firstKey=%s accepted=%d traced=%d offence=%d follow=%d raw=%d terminalRefused=%d terminalAccepted=%d insectTotal=%d insectTraced=%d insectLanded=%d insectCost=%.2f lateInsect=%d unknownInsect=%d liveSamples=%d lowSamples=%d unknownSamples=%d minTTD=%.2f wrath=%d starfire=%d moonfire=%d manaEnd=%.2f killAt=%s"):format(
    profile,case.name,seed,case.arm,case.hp,rr.us.power0,a.firstMana,a.firstTime,a.firstKey,rr.presses,a.active,a.offence,a.follow,a.raw,a.terminalRefused,a.terminalAccepted,counts.insect_swarm or 0,a.insect,applied,a.insectCost,a.late,a.unknownInsect,a.live,a.low,a.unknown,a.min,counts.wrath or 0,counts.starfire or 0,counts.moonfire or 0,rr.us.power,tostring(rr.W.killAt)))
  assert.is_true(a.insect<=(counts.insect_swarm or 0))
  assert.is_true(a.offence>=3,"no accepted offensive progression")
  assert.is_true(a.follow>=2)
  if profile=="guarded" or profile=="refined" then
    assert.are.equal(0,a.raw,"guarded profile has raw refusal")
    assert.are.equal(0,a.late,"guard failed at an observed low TTD")
  end
  if case.arm=="lib-absent" then
    assert.are.equal(0,a.live,"unknown library control not exercised")
    assert.is_true(a.unknown>0)
  end
  a.kill=rr.W.killAt or -1;a.endMana=rr.us.power;a.counts=counts
  print(("BALANCE_TTD_COST profile=%s case=%s seed=%d tracedOffenceCost=%.2f moonfireCost=%.2f lateMoonfire=%d endMana=%.2f killAt=%.3f"):format(profile,case.name,seed,a.totalCost,a.moonfireCost,a.lateMoonfire,a.endMana,a.kill))
  return a
end
describe("Balance v0.12.1 Insect Swarm late-refresh opportunity",function()
  local lowSamples=0
  for _,seed in ipairs({30417,30437,30461}) do
    for _,case in ipairs({
      {name="short",hp=5000,mana=4000,arm="ttd"},
      {name="veryshort",hp=2500,mana=4000,arm="ttd"},
      {name="medium",hp=8000,mana=4000,arm="ttd"},
      {name="long",hp=15000,mana=1000,arm="ttd"},
      {name="unknown",hp=5000,mana=4000,arm="lib-absent"},
    }) do
      it(case.name.." seed "..seed,function()
        local shipped=trial("shipped",seed,case)
        local old=trial("current",seed,case)
        local new=trial("guarded",seed,case)
        local alt=trial("refined",seed,case)
        print(("BALANCE_TTD_MATCH case=%s seed=%d currentCost=%.2f guardedCost=%.2f refinedCost=%.2f currentEndMana=%.2f guardedEndMana=%.2f refinedEndMana=%.2f currentKill=%.3f guardedKill=%.3f refinedKill=%.3f"):format(case.name,seed,old.totalCost,new.totalCost,alt.totalCost,old.endMana,new.endMana,alt.endMana,old.kill,new.kill,alt.kill))
        if case.arm=="ttd" then lowSamples=lowSamples+old.low+new.low+alt.low
        else
          assert.are.equal(old.insect,new.insect,"unknown TTD should retain observed upkeep")
          assert.are.equal(old.active,new.active,"unknown fallback progression changed")
          assert.are.same(old.counts,alt.counts,"refined unknown fallback action counts changed")
          assert.are.equal(old.active,alt.active,"refined unknown fallback progression changed")
        end
      end)
    end
  end
  it("real estimator exercised low-time opportunity, not just unknown",function()
    assert.is_true(lowSamples>0,"no low TTD samples: test is blocked, not improvement evidence")
  end)
end)
