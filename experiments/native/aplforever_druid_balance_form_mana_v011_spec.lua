-- Druid Balance: published Forever v0.11.0 exact full shipped comparator
-- against immutable original Current v1.0. Real Moonkin, Eclipse, Mana,
-- dot/filler fallback. No PvE DPS/survival/in-game inference.
-- zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.druid_loop_world").Balance)
local form=assert(require("Forever.helpers.druid_loop_world").FORM.moonkin_form)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Druid/Current/APL_Druid_Balance_DPS_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local offence={wrath=true,starfire=true,moonfire=true,insect_swarm=true,hurricane=true}
local dots={moonfire=true,insect_swarm=true}
local function simulate(profile,seed,mana,initialForm,cooldowns,duration)
  local world=setmetatable({power=mana,mobHealth=1000000000,distance=20},
    {__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  if initialForm=="unshifted" then
    C.character=function()
      local c=stock.character()
      c.form=0
      return c
    end
  end
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  assert.are.equal("Balance (wowsims.com)",C.PACK)
  assert.is_table(C.IDS.moonkin_form)
  assert.is_table(C.IDS.wrath)
  assert.is_table(C.IDS.innervate)
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL(
      "Druid_Balance","APLForever-Balance-v011",current,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","mana_recovery",
      "major_cooldowns","aoe","upkeep","eclipse_spenders","final_fallback"}) do
      assert.is_table(lists[name],"full APL missing "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
    end
    assert.are.same({},H.errors)
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=cooldowns
  toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  local acceptedEvents,failedEvents={},{}
  local installed=false
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(run)
      if installed then return end
      local old=run.W.press
      run.W.press=function(player,key,p)
        local t=run.W.t
        local manaBefore=player.power
        local castRem=(player.castUntil or 0)-t
        local ok,why=old(player,key,p)
        if player==run.us and t>=loop.PULL and type(key)=="string" then
          if ok then
            acceptedEvents[#acceptedEvents+1]={t=t,key=key,mana=manaBefore}
          else
            failedEvents[#failedEvents+1]={t=t,key=key,mana=manaBefore,
              reason=why,castRemaining=castRem}
          end
        end
        return ok,why
      end
      installed=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refuse=0
  for why,n in pairs(rr.refused or {}) do
    refuse=refuse+n
    print(("BALANCE_REFUSAL_SUMMARY profile=%s seed=%d mana=%.1f init=%s cd=%s reason=%s n=%d"):format(
      profile,seed,mana,initialForm,tostring(cooldowns),tostring(why),n))
  end
  for _,e in ipairs(failedEvents) do
    print(("BALANCE_REFUSED profile=%s seed=%d mana0=%.1f init=%s cd=%s t=%.17g key=%s manaBefore=%.6f reason=%s castRemaining=%.17g"):format(
      profile,seed,mana,initialForm,tostring(cooldowns),e.t,e.key,e.mana,
      tostring(e.reason),e.castRemaining))
  end
  local counts=rr.pressedBy or {}
  local offences,traceOffence=0,0
  for k in pairs(offence) do offences=offences+(counts[k] or 0) end
  local postDot,seenDot=0,false
  for _,e in ipairs(acceptedEvents) do
    if offence[e.key] then traceOffence=traceOffence+1 end
    if dots[e.key] then seenDot=true
    elseif seenDot and offence[e.key] then postDot=postDot+1 end
  end
  assert.is_true(traceOffence<=offences,
    "W.press hook has more attacks than authoritative pressedBy")
  local shift=counts.moonkin_form or 0
  local innervate=counts.innervate or 0
  local first3={}
  for i=1,math.min(#acceptedEvents,12) do first3[#first3+1]=acceptedEvents[i].key end
  print(("BALANCE_V011 profile=%s seed=%d mana0=%.1f init=%s cd=%s accepted=%d offensive=%d traced=%d postDot=%d wrath=%d starfire=%d moonfire=%d insect=%d moonkinCasts=%d innervates=%d refused=%d finalForm=%s finalMana=%.2f first=%s"):format(
    profile,seed,mana,initialForm,tostring(cooldowns),
    rr.presses,offences,traceOffence,postDot,counts.wrath or 0,
    counts.starfire or 0,counts.moonfire or 0,counts.insect_swarm or 0,
    shift,innervate,refuse,tostring(rr.us.form),rr.us.power,
    table.concat(first3,",")))
  return {accepted=rr.presses,offensive=offences,postDot=postDot,
    refused=refuse,failed=failedEvents,form=rr.us.form,
    moonkin=shift,innervate=innervate,wrath=counts.wrath or 0,
    starfire=counts.starfire or 0,moonfire=counts.moonfire or 0,
    insect=counts.insect_swarm or 0}
end
describe("Druid Balance v0.11 complete Moonkin/Mana/final fallbacks",function()
  local cases={
    {label="moonkin full Mana cooldowns OFF",mana=4000,initial="moonkin",cd=false,duration=75},
    {label="moonkin quarter Mana cooldowns OFF",mana=1000,initial="moonkin",cd=false,duration=90},
    {label="moonkin five percent Mana cooldowns OFF",mana=200,initial="moonkin",cd=false,duration=70},
    {label="unshifted full Mana cooldowns OFF",mana=4000,initial="unshifted",cd=false,duration=80},
    {label="unshifted quarter Mana cooldowns ON",mana=1000,initial="unshifted",cd=true,duration=95},
  }
  for _,seed in ipairs({30417,30437}) do
    for _,case in ipairs(cases) do
      it(case.label.." seed "..seed,function()
        local shipped=simulate("shipped",seed,case.mana,case.initial,case.cd,case.duration)
        local custom=simulate("current",seed,case.mana,case.initial,case.cd,case.duration)
        assert.is_true(shipped.accepted>=1,"shipped comparison world cannot progress")
        assert.is_true(custom.accepted>=1,"Current no source-accepted actions")
        if not case.cd then
          assert.are.equal(0,custom.innervate,
            "Current used Innervate against player's cooldown off-switch")
        end
        if case.initial=="unshifted" and case.mana>=1000 then
          assert.is_true(custom.moonkin>=1,
            "Current did not shift from unshifted when known and affordable")
          assert.are.equal(form,custom.form,
            "Current did not remain Moonkin in known-kit source test")
        end
        if case.mana>=1000 then
          assert.is_true(custom.offensive>=3,
            "Current lacks three genuine accepted offensive follow-ons")
          assert.is_true(custom.wrath+custom.starfire>=1,
            "Current never accessed either whole-chain offensive filler")
        end
        -- Full source refusals are reported individually; do not conceal
        -- cost/form/GCD or repetitive end-of-list failures as sim ticks.
        assert.are.equal(0,custom.refused,
          "Current has source-refused recommendations; inspect W.press trace")
      end)
    end
  end
end)
