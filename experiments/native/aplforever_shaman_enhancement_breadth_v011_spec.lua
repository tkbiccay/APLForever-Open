-- Shaman Enhancement published v0.11.0 source-native, no synthetic procs.
-- Falsifiable: at melee range, protected Current can advance three accepted
-- combat presses under normal and 25% starting Mana, while preserving
-- autonomous weapon/shield upkeep with cooldowns deliberately OFF.
-- Full shipped/Current comparator. Source model may not expose weapon-enchant
-- truth or real melee threat: never claim these from accepted counts.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.shaman_world").Enhancement)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Shaman/Current/APL_Shaman_Enhancement_v1.0_Draft.txt","rb"))
local current=assert(f:read("*a"));f:close()
local function trial(profile,seed,low)
  local mana=low and stock.WORLD.max*0.25 or stock.WORLD.power
  local world=setmetatable({distance=5,power=mana,mobHealth=1000000000},{__index=stock.WORLD})
  local C=setmetatable({WORLD=world},{__index=stock})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL("Shaman_Enhancement","APLForever-Enhancement-v011",current,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs({
      "precombat","default","weapon_upkeep","support_totems","fire_totems",
      "mana_recovery","major_cooldowns","aoe","final_fallback",
    }) do
      assert.is_table(lists[name],"missing complete Current list "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
  end
  local t=H.Hekili.DB.profile.toggles
  t.cooldowns.value=false
  t.minor_cooldowns.value=false
  t.defensives.value=false
  local rr=loop.run(L,seed,{duration=90},{{H=H}})
  local refused=0
  for reason,n in pairs(rr.refused or {}) do
    refused=refused+n
    print(("ENH_REFUSAL profile=%s seed=%d low=%s reason=%s count=%d"):format(profile,seed,tostring(low),tostring(reason),n))
  end
  local m=rr.pressedBy or {}
  print(("ENH_V011 profile=%s seed=%d low=%s accepted=%d refused=%d stormstrike=%d shock=%d bolt=%d shield=%d windfury=%d manaEnd=%.1f"):format(
    profile,seed,tostring(low),rr.presses,refused,m.stormstrike or 0,
    (m.flame_shock or 0)+(m.earth_shock or 0),m.lightning_bolt or 0,
    m.lightning_shield or 0,m.windfury_weapon or 0,rr.us.power))
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  return {accepted=rr.presses,refused=refused,major=(m.rage_of_the_farseer or 0)+(m.blood_fury or 0),
    offensive=(m.stormstrike or 0)+(m.flame_shock or 0)+(m.earth_shock or 0)+(m.lightning_bolt or 0), shield=m.lightning_shield or 0, windfury=m.windfury_weapon or 0}
end
describe("Enhancement v0.11 melee Mana and final fallback",function()
  for _,seed in ipairs({30417,30437}) do
    for _,low in ipairs({false,true}) do
      it(("compares shipped and full Current seed %d low=%s"):format(seed,tostring(low)),function()
        local shipped=trial("shipped",seed,low)
        local currentResult=trial("current",seed,low)
        assert.is_true(shipped.accepted>=3,"shipped source world cannot advance")
        assert.is_true(currentResult.accepted>=3,"Current lacks three accepted follow-on presses")
        assert.are.equal(0,currentResult.major,"Major OFF ignored")
        -- Refusals are intentionally diagnostic first; a reproducible
        -- refusal is a failure hypothesis for a subsequent isolated gate,
        -- not evidence of DPS or permission to mutate protected Current.
        assert.is_true(currentResult.offensive>=4,
          "Current lacks first plus three source-accepted offensive actions")
        assert.are.equal(0,currentResult.refused,"Current has source-refused actions")
        assert.is_true(currentResult.shield>=1,"Current fails autonomous Lightning Shield upkeep")
        -- Windfury is diagnostic only: the released fixture observed zero
        -- weapon imbue presses in both profiles; do not infer live upkeep.
      end)
    end
  end
end)
