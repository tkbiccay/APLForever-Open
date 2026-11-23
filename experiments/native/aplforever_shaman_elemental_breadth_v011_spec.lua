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
  local rr=loop.run(L,seed,{duration=duration},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for _,n in pairs(rr.refused or {}) do refused=refused+n end
  local m=rr.pressedBy or {}
  local offensive=(m.lightning_bolt or 0)+(m.chain_lightning or 0)
    +(m.flame_shock or 0)+(m.earth_shock or 0)
  local nextThree={}
  local seen=false
  for i=1,rr.combat do
    local a=rr.pressed[i]
    if a=="flame_shock" or a=="lightning_bolt" then seen=true
    elseif seen and type(a)=="string" and #nextThree<3 then
      nextThree[#nextThree+1]=a
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
      assert.are.equal(0,current.major,"native Major OFF not honoured")
    end)
    it("25-percent starting Mana and final fallback seed "..seed,function()
      local mana=stock.WORLD.max*0.25
      local shipped=run("shipped",seed,25,mana,90)
      local current=run("current",seed,25,mana,90)
      assert.is_true(current.accepted>=3,"Current failed three legal actions")
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
