-- #37: test earlier native Inner Focus to fund otherwise expensive upkeep at low Mana.
-- Full shipped/current/alternative, no fabricated player HP, no health-cost actions added.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.priest_world").Shadow)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Priest/Current/APL_Priest_Shadow_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local anchor="actions+=/call_action_list,name=upkeep,if=!action.mind_flay.channeling"
local extra="actions+=/inner_focus,use_off_gcd=1,if=toggle.cooldowns&toggle.minor_cooldowns&combat>0&action.inner_focus.known&!buff.inner_focus.up&!action.mind_flay.channeling&mana.pct_lo<=25&((action.shadow_word_pain.known&!debuff.shadow_word_pain.up)|(action.devouring_plague.known&action.devouring_plague.ready&!debuff.devouring_plague.up))"
local at=assert(current:find(anchor,1,true))
assert.is_nil(current:find(anchor,at+#anchor,1,true))
local alternative=current:sub(1,at-1)..extra.."\n"..current:sub(at)
local offence={shadow_word_pain=true,devouring_plague=true,mind_blast=true,mind_flay=true,smite=true,shadow_word_death=true,shoot=true}
local function run(profile,seed,case)
  local C=setmetatable({WORLD=setmetatable({
    power=stock.WORLD.max*case.pct,mobHealth=1000000000,distance=15
  },{__index=stock.WORLD})},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Priest_Shadow","APLForever-Shadow-focus-"..profile,
      profile=="current" and current or alternative,C.PACK)
    for _,k in ipairs({"precombat","default","upkeep","major_cooldowns","minor_cooldowns","final_fallback"}) do assert.is_table(lists[k]) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=case.major;t.minor_cooldowns.value=case.minor;t.defensives.value=false
  t.cooldowns.override=false;t.cooldowns.infusion=false
  t.minor_cooldowns.override=case.auto==true
  local effectiveMinor=case.minor or (case.auto==true and case.major)
  assert.are.equal(effectiveMinor,H.Hekili.State.toggle.minor_cooldowns,"native effective Minor toggle")
  print("SHADOW_FOCUS_TOGGLE",profile,case.name,seed,tostring(case.major),tostring(case.minor),tostring(t.minor_cooldowns.override),tostring(H.Hekili.State.toggle.minor_cooldowns))
  t.interrupts.value=false;if t.movement then t.movement.value=false end
  local focus=assert(H.Hekili.Class.auras.inner_focus.id)
  local flay=assert(H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.mind_flay.id))
  local swp=assert(H.Hekili.Class.auras.shadow_word_pain.id)
  local dp=assert(H.Hekili.Class.auras.devouring_plague.id)
  local v={raw=0,epsilon=0,offence=0,follow=0,focus=0,freeDot=0,freeOther=0,cost=0,firstMana=-1,firstKey="none",afterFocus=0,low=0,dot=0}
  local installed=false
  local rr=loop.run(L,seed,{duration=115,on=function(w,_,time)
    if time>=loop.PULL and not w.us.stopped and w.us.power<stock.WORLD.max*0.25 then v.low=v.low+1 end
    if installed then return end
    installed=true
    local press=w.W.press
    w.W.press=function(e,key,p)
      if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
      local mana=e.power
      local up=e.auras[focus]~=nil
      local remaining=(e.castUntil or 0)-w.W.t
      local stopped=e.stopped==true
      local ok,why=press(e,key,p)
      if not ok then
        v.raw=v.raw+1
        if why=="casting" and math.abs(remaining)<=1e-8 then v.epsilon=v.epsilon+1 end
        print("SHADOW_FOCUS_REFUSED",profile,case.name,seed,w.W.t,key,why,remaining,tostring(stopped),mana)
      elseif not stopped then
        if key=="inner_focus" then v.focus=v.focus+1
        elseif offence[key] then
          v.offence=v.offence+1
          if v.firstMana<0 then v.firstMana=mana;v.firstKey=key end
          if v.offence>1 then v.follow=v.follow+1 end
          if v.focus>0 then v.afterFocus=v.afterFocus+1 end
          v.cost=v.cost+(p.cost or 0)
          if up and (p.cost or 0)==0 then
            if key=="shadow_word_pain" or key=="devouring_plague" then v.freeDot=v.freeDot+1
            else v.freeOther=v.freeOther+1 end
            print("SHADOW_FOCUS_FREE",profile,case.name,seed,w.W.t,key,mana)
          end
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.is_true(math.abs(rr.us.power0-stock.WORLD.max*case.pct)<1e-6)
  local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
  assert.are.equal(raw,v.raw)
  local full,clip,cutoff,starts=0,0,0,0
  local ending
  local swpAura,dpAura=0,0
  for _,e in ipairs(rr.W.truth) do
    if e.kind=="aura" and e.dst and e.dst.kind=="mob" and (e.stacks or 0)>0 then
      if e.aura==swp then swpAura=swpAura+1 elseif e.aura==dp then dpAura=dpAura+1 end
    end
    if e.src==rr.us and e.spell==flay then
      if e.kind=="cast" and e.chanEnds then starts=starts+1;ending=e.chanEnds
      elseif e.kind=="channelStop" and ending then
        if e.t>=ending-0.02 then full=full+1
        elseif math.abs(e.t-rr.W.t)<=1e-6 then cutoff=cutoff+1
        else clip=clip+1 end
        ending=nil
      end
    end
  end
  local c=rr.pressedBy or {}
  v.dot=swpAura+dpAura;v.full=full;v.endMana=rr.us.power;v.counts=c
  print(("SHADOW_FOCUS_V0121 profile=%s case=%s seed=%d initial=%.2f firstMana=%.2f firstKey=%s accepted=%d offence=%d follow=%d raw=%d epsilon=%d focus=%d freeDot=%d freeOther=%d afterFocus=%d swpAura=%d dpAura=%d flayStarts=%d full=%d clips=%d cutoff=%d lowSamples=%d cost=%.2f endMana=%.2f"):format(
    profile,case.name,seed,rr.us.power0,v.firstMana,v.firstKey,rr.presses,v.offence,v.follow,v.raw,v.epsilon,v.focus,v.freeDot,v.freeOther,v.afterFocus,swpAura,dpAura,starts,full,clip,cutoff,v.low,v.cost,v.endMana))
  if profile~="shipped" then
    assert.are.equal(0,raw-v.epsilon,"substantive refusal")
    assert.are.equal(0,clip,"combat channel clip")
    assert.are.equal(0,c.shadow_word_death or 0)
    assert.are.equal(0,c.dark_sacrifice or 0)
    assert.is_true(v.offence>=3)
    if v.focus>0 then assert.is_true(v.afterFocus>=3,"no subsequent progression") end
    if not case.major or not (case.minor or (case.auto==true and case.major)) then assert.are.equal(0,v.focus,"native off-switch violation") end
  end
  return v
end
describe("Shadow v0.12.1 low-Mana Inner Focus upkeep opportunity",function()
  local opportunities=0
  for _,seed in ipairs({30417,30437,30461}) do
    for _,case in ipairs({
      {name="full_on",pct=1,major=true,minor=true},
      {name="quarter_on",pct=0.25,major=true,minor=true},
      {name="extreme_on",pct=0.05,major=true,minor=true},
      {name="extreme_minor_off",pct=0.05,major=true,minor=false},
      {name="extreme_minor_auto",pct=0.05,major=true,minor=false,auto=true},
      {name="extreme_major_off",pct=0.05,major=false,minor=true},
    }) do
      it(case.name.." seed "..seed,function()
        run("shipped",seed,case)
        local old=run("current",seed,case)
        local new=run("alternative",seed,case)
        if not case.major or not (case.minor or (case.auto==true and case.major)) then
          assert.are.same(old.counts,new.counts,"off-switch baseline changed")
        else
          opportunities=opportunities+new.freeDot
        end
        print(("SHADOW_FOCUS_MATCH case=%s seed=%d oldFreeDot=%d newFreeDot=%d oldDot=%d newDot=%d oldFull=%d newFull=%d oldOffence=%d newOffence=%d oldCost=%.2f newCost=%.2f oldMana=%.2f newMana=%.2f"):format(case.name,seed,old.freeDot,new.freeDot,old.dot,new.dot,old.full,new.full,old.offence,new.offence,old.cost,new.cost,old.endMana,new.endMana))
      end)
    end
  end
  it("actual free DoT opportunity exercised",function()
    assert.is_true(opportunities>0,"no free DoT observed: experiment blocked")
  end)
end)
