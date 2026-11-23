-- BREADTH candidate units 12-13: published v0.11.0 *boss-specific*
-- Cooldowns ON vs OFF with an independent known trained major per class,
-- complete original shipped vs full exact Current, real press/refusal.
-- No DPS or real-boss/power-gain conclusion from the synthetic world.
local loop=require("Game.harness.loop")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local cases={
  {name="Mage_Arcane",key="Mage Arcane",base=require("Forever.helpers.mage_world").Arcane,
   path="roles/Mage/Current/APL_Mage_Arcane_v1.0_Draft.txt",
   major="arcane_power",other="presence_of_mind",
   names={"precombat","default","mana_recovery","major_cooldowns","aoe","final_fallback"},
   offensive={arcane_blast=true,arcane_wrath=true,arcane_missiles=true,
     frostbolt=true,fire_blast=true,scorch=true,fireball=true}},
  {name="Shaman_Elemental",key="Shaman Elemental",
   base=require("Forever.helpers.shaman_world").Elemental,
   path="roles/Shaman/Current/APL_Shaman_Elemental_v1.0_Draft.txt",
   major="elemental_mastery",
   names={"precombat","default","shields","support_totems","fire_totems",
     "mana_recovery","major_cooldowns","aoe","final_fallback"},
   offensive={lightning_bolt=true,chain_lightning=true,
     flame_shock=true,earth_shock=true}}
}
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"))
  local s=assert(f:read("*a"));f:close();return s
end
for _,k in ipairs(cases) do
  k.apl=read(k.path)
  assert.is_truthy(k.apl:find(k.major,1,true))
  assert.is_truthy(k.apl:find("toggle.cooldowns",1,true))
end
local function one(spec,profile,seed,pct,cooldowns)
  local p=spec.base
  local nominal=p.WORLD.max
  assert.is_true(type(nominal)=="number" and nominal>0,spec.name.." invalid mana")
  local start=nominal*pct/100
  local world=setmetatable({
     power=start,distance=25,targetLevel=-1,mobHealth=1000000000,
    },{__index=p.WORLD})
  local C=setmetatable({WORLD=world},{__index=p})
  local L=loop.new(C)
  local H=L.us
  assert.are.same({},H.loadErrors)
  assert.are.same({},H.Hekili.Class.loadErrors or {})
  assert.is_truthy(C.IDS[spec.major],
    spec.key.." source fixture lacks trainer-known major")
  assert.is_truthy(C.PACK:find(" (wowsims.com)",1,true))
  if profile=="current" then
    local lists,warnings=H.Hekili:ImportSimcAPL(
      spec.name,"APLForever-Cooldown-ON-Breadth-v011",spec.apl,C.PACK)
    assert.is_table(lists)
    for _,name in ipairs(spec.names) do
      assert.is_table(lists[name],spec.key.." full APL missing "..name)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
      assert.is_true(H.Hekili:IsListActive(C.PACK,name),
        spec.key.." inactive "..name)
    end
    assert.are.same({},H.errors)
  end
  local toggle=H.Hekili.DB.profile.toggles
  toggle.cooldowns.value=cooldowns
  toggle.minor_cooldowns.value=false
  toggle.defensives.value=false
  toggle.interrupts.value=false
  local accepted,failures={},{}
  local installed=false
  local rr=loop.run(L,seed,{
    duration=pct==100 and 90 or 100,
    on=function(run)
      if installed then return end
      local prev=run.W.press
      run.W.press=function(player,key,resolved)
        local t=run.W.t
        local castRemaining=(player.castUntil or 0)-t
        local mana=player.power
        local ok,reason=prev(player,key,resolved)
        if player==run.us and t>=loop.PULL and type(key)=="string" then
          if ok then accepted[#accepted+1]={t=t,key=key,mana=mana}
          else failures[#failures+1]={t=t,key=key,mana=mana,
            reason=reason,castRem=castRemaining} end
        end
        return ok,reason
      end
      installed=true
    end
  },{{H=H}})
  assert.are.equal(0,rr.errors)
  assert.are.equal(0,rr.raises)
  local refuse,substantive,boundary=0,0,0
  for reason,n in pairs(rr.refused or {}) do
    refuse=refuse+n
    print(("BOSS_CD_REFUSED_SUM role=%s profile=%s seed=%d pct=%d cd=%s reason=%s count=%d"):format(
      spec.name,profile,seed,pct,tostring(cooldowns),tostring(reason),n))
  end
  for _,x in ipairs(failures) do
    local eps=(x.reason=="casting" and x.castRem>0 and x.castRem<=1e-7)
    if eps then boundary=boundary+1 else substantive=substantive+1 end
    print(("BOSS_CD_REFUSED_TRACE role=%s profile=%s seed=%d pct=%d cd=%s t=%.17g spell=%s reason=%s castRemainder=%.17g mana=%.3f tinyBoundary=%s"):format(
      spec.name,profile,seed,pct,tostring(cooldowns),x.t,x.key,
      tostring(x.reason),x.castRem,x.mana,tostring(eps)))
  end
  local m=rr.pressedBy or {}
  local offensive=0
  for name in pairs(spec.offensive) do offensive=offensive+(m[name] or 0) end
  local first=false
  local later=0
  for _,ev in ipairs(accepted) do
    if spec.offensive[ev.key] then
      if first then later=later+1 else first=true end
    end
  end
  local major=m[spec.major] or 0
  local extras=spec.other and (m[spec.other] or 0) or 0
  print(("BOSS_CD_V011 role=%s profile=%s seed=%d pct=%d cd=%s maxMana=%.0f accepted=%d offense=%d postFirstOffense=%d major=%d extra=%d refused=%d subst=%d tinyBoundary=%d finalMana=%.1f"):format(
    spec.name,profile,seed,pct,tostring(cooldowns),nominal,
    rr.presses,offensive,later,major,extras,refuse,substantive,boundary,
    rr.us.power))
  return {accepted=rr.presses,offense=offensive,follow=later,
    major=major,extra=extras,refused=refuse,subst=substantive,
    boundary=boundary,traced=#failures}
end
describe("Published v0.11 real accepted Boss Cooldowns ON/OFF vs full shipped",function()
  for _,spec in ipairs(cases) do
    for _,seed in ipairs({30417,30437}) do
      for _,pct in ipairs({100,25}) do
        it(("%s seed=%d initialMana=%d%% exact native Boss Cooldowns ON/OFF"):format(
          spec.name,seed,pct),function()
          local shippedOff=one(spec,"shipped",seed,pct,false)
          local currentOff=one(spec,"current",seed,pct,false)
          local shippedOn=one(spec,"shipped",seed,pct,true)
          local currentOn=one(spec,"current",seed,pct,true)
          assert.is_true(shippedOff.accepted>=3)
          assert.is_true(currentOff.accepted>=3)
          assert.is_true(currentOn.accepted>=3)
          assert.is_true(currentOn.offense>=3)
          assert.is_true(currentOn.follow>=3,
            "the source actually accepted fewer than three later offensive casts")
          assert.are.equal(0,currentOff.major,
            "Current used role's major cooldown with CD OFF")
          assert.are.equal(0,currentOff.extra)
          assert.are.equal(0,currentOff.subst,
            "Current OFF had a genuinely refused source spell")
          assert.are.equal(0,currentOn.subst,
            "Current ON introduced genuinely refused or unaffordable action")
          assert.is_true(currentOn.boundary<=2,
            "repeated tiny cast-end overlap is not safe to waive")
          assert.are.equal(currentOn.refused,currentOn.traced,
            "source refused counter and exact W.press trace disagree")
          -- Do not demand that an unmeasured boss-world bonus matches damage.
          -- A complete ON-positive major is separately required below:
          assert.is_true(currentOn.major>0,
            "Current never used trained cooldown in boss ON window: investigate gate")
          assert.is_true(currentOn.major>=currentOff.major)
          print(("BOSS_CD_DIFF_V011 role=%s seed=%d mana=%d on=%d off=%d shippedOn=%d shippedOff=%d"):format(
            spec.name,seed,pct,currentOn.major,currentOff.major,
            shippedOn.major,shippedOff.major))
        end)
      end
    end
  end
end)
