-- Released source-world comparison: remove a redundant Mana gate ONLY for a proven free single-target cast.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.shaman_world").Elemental)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Shaman/Current/APL_Shaman_Elemental_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local anchor="actions+=/chain_lightning,if=action.chain_lightning.known&buff.clearcasting.up&mana.pct_lo>=35&!buff.elemental_mastery.up"
local new="actions+=/chain_lightning,if=action.chain_lightning.known&buff.clearcasting.up&(mana.pct_lo>=35|(active_enemies=1&action.chain_lightning.cost=0&buff.clearcasting.remains>action.chain_lightning.cast+0.2))&!buff.elemental_mastery.up"
local a=assert(current:find(anchor,1,true))
assert.is_nil(current:find(anchor,a+#anchor,1,true))
local alternate=current:sub(1,a-1)..new..current:sub(a+#anchor)
local function trial(profile,seed,case)
  local initial=stock.WORLD.max*case.pct
  local C=setmetatable({WORLD=setmetatable({
    power=initial,mobHealth=1000000000,distance=20,attackers=1,
    script=function(W,us) stock.WORLD.script(W,us);W.moveTo(us,20) end
  },{__index=stock.WORLD})},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Shaman_Elemental","APLForever-Ele-CC-"..profile,
      profile=="current" and current or alternate,C.PACK)
    for _,k in ipairs({"precombat","default","mana_recovery","shields","support_totems","fire_totems","major_cooldowns","aoe","final_fallback"}) do assert.is_table(lists[k]) end
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
  local cc=assert(H.Hekili.Class.auras.clearcasting.id)
  assert.are.equal(16246,cc)
  local ids,offence={},{}
  for _,key in ipairs({"lightning_bolt","chain_lightning","flame_shock","earth_shock","fire_nova"}) do
    for _,id in ipairs(assert(C.IDS[key])) do ids[id]=key end
    offence[key]=true
  end
  local v={raw=0,boundary=0,active=0,firstMana=-1,follow=0,freeLowStart=0,paidLowStart=0,
    lowSamples=0,procSamples=0,rangeSamples=0,completion=0,freeCL=0,paidCL=0,landCost=0,freeLB=0,procGrants=0}
  local installed=false
  local rr=loop.run(L,seed,{duration=100,on=function(w,_,time)
    if time>loop.PULL+1 and not w.us.stopped then
      assert.are.equal(20,H.ctl.distance.target)
      v.rangeSamples=v.rangeSamples+1
      if w.us.power<stock.WORLD.max*0.35 then
        v.lowSamples=v.lowSamples+1
        if w.us.auras[cc] then v.procSamples=v.procSamples+1 end
      end
    end
    if installed then return end
    installed=true
    local press=w.W.press
    w.W.press=function(e,key,p)
      if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
      local mana=e.power
      local up=e.auras[cc]~=nil
      local left=(e.castUntil or 0)-w.W.t
      local stopped=e.stopped==true
      local ok,why=press(e,key,p)
      if not ok then
        v.raw=v.raw+1
        if why=="casting" and math.abs(left)<=1e-8 then v.boundary=v.boundary+1 end
        print("ELE_CC_REFUSAL",profile,case.name,seed,w.W.t,key,why,left,mana,tostring(stopped))
      elseif not stopped and offence[key] then
        v.active=v.active+1
        if v.firstMana<0 then v.firstMana=mana else v.follow=v.follow+1 end
        if key=="chain_lightning" and mana<stock.WORLD.max*0.35 then
          if up and (p.cost or 0)==0 then v.freeLowStart=v.freeLowStart+1
          else v.paidLowStart=v.paidLowStart+1 end
          print("ELE_CC_START",profile,case.name,seed,w.W.t,mana,tostring(up),p.cost or 0,p.cast or 0)
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.is_true(math.abs(initial-rr.us.power0)<1e-6)
  assert.is_true(v.rangeSamples>3)
  local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
  assert.are.equal(raw,v.raw)
  for _,ev in ipairs(rr.W.truth) do
    if ev.t>=loop.PULL and ev.src==rr.us and ev.kind=="cast" and ids[ev.spell] then
      local k=ids[ev.spell]
      v.completion=v.completion+1;v.landCost=v.landCost+(ev.cost or 0)
      if k=="chain_lightning" then
        if (ev.cost or 0)==0 then v.freeCL=v.freeCL+1 else v.paidCL=v.paidCL+1 end
        print("ELE_CC_COMPLETE",profile,case.name,seed,ev.t,ev.cost or 0)
      elseif k=="lightning_bolt" and (ev.cost or 0)==0 then v.freeLB=v.freeLB+1 end
    elseif ev.kind=="aura" and ev.dst==rr.us and ev.aura==cc and (ev.stacks or 0)>0 then
      v.procGrants=v.procGrants+1
    end
  end
  v.endMana=rr.us.power
  local c=rr.pressedBy or {}
  print(("ELE_CC_V0121 profile=%s case=%s seed=%d initial=%.2f firstMana=%.2f active=%d follow=%d completed=%d raw=%d boundary=%d freeLowStart=%d paidLowStart=%d freeCL=%d paidCL=%d freeLB=%d procGrants=%d lowSamples=%d procSamples=%d cost=%.2f endMana=%.2f lb=%d cl=%d fs=%d"):format(
    profile,case.name,seed,rr.us.power0,v.firstMana,v.active,v.follow,v.completion,v.raw,v.boundary,v.freeLowStart,v.paidLowStart,v.freeCL,v.paidCL,v.freeLB,v.procGrants,v.lowSamples,v.procSamples,v.landCost,v.endMana,c.lightning_bolt or 0,c.chain_lightning or 0,c.flame_shock or 0))
  if profile=="alternate" then
    assert.are.equal(0,v.raw-v.boundary,"substantive refusal")
    assert.is_true(v.active>=3 and v.follow>=2,"offensive progression")
  end
  return v
end
describe("Elemental v0.12.1 free Chain Lightning below 35% Mana",function()
  local opportunities=0
  for _,seed in ipairs({30417,30437,30461}) do
    for _,case in ipairs({
      {name="full",pct=1},
      {name="quarter",pct=0.25},
      {name="tenth",pct=0.10},
      {name="extreme",pct=0.05}
    }) do
      it(case.name.." seed "..seed,function()
        trial("shipped",seed,case)
        local old=trial("current",seed,case)
        local alt=trial("alternate",seed,case)
        opportunities=opportunities+alt.freeLowStart
        print(("ELE_CC_MATCH case=%s seed=%d oldFreeLow=%d newFreeLow=%d oldPaidLow=%d newPaidLow=%d oldFreeCL=%d newFreeCL=%d oldCompleted=%d newCompleted=%d oldCost=%.2f newCost=%.2f oldMana=%.2f newMana=%.2f"):format(
          case.name,seed,old.freeLowStart,alt.freeLowStart,old.paidLowStart,alt.paidLowStart,old.freeCL,alt.freeCL,old.completion,alt.completion,old.landCost,alt.landCost,old.endMana,alt.endMana))
      end)
    end
  end
  it("actual low-Mana free Chain Lightning opportunity exercised",function()
    assert.is_true(opportunities>0,"no natural opportunity; blocked, not improvement")
  end)
end)
