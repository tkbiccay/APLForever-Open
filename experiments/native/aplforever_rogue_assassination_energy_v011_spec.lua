-- Rogue Assassination v0.11.0 source-native cross-spec falsification.
-- Question: does Combat's low-Energy stealth Garrote refusal transfer to
-- Assassination, and can a single in-memory opener guard restore legal fallback?
-- This is NOT a deployable APL, DPS comparison or gameplay proof.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.rogue_world").Assassination)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Rogue/Current/APL_Rogue_Assassination_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local old="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&(buff.stealth.up|buff.vanish.up|buff.ghostly_strike_next.up)"
local new="actions.opener=garrote,focus=1,if=action.garrote.known&!debuff.garrote.up&((!combat&buff.stealth.up)|buff.vanish.up|buff.ghostly_strike_next.up)"
local guarded,n=current:gsub(old:gsub("([^%w])","%%%1"),new)
assert.are.equal(1,n,"Assassination original opener changed; re-evaluate hypothesis")
local function simulate(profile,seed,energy)
  local world=setmetatable({power=energy,mobHealth=1000000000},{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  if profile~="shipped" then
    local apl=profile=="guarded" and guarded or current
    local lists,warnings=H.Hekili:ImportSimcAPL("Rogue_Assassination",
      "APLForever-Assassination-Energy-Transfer",apl,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","opener","final_fallback"}) do
      assert.is_table(lists[name],"missing complete list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),name)
    end
    assert.are.same({},H.errors)
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.minor_cooldowns.value=false
  t.defensives.value=false
  local rr=loop.run(L,seed,{duration=energy==25 and 100 or 75},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for reason,count in pairs(rr.refused or {}) do
    refused=refused+count
    print(("ASSASSIN_REFUSED profile=%s seed=%d energy=%d reason=%s count=%d"):format(
      profile,seed,energy,tostring(reason),count))
  end
  local acceptedCombat={}
  for i=1,rr.presses do
    if type(rr.pressed[i])=="string" then
      acceptedCombat[#acceptedCombat+1]=rr.pressed[i]
    end
  end
  local m=rr.pressedBy or {}
  local major=(m.blade_flurry or 0)+(m.adrenaline_rush or 0)+(m.cold_blood or 0)
  print(("ASSASSIN_V011 profile=%s seed=%d energy=%d presses=%d combat=%d follow=%d refused=%d garrote=%d shank=%d mutilate=%d sinister=%d eviscerate=%d major=%d first=%s"):format(
    profile,seed,energy,rr.presses,#acceptedCombat,math.max(0,#acceptedCombat-1),
    refused,m.garrote or 0,m.shank or 0,m.mutilate or 0,m.sinister_strike or 0,
    m.eviscerate or 0,major,table.concat({tostring(acceptedCombat[1]),tostring(acceptedCombat[2]),tostring(acceptedCombat[3]),tostring(acceptedCombat[4])},",")))
  return {combat=#acceptedCombat,refused=refused,major=major,garrote=m.garrote or 0}
end
describe("Assassination published v0.11 native low-Energy opener transfer",function()
  for _,seed in ipairs({30417,30437}) do
    it("normal Energy preserves full Current and one-guard progression seed "..seed,function()
      local shipped=simulate("shipped",seed,100)
      local currentRun=simulate("current",seed,100)
      local guardedRun=simulate("guarded",seed,100)
      assert.is_true(shipped.combat>=3,"shipped baseline cannot advance")
      assert.is_true(currentRun.combat>=4,"Current lost three accepted follow-ons")
      assert.is_true(guardedRun.combat>=4,"in-memory guard regressed normal Energy")
      assert.are.equal(0,guardedRun.refused)
      assert.are.equal(0,guardedRun.major)
    end)
    it("25 Energy distinguishes repeated refusals from legal fallback seed "..seed,function()
      local shipped=simulate("shipped",seed,25)
      local currentRun=simulate("current",seed,25)
      local guardedRun=simulate("guarded",seed,25)
      assert.is_true(shipped.combat>=3,"shipped low-Energy baseline cannot advance")
      assert.is_true(currentRun.refused>0,"Combat's refusal symptom did not transfer; record negative result")
      assert.is_true(guardedRun.combat>=4,"guarded alternative lacks three accepted follow-ons")
      assert.are.equal(0,guardedRun.refused,"guard did not prevent refused recommendation")
      assert.are.equal(0,guardedRun.major)
    end)
  end
end)
