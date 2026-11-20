-- Cross-spec Hunter pet recovery, real published Hekili Forever v0.11.0.
-- Two SEPARATE stored full Draft APLs, equality-checked to earlier source
-- in-memory variants, no shared runtime imports.
-- Pet recommendations = source client tests, not accepted Call/Revive casts.
-- Normal rotation source-world comparator uses actual accepted actions.
local headless=require("Game.harness.headless")
local loop=require("Game.harness.loop")
local hunter=require("Forever.helpers.hunter_world")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local specs={
  {name="MM",apl="Hunter_Marksmanship",world="MarksmanshipTurret",
   path="roles/Hunter/Current/APL_Hunter_Marksmanship_DPS_v1.0_Draft.txt",
   candidatePath="roles/Hunter/Candidates/APL_Hunter_Marksmanship_v1.1_Draft.txt",
   lwBase=true},
  {name="SV",apl="Hunter_Survival",world="SurvivalMelee",
   path="roles/Hunter/Current/APL_Hunter_Survival_DPS_v1.0_Draft.txt",
   candidatePath="roles/Hunter/Candidates/APL_Hunter_Survival_v1.1_Draft.txt",
   lwBase=false},
}
local function read(path)
   local f=assert(io.open(root.."/"..path,"rb"))
   local s=assert(f:read("*a"));f:close();return s
end
local function variant(source)
   -- Insert only four independent class-verified recovery actions, convert
   -- original first precombat/default action into an append. No shared APL.
   local pre=assert(source:match("(actions%.precombat=)([^\n]+)"))
   local first=assert(source:match("(actions=)([^\n]+)"))
   assert.is_nil(source:find("actions.precombat+=/call_pet",1,true))
   assert.is_nil(source:find("revive_pet",1,true))
   source=source:gsub("^actions%.precombat=", 
      "actions.precombat=call_pet,if=!pet_out&!pet.dead&!talent.lone_wolf.enabled\n"..
      "actions.precombat+=/revive_pet,if=pet.dead&!talent.lone_wolf.enabled\n"..
      "actions.precombat+=/",1)
   source=source:gsub("\nactions=",
      "\nactions=call_pet,if=!pet_out&!pet.dead&!talent.lone_wolf.enabled\n"..
      "actions+=/revive_pet,if=pet.dead&!talent.lone_wolf.enabled\n"..
      "actions+=/",1)
   assert.is_truthy(source:find("actions.precombat=call_pet,",1,true))
   assert.is_truthy(source:find("actions=call_pet,",1,true))
   return source
end
local function checkedFull(spec,original)
    -- Verify each separate complete versioned stored APL is EXACTLY
    -- the previously source-tested in-memory class-specific alternative.
    local expected=variant(original)
    local actual=read(spec.candidatePath)
    assert.are.equal(expected,actual,
        "new stored file changed more than four sourced pet actions")
    return actual
end
local function talentCharacter(C,name,lw)
    local c=C.character()
    local talents={}
    for id,r in pairs(c.talents) do talents[id]=r end
    local sum=0;for _,r in pairs(talents) do sum=sum+r end
    assert.are.equal(51,sum,"source class talent header changed")
    if name=="MM" then
        assert.are.equal(1,talents[415370])
        assert.are.equal(4,talents[19416])
        if not lw then
            talents[415370]=nil
            talents[19416]=5
        end
    else
        assert.is_nil(talents[415370])
        assert.are.equal(3,talents[19583])
        if lw then
            talents[19583]=2
            talents[415370]=1
        end
    end
    local count=0;for _,r in pairs(talents) do count=count+r end
    assert.are.equal(51,count)
    c.talents=talents
    c.known[#c.known+1]=883
    c.known[#c.known+1]=982
    return c
end
local function getFirst(H)
    local out=assert(H.Hekili.Engine.Output.Primary)
    return out.count>0 and out.recs[1] and out.recs[1].actionName or "NO_ACTION"
end
local function client(spec,version,lw,pet)
    local C=assert(hunter[spec.world],"source world missing")
    local c=talentCharacter(C,spec.name,lw)
    local H=headless.new({character=c,pack=C.PACK})
    assert.are.same({},H.loadErrors)
    local original=read(spec.path)
    local full=version=="original" and original or checkedFull(spec,original)
    local lists,warnings=H.Hekili:ImportSimcAPL(spec.apl,"APLForever-Pet-Transfer",full,C.PACK)
    assert.is_table(lists);assert.is_table(lists.precombat);assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,name)) end
    assert.are.same({},H.errors)
    assert.are.equal(lw,H.Hekili.State.talent.lone_wolf.enabled)
    H.ctl.exists.pet=pet~="absent"
    H.ctl.dead.pet=pet=="dead"
    H.ctl.usable[883]={pet=="absent",false}
    H.ctl.usable[982]={pet=="dead",false}
    H.ctl.inRange.target=true
    H.ctl.level.target=60
    H.Fire("UNIT_PET","player")
    H.Fire("SPELL_UPDATE_USABLE")
    H.Fire("PLAYER_TARGET_CHANGED")
    assert.is_true(H.Hekili.Engine.Subscribe("Primary",function() end))
    local now=H.ctl.now
    local actions={}
    for i=1,3 do
        H.Fire("UNIT_PET","player")
        H.Fire("SPELL_UPDATE_USABLE")
        local ok,err=headless.cycle(H,now+i*1.65)
        assert.is_true(ok,tostring(err));assert.are.same({},H.errors)
        actions[#actions+1]=getFirst(H)
    end
    print(("HUNTER_PET_TRANSFER_V011 spec=%s version=%s lone=%s pet=%s first3=%s real_pet_cast=NOT_TESTED"):format(
       spec.name,version,tostring(lw),pet,table.concat(actions,",")))
    return actions
end
local function noRecovery(a)
    for _,key in ipairs(a) do
        assert.is_true(key~="call_pet" and key~="revive_pet",
           "user deliberately chose Lone Wolf yet recovery is advised")
    end
end
local function accepted(spec,version)
    local C=assert(hunter[spec.world])
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    local s=read(spec.path)
    if version=="candidate" then s=checkedFull(spec,s) end
    local lists,warnings=H.Hekili:ImportSimcAPL(spec.apl,
        "APLForever-Normal-Combat",s,C.PACK)
    assert.is_table(lists);assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local rr=loop.run(L,30417,{duration=35},{{H=H}})
    assert.are.equal(0,rr.raises)
    assert.are.equal(0,rr.errors)
    assert.are.same({},rr.refused)
    assert.is_true(rr.presses>=3 and #rr.W.truth>3)
    local by=rr.pressedBy or {}
    print(("HUNTER_PET_TRANSFER_NORMAL_V011 spec=%s version=%s accepted=%d mana_end=%.2f refused=%s"):format(
       spec.name,version,rr.presses,rr.us.power,tostring(next(rr.refused)~=nil)))
    return {casts=by,pressed=rr.presses,mana=rr.us.power}
end
describe("Forever v0.11 MM/SV independent pet recovery first-three-icon opportunity",function()
    for _,sp in ipairs(specs) do
      it(sp.name..": existing Current lacks pet care with dead or missing pet",function()
         noRecovery(client(sp,"original",false,"dead"))
         noRecovery(client(sp,"original",false,"absent"))
      end)
      it(sp.name..": in-memory recovery with no Lone Wolf requests correct spell",function()
         assert.are.equal("revive_pet",client(sp,"candidate",false,"dead")[1])
         assert.are.equal("call_pet",client(sp,"candidate",false,"absent")[1])
      end)
      it(sp.name..": Lone Wolf never recommends either pet recovery",function()
         noRecovery(client(sp,"candidate",true,"dead"))
         noRecovery(client(sp,"candidate",true,"absent"))
      end)
      it(sp.name..": natural source-world accepted normal actions unchanged",function()
         local a=accepted(sp,"original")
         local b=accepted(sp,"candidate")
         assert.are.same(a.casts,b.casts)
         assert.are.equal(a.pressed,b.pressed)
         assert.is_true(math.abs(a.mana-b.mana)<0.0001)
      end)
    end
end)
