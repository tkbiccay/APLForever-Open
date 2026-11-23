-- Warlock Destruction: published Forever v0.11.0 complete shipped
-- comparator vs exactly protected Current v1.0; no game-HP safety claim.
-- Source SHA 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Hypothesis: actual Immolate/Conflagrate accepted sequencing plus
-- low-Mana post-upkeep fallback without repeated substantive refusals.
-- Do not count Life Tap as safe: source world does not subtract player HP.
local loop = require("Game.harness.loop")
local stock = assert(require("Forever.helpers.warlock_world").Destruction)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local fp=assert(io.open(root.."/roles/Warlock/Current/APL_Warlock_Destruction_DPS_v1.0_Draft.txt","rb"))
local current=assert(fp:read("*a"));fp:close()
assert.is_nil(current:find("life_tap",1,true),
  "protected Current unexpectedly includes unsafe unmodelled-health Life Tap")
local offence={shadow_bolt=true,searing_pain=true,incinerate=true,immolate=true,
  corruption=true,bane_of_agony=true,bane_of_doom=true,rain_of_fire=true,
  conflagrate=true,shadowburn=true,soul_fire=true}
local dots={immolate=true,corruption=true,bane_of_agony=true}
local function run(profile,seed,startMana,duration)
  local W=setmetatable({distance=25,power=startMana,mobHealth=1000000000},
    {__index=stock.WORLD})
  local C=setmetatable({WORLD=W},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  assert.is_table(C.IDS.immolate,"Destruction source world does not know Immolate")
  assert.is_table(C.IDS.conflagrate,"Destruction talent ability not in known kit")
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL(
      "Warlock_Destruction","APLForever-Destruction-v011",current,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","boss_curse","aoe",
       "minor_cooldowns","upkeep","major_cooldowns","instant_burst","final_fallback"}) do
      assert.is_table(lists[name],"missing full Current action list "..name)
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
  toggles.cooldowns.value=false; toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  local events,failed={},{}
  local installed=false
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(w)
      if installed then return end
      local old=w.W.press
      w.W.press=function(player,key,resolved)
        local timestamp=w.W.t
        local castingRemaining=(player.castUntil or 0)-timestamp
        local ok,why=old(player,key,resolved)
        if player==w.us and timestamp>=loop.PULL and type(key)=="string" then
          if ok then
            events[#events+1]={t=timestamp,key=key}
          else
            failed[#failed+1]={t=timestamp,key=key,reason=why,
              remaining=castingRemaining}
          end
        end
        return ok,why
      end
      installed=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for why,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("DESTRO_REFUSED profile=%s seed=%d mana=%.2f reason=%s count=%d"):format(
      profile,seed,startMana,tostring(why),n))
  end
  for _,e in ipairs(failed) do
    print(("DESTRO_PRESS_FAIL profile=%s seed=%d mana=%.2f t=%.17g key=%s reason=%s castRemain=%.17g"):format(
      profile,seed,startMana,e.t,tostring(e.key),tostring(e.reason),e.remaining))
  end
  assert.are.equal(refused,#failed,
    "world refusal count differs from captured failed presses")
  -- Native W.press refuses any cast while t < castUntil (no epsilon).
  -- Strictly classify ONLY the observed Conflagrate nanosecond cast-end
  -- overlap; every substantial/cost/GCD/range/other refusal still FAILS.
  -- A 0 or negative remaining duration does NOT qualify as a boundary.
  local boundary,substantive=0,0
  for _,e in ipairs(failed) do
    if e.key=="conflagrate" and e.reason=="casting"
        and e.remaining>0 and e.remaining<=1e-7 then
      boundary=boundary+1
    else
      substantive=substantive+1
    end
  end
  print(("DESTRO_REFUSAL_CLASS profile=%s seed=%d mana=%.2f raw=%d boundary=%d substantive=%d"):format(
    profile,seed,startMana,refused,boundary,substantive))
  local accepted=rr.pressedBy or {}
  local totals,traceOffence=0,0
  for key in pairs(offence) do totals=totals+(accepted[key] or 0) end
  local firstDot,postDot=0,0
  local seenDot=false
  local sawImmolation=false
  local orderedConflag=0
  for _,e in ipairs(events) do
    if offence[e.key] then traceOffence=traceOffence+1 end
    if dots[e.key] then
      if firstDot==0 then firstDot=1 end
      seenDot=true
      if e.key=="immolate" then sawImmolation=true end
    elseif seenDot and offence[e.key] then
      postDot=postDot+1
    end
    if e.key=="conflagrate" and sawImmolation then
      orderedConflag=orderedConflag+1
    end
  end
  assert.is_true(traceOffence<=totals,
    "the accepted event trace exceeds authoritative pressedBy totals")
  local majors=(accepted.blood_fury or 0)+(accepted.berserking or 0)+
    (accepted.eureka or 0)+(accepted.use_items or 0)
  local minor=accepted.amplify_curse or 0
  local taps=accepted.life_tap or 0
  local immolate=accepted.immolate or 0
  local conflag=accepted.conflagrate or 0
  local fillers=(accepted.incinerate or 0)+(accepted.shadow_bolt or 0)+
    (accepted.searing_pain or 0)
  print(("DESTRO_V011 profile=%s seed=%d startMana=%.2f accepted=%d refuse=%d offensive=%d tracedOffensive=%d immolate=%d conflag=%d conflagAfterImmolate=%d dots=%d laterOffense=%d filler=%d tap=%d major=%d minor=%d endMana=%.2f"):format(
    profile,seed,startMana,rr.presses,refused,totals,traceOffence,
    immolate,conflag,orderedConflag,firstDot,postDot,fillers,
    taps,majors,minor,rr.us.power))
  return {presses=rr.presses,refused=refused,boundary=boundary,substantive=substantive,offence=totals,
    trace=traceOffence,immolate=immolate,conflag=conflag,
    orderedConflag=orderedConflag,postDot=postDot,firstDot=firstDot,
    fillers=fillers,tap=taps,major=majors,minor=minor}
end
describe("Warlock Destruction v0.11 native Immolate/Conflagrate/fallback",function()
  for _,seed in ipairs({30417,30437}) do
    it("full Mana complete shipped vs Current, post-DoT and Conflagrate "..seed,function()
      local full=stock.WORLD.max
      local s=run("shipped",seed,full,90)
      local c=run("current",seed,full,90)
      assert.is_true(s.presses>=3,"shipped world cannot advance")
      assert.is_true(c.immolate>=1,"Current did not cast Immolate at full Mana")
      assert.is_true(c.postDot>=3,"Current did not follow upkeep with 3 accepted offence actions")
      assert.is_true(c.orderedConflag>=1,
        "Current never cast Conflagrate after an accepted Immolate")
      assert.is_true(c.fillers>=3,"Current lacks accepted offensive fallback")
      assert.are.equal(0,c.substantive,"Current has a genuine refused cast")
      assert.is_true(c.boundary<=1,"Repeated cast-end collisions need root cause")
      assert.are.equal(0,c.tap,"Current cast source health-unmodelled Life Tap")
      assert.are.equal(0,c.major,"Current violated Major OFF")
      assert.are.equal(0,c.minor,"Current violated Minor OFF")
    end)
    it("25 percent Mana safe three-post-upkeep and no refused loop "..seed,function()
      local low=stock.WORLD.max*0.25
      local s=run("shipped",seed,low,110)
      local c=run("current",seed,low,110)
      assert.is_true(s.presses>=1)
      assert.is_true(c.firstDot>=1,"Current never reached DoT upkeep")
      assert.is_true(c.postDot>=3,"Current lacks three source-accepted post-DoT offences")
      assert.are.equal(0,c.refused,"Current low Mana refused action")
      assert.are.equal(0,c.tap,"Current tried health-unmodelled Life Tap")
      assert.are.equal(0,c.major);assert.are.equal(0,c.minor)
    end)
    it("five percent Mana no unsafe Life Tap or repeated refused fallback "..seed,function()
      local extreme=stock.WORLD.max*0.05
      local s=run("shipped",seed,extreme,70)
      local c=run("current",seed,extreme,70)
      assert.is_true(s.presses>=1)
      assert.are.equal(0,c.tap)
      assert.are.equal(0,c.refused,"Current refused at extreme Mana")
      assert.are.equal(0,c.major);assert.are.equal(0,c.minor)
      -- Positive post-DoT is not assumed if the initial Mana cannot buy a DoT.
      print(("DESTRO_5PCT_FALLBACK seed=%d CurrentAccepted=%d CurrentDots=%d CurrentFollowons=%d shippedLifeTaps=%d"):format(
        seed,c.presses,c.firstDot,c.postDot,s.tap))
    end)
  end
end)
