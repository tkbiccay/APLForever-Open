-- Proposed breadth #29: real Slice and Dice resource/finisher opportunity cost.
-- Released Forever v0.11.0; no synthetic haste or damage claim.
local loop=require("Game.harness.loop")
local R=assert(require("Forever.helpers.rogue_world").Combat)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local apl={
  current=read("roles/Rogue/Current/APL_Rogue_Combat_v1.0_Draft.txt"),
  candidate=read("roles/Rogue/Candidates/APL_Rogue_Combat_v1.1_Draft.txt")
}
-- Single isolated in-memory hypothesis, never a replacement or published APL.
local before="combo_points.current>=1&(target.is_boss|active_enemies>=2)"
local after="combo_points.current>=1&(target.is_boss|active_enemies>=2|combo_points.current>=3&active_enemies=1)"
local n
apl.solo,n=apl.candidate:gsub(before:gsub("([^%w])","%%%1"),function() return after end)
assert(n==1,"expected exactly one protected Slice and Dice guard")
local function trial(profile,seed,seconds)
  local C=setmetatable({WORLD=setmetatable({power=R.WORLD.max,
    mobHealth=1000000000,distance=4},{__index=R.WORLD})},{__index=R})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors);assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Rogue_Combat",
      "APLForever-SnD-"..profile,apl[profile],C.PACK)
    for _,k in ipairs({"default","precombat","opener","major_cooldowns","final_fallback"}) do assert.is_table(lists[k]) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false;toggles.minor_cooldowns.value=false
  toggles.defensives.value=false;toggles.interrupts.value=false
  if toggles.movement then toggles.movement.value=false end
  local id=assert(H.Hekili.Class.auras.slice_and_dice.id)
  local t={accepted=0,refused=0,activeRefused=0,snd=0,sndCP=0,sndCost=0,
    sndGain=0,sndInvalid=0,evic=0,evicCP=0,evicSpent=0,evicAvoid=0,
    postSnd=0,minEnergy=100,firstSnd=-1,afterStop=0}
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
      local prior=e.auras[id]
      local expiry=prior and prior.expires
      local ok,why=old(e,key,p)
      if not ok then
        t.refused=t.refused+1
        if not halted then t.activeRefused=t.activeRefused+1 end
        print("SND_RAW_REFUSAL",profile,seed,seconds,w.W.t,key,why,tostring(halted))
      elseif halted then t.afterStop=t.afterStop+1
      else
        t.accepted=t.accepted+1
        t.minEnergy=math.min(t.minEnergy,energy)
        if t.snd>0 and key~="slice_and_dice" then t.postSnd=t.postSnd+1 end
        if key=="slice_and_dice" then
          t.snd=t.snd+1;t.sndCP=t.sndCP+cp;t.sndCost=t.sndCost+(p.cost or 0)
          if t.firstSnd<0 then t.firstSnd=w.W.t end
          local a=e.auras[id]
          local fresh=a and (not expiry or a.expires>expiry)
          if fresh then t.sndGain=t.sndGain+1 end
          if not fresh or cp<1 or w.W.res(e,4)~=0 then t.sndInvalid=t.sndInvalid+1 end
        elseif key=="eviscerate" then
          t.evic=t.evic+1;t.evicCP=t.evicCP+cp
          local now=w.W.res(e,4)
          if now==0 then t.evicSpent=t.evicSpent+1
          elseif now==cp then t.evicAvoid=t.evicAvoid+1
          else error("unexpected Eviscerate point transition") end
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  assert.are.equal(C.WORLD.power,rr.us.power0)
  local raw=0;for _,v in pairs(rr.refused or {}) do raw=raw+v end
  assert.are.equal(raw,t.refused,"raw refusal count must match")
  local pull,stop=loop.PULL,loop.PULL+seconds
  local up,untilTime=0,pull
  local main,off,mainSpeed,offSpeed=0,0,nil,nil
  local auraEvents=0
  for _,ev in ipairs(rr.W.truth) do
    if ev.kind=="aura" and ev.dst==rr.us and ev.aura==id and ev.t>=pull and ev.t<stop then
      if ev.stacks>0 then
        auraEvents=auraEvents+1
        local start=math.max(ev.t,untilTime)
        local finish=math.min(ev.expires,stop)
        up=up+math.max(0,finish-start)
        untilTime=math.max(untilTime,finish)
      end
    elseif ev.kind=="swing" and ev.src==rr.us and ev.t>=pull and ev.t<stop then
      if ev.hand==1 then main=main+1;mainSpeed=ev.speed or mainSpeed
      elseif ev.hand==2 then off=off+1;offSpeed=ev.speed or offSpeed end
    end
  end
  print(("SND_TRUTH profile=%s seed=%d seconds=%d accepted=%d raw=%d activeRefused=%d afterStopAccepted=%d snd=%d cpSpent=%d energyCost=%.1f auraEvents=%d buffSeconds=%.3f firstSnd=%.3f evic=%d evicCP=%d evicSpent=%d evicAvoid=%d postSnd=%d minPressEnergy=%.1f main=%d off=%d mainSpeed=%s offSpeed=%s"):format(
    profile,seed,seconds,t.accepted,t.refused,t.activeRefused,t.afterStop,t.snd,t.sndCP,t.sndCost,auraEvents,up,t.firstSnd,t.evic,t.evicCP,t.evicSpent,t.evicAvoid,t.postSnd,t.minEnergy,main,off,tostring(mainSpeed),tostring(offSpeed)))
  assert.are.equal(0,t.sndInvalid,"accepted SnD must grant/extend actual aura and spend real points")
  assert.are.equal(t.snd,t.sndGain)
  assert.is_true(t.accepted>=4,"no legal follow-on sequence")
  assert.is_true(up>=0 and up<=seconds+1e-6)
  t.up=up;t.auraEvents=auraEvents
  return t
end
describe("Proposed #29 Solo SnD opportunity cost; not a damage sim",function()
  for _,seed in ipairs({30417,30437,30461}) do
    for _,seconds in ipairs({20,95}) do
      it(("matched seed %d duration %ds"):format(seed,seconds),function()
        local shipped=trial("shipped",seed,seconds)
        local current=trial("current",seed,seconds)
        local candidate=trial("candidate",seed,seconds)
        local solo=trial("solo",seed,seconds)
        assert.are.equal(0,candidate.activeRefused)
        assert.are.equal(0,solo.activeRefused)
        assert.is_true(solo.snd>=1,"hypothesis did not exercise SnD")
        assert.is_true(solo.postSnd>=3,"fewer than three subsequent legal actions")
        assert.is_true(solo.up>0)
        assert.are.equal(0,candidate.snd,"existing solo guard control changed")
        assert.are.equal(0,current.snd,"existing solo guard control changed")
        assert.is_true(shipped.snd>=1,"shipped control did not exercise SnD")
      end)
    end
  end
end)
