-- Affliction partial-upkeep Wrack opportunity, source-native, no new health spending.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.warlock_world").Affliction)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Warlock/Current/APL_Warlock_Affliction_DPS_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local anchor="actions+=/wrack,if=action.wrack.known&active_enemies<3&debuff.corruption.up&debuff.bane_of_agony.up&(!action.siphon_life.known|debuff.siphon_life.up)"
local alternativeLine=anchor:sub(1,-2).."|(active_enemies=1&mana.lo<action.siphon_life.cost&debuff.corruption.remains>=3&debuff.bane_of_agony.remains>=3))"
local at=assert(current:find(anchor,1,true))
assert.is_nil(current:find(anchor,at+#anchor,1,true))
local alternative=current:sub(1,at-1)..alternativeLine..current:sub(at+#anchor)
local offence={shadow_bolt=true,searing_pain=true,wrack=true,corruption=true,bane_of_agony=true,siphon_life=true,immolate=true,rain_of_fire=true}
local function trial(profile,seed,pct)
  local initial=stock.WORLD.max*pct
  local C=setmetatable({WORLD=setmetatable({power=initial,mobHealth=1000000000,distance=25,
    attackers=1,script=function(W,us) stock.WORLD.script(W,us);W.moveTo(us,25) end
  },{__index=stock.WORLD})},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Warlock_Affliction","APLForever-Affliction-partial-"..profile,
      profile=="current" and current or alternative,C.PACK)
    for _,k in ipairs({"precombat","default","boss_curse","major_cooldowns","aoe","minor_cooldowns","upkeep","final_fallback"}) do assert.is_table(lists[k]) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.cooldowns.override=false;t.cooldowns.infusion=false
  t.minor_cooldowns.value=false;t.minor_cooldowns.override=false
  t.defensives.value=false;t.interrupts.value=false;t.movement.value=false
  local A=H.Hekili.Class.auras
  local cor,bane,siphon,trance=assert(A.corruption.id),assert(A.bane_of_agony.id),assert(A.siphon_life.id),assert(A.shadow_trance.id)
  local wrack=assert(H.Hekili.Class.abilities.wrack.id)
  local v={raw=0,epsilon=0,offence=0,follow=0,partial=0,partialOpportunity=0,rangeSamples=0,
    wrackStarts=0,full=0,clip=0,cutoff=0,ticks=0,shadowTicks=0,cor=0,bane=0,siphon=0,nightfall=0,cost=0}
  local installed=false
  local firstDot=false
  local function remains(e,id,now)
    local a=e and e.auras[id]
    return a and math.max(0,a.expires-now) or 0
  end
  local rr=loop.run(L,seed,{duration=115,on=function(w,_,time)
    if time>loop.PULL+1 and not w.us.stopped then
      assert.are.equal(25,H.ctl.distance.target);v.rangeSamples=v.rangeSamples+1
      local c,b,s=remains(w.us.target,cor,w.W.t),remains(w.us.target,bane,w.W.t),remains(w.us.target,siphon,w.W.t)
      if c>=3 and b>=3 and s==0 and w.us.power>=200 then v.partialOpportunity=v.partialOpportunity+1 end
    end
    if installed then return end
    installed=true
    local press=w.W.press
    w.W.press=function(e,key,p)
      if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
      local mana=e.power
      local c,b,s=remains(e.target,cor,w.W.t),remains(e.target,bane,w.W.t),remains(e.target,siphon,w.W.t)
      local castLeft=(e.castUntil or 0)-w.W.t
      local stopped=e.stopped==true
      local ok,why=press(e,key,p)
      if not ok then
        v.raw=v.raw+1
        if why=="casting" and math.abs(castLeft)<=1e-8 then v.epsilon=v.epsilon+1 end
        print("AFF_PARTIAL_REFUSAL",profile,seed,pct,w.W.t,key,why,castLeft,mana,tostring(stopped))
      elseif not stopped and offence[key] then
        v.offence=v.offence+1
        v.cost=v.cost+(p.cost or 0)
        if firstDot then v.follow=v.follow+1 end
        if key=="corruption" or key=="bane_of_agony" then firstDot=true end
        if key=="wrack" then
          if c>=3 and b>=3 and s==0 then v.partial=v.partial+1 end
          print("AFF_PARTIAL_WRACK",profile,seed,pct,w.W.t,mana,p.cost or 0,c,b,s)
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.is_true(math.abs(initial-rr.us.power0)<1e-6)
  assert.is_true(v.rangeSamples>3)
  local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
  assert.are.equal(raw,v.raw,"raw trace incomplete")
  local ending
  for _,ev in ipairs(rr.W.truth) do
    if ev.kind=="aura" and ev.dst and (ev.stacks or 0)>0 then
      if ev.dst.kind=="mob" then
        if ev.aura==cor then v.cor=v.cor+1 elseif ev.aura==bane then v.bane=v.bane+1 elseif ev.aura==siphon then v.siphon=v.siphon+1 end
      elseif ev.dst==rr.us and ev.aura==trance then v.nightfall=v.nightfall+1 end
    end
    if ev.src==rr.us then
      if ev.kind=="tick" and ev.dst and ev.dst.kind=="mob" then
        v.ticks=v.ticks+1
        if ev.school==32 and (ev.amount or 0)>0 then v.shadowTicks=v.shadowTicks+1 end
      elseif ev.spell==wrack and ev.kind=="cast" and ev.chanEnds then
        v.wrackStarts=v.wrackStarts+1;ending=ev.chanEnds
      elseif ev.spell==wrack and ev.kind=="channelStop" and ending then
        if ev.t>=ending-0.02 then v.full=v.full+1
        elseif math.abs(ev.t-rr.W.t)<=1e-6 then v.cutoff=v.cutoff+1
        else v.clip=v.clip+1 end
        ending=nil
      end
    end
  end
  local c=rr.pressedBy or {}
  v.tap=c.life_tap or 0;v.pain=c.searing_pain or 0;v.endMana=rr.us.power
  print(("AFF_PARTIAL_V0121 profile=%s seed=%d pct=%.2f active=%d follow=%d raw=%d epsilon=%d partial=%d opportunities=%d wrack=%d full=%d clip=%d cutoff=%d cor=%d bane=%d siphon=%d ticks=%d shadow=%d nightfall=%d pain=%d tap=%d cost=%.2f endMana=%.2f"):format(
    profile,seed,pct,v.offence,v.follow,v.raw,v.epsilon,v.partial,v.partialOpportunity,v.wrackStarts,v.full,v.clip,v.cutoff,v.cor,v.bane,v.siphon,v.ticks,v.shadowTicks,v.nightfall,v.pain,v.tap,v.cost,v.endMana))
  if profile~="shipped" then
    assert.are.equal(0,v.tap,"automatic Life Tap regression")
    assert.are.equal(0,v.raw-v.epsilon,"substantive refusal")
    assert.is_true(v.offence>=3,"final fallback progression")
    if pct>=0.25 then assert.is_true(v.follow>=3,"post-DoT progression") end
  end
  return v
end
describe("Affliction v0.12.1 partial-upkeep Wrack while Siphon unaffordable",function()
  local opportunity=0
  for _,seed in ipairs({30417,30437,30461}) do
    for _,pct in ipairs({1,0.35,0.25,0.05}) do
      it(("seed %d Mana %.2f"):format(seed,pct),function()
        trial("shipped",seed,pct)
        local old=trial("current",seed,pct)
        local new=trial("alternative",seed,pct)
        opportunity=opportunity+new.partial
        assert.is_true(new.clip<=old.clip,"new combat channel clipping")
        print(("AFF_PARTIAL_MATCH seed=%d pct=%.2f oldPartial=%d newPartial=%d oldFull=%d newFull=%d oldTicks=%d newTicks=%d oldOffence=%d newOffence=%d oldCost=%.2f newCost=%.2f oldMana=%.2f newMana=%.2f"):format(
          seed,pct,old.partial,new.partial,old.full,new.full,old.shadowTicks,new.shadowTicks,old.offence,new.offence,old.cost,new.cost,old.endMana,new.endMana))
      end)
    end
  end
  it("actual partial Wrack opportunity exercised",function()
    assert.is_true(opportunity>0,"no naturally exercised partial Wrack; blocked not improved")
  end)
end)
