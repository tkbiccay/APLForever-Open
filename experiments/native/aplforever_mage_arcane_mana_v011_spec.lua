-- Forever v0.11.0 Mage Arcane breadth, source-native complete shipped vs protected Current.
-- Falsifiable hypothesis: with Major/Minor OFF, the full Current can sustain
-- three genuinely accepted follow-on spells after the first offensive spell
-- at normal and 25% starting Mana without repeatedly source-refused presses.
-- World cannot prove real target range, proc fidelity, damage or client Mana.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.mage_world").Arcane)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Mage/Current/APL_Mage_Arcane_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local function run(profile,seed,mana,duration)
  local world=setmetatable({power=mana or stock.WORLD.power,mobHealth=1000000000},{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Mage_Arcane","APLForever-Mage-Arcane-Breadth",current,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","mana_recovery","major_cooldowns","aoe","final_fallback"}) do
      assert.is_table(lists[name],"missing full Current list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,name),name) end
    assert.are.same({},H.errors)
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false
  toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  local rr=loop.run(L,seed,{duration=duration},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for reason,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("ARCANE_REFUSED profile=%s seed=%d mana=%s reason=%s count=%d"):format(profile,seed,tostring(mana),tostring(reason),n))
  end
  local m=rr.pressedBy or {}
  local offensiveKeys={arcane_wrath=true,arcane_blast=true,arcane_missiles=true,
    fire_blast=true,pyroblast=true,scorch=true,frostbolt=true,fireball=true,blizzard=true}
  local offensive,follow,seen=0,0,false
  for i=1,rr.combat do
    local key=rr.pressed[i]
    if offensiveKeys[key] then
      offensive=offensive+1
      if seen then follow=follow+1 else seen=true end
    end
  end
  local major=(m.arcane_power or 0)+(m.presence_of_mind or 0)
  print(("ARCANE_V011 profile=%s seed=%d mana=%s accepted=%d combat=%d offensive=%d follow=%d refused=%d major=%d endMana=%s"):format(
    profile,seed,tostring(mana),rr.presses,rr.combat,offensive,follow,refused,major,tostring(rr.us.power)))
  return {accepted=rr.presses,offensive=offensive,follow=follow,refused=refused,major=major}
end
describe("Mage Arcane v0.11 complete source-native Mana and final fallback",function()
  for _,seed in ipairs({30417,30437}) do
    it("normal Mana and deliberate Major OFF seed "..seed,function()
      local shipped=run("shipped",seed,nil,75)
      local currentRun=run("current",seed,nil,75)
      assert.is_true(shipped.accepted>=3,"shipped did not advance; inspect source fixture")
      assert.is_true(currentRun.offensive>=4,"Current lost first plus three accepted offensive casts")
      assert.is_true(currentRun.follow>=3,"Current lost three accepted offensive follow-ons")
      assert.are.equal(0,currentRun.major,"native Major OFF violation")
      assert.are.equal(0,currentRun.refused,"Current repeated a refused action")
    end)
    it("25 percent starting Mana and fallback seed "..seed,function()
      local mana=stock.WORLD.max*0.25
      local shipped=run("shipped",seed,mana,100)
      local currentRun=run("current",seed,mana,100)
      assert.is_true(shipped.accepted>=1,"shipped low-Mana source world cannot advance")
      assert.is_true(currentRun.follow>=3,"Current low-Mana fallback lacks three accepted offensive follow-ons")
      assert.are.equal(0,currentRun.refused,"Current repeated an unaffordable or refused spell")
      assert.are.equal(0,currentRun.major)
    end)
  end
end)
