-- #35: full Arcane profiles; compare free Missile Barrage channel vs paid Fire Blast priority.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.mage_world").Arcane)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Mage/Current/APL_Mage_Arcane_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local fire="actions+=/fire_blast,if=action.fire_blast.known"
local missiles="actions+=/arcane_missiles,focus=1,if=action.arcane_missiles.known&buff.missile_barrage.up"
local first=assert(current:find(fire.."\n"..missiles,1,true))
local last=first+#fire+#missiles
local alternate=current:sub(1,first-1)..missiles.."\n"..fire..current:sub(last+1)
assert.is_true(alternate~=current)
local offence={arcane_wrath=true,arcane_blast=true,arcane_missiles=true,fire_blast=true,
  pyroblast=true,blizzard=true,scorch=true,frostbolt=true,fireball=true}
local function trial(profile,seed,case)
  local initial=stock.WORLD.max*case.pct
  local C=setmetatable({WORLD=setmetatable({power=initial,mobHealth=1000000000,
    distance=case.range,attackers=1},{__index=stock.WORLD})},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Mage_Arcane","APLForever-Arcane-proc-"..profile,
      profile=="current" and current or alternate,C.PACK)
    for _,k in ipairs({"precombat","default","mana_recovery","major_cooldowns","aoe","final_fallback"}) do assert.is_table(lists[k]) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  assert.are.same({},H.errors)
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false;t.minor_cooldowns.value=false;t.defensives.value=false
  t.interrupts.value=false;if t.movement then t.movement.value=false end
  local mb=assert(H.Hekili.Class.auras.missile_barrage.id)
  local cc=assert(H.Hekili.Class.auras.clearcasting.id)
  local v={offence=0,follow=0,raw=0,terminal=0,terminalAccepted=0,fireWithProc=0,
    paidFireWithProc=0,procMissiles=0,freeMissiles=0,ccRetained=0,firstMana=-1,
    firstTime=-1,totalCost=0,channels=0,cut=0,full=0,unclosed=0}
  local installed=false
  local rr=loop.run(L,seed,{duration=100,on=function(w)
    if installed then return end
    installed=true
    local old=w.W.press
    w.W.press=function(e,key,p)
      if e~=w.us or w.W.t<loop.PULL then return old(e,key,p) end
      local stop=e.stopped==true
      local proc=e.auras[mb]~=nil
      local clear=e.auras[cc]~=nil
      local mana=e.power
      local ok,why=old(e,key,p)
      if not ok then
        v.raw=v.raw+1;if stop then v.terminal=v.terminal+1 end
        print("ARCANE_PROC_REFUSAL",profile,case.name,seed,w.W.t,key,why,tostring(stop),mana)
      elseif stop then v.terminalAccepted=v.terminalAccepted+1
      elseif offence[key] then
        v.offence=v.offence+1
        if v.firstMana<0 then v.firstMana=mana;v.firstTime=w.W.t end
        if v.offence>1 then v.follow=v.follow+1 end
        v.totalCost=v.totalCost+(p.cost or 0)
        if key=="fire_blast" and proc then
          v.fireWithProc=v.fireWithProc+1
          if (p.cost or 0)>0 then v.paidFireWithProc=v.paidFireWithProc+1 end
        elseif key=="arcane_missiles" and proc then
          v.procMissiles=v.procMissiles+1
          if (p.cost or 0)==0 then v.freeMissiles=v.freeMissiles+1 end
          if clear and e.auras[cc] then v.ccRetained=v.ccRetained+1 end
          assert.is_nil(e.auras[mb],"source proc must be consumed at channel start")
          print("ARCANE_PROC_CHANNEL",profile,case.name,seed,w.W.t,mana,p.cost or 0,tostring(clear),tostring(e.auras[cc]~=nil))
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.is_true(math.abs(initial-rr.us.power0)<1e-6)
  local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
  assert.are.equal(raw,v.raw)
  local ids={};for _,id in ipairs(assert(C.IDS.arcane_missiles)) do ids[id]=true end
  local grants=0
  local finish=nil
  for _,ev in ipairs(rr.W.truth) do
    if ev.src==rr.us and ev.kind=="cast" and ids[ev.spell] and ev.chanEnds then
      v.channels=v.channels+1;finish=ev.chanEnds
    elseif ev.src==rr.us and ev.kind=="channelStop" and ids[ev.spell] and finish then
      if ev.t<finish-1e-7 then v.cut=v.cut+1 else v.full=v.full+1 end
      finish=nil
    elseif ev.kind=="aura" and ev.dst==rr.us and ev.aura==mb and (ev.stacks or 0)>0 then grants=grants+1 end
  end
  v.unclosed=v.channels-v.cut-v.full
  local c=rr.pressedBy or {}
  print(("ARCANE_PROC_V0121 profile=%s case=%s seed=%d mana0=%.2f firstMana=%.2f firstTime=%.3f accepted=%d offence=%d follow=%d raw=%d terminal=%d afterStop=%d fire=%d fireWithProc=%d paidFireWithProc=%d missiles=%d procMissiles=%d freeMissiles=%d ccRetained=%d procEvents=%d channels=%d full=%d cut=%d unclosed=%d blast=%d wrath=%d scorch=%d frostbolt=%d cost=%.2f endMana=%.2f"):format(
    profile,case.name,seed,rr.us.power0,v.firstMana,v.firstTime,rr.presses,v.offence,v.follow,v.raw,v.terminal,v.terminalAccepted,c.fire_blast or 0,v.fireWithProc,v.paidFireWithProc,c.arcane_missiles or 0,v.procMissiles,v.freeMissiles,v.ccRetained,grants,v.channels,v.full,v.cut,v.unclosed,c.arcane_blast or 0,c.arcane_wrath or 0,c.scorch or 0,c.frostbolt or 0,v.totalCost,rr.us.power))
  assert.is_true(v.offence>=3,"whole-chain offensive progression failed")
  assert.is_true(v.follow>=2)
  if profile=="alternate" then assert.are.equal(0,v.raw,"alternative raw refusal") end
  v.counts=c;v.endMana=rr.us.power
  return v
end
describe("Arcane v0.12.1 free Missile Barrage priority",function()
  local opportunity=0
  for _,seed in ipairs({30417,30437,30461}) do
    for _,case in ipairs({
      {name="near_full",range=15,pct=1},
      {name="near_quarter",range=15,pct=0.25},
      {name="near_extreme",range=15,pct=0.05},
      {name="ranged_quarter",range=25,pct=0.25}
    }) do
      it(case.name.." seed "..seed,function()
        trial("shipped",seed,case)
        local old=trial("current",seed,case)
        local new=trial("alternate",seed,case)
        opportunity=opportunity+old.paidFireWithProc
        if case.range==25 then
          assert.are.equal(0,old.counts.fire_blast or 0)
          assert.are.equal(0,new.counts.fire_blast or 0)
          assert.are.same(old.counts,new.counts,"out-of-range Fire Blast priority changed")
        end
        print(("ARCANE_PROC_MATCH case=%s seed=%d currentPaidFireProc=%d alternatePaidFireProc=%d currentFreeMissiles=%d alternateFreeMissiles=%d currentFull=%d alternateFull=%d currentCut=%d alternateCut=%d currentOffence=%d alternateOffence=%d currentCost=%.2f alternateCost=%.2f currentEndMana=%.2f alternateEndMana=%.2f"):format(case.name,seed,old.paidFireWithProc,new.paidFireWithProc,old.freeMissiles,new.freeMissiles,old.full,new.full,old.cut,new.cut,old.offence,new.offence,old.totalCost,new.totalCost,old.endMana,new.endMana))
      end)
    end
  end
  it("paid Fire Blast with true Missile Barrage was actually exercised",function()
    assert.is_true(opportunity>0,"no actual priority opportunity: blocked, not improvement")
  end)
end)
