-- Hekili Forever v0.11.0 Hunter BM source-native Lone Wolf / dead-pet regression.
-- Published World uses pet alive; these tests CHANGE ONLY SOURCE CLIENT PET STATE,
-- source talent allocation and IsSpellUsable; no world "accepted revive" is claimed.
-- Full v1.4 is exact-byte checked against the source-tested two-line variant.
local headless=require("Game.harness.headless")
local hunter=require("Forever.helpers.hunter_world")
local C=assert(hunter.BeastMasteryTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.3_Draft.txt","rb"))
local baseline=assert(f:read("*a"));f:close()
local function replace(s,a,b)
    local i=assert(s:find(a,1,true),"missing expected exact source line")
    assert.is_nil(s:find(a,i+#a,true),"duplicate source action")
    return s:sub(1,i-1)..b..s:sub(i+#a)
end
local variant=replace(baseline,
    "actions.precombat+=/revive_pet,if=pet.dead",
    "actions.precombat+=/revive_pet,if=pet.dead&!talent.lone_wolf.enabled")
variant=replace(variant,
    "actions+=/revive_pet,if=pet.dead",
    "actions+=/revive_pet,if=pet.dead&!talent.lone_wolf.enabled")

-- The NEW full v1.4 file must equal exactly the pre-verified in-memory
-- experiment, including all other actions, abilities, lists and final tail.
local candidateFile=assert(io.open(root.."/roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt","rb"))
local actual=assert(candidateFile:read("*a"));candidateFile:close()
assert.are.equal(variant,actual,
    "Stored BM v1.4 must match two source-tested Revive guards ONLY")
variant=actual
local function readFirst(H)
    local output=assert(H.Hekili.Engine.Output.Primary)
    return output.count>0 and output.recs[1] and output.recs[1].actionName or "NO_ACTION"
end
local function run(version,lone,pet,combat)
    local character=C.character()
    character.known[#character.known+1]=883 -- source-registered Call Pet
    character.known[#character.known+1]=982 -- source-registered Revive Pet
    -- Source WoWSims BM fixture has 51 talent points, Mortal Shots rank 4.
    -- Make the alternate still a 51-point, BM-primary talent allocation:
    -- MM Mortal Shots 4->3, MM Lone Wolf 0->1 (11-point talent).
    local talents={}
    local sum=0
    for id,rank in pairs(character.talents) do talents[id]=rank;sum=sum+rank end
    assert.are.equal(51,sum,"re-pinned WoWSims character source must be reviewed")
    assert.are.equal(4,talents[19485])
    if lone then talents[19485]=3;talents[415370]=1 end
    character.talents=talents
    local check=0
    for _,rank in pairs(character.talents) do check=check+rank end
    assert.are.equal(51,check,"test must not invent impossible 52-point character")
    local H=headless.new({character=character,pack=C.PACK})
    assert.are.same({},H.loadErrors)
    local lists,warnings=H.Hekili:ImportSimcAPL(
       "Hunter_BeastMastery","APLForever-LoneWolf-BM",version=="old" and baseline or variant,C.PACK)
    assert.is_table(lists);assert.is_table(lists.precombat);assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for list in pairs(lists) do assert.is_true(H.Hekili:IsListActive(C.PACK,list)) end
    assert.are.same({},H.errors)
    local enabled=H.Hekili.State.talent.lone_wolf.enabled
    assert.are.equal(lone,enabled,"engine not observing source 51-point Lone Wolf talent")
    H.ctl.inRange.target=true
    H.ctl.level.target=60
    H.ctl.exists.pet=pet~="absent"
    H.ctl.dead.pet=pet=="dead"
    H.ctl.usable[883]={pet=="absent",false}
    H.ctl.usable[982]={pet=="dead",false}
    H.Fire("UNIT_PET","player")
    H.Fire("SPELL_UPDATE_USABLE")
    H.Fire("PLAYER_TARGET_CHANGED")
    if combat then
        H.ctl.combat=true
        H.Fire("PLAYER_REGEN_DISABLED")
    end
    assert.is_true(H.Hekili.Engine.Subscribe("Primary",function() end))
    local actions={}
    local start=H.ctl.now
    for i=1,3 do
        H.Fire("UNIT_PET","player")
        H.Fire("SPELL_UPDATE_USABLE")
        local ok,err=headless.cycle(H,start+i*1.65)
        assert.is_true(ok,tostring(err))
        assert.are.same({},H.errors)
        actions[#actions+1]=readFirst(H)
    end
    print(("BM_LONEWOLF_V011 version=%s lone=%s pet=%s combat=%s enabled=%s actions=%s source_pet_arrival=NOT_TESTED"):format(
        version,tostring(lone),pet,tostring(combat),tostring(enabled),
        table.concat(actions,",")))
    return actions
end
local function noRecovery(actions)
    for _,a in ipairs(actions) do
        assert.is_true(a~="revive_pet" and a~="call_pet",
            "repeated inappropriate pet recovery icon despite intentional Lone Wolf")
    end
end
describe("BM v0.11.0 source Lone Wolf pet recovery, all three subsequent icons",function()
    it("original full v1.3 with true Lone Wolf and dead pet still suggests costly Revive",function()
        local a=run("old",true,"dead",false)
        assert.are.equal("revive_pet",a[1])
    end)
    it("test-only guard suppresses Revive with Lone Wolf and dead pet out of combat",function()
        noRecovery(run("fixed",true,"dead",false))
    end)
    it("test-only guard also suppresses Revive in combat",function()
        noRecovery(run("fixed",true,"dead",true))
    end)
    it("without Lone Wolf, original and guarded still revive actual dead pet",function()
        assert.are.equal("revive_pet",run("old",false,"dead",false)[1])
        assert.are.equal("revive_pet",run("fixed",false,"dead",false)[1])
    end)
    it("without Lone Wolf, Call Pet remains first when absent",function()
        assert.are.equal("call_pet",run("fixed",false,"absent",false)[1])
    end)
    it("with Lone Wolf and absent pet, neither Call nor Revive are suggested",function()
        noRecovery(run("fixed",true,"absent",false))
    end)
end)
