-- Proposed #34: whole Frost profiles, single-target Cone of Cold Mana reserve.
-- Source-world costs and proc effects, not live DPS or mitigation.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.mage_world").Frost)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Mage/Current/APL_Mage_Frost_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local anchor="actions+=/cone_of_cold,focus=1,if="
local start=assert(current:find(anchor,1,true))
assert.is_nil(current:find(anchor,start+#anchor,1,true))
local reserve=current:sub(1,start+#anchor-1).."(active_enemies>=2|mana.pct_lo>=25)&"..current:sub(start+#anchor)
local offence={frostbolt=true,fireball=true,ice_lance=true,cone_of_cold=true,blizzard=true}
local function trial(profile,seed,case)
  local initial=stock.WORLD.max*case.pct
  local C=setmetatable({WORLD=setmetatable({power=initial,mobHealth=1000000000,
    attackers=1,distance=case.range},{__index=stock.WORLD})},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Mage_Frost","APLForever-Frost-reserve-"..profile,
      profile=="current" and current or reserve,C.PACK)
    for _,k in ipairs({"precombat","default","defensives","mana_recovery","major_cooldowns","aoe","final_fallback"}) do assert.is_table(lists[k]) end
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
  local A=H.Hekili.Class.auras
  local fof=assert(A.fingers_of_frost.id);local chill=assert(A.winters_chill.id)
  local function stacks(e,id)
    local a=e and e.auras[id]
    return a and a.stacks or 0
  end
  local v={active=0,offence=0,follow=0,raw=0,terminal=0,afterStop=0,cone=0,
    coneLow=0,coneCost=0,coneAt5=0,coneDrop=0,coneFoF=0,lanceFoF=0,
    totalCost=0,firstMana=-1,firstTime=-1,minMana=initial,lowSamples=0}
  local installed=false
  local rr=loop.run(L,seed,{duration=100,on=function(w,_,time)
    if not installed then
      installed=true
      local press=w.W.press
      w.W.press=function(e,key,p)
        if e~=w.us or w.W.t<loop.PULL then return press(e,key,p) end
        local stop=e.stopped==true
        local mana=e.power
        local cp=stacks(e.target,chill)
        local fp=stacks(e,fof)
        local ok,why=press(e,key,p)
        if not ok then
          v.raw=v.raw+1;if stop then v.terminal=v.terminal+1 end
          print("FROST_RESERVE_REFUSAL",profile,case.name,seed,w.W.t,key,why,tostring(stop),mana)
        elseif stop then v.afterStop=v.afterStop+1
        else
          v.active=v.active+1
          if v.firstMana<0 then v.firstMana=mana;v.firstTime=w.W.t end
          if offence[key] then
            v.offence=v.offence+1;v.totalCost=v.totalCost+(p.cost or 0)
            if v.offence>1 then v.follow=v.follow+1 end
          end
          if key=="cone_of_cold" then
            v.cone=v.cone+1;v.coneCost=v.coneCost+(p.cost or 0)
            if mana<stock.WORLD.max*0.25 then v.coneLow=v.coneLow+1 end
            if cp>=5 then v.coneAt5=v.coneAt5+1 end
            if cp>0 and stacks(e.target,chill)==0 then v.coneDrop=v.coneDrop+1 end
            if fp>0 then v.coneFoF=v.coneFoF+1 end
            print("FROST_RESERVE_CONE",profile,case.name,seed,w.W.t,mana,p.cost or 0,cp,stacks(e.target,chill),fp,stacks(e,fof))
          elseif key=="ice_lance" and fp>0 then v.lanceFoF=v.lanceFoF+1 end
        end
        return ok,why
      end
    end
    if time>=loop.PULL and not w.us.stopped then
      v.minMana=math.min(v.minMana,w.us.power)
      if w.us.power<stock.WORLD.max*0.25 then v.lowSamples=v.lowSamples+1 end
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.is_true(math.abs(initial-rr.us.power0)<1e-6,"initial Mana differs")
  local raw=0;for _,n in pairs(rr.refused or {}) do raw=raw+n end
  assert.are.equal(raw,v.raw,"raw refusal trace incomplete")
  local counts=rr.pressedBy or {}
  local grants,peak,chillEvents=0,0,0
  for _,e in ipairs(rr.W.truth) do
    if e.kind=="aura" and e.dst==rr.us and e.aura==fof and (e.stacks or 0)>0 then
      grants=grants+1;peak=math.max(peak,e.stacks)
    elseif e.kind=="aura" and e.dst and e.dst.kind=="mob" and e.aura==chill and (e.stacks or 0)>0 then
      chillEvents=chillEvents+1
    end
  end
  print(("FROST_RESERVE_V0121 profile=%s case=%s seed=%d range=%d mana0=%.2f firstMana=%.2f firstTime=%.3f accepted=%d traced=%d offence=%d follow=%d raw=%d terminal=%d afterStop=%d cone=%d coneLow=%d coneAt5=%d coneDrop=%d coneFoF=%d coneCost=%.2f lance=%d lanceFoF=%d frostbolt=%d fofEvents=%d peakFoF=%d chillEvents=%d tracedOffenceCost=%.2f minMana=%.2f lowSamples=%d endMana=%.2f"):format(
    profile,case.name,seed,case.range,rr.us.power0,v.firstMana,v.firstTime,rr.presses,v.active,v.offence,v.follow,v.raw,v.terminal,v.afterStop,counts.cone_of_cold or 0,v.coneLow,v.coneAt5,v.coneDrop,v.coneFoF,v.coneCost,counts.ice_lance or 0,v.lanceFoF,counts.frostbolt or 0,grants,peak,chillEvents,v.totalCost,v.minMana,v.lowSamples,rr.us.power))
  assert.is_true(v.offence>=3,"whole-chain offensive progression failed")
  assert.is_true(v.follow>=2)
  if profile=="reserve" then assert.are.equal(0,v.raw,"reserve profile refused an action") end
  v.counts=counts;v.endMana=rr.us.power
  return v
end
describe("Frost v0.12.1 single-target Cone reserve hypothesis",function()
  local opportunity=0
  for _,seed in ipairs({30417,30437,30461}) do
    for _,case in ipairs({
      {name="melee_full",range=4,pct=1},
      {name="melee_quarter",range=4,pct=0.25},
      {name="melee_tenth",range=4,pct=0.10},
      {name="melee_extreme",range=4,pct=0.05},
      {name="ranged_quarter",range=25,pct=0.25}
    }) do
      it(case.name.." seed "..seed,function()
        trial("shipped",seed,case)
        local old=trial("current",seed,case)
        local new=trial("reserve",seed,case)
        opportunity=opportunity+old.coneLow
        if case.range==25 then
          assert.are.equal(0,old.cone);assert.are.equal(0,new.cone)
          assert.are.same(old.counts,new.counts,"ranged fallback altered")
        end
        print(("FROST_RESERVE_MATCH case=%s seed=%d currentLowCone=%d reserveLowCone=%d currentCost=%.2f reserveCost=%.2f currentEndMana=%.2f reserveEndMana=%.2f currentOffence=%d reserveOffence=%d"):format(case.name,seed,old.coneLow,new.coneLow,old.totalCost,new.totalCost,old.endMana,new.endMana,old.offence,new.offence))
      end)
    end
  end
  it("actual low-Mana Cone opportunity was exercised",function()
    assert.is_true(opportunity>0,"no observed low-Mana Cone casts: hypothesis not exercised")
  end)
end)
