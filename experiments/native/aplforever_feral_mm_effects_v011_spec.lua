-- Proposed breadth #26/#27, NOT completed until source evidence and merge.
-- Pinned v0.11.0. Real source aura/points and cast start/finish events.
-- No inferred bleed ticks, pet damage, DPS, actual solo aggro or clipping.
local loop=require("Game.harness.loop")
local F=assert(require("Forever.helpers.druid_loop_world").Feral)
local M=assert(require("Forever.helpers.hunter_world").MarksmanshipTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local files={
  feral={current="roles/Druid/Archive/APL_Druid_Feral_DPS_v1.0_Draft.txt",
    candidate="roles/Druid/Archive/APL_Druid_Feral_v1.4_Draft.txt"},
  mm={current="roles/Hunter/Current/APL_Hunter_Marksmanship_DPS_v1.0_Draft.txt",
    candidate="roles/Hunter/Candidates/APL_Hunter_Marksmanship_v1.1_Draft.txt"},
}
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
local function trial(kind,profile,seed,duration,pct)
  local stock=kind=="feral" and F or M
  local world=setmetatable({distance=kind=="feral" and 4 or 12,
    mobHealth=1000000000,power=stock.WORLD.max*pct},{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C);local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  if profile~="shipped" then
    local lists,warnings=H.Hekili:ImportSimcAPL(
      kind=="feral" and "Druid_Feral" or "Hunter_Marksmanship",
      "APLForever-Effects-"..kind.."-"..profile,read(files[kind][profile]),C.PACK)
    local names=kind=="feral" and
      {"precombat","default","cat","cat_melee","finish","procs","builders","defensives","caster"} or
      {"precombat","default","ranged","melee","aoe","major_cooldowns"}
    for _,name in ipairs(names) do assert.is_table(lists[name],"missing list "..name) end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,k),k) end
    -- Existing source negative control: full Feral Current has three known
    -- health.pct errors (PR #61/#79). Not a clean import or approval.
    assert.are.equal(kind=="feral" and profile=="current" and 3 or 0,#H.errors)
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false
  toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  toggles.movement.value=false
  local A=H.Hekili.Class.auras
  local rip=kind=="feral" and assert(A.rip.id)
  local rake=kind=="feral" and assert(A.rake.id)
  local t={refused=0,first="",builders=0,finishes=0,spent=0,avoided=0,
    invalid=0,maxCP=0,aimedIDs={},accepted=0,follow=0,firstAction=nil,
    lowAt=nil,lowFollow=0}
  local installed=false
  local rr=loop.run(L,seed,{duration=duration,on=function(w)
    if installed then return end
    installed=true
    local old=w.W.press
    w.W.press=function(e,key,p)
      local relevant=e==w.us and w.W.t>=loop.PULL
      local before=kind=="feral" and w.W.res(e,4) or 0
      local power=e.power
      local ok,why=old(e,key,p)
      if relevant then
        if not ok then
          t.refused=t.refused+1
          if t.first=="" then t.first=key..":"..tostring(why) end
        else
          t.accepted=t.accepted+1
          local offense=kind=="feral" and
            (key=="rake" or key=="claw" or key=="shred" or key=="rip" or key=="ferocious_bite")
            or kind=="mm" and
            (key=="aimed_shot" or key=="sniper_shot" or key=="arcane_shot" or
              key=="serpent_sting" or key=="multi_shot" or key=="summon_hawk")
          if offense then
            if t.firstAction then t.follow=t.follow+1 else t.firstAction=key end
          end
          if power<=stock.WORLD.max*0.25 and not t.lowAt then t.lowAt=w.W.t end
          if t.lowAt and w.W.t>t.lowAt then t.lowFollow=t.lowFollow+1 end
          if kind=="feral" then
            local after=w.W.res(e,4)
            t.maxCP=math.max(t.maxCP,before,after)
            if (key=="rake" or key=="claw" or key=="shred") and after>before then
              t.builders=t.builders+1
            end
            if key=="rip" or key=="ferocious_bite" then
              t.finishes=t.finishes+1
              if before>0 and after==0 then t.spent=t.spent+1
              elseif before>0 and after==before and e.lastHit and e.lastHit.act~="WOUND" then
                t.avoided=t.avoided+1
              else t.invalid=t.invalid+1 end
            end
          elseif key=="aimed_shot" then
            assert.is_not_nil(p.spell,"source press spell ID missing")
            t.aimedIDs[p.spell]=true
          end
        end
      end
      return ok,why
    end
  end},{{H=H}})
  assert.are.equal(0,rr.errors);assert.are.equal(0,rr.raises)
  local raw=0
  for why,n in pairs(rr.refused or {}) do
    raw=raw+n
    print("EFFECT_REFUSE",kind,profile,seed,duration,pct,why,n)
  end
  assert.are.equal(raw,t.refused,"unaccounted source refusal")
  local ra,ri,gain,spend=0,0,0,0
  local starts,finished,stopped,bad,autos,inside=0,0,0,0,0,0
  local active=nil
  local lastAuto,minAuto,maxAuto=nil,math.huge,0
  for _,ev in ipairs(rr.W.truth) do
    if ev.t>=loop.PULL and ev.t<=loop.PULL+duration+1e-6 then
      if kind=="feral" then
        if ev.kind=="aura" and ev.dst and ev.dst.kind=="mob" and (ev.stacks or 0)>0 then
          if ev.aura==rake then ra=ra+1 elseif ev.aura==rip then ri=ri+1 end
        end
        if ev.src==rr.us and ev.pt==4 then
          if (ev.rage or 0)>0 then gain=gain+1 end
          if (ev.cost or 0)>0 then spend=spend+1 end
        end
      elseif ev.src==rr.us then
        if ev.kind=="castStart" and t.aimedIDs[ev.spell] then
          starts=starts+1
          if active then bad=bad+1 end
          active=ev.ends
        elseif ev.kind=="cast" and t.aimedIDs[ev.spell] then
          finished=finished+1
          if not active or math.abs(ev.t-active)>1e-6 then bad=bad+1 end
          active=nil
        elseif ev.kind=="castStop" and t.aimedIDs[ev.spell] then
          stopped=stopped+1
          active=nil
        elseif ev.kind=="cast" and ev.spell==75 then -- pinned hunter_world AUTO_SHOT
          autos=autos+1
          if active and ev.t<active-1e-6 then inside=inside+1 end
          if lastAuto then
            minAuto=math.min(minAuto,ev.t-lastAuto)
            maxAuto=math.max(maxAuto,ev.t-lastAuto)
          end
          lastAuto=ev.t
        end
      end
    end
  end
  print(("EFFECT_TRUTH role=%s profile=%s seed=%d sec=%d start=%.2f accepted=%d refused=%d follow=%d lowFollow=%d rakeAuras=%d ripAuras=%d cpGainEvents=%d cpSpendEvents=%d builders=%d finishes=%d spent=%d avoided=%d invalid=%d maxCP=%d aimedStarts=%d aimedComplete=%d aimedStop=%d aimedBadTiming=%d auto=%d autoInsideAim=%d autoMin=%.3f autoMax=%.3f firstRefusal=%s"):format(
    kind,profile,seed,duration,pct,rr.presses,raw,t.follow,t.lowFollow,
    ra,ri,gain,spend,t.builders,t.finishes,t.spent,t.avoided,t.invalid,t.maxCP,
    starts,finished,stopped,bad,autos,inside,minAuto==math.huge and 0 or minAuto,maxAuto,t.first))
  return {refused=raw,follow=t.follow,lowFollow=t.lowFollow,accepted=rr.presses,
    rake=ra,rip=ri,builders=t.builders,spent=t.spent,avoided=t.avoided,
    invalid=t.invalid,finishes=t.finishes,maxCP=t.maxCP,cpSpend=spend,
    starts=starts,finished=finished,bad=bad,autos=autos,inside=inside,stopped=stopped}
end
describe("Proposed #26 Feral real bleed AURAS and combo spends",function()
  for _,seed in ipairs({30417,30437,30461}) do
    for _,duration in ipairs({20,95}) do
      it(("seed %d duration %d whole protected comparators"):format(seed,duration),function()
        local shipped=trial("feral","shipped",seed,duration,1)
        local current=trial("feral","current",seed,duration,1)
        local candidate=trial("feral","candidate",seed,duration,1)
        assert.is_true(shipped.accepted>=3)
        assert.are.equal(0,candidate.refused)
        assert.are.equal(0,candidate.invalid)
        assert.is_true(candidate.maxCP<=5)
        assert.are.equal(candidate.finishes,candidate.spent+candidate.avoided)
        assert.is_true(candidate.follow>=3)
        assert.is_true(candidate.builders>=1)
        if duration==95 then
          assert.is_true(candidate.rake>=1 and candidate.rip>=1,"no actual bleed aura application")
          assert.is_true(candidate.spent>=1 and candidate.cpSpend>=1,"no actual finisher spend")
          assert.is_true(candidate.lowFollow>=3,"no three follow-ons after low Energy")
        end
      end)
    end
  end
end)
describe("Proposed #27 MM source Aimed start/end and true Auto Shot cadence",function()
  for _,seed in ipairs({30417,30437,30461}) do
    for _,duration in ipairs({20,95}) do
      it(("seed %d duration %d full Mana complete comparators"):format(seed,duration),function()
        local shipped=trial("mm","shipped",seed,duration,1)
        local current=trial("mm","current",seed,duration,1)
        local candidate=trial("mm","candidate",seed,duration,1)
        assert.is_true(shipped.autos>=3,"fixture did not actually Auto Shot")
        for _,x in ipairs({current,candidate}) do
          assert.are.equal(0,x.refused)
          assert.are.equal(0,x.bad,"source cast completion timing inconsistent")
          assert.is_true(x.autos>=3)
          assert.is_true(x.follow>=3)
          if duration==95 then
            assert.is_true(x.finished>=1,"no Aimed Shot completion: investigate priority/kit")
          end
        end
      end)
    end
  end
end)
