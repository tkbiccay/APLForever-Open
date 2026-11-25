-- Proposed breadth #28: distinguish actual world stop from active Garrote failures.
-- Published Hekili Forever v0.11.0 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Preserve raw refusals; no synthetic stealth, injected CP or changed world effects.
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
local function trial(profile,seed,seconds,pct)
  local C=setmetatable({WORLD=setmetatable({power=R.WORLD.max*pct,
    mobHealth=1000000000,distance=4},{__index=R.WORLD})},{__index=R})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Rogue_Combat",
      "APLForever-Rogue-Terminal-"..profile,apl[profile],C.PACK)
    for _,k in ipairs({"default","precombat","opener","major_cooldowns","final_fallback"}) do
      assert.is_table(lists[k])
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false; toggles.minor_cooldowns.value=false
  toggles.defensives.value=false; toggles.interrupts.value=false
  if toggles.movement then toggles.movement.value=false end
  local A=H.Hekili.Class.auras
  local ids={assert(A.stealth.id),assert(A.vanish.id),assert(A.ghostly_strike_next.id)}
  local t={raw=0,active=0,afterStop=0,terminalGarrote=0,badTerminal=0,
    accepted=0,offense=0,follow=0,firstActive=nil,stoppedAccepted=0}
  local installed=false
  local rr=loop.run(L,seed,{duration=seconds,on=function(w)
    if installed then return end
    installed=true
    local old=w.W.press
    w.W.press=function(e,key,p)
      if e~=w.us or w.W.t<loop.PULL then return old(e,key,p) end
      -- BEFORE press, find actual stop truth, not merely wall-clock equality.
      local now=w.W.t
      local stop
      for i=#w.W.truth,1,-1 do
        local ev=w.W.truth[i]
        if ev.kind=="stop" then stop=ev.t;break end
      end
      local halted=e.stopped==true
      local stealth=e.auras[ids[1]]~=nil
      local vanish=e.auras[ids[2]]~=nil
      local ghost=e.auras[ids[3]]~=nil
      local power=e.power
      local cp=w.W.res(e,4)
      local output=H.Hekili.Engine.Output.Primary
      local rec=output and output.recs and output.recs[1]
      local icon=rec and rec.actionName or "none"
      local ok,why=old(e,key,p)
      if ok then
        if stop then t.stoppedAccepted=t.stoppedAccepted+1
        else
          t.accepted=t.accepted+1
          if key=="sinister_strike" or key=="shank" or key=="eviscerate"
            or key=="garrote" or key=="riposte" or key=="slice_and_dice" then
            t.offense=t.offense+1
            if t.offense>1 then t.follow=t.follow+1 end
          end
        end
      else
        t.raw=t.raw+1
        local context=("ROGUE_TERMINAL_TRACE profile=%s seed=%d seconds=%.1f energy=%.2f t=%.6f stop=%s stopped=%s action=%s icon=%s why=%s stealth=%s vanish=%s ghost=%s trueEnergy=%.2f cp=%d"):format(
          profile,seed,seconds,pct,now,tostring(stop),tostring(halted),
          tostring(key),tostring(icon),tostring(why),tostring(stealth),
          tostring(vanish),tostring(ghost),power,cp)
        if stop then
          t.afterStop=t.afterStop+1
          print(context)
          if key=="garrote" and why=="requires:not stealthed" and
            halted and not stealth and not vanish and not ghost and stop<=now+1e-6 then
            t.terminalGarrote=t.terminalGarrote+1
          else t.badTerminal=t.badTerminal+1 end
        else
          t.active=t.active+1
          if not t.firstActive then t.firstActive=context;print(context) end
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  local raw=0
  for reason,n in pairs(rr.refused or {}) do
    raw=raw+n
    print("ROGUE_RAW_REFUSAL",profile,seed,seconds,pct,reason,n)
  end
  assert.are.equal(raw,t.raw,"no raw refusal may disappear")
  assert.are.equal(t.raw,t.active+t.afterStop)
  local stops=0
  for _,ev in ipairs(rr.W.truth) do if ev.kind=="stop" then stops=stops+1 end end
  assert.are.equal(1,stops,"fixture never emitted its actual stop")
  print(("ROGUE_TERMINAL_SUMMARY profile=%s seed=%d seconds=%.1f energy=%.2f active=%d afterStop=%d terminalGarrote=%d otherTerminal=%d raw=%d acceptedActive=%d acceptedAfterStop=%d offense=%d follow=%d"):format(
    profile,seed,seconds,pct,t.active,t.afterStop,t.terminalGarrote,
    t.badTerminal,raw,t.accepted,t.stoppedAccepted,t.offense,t.follow))
  return t
end
describe("Proposed #28 real combat-end event versus live Garrote legality",function()
  -- Shift the stop by one 5-Hz tick either way, no change to spell logic.
  -- No terminal rejection is forgiven; residual stays explicitly unresolved.
  for _,seconds in ipairs({94.8,95,95.2}) do
    it(("seed 30437 low Energy stop %.1f"):format(seconds),function()
      local shipped=trial("shipped",30437,seconds,0.25)
      local current=trial("current",30437,seconds,0.25)
      local candidate=trial("candidate",30437,seconds,0.25)
      assert.is_true(shipped.follow>=3)
      assert.is_true(current.active>=10,"historic active Garrote regression not reproduced")
      assert.are.equal(0,candidate.active,"new active-combat refusal, not terminal")
      assert.are.equal(0,candidate.badTerminal,"unexpected refusal after stop, investigate")
      assert.is_true(candidate.follow>=3)
      assert.is_true(candidate.afterStop<=1,"repeated terminal refusals")
      if seconds==95 then
        assert.are.equal(1,candidate.terminalGarrote,
          "historical raw terminal rejection changed: investigate rather than waive")
      end
    end)
  end
  for _,case in ipairs({{30417,95,0.25},{30437,95,1},{30437,20,1}}) do
    local seed,seconds,pct=unpack(case)
    it(("control seed %d %.1fs resource %.2f"):format(seed,seconds,pct),function()
      local shipped=trial("shipped",seed,seconds,pct)
      local current=trial("current",seed,seconds,pct)
      local candidate=trial("candidate",seed,seconds,pct)
      assert.is_true(shipped.follow>=3)
      assert.are.equal(0,candidate.active)
      assert.are.equal(0,candidate.badTerminal)
      assert.is_true(candidate.follow>=3)
      if pct==1 then assert.are.equal(0,current.active) end
    end)
  end
end)
