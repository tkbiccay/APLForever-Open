-- Proposed breadth #30: isolate 4 vs 5 CP Rip threshold and targettarget context.
-- Source v0.11.0 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- No synthetic points, bleed damage, facing, or client DPS claims.
local loop=require("Game.harness.loop")
local F=assert(require("Forever.helpers.druid_loop_world").Feral)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local apl={
  current=read("roles/Druid/Archive/APL_Druid_Feral_DPS_v1.0_Draft.txt"),
  four=read("roles/Druid/Archive/APL_Druid_Feral_v1.4_Draft.txt")
}
local n
apl.five,n=apl.four:gsub("action%.rip%.known&combo_points%.current>=4&","action.rip.known&combo_points.current>=5&")
assert(n==1,"exact single threshold counterfactual")
local function trial(profile,seed,seconds,targeted)
  local obs={}
  for k,v in pairs(F.OBSERVE) do obs[k]=v end
  -- Published observer knob controls targettarget answer, NOT geometric facing.
  obs.notTargeted=not targeted
  local C=setmetatable({OBSERVE=obs,WORLD=setmetatable({
    distance=4,mobHealth=1000000000,power=F.WORLD.max
  },{__index=F.WORLD})},{__index=F})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Feral",
      "APLForever-Feral-CP-"..profile,apl[profile],C.PACK)
    for _,k in ipairs({"default","precombat","cat","cat_melee","finish","procs","builders","defensives","caster"}) do
      assert.is_table(lists[k])
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    -- Protected Current has the same three historical health compiler errors.
    assert.are.equal(profile=="current" and 3 or 0,#H.errors)
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false;toggles.minor_cooldowns.value=false
  toggles.defensives.value=false;toggles.movement.value=false
  toggles.interrupts.value=false
  local A=H.Hekili.Class.auras
  local id=assert(A.rip.id)
  local rakeID=assert(A.rake.id)
  local t={accepted=0,raw=0,activeRefused=0,terminalRefused=0,terminalAccepted=0,
    offense=0,follow=0,rip4=0,rip5=0,ripOther=0,ripCP=0,ripCost=0,ripApplied=0,
    ripAvoid=0,bite=0,invalid=0,claw=0,shred=0,rake=0,cpWaste=0,
    maxCP=0,minEnergy=100,firstRip=-1,first4=-1,actualTargeted=0,postRip=0}
  local installed=false
  local rr=loop.run(L,seed,{duration=seconds,on=function(w)
    if installed then return end
    installed=true
    local old=w.W.press
    w.W.press=function(e,key,p)
      if e~=w.us or w.W.t<loop.PULL then return old(e,key,p) end
      local halted=e.stopped==true
      local cp=w.W.res(e,4)
      local energy=e.power
      local actual=e.target and e.target.target==e
      local prior=e.target and e.target.auras[id]
      local expiry=prior and prior.expires
      if not halted and not t.firstEnergy then t.firstEnergy=energy;t.firstKey=key;t.firstTime=w.W.t end
      if not halted and cp==4 and t.first4<0 then t.first4=w.W.t end
      local ok,why=old(e,key,p)
      if not ok then
        t.raw=t.raw+1
        if halted then t.terminalRefused=t.terminalRefused+1 else t.activeRefused=t.activeRefused+1 end
        print("FERAL_CP_REFUSAL",profile,seed,seconds,tostring(targeted),w.W.t,key,why,cp,energy,tostring(halted))
      elseif halted then
        t.terminalAccepted=t.terminalAccepted+1
        print("FERAL_CP_TERMINAL_ACCEPT",profile,seed,seconds,tostring(targeted),w.W.t,key,cp,energy)
      else
        t.accepted=t.accepted+1
        if actual then t.actualTargeted=t.actualTargeted+1 end
        local after=w.W.res(e,4)
        t.maxCP=math.max(t.maxCP,cp,after)
        t.minEnergy=math.min(t.minEnergy,energy)
        if t.firstRip>=0 and key~="rip" then t.postRip=t.postRip+1 end
        if key=="claw" or key=="shred" or key=="rake" or key=="rip" or key=="ferocious_bite" then
          t.offense=t.offense+1
          if t.offense>1 then t.follow=t.follow+1 end
        end
        if key=="claw" or key=="shred" or key=="rake" then
          t[key]=t[key]+1
          if cp==5 then t.cpWaste=t.cpWaste+1 end
        end
        if key=="rip" then
          if cp==4 then t.rip4=t.rip4+1 elseif cp==5 then t.rip5=t.rip5+1 else t.ripOther=t.ripOther+1 end
          t.ripCP=t.ripCP+cp;t.ripCost=t.ripCost+(p.cost or 0)
          if t.firstRip<0 then t.firstRip=w.W.t end
          local a=e.target and e.target.auras[id]
          if after==0 and cp>0 and a and (not expiry or a.expires>expiry) then
            t.ripApplied=t.ripApplied+1
          elseif cp>0 and after==cp and e.lastHit and e.lastHit.act~="WOUND" then
            t.ripAvoid=t.ripAvoid+1
          else t.invalid=t.invalid+1 end
        elseif key=="ferocious_bite" then
          t.bite=t.bite+1
          if not (cp>0 and (after==0 or (after==cp and e.lastHit and e.lastHit.act~="WOUND"))) then
            t.invalid=t.invalid+1
          end
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.are.equal(C.WORLD.power,rr.us.power0)
  assert.is_number(t.firstEnergy)
  local raw=0;for _,v in pairs(rr.refused or {}) do raw=raw+v end
  assert.are.equal(raw,t.raw,"raw refused count must match")
  assert.are.equal(t.raw,t.activeRefused+t.terminalRefused)
  local pull,stop=loop.PULL,loop.PULL+seconds
  local up,untilTime,ripAuras,rakeAuras=0,pull,0,0
  for _,ev in ipairs(rr.W.truth) do
    if ev.kind=="aura" and ev.dst and ev.dst.kind=="mob" and ev.t>=pull and ev.t<stop and (ev.stacks or 0)>0 then
      if ev.aura==id then
        ripAuras=ripAuras+1
        local start=math.max(ev.t,untilTime)
        local finish=math.min(ev.expires,stop)
        up=up+math.max(0,finish-start)
        untilTime=math.max(untilTime,finish)
      elseif ev.aura==rakeID then rakeAuras=rakeAuras+1 end
    end
  end
  print(("FERAL_CP_TRUTH profile=%s seed=%d seconds=%d targetedProxy=%s actualTargetingAccepted=%d initial=%.2f firstEnergy=%.2f firstKey=%s firstTime=%.3f accepted=%d raw=%d activeRefused=%d terminalRefused=%d terminalAccepted=%d rip4=%d rip5=%d ripOther=%d ripCP=%d ripCost=%.2f ripApplied=%d ripAvoid=%d ripAuras=%d ripSeconds=%.3f rakeAuras=%d first4=%.3f firstRip=%.3f bite=%d claw=%d shred=%d rake=%d capBuilder=%d maxCP=%d minEnergy=%.2f postRip=%d follow=%d invalid=%d"):format(
    profile,seed,seconds,tostring(targeted),t.actualTargeted,rr.us.power0,t.firstEnergy,tostring(t.firstKey),t.firstTime,
    t.accepted,t.raw,t.activeRefused,t.terminalRefused,t.terminalAccepted,t.rip4,t.rip5,t.ripOther,t.ripCP,t.ripCost,
    t.ripApplied,t.ripAvoid,ripAuras,up,rakeAuras,t.first4,t.firstRip,t.bite,t.claw,t.shred,t.rake,t.cpWaste,t.maxCP,
    t.minEnergy,t.postRip,t.follow,t.invalid))
  t.up=up;t.ripAuras=ripAuras
  assert.is_true(up>=0 and up<=seconds+1e-6)
  return t
end
describe("Proposed #30 Feral isolated Rip CP threshold and targettarget proxy",function()
  for _,seed in ipairs({30417,30437,30461}) do
    for _,case in ipairs({{20,true},{95,true},{95,false}}) do
      local seconds,targeted=case[1],case[2]
      it(("seed %d %ds targetedProxy=%s"):format(seed,seconds,tostring(targeted)),function()
        local shipped=trial("shipped",seed,seconds,targeted)
        local current=trial("current",seed,seconds,targeted)
        local four=trial("four",seed,seconds,targeted)
        local five=trial("five",seed,seconds,targeted)
        assert.is_true(shipped.follow>=3 and current.follow>=3)
        for _,x in ipairs({four,five}) do
          assert.are.equal(0,x.activeRefused)
          assert.are.equal(0,x.invalid)
          assert.is_true(x.maxCP<=5)
          assert.is_true(x.follow>=3)
          assert.are.equal(x.rip4+x.rip5+x.ripOther,x.ripApplied+x.ripAvoid)
          if seconds==95 then
            assert.is_true(x.ripApplied>=1,"no real Rip effect in sustained trial")
            assert.is_true(x.postRip>=3)
          end
        end
        assert.are.equal(0,four.ripOther)
        assert.are.equal(0,five.ripOther)
        assert.are.equal(0,five.rip4,"five-point guard failed")
        if seconds==95 then
          assert.is_true(four.rip4>=1,"four-point opportunity unexercised")
          assert.is_true(five.rip5>=1,"five-point opportunity unexercised")
        end
      end)
    end
  end
end)
