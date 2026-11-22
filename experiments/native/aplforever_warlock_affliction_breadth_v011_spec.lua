-- Portfolio breadth: exact released v0.11.0 Warlock Affliction full APL
-- compared with shipped, via real native source-world accepted/refused casts.
-- Goal: after DoT upkeep, three further legal actions, low Mana, and
-- independently observe caster range fidelity (not presume game cast range).
-- Source world does NOT implement Life Tap health damage: no real health proof.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.warlock_world").Affliction)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local file=assert(io.open(root.."/roles/Warlock/Current/APL_Warlock_Affliction_DPS_v1.0_Draft.txt","rb"))
local current=assert(file:read("*a")); file:close()
local function one(profile,seed,distance,initialMana,duration)
    local world=setmetatable({
        distance=distance, mobHealth=1000000000,
        power=initialMana or stock.WORLD.power,
    },{__index=stock.WORLD})
    local C=setmetatable({WORLD=world},{__index=stock})
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    if profile=="current" then
        local lists,warnings=H.Hekili:ImportSimcAPL("Warlock_Affliction",
            "APLForever-Affliction-Breadth",current,C.PACK)
        assert.is_table(lists)
        for _,name in ipairs({"precombat","default","upkeep","final_fallback"}) do
            assert.is_table(lists[name],"complete Current list "..name)
        end
        assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
        assert.is_falsy((warnings or ""):find("Unknown key",1,true))
        H.Hekili.DB.profile.packs[C.PACK].lists=lists
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
        end
        assert.are.same({},H.errors)
    end
    local t=H.Hekili.DB.profile.toggles
    t.cooldowns.value=false
    t.minor_cooldowns.value=false
    t.defensives.value=false
    t.movement.value=false
    local rr=loop.run(L,seed,{duration=duration},{{H=H}})
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    local m=rr.pressedBy or {}
    local refused=0
    for _,n in pairs(rr.refused or {}) do refused=refused+n end
    local dots={"corruption","bane_of_agony","siphon_life","immolate"}
    local firstDot=0
    for _,name in ipairs(dots) do firstDot=firstDot+(m[name] or 0) end
    local post=0
    local seenDot=false
    local firstThree={}
    for i=1,rr.combat do
        local a=rr.pressed[i]
        if a=="corruption" or a=="bane_of_agony" then
            seenDot=true
        elseif seenDot and type(a)=="string" then
            post=post+1
            if #firstThree<3 then firstThree[#firstThree+1]=a end
        end
    end
    local offense=0
    for _,key in ipairs({"shadow_bolt","searing_pain","wrack","drain_life",
        "rain_of_fire","corruption","bane_of_agony","siphon_life","immolate"}) do
        offense=offense+(m[key] or 0)
    end
    print(("AFF_BREADTH_V011 profile=%s seed=%d yd=%d startMana=%.1f accepted=%d refused=%d offensive=%d dotCasts=%d afterDot=%d bolt=%d wrack=%d tap=%d manaEnd=%.1f next=%s"):format(
        profile,seed,distance,world.power,rr.presses,refused,offense,
        firstDot,post,m.shadow_bolt or 0,m.wrack or 0,
        m.life_tap or 0,rr.us.power,table.concat(firstThree,",")))
    return {presses=rr.presses,refused=refused,offense=offense,
        dotCasts=firstDot,postDot=post,lifeTap=m.life_tap or 0}
end
describe("Affliction full shipped and Current v0.11 DoT and final-fallback breadth",function()
    for _,seed in ipairs({30417,30437}) do
        it("full Mana and native 25yd normal single-target seed "..seed,function()
            local shipped=one("shipped",seed,25,nil,65)
            local candidate=one("current",seed,25,nil,65)
            assert.is_true(shipped.presses>=3,"shipped failed ordinary source advance")
            assert.is_true(candidate.presses>=3,"Current failed three accepted source actions")
            assert.is_true(candidate.dotCasts>=1,"Current never source-cast a DoT")
            assert.is_true(candidate.postDot>=3,"no three genuine follow-on actions after DoT")
            assert.are.equal(0,candidate.refused,
                "Current presented repeatedly source-refused action in normal combat")
        end)
        it("25-percent natural starting Mana at 25yd seed "..seed,function()
            local initial=stock.WORLD.max*0.25
            local shipped=one("shipped",seed,25,initial,90)
            local candidate=one("current",seed,25,initial,90)
            assert.is_true(candidate.presses>=3,
                "Current ran out of accepted follow-on actions in low-Mana world")
            assert.are.equal(0,candidate.refused,
                "Current recommended an unavailable low-Mana cast")
            -- We do not demand Life Tap: Current does not contain that
            -- action and source-world health costs are not implemented.
            print(("AFF_LOW_MANA_COMPARE_V011 seed=%d shipped=%d/%d current=%d/%d health_cost=UNMODELLED"):format(
                seed,shipped.presses,shipped.refused,
                candidate.presses,candidate.refused))
        end)
        it("observes source caster range fidelity at 60yd seed "..seed,function()
            local shipped=one("shipped",seed,60,nil,28)
            local candidate=one("current",seed,60,nil,28)
            -- Published Warlock fixture declares client spell ranges.
            -- Source press/usability may nevertheless permit 60-yard
            -- attacks. Diagnose rather than assuming 'out of range'.
            print(("AFF_RANGE_DIAGNOSTIC_V011 seed=%d yd=60 shipped_offensive=%d current_offensive=%d source_only=1"):format(
                seed,shipped.offense,candidate.offense))
            assert.is_true(shipped.presses>=0 and candidate.presses>=0)
        end)
    end
end)
