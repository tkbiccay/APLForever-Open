-- Published Forever v0.11.0: BM v1.4 Major Cooldowns native off-switch.
-- Test source-accepted casts, not displayed icons or damage. No fake pet
-- arrival, injected Mana, guardian population or altered engine restrictions.
local loop=require("Game.harness.loop")
local hunter=require("Forever.helpers.hunter_world")
local stock=assert(hunter.BeastMasteryTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local paths={
 current="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.1_Draft.txt",
 candidate="roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt",
}
local content=setmetatable({
 WORLD=setmetatable({distance=12,mobHealth=1000000000},{__index=stock.WORLD})
},{__index=stock})
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=assert(f:read("*a"));f:close();return s
end
local function one(profile,seed,enabled)
 local L=loop.new(content)
 local H=L.us
 assert.are.same({},H.loadErrors)
 if profile~="shipped" then
  local lists,warnings=H.Hekili:ImportSimcAPL(
   "Hunter_BeastMastery","APLForever-BM-Major-Offswitch",read(paths[profile]),content.PACK)
  assert.is_table(lists.default)
  assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
  assert.is_falsy((warnings or ""):find("Unknown key",1,true))
  H.Hekili.DB.profile.packs[content.PACK].lists=lists
  H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
  for name in pairs(lists) do assert.is_true(H.Hekili:IsListActive(content.PACK,name)) end
  assert.are.same({},H.errors)
 end
 local toggles=H.Hekili.DB.profile.toggles
 toggles.cooldowns.value=enabled
 toggles.defensives.value=false
 toggles.movement.value=false
 local rr=loop.run(L,seed,{duration=55},{{H=H}})
 assert.are.equal(0,rr.errors)
 assert.are.equal(0,rr.raises)
 local by=rr.pressedBy or {}
 local majors={"bestial_wrath","rapid_fire","blood_fury","elunes_light","berserking"}
 local n=0
 for _,name in ipairs(majors) do n=n+(by[name] or 0) end
 local tail=0
 for _,name in ipairs({"arcane_shot","aimed_shot","serpent_sting","multi_shot","summon_hawk","aspect_of_the_hawk"}) do
  tail=tail+(by[name] or 0)
 end
 local refused=0
 for _,v in pairs(rr.refused or {}) do refused=refused+v end
 print(("BM_MAJOR_OFFSWITCH_V011 profile=%s seed=%d enabled=%s major=%d follow=%d accepted=%d refused=%d bestial=%d rapid=%d"):format(
  profile,seed,tostring(enabled),n,tail,rr.presses,refused,by.bestial_wrath or 0,by.rapid_fire or 0))
 if profile=="candidate" then
  assert.are.equal(0,refused,"complete candidate source-refused an action")
  assert.is_true(rr.presses>=3,"complete candidate lost three accepted actions")
  assert.is_true(tail>=3,"complete candidate lost normal non-major progression")
  if not enabled then
   assert.are.equal(0,n,"candidate ignored player's native Major Cooldowns OFF")
  end
 end
 return {major=n,follow=tail,accepted=rr.presses,refused=refused}
end
describe("BM published v0.11.0 complete major off-switch, no compulsory per-spec settings",function()
 for _,seed in ipairs({30417,30437}) do
  it("matched shipped/current/v1.4 native OFF and ON seed "..seed,function()
   for _,enabled in ipairs({false,true}) do
    local shipped=one("shipped",seed,enabled)
    local current=one("current",seed,enabled)
    local candidate=one("candidate",seed,enabled)
    print(("BM_MAJOR_COMPARE_V011 seed=%d enabled=%s shipped=%d/%d current=%d/%d candidate=%d/%d"):format(
     seed,tostring(enabled),shipped.major,shipped.follow,
     current.major,current.follow,candidate.major,candidate.follow))
   end
  end)
 end
end)
