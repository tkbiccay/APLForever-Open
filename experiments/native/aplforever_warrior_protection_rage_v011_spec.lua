-- Forever v0.11.0 Warrior Protection BREADTH: real source-native complete APL loop.
-- Hypothesis: Current and unselected v1.1 can progress beyond the first action
-- under low starting Rage without repeatedly pressing a refused action.
-- This does not model true incoming aggro, mitigation, threat or DPS.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.warrior_world").Protection)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a")); f:close(); return s
end
local current=read("roles/Warrior/Current/APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt")
local candidate=read("roles/Warrior/Candidates/APL_Warrior_Protection_v1.1_Draft.txt")
local function run(profile,seed,rage)
  local world=setmetatable({power=rage,mobHealth=1000000000},{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  if profile~="shipped" then
    local source=profile=="current" and current or candidate
    local lists,warnings=H.Hekili:ImportSimcAPL("Warrior_Protection","APLForever-Warrior-Protection-Breadth",source,C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default,"complete imported default list missing")
    assert.is_table(lists.precombat,"complete imported precombat list missing")
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
  end
  local toggles=H.Hekili.DB.profile.toggles
  toggles.cooldowns.value=false
  toggles.minor_cooldowns.value=false
  toggles.defensives.value=false
  local rr=loop.run(L,seed,{duration=100},{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refused=0
  for reason,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("PROT_REFUSED profile=%s seed=%d rage=%d reason=%s count=%d"):format(profile,seed,rage,tostring(reason),n))
  end
  local combatActions={}
  for i=1,rr.combat do combatActions[#combatActions+1]=tostring(rr.pressed[i]) end
  local majors=rr.pressedBy or {}
  local major=(majors.blood_fury or 0)+(majors.berserking or 0)+(majors.eureka or 0)+(majors.elunes_light or 0)
  print(("PROT_V011 profile=%s seed=%d rage=%d accepted=%d combat=%d refused=%d major=%d first=%s"):format(profile,seed,rage,rr.presses,rr.combat,refused,major,table.concat(combatActions,",",1,math.min(8,#combatActions))))
  return {combat=rr.combat,refused=refused,major=major}
end
describe("Warrior Protection v0.11 complete source-native Rage/final fallback",function()
  for _,seed in ipairs({30461,30479}) do
    for _,rage in ipairs({100,25}) do
      it(("seed %d initial Rage %d with native Major OFF"):format(seed,rage),function()
        local shipped=run("shipped",seed,rage)
        local currentRun=run("current",seed,rage)
        local candidateRun=run("candidate",seed,rage)
        assert.is_true(shipped.combat>=3,"source world shipped failed to advance three actions")
        assert.is_true(currentRun.combat>=4,"Current did not advance first plus three follow-on combat actions")
        assert.is_true(candidateRun.combat>=4,"unselected Candidate did not advance first plus three follow-on combat actions")
        assert.are.equal(0,currentRun.refused,"Current source-refused an action")
        assert.are.equal(0,candidateRun.refused,"Candidate source-refused an action")
        assert.are.equal(0,currentRun.major)
        assert.are.equal(0,candidateRun.major)
      end)
    end
  end
end)
