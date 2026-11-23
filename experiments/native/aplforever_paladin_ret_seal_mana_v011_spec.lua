-- Paladin Retribution breadth: full released source-native shipped vs Current.
-- Published Hekili Forever v0.11.0 pinned 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Source truth: Seal/Echo, melee auto attacks and secret Mana. Never treat raw cast count as DPS.
local loop=require("Game.harness.loop")
local C=assert(require("Forever.helpers.paladin_world").Retribution)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Paladin/Current/APL_Paladin_Retribution_v1.2_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local function simulate(profile,seed,mana,duration)
  local world=setmetatable({power=mana or C.WORLD.power,
    mobHealth=1000000000}, {__index=C.WORLD})
  local P=setmetatable({WORLD=world},{__index=C})
  local L=loop.new(P)
  local H=L.us
  assert.are.same({},H.loadErrors)
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL(
      "Paladin_Retribution","APLForever-Ret-Seal-Breadth",current,P.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","crusader_open","seals","major_cooldowns","aoe","final_fallback"}) do
      assert.is_table(lists[name],"missing Current full list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[P.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(P.PACK,name),"inactive list "..name)
    end
    assert.are.same({},H.errors)
  end
  local T=H.Hekili.DB.profile.toggles
  T.cooldowns.value=false
  T.minor_cooldowns.value=false
  T.defensives.value=false
  T.movement.value=false
  local rr=loop.run(L,seed,{duration=duration},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for reason,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("RET_REFUSED_V011 profile=%s seed=%d mana=%.0f reason=%s count=%d"):format(
      profile,seed,world.power,tostring(reason),n))
  end
  local m=rr.pressedBy or {}
  local nseal=(m.seal_of_command or 0)+(m.seal_of_righteousness or 0)
    +(m.seal_of_the_crusader or 0)
  local offense=(m.judgement or 0)+(m.holy_strike or 0)
    +(m.exorcism or 0)+(m.hammer_of_wrath or 0)
    +(m.consecration or 0)
  local firstSeal=false
  local follow={}
  for i=1,rr.combat do
    local act=rr.pressed[i]
    if act=="seal_of_command" or act=="seal_of_righteousness" or act=="seal_of_the_crusader" then
      firstSeal=true
    elseif firstSeal and type(act)=="string" and #follow<3 then
      follow[#follow+1]=act
    end
  end
  local off=(m.blood_fury or 0)+(m.elunes_light or 0)+(m.berserking or 0)
  print(("RET_BREADTH_V011 profile=%s seed=%d initialMana=%.0f accepted=%d refused=%d seal=%d command=%d righteous=%d crusader=%d judgement=%d holyStrike=%d offense=%d afterSeal=%d major=%d manaEnd=%.1f next=%s"):format(
    profile,seed,world.power,rr.presses,refused,nseal,
    m.seal_of_command or 0,m.seal_of_righteousness or 0,
    m.seal_of_the_crusader or 0,m.judgement or 0,
    m.holy_strike or 0,offense,#follow,off,rr.us.power,
    table.concat(follow,",")))
  return {accepted=rr.presses,refused=refused,seals=nseal,
    offense=offense,afterSeal=#follow,major=off}
end

describe("Retribution complete Forever v0.11 native seal, low Mana and fallback",function()
  for _,seed in ipairs({30417,30437}) do
    it("normal Mana, Seal upkeep and genuine follow-ons seed "..seed,function()
      local shipped=simulate("shipped",seed,nil,75)
      local cur=simulate("current",seed,nil,75)
      assert.is_true(shipped.accepted>=4,"shipped world failed to advance")
      assert.is_true(cur.accepted>=4,"Current failed four real accepted actions")
      assert.is_true(cur.seals>=1,"Current never sourced a legal seal")
      assert.is_true(cur.afterSeal>=3,"Current lacks three genuine accepted subsequent casts after seal")
      assert.are.equal(0,cur.major,"Major OFF was not honoured")
      assert.are.equal(0,cur.refused,"Current source-refused normal-Mana action; diagnose before any promotion")
    end)
    it("25 percent initial Mana / repeated final action seed "..seed,function()
      local mana=C.WORLD.max*0.25
      local shipped=simulate("shipped",seed,mana,95)
      local cur=simulate("current",seed,mana,95)
      assert.is_true(shipped.accepted>=1,"shipped source world did not advance")
      assert.is_true(cur.accepted>=4,"Current lost four accepted low-Mana casts")
      assert.is_true(cur.afterSeal>=3,"Current has no three accepted post-Seal actions at low Mana")
      assert.are.equal(0,cur.refused,"Current repeated an unaffordable low-Mana action")
      assert.are.equal(0,cur.major)
    end)
    it("5 percent starting Mana negative-control: report not assume output seed "..seed,function()
      local mana=C.WORLD.max*0.05
      local shipped=simulate("shipped",seed,mana,45)
      local cur=simulate("current",seed,mana,45)
      -- At 5% starting Mana no 3-cast requirement until known cast costs
      -- and regen are proven. Idle is not a refused action; diagnose it.
      assert.are.equal(0,cur.refused,"Current repeatedly tries an unaffordable spell")
      assert.are.equal(0,cur.major)
      assert.is_true(shipped.accepted>=0 and cur.accepted>=0)
    end)
  end
end)
