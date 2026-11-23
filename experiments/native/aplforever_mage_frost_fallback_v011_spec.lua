-- Mage Frost breadth #07: published Forever v0.11.0, exact SHA
-- 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- Independent full shipped versus immutable Current Frost v1.0 in the
-- published FROST pack, not the separate Fire-based FROSTFIRE pack.
-- Test true source-accepted next-three/final fallback; never infer damage.
local loop=require("Game.harness.loop")
local mage=require("Forever.helpers.mage_world")
local stock=assert(mage.Frost)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Mage/Current/APL_Mage_Frost_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a")); f:close()
local offensive={frostbolt=true,fireball=true,ice_lance=true,cone_of_cold=true,
    blizzard=true,frostfire_bolt=true}
local function one(profile,seed,initial,duration)
  local W=setmetatable({distance=25,power=initial,mobHealth=1000000000},
    {__index=stock.WORLD})
  local C=setmetatable({WORLD=W},{__index=stock})
  local L=loop.new(C); local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  assert.is_nil(C.IDS.frostfire_bolt,
    "Frost world's published known kit unexpectedly includes Frostfire Bolt")
  assert.is_table(C.IDS.frostbolt)
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL(
      "Mage_Frost","APLForever-Frost-Breadth",current,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({"precombat","default","defensives","mana_recovery",
      "major_cooldowns","aoe","final_fallback"}) do
      assert.is_table(lists[name],"missing complete Current list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
    end
    assert.are.same({},H.errors)
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false
  toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  local events,failures,installed={},{},false
  local rr=loop.run(L,seed,{
    duration=duration,
    on=function(w)
      if installed then return end
      local original=w.W.press
      w.W.press=function(player,key,resolved)
        local t=w.W.t
        local ok,reason=original(player,key,resolved)
        if player==w.us and t>=loop.PULL and type(key)=="string" then
          if ok then
            events[#events+1]={t=t,key=key}
          else
            failures[#failures+1]={t=t,key=key,reason=reason,
              castRemain=math.max(0,(player.castUntil or 0)-t)}
          end
        end
        return ok,reason
      end
      installed=true
    end,
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for reason,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("FROST_REFUSED profile=%s seed=%d startMana=%.2f reason=%s n=%d"):format(
      profile,seed,initial,tostring(reason),n))
  end
  for _,e in ipairs(failures) do
    print(("FROST_REFUSAL_TRACE profile=%s seed=%d time=%.12f key=%s reason=%s castRemain=%.12f"):format(
      profile,seed,e.t,e.key,tostring(e.reason),e.castRemain))
  end
  local m=rr.pressedBy or {}
  local count,first,later=0,false,0
  for _,e in ipairs(events) do
    if offensive[e.key] then
      count=count+1
      if first then later=later+1 else first=true end
    end
  end
  local total=0
  for key in pairs(offensive) do total=total+(m[key] or 0) end
  assert.is_true(count<=total,
    "accepted action chronology exceeds published world accepted counters")
  local major=(m.cold_snap or 0)+(m.eureka or 0)+(m.blood_fury or 0)+
    (m.berserking or 0)+(m.use_items or 0)
  print(("FROST_V011 profile=%s seed=%d startMana=%.2f accepted=%d eventOffense=%d totalOffense=%d followons=%d refused=%d major=%d frostbolt=%d icelance=%d frostfire=%d endMana=%s"):format(
    profile,seed,initial,rr.presses,count,total,later,refused,major,
    m.frostbolt or 0,m.ice_lance or 0,m.frostfire_bolt or 0,
    tostring(rr.us.power)))
  return {accepted=rr.presses,follow=later,refused=refused,major=major,
    frostfire=m.frostfire_bolt or 0,offense=total}
end
describe("Mage Frost actual published v0.11 pack, kit and final fallback",function()
  it("Frost vs Fire-based Frostfire pack: published fixture taxonomy",function()
    local frost=loop.new(stock)
    local ff=loop.new(mage.Frostfire)
    assert.are.same({},frost.us.loadErrors)
    assert.are.same({},ff.us.loadErrors)
    assert.is_nil(stock.IDS.frostfire_bolt,
      "Frost pack unexpectedly knows Frostfire Bolt")
    assert.is_table(mage.Frostfire.IDS.frostfire_bolt,
      "Frostfire pack no longer knows Frostfire Bolt")
    print("FROST_V011_KIT FrostfireBolt=NOT_KNOWN_IN_FROST; known_in_Frostfire=true; client game unverified")
  end)
  for _,seed in ipairs({30417,30437}) do
    it("full Mana complete shipped and Current: three accepted post-opener actions "..seed,function()
      local s=one("shipped",seed,stock.WORLD.max,75)
      local c=one("current",seed,stock.WORLD.max,75)
      assert.is_true(s.accepted>=3,"shipped fixture cannot progress")
      assert.is_true(c.follow>=3,"Current full-Mana final/repeated fallback stalled")
      assert.are.equal(0,c.refused,"Current source refused repeat/full Mana")
      assert.are.equal(0,c.major,"Major OFF overridden")
      assert.are.equal(0,c.frostfire,"unsupported Frostfire cast in Frost kit")
    end)
    it("25 percent Mana: three accepted follow-ons and no refused loop "..seed,function()
      local start=stock.WORLD.max*0.25
      local s=one("shipped",seed,start,100)
      local c=one("current",seed,start,100)
      assert.is_true(s.accepted>=1,"shipped low-Mana fixture cannot progress")
      assert.is_true(c.follow>=3,"Current low-Mana final fallback stalled")
      assert.are.equal(0,c.refused,"Current repeatedly suggests unaffordable action")
      assert.are.equal(0,c.major)
      assert.are.equal(0,c.frostfire)
    end)
    it("5 percent Mana: refusal/fallback diagnostic without invented output "..seed,function()
      local start=stock.WORLD.max*0.05
      local s=one("shipped",seed,start,100)
      local c=one("current",seed,start,100)
      assert.is_true(s.accepted>=1,"shipped extreme Mana fixture cannot advance")
      assert.are.equal(0,c.major)
      assert.are.equal(0,c.frostfire)
      -- Failure here is real evidence to triage; 3 follow-ons are not
      -- assumed achievable at 5% from this known kit's costs.
      assert.are.equal(0,c.refused,"Current extreme Mana refused source action")
      print(("FROST_5PCT_DIAGNOSTIC seed=%d currentFollow=%d shippedAccepted=%d"):format(
        seed,c.follow,s.accepted))
    end)
  end
end)
