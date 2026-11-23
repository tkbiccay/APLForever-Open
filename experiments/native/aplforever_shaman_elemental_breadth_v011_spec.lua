-- Published Forever v0.11 Shaman Elemental: full shipped vs protected Current.
-- Hypothesis: Current retains three source-accepted follow-on casts at low
-- Mana without repeated ready-but-refused Lightning Bolt recommendations.
-- Range is diagnostic only: source C.usable has no distance predicate.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.shaman_world").Elemental)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Shaman/Current/APL_Shaman_Elemental_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local function run(profile,seed,distance,mana,duration)
  local world=setmetatable({distance=distance,power=mana or stock.WORLD.power,
    mobHealth=1000000000},{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Shaman_Elemental",
      "APLForever-Shaman-Elemental-Breadth",current,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","final_fallback"}) do
      assert.is_table(lists[name],"complete Current list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
    end
    assert.are.same({},H.errors)
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.minor_cooldowns.value=false
  t.defensives.value=false
  -- Test-only trace: source-world refusal *reason* is indexed rather than
  -- action name in rr.refused. Capture exact attempted spell and existing cast
  -- timing without manufacturing a spell, Mana gain, or client recommendation.
  local hookInstalled=false
  local refusalTrace={}
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(w,_,time)
      if hookInstalled then return end
      local raw=w.W.press
      w.W.press=function(player,key,resolved)
        local at=w.W.t
        local wasCastingUntil=player.castUntil or 0
        local ok,reason=raw(player,key,resolved)
        if player==w.us and not ok and at>=loop.PULL then
          refusalTrace[#refusalTrace+1]={
            t=at, key=key, reason=reason,
            castRemain=math.max(0,wasCastingUntil-at),
            mana=player.power,
            cost=resolved and resolved.cost,
          }
        end
        return ok,reason
      end
      hookInstalled=true
    end,
  },{{H=H}})
  for i,entry in ipairs(refusalTrace) do
    print(("ELEMENTAL_PRESS_REFUSAL_V011 profile=%s seed=%d yd=%d i=%d t=%.3f spell=%s reason=%s castingRemain=%.3f mana=%.1f cost=%s"):format(
      profile,seed,distance,i,entry.t,tostring(entry.key),
      tostring(entry.reason),entry.castRemain,entry.mana,
      tostring(entry.cost)))
  end
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for key,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("ELEMENTAL_REFUSAL_V011 profile=%s seed=%d yd=%d spell=%s count=%d"):format(
      profile,seed,distance,tostring(key),n))
  end
  local m=rr.pressedBy or {}
  local offensive=(m.lightning_bolt or 0)+(m.chain_lightning or 0)
    +(m.flame_shock or 0)+(m.earth_shock or 0)
  -- Count genuinely ACCEPTED subsequent actions even when the SAME
  -- legal Lightning Bolt repeats. The original test skipped all subsequent
  -- Bolts and falsely printed zero follow-ons during low-Mana normal filler.
  local nextThree={}
  local seen=false
  for i=1,rr.combat do
    local key=rr.pressed[i]
    if not seen and (key=="flame_shock" or key=="lightning_bolt") then
      seen=true
    elseif seen and type(key)=="string" and #nextThree<3 then
      nextThree[#nextThree+1]=key
    end
  end
  print(("ELEMENTAL_BREADTH_V011 profile=%s seed=%d yd=%d initialMana=%.1f accepted=%d refused=%d offensive=%d bolt=%d chain=%d shock=%d manaEnd=%.1f follow=%s"):format(
    profile,seed,distance,world.power,rr.presses,refused,offensive,
    m.lightning_bolt or 0,m.chain_lightning or 0,m.flame_shock or 0,
    rr.us.power,table.concat(nextThree,",")))
  return {accepted=rr.presses,refused=refused,offensive=offensive,
    follow=#nextThree,major=m.elemental_mastery or 0}
end
describe("Elemental v0.11 source-native full profile Mana and fallback",function()
  for _,seed in ipairs({30417,30437}) do
    it("normal Mana and native caster distance seed "..seed,function()
      local shipped=run("shipped",seed,25,nil,65)
      local current=run("current",seed,25,nil,65)
      assert.is_true(shipped.accepted>=3,"shipped source failed to advance")
      assert.is_true(current.accepted>=3,"Current failed three accepted casts")
      assert.is_true(current.offensive>=3,"Current failed offensive progression")
      assert.is_true(current.follow>=3,
        "Current lost three actual accepted follow-on actions after first offensive cast")
      assert.are.equal(0,current.refused,
        "Current had source-refused normal-Mana casts; diagnose precise spell before claiming safe")
      assert.are.equal(0,current.major,"native Major OFF not honoured")
    end)
    it("25-percent starting Mana and final fallback seed "..seed,function()
      local mana=stock.WORLD.max*0.25
      local shipped=run("shipped",seed,25,mana,90)
      local current=run("current",seed,25,mana,90)
      assert.is_true(current.accepted>=3,"Current failed three legal actions")
      assert.is_true(current.follow>=3,
        "low-Mana Current failed three genuinely accepted subsequent actions")
      assert.are.equal(0,current.refused,"Current repeated refused low-Mana action")
      print(("ELEMENTAL_LOW_MANA_V011 seed=%d shipped=%d/%d current=%d/%d"):format(
        seed,shipped.accepted,shipped.refused,current.accepted,current.refused))
    end)
    it("diagnoses published source-world 60yd range fidelity seed "..seed,function()
      local shipped=run("shipped",seed,60,nil,28)
      local current=run("current",seed,60,nil,28)
      print(("ELEMENTAL_RANGE_V011 seed=%d shipped_offensive=%d current_offensive=%d source_only=1"):format(
        seed,shipped.offensive,current.offensive))
      assert.is_true(shipped.accepted>=0 and current.accepted>=0)
    end)
  end
end)
