-- Feral DPS v0.11.0: actual published learn-level Cat/finisher boundaries.
-- Scope: levels 20,21,22,23,24,31,32 in the shipped source Cat world.
-- The source fixture starts in Cat and carries endgame talents/energy:
-- NO pre-Cat or natural low-level Mana/talent-spend claim. No mocked levels,
-- injected Energy, pet/HP, guessed ranks or modified stored APLs.
local loop=require("Game.harness.loop")
local ws=require("Forever.helpers.wowsims")
local stock=assert(require("Forever.helpers.druid_loop_world").Feral)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local profiles={
    current="roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt",
    candidate="roles/Druid/Candidates/APL_Druid_Feral_v1.4_Draft.txt",
}
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=assert(f:read("*a"));f:close();return s
end
local function worldAt(level)
    local content=ws.content(stock,{
        pack=stock.PACK,level=level,learn=ws.learn("DRUID"),
        talents=ws.header("druid_feral").talents,
        race=ws.race("druid_feral"),
        gear=level==60 and ws.gear("druid_feral") or nil,
    })
    content.WORLD=setmetatable({level=level,distance=4,attackers=1,
        mobHealth=1000000000},{__index=content.WORLD})
    return content
end
local function import(H,C,profile)
    if profile=="shipped" then return end
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Feral",
        "APLForever-Feral-LevelGate",read(profiles[profile]),C.PACK)
    for _,k in ipairs({"precombat","default","cat","cat_melee",
        "finish","procs","builders","caster"}) do
        assert.is_table(lists[k],"missing complete source APL list "..k)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,name),name)
    end
    -- Protected Current has 3 known source-import health.pct errors at 60;
    -- log independently at lower levels, never silently count as clean.
    if profile=="candidate" then assert.are.same({},H.errors) end
    return #H.errors
end
local function execute(profile,level)
    local C=worldAt(level)
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    local parseErrors=import(H,C,profile) or 0
    local t=H.Hekili.DB.profile.toggles
    t.cooldowns.value=false
    t.minor_cooldowns.value=false
    t.defensives.value=false
    t.movement.value=false
    local S=H.Hekili.State
    local known={
        cat=S:IsKnown("cat_form"),
        claw=S:IsKnown("claw"),
        shred=S:IsKnown("shred"),
        rake=S:IsKnown("rake"),
        rip=S:IsKnown("rip"),
        bite=S:IsKnown("ferocious_bite"),
    }
    -- Forever's published tests/Forever/wowsims/learn_druid.lua.
    assert.are.equal(level>=20,known.cat)
    assert.are.equal(level>=20,known.claw)
    assert.are.equal(level>=22,known.shred)
    assert.are.equal(level>=20,known.rip)
    -- Exact released class metadata includes Rake variant 1289140 and
    -- Bite variants 1328618/1289142. These IDs are ABSENT from the
    -- generated learn_druid.lua table, and ws.content defaults an absent
    -- ID to level 1: "known" cannot prove pre-24 actual unlocks.
    -- Never guess a variant's real character learn-level.
    local learnt=ws.learn("DRUID")
    assert.is_nil(learnt[1289140])
    assert.is_nil(learnt[1328618])
    assert.is_nil(learnt[1289142])
    if level>=24 then assert.is_true(known.rake) end
    if level>=32 then assert.is_true(known.bite) end
    if level<24 then
        print(("FERAL_UNLOCK_LIMIT level=%d rakeKnown=%s biteKnown=%s source=unmapped-Forever-variant-rank NO-NEGATIVE-UNLOCK-PROOF"):format(
            level,tostring(known.rake),tostring(known.bite)))
    end
    local r=loop.run(L,30417,{duration=36},{{H=H}})
    local by=r.pressedBy or {}
    local first={}
    for i=1,r.combat or 0 do
        if r.pressed[i] and #first<4 then first[#first+1]=r.pressed[i] end
    end
    local refused=0
    for _,n in pairs(r.refused or {}) do refused=refused+n end
    print(("FERAL_LEVEL_V011 level=%d profile=%s parseErrors=%d accepted=%d refused=%d claw=%d shred=%d rake=%d rip=%d bite=%d first=%s events=%d"):format(
        level,profile,parseErrors,r.presses,refused,by.claw or 0,
        by.shred or 0,by.rake or 0,by.rip or 0,
        by.ferocious_bite or 0,table.concat(first,","),#r.W.truth))
    assert.are.equal(0,r.errors)
    assert.are.equal(0,r.raises)
    assert.is_true(#r.W.truth>=3,"source world did not advance")
    if not known.claw then assert.are.equal(0,by.claw or 0) end
    if not known.shred then assert.are.equal(0,by.shred or 0) end
    if not known.rake then assert.are.equal(0,by.rake or 0) end
    if not known.rip then assert.are.equal(0,by.rip or 0) end
    if not known.bite then assert.are.equal(0,by.ferocious_bite or 0) end
    if profile=="candidate" then
        assert.are.same({},r.refused,"source-refused custom levelling action")
        assert.is_true(r.presses>=3,"no legal accepted levelling follow-on")
        assert.is_true(#first>=3,"no three accepted source actions")
    end
    return {by=by,accepted=r.presses,refused=refused,errors=parseErrors}
end
describe("Feral DPS v0.11 exact Cat unlock boundaries with full source APL",function()
    for _,level in ipairs({20,21,22,23,24,31,32}) do
        it("level "..level.." shipped vs protected Current vs v1.4 full Candidate",function()
            local shipped=execute("shipped",level)
            local current=execute("current",level)
            local candidate=execute("candidate",level)
            print(("FERAL_LEVEL_COMPARE level=%d shipped=%d/%d current=%d/%d/%d v14=%d/%d/%d"):format(
                level,shipped.accepted,shipped.refused,
                current.accepted,current.refused,current.errors,
                candidate.accepted,candidate.refused,candidate.errors))
        end)
    end
end)
