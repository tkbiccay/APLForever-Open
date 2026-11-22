-- First breadth lane: published Forever v0.11.0 Shadow Priest entire Current
-- APL vs shipped. Real source-world Mana, channels and DoT accepted actions.
-- This is a castability/fallback test, NOT damage or in-game proof.
local loop=require("Game.harness.loop")
local priest=require("Forever.helpers.priest_world")
local stock=assert(priest.Shadow)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local file=assert(io.open(root.."/roles/Priest/Current/APL_Priest_Shadow_v1.0_Draft.txt","rb"))
local current=assert(file:read("*a"));file:close()
local function one(profile,seed,distance,startingPower,duration)
    local world=setmetatable({distance=distance,mobHealth=1000000000,
        power=startingPower or stock.WORLD.power},{__index=stock.WORLD})
    local C=setmetatable({WORLD=world},{__index=stock})
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    if profile=="current" then
        local lists,warnings=H.Hekili:ImportSimcAPL("Priest_Shadow",
            "APLForever-Shadow-Breadth",current,C.PACK)
        assert.is_table(lists);assert.is_table(lists.default)
        assert.is_table(lists.precombat);assert.is_table(lists.final_fallback)
        assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
        assert.is_falsy((warnings or ""):find("Unknown key",1,true))
        H.Hekili.DB.profile.packs[C.PACK].lists=lists
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(C.PACK,name),name)
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
    for _,count in pairs(rr.refused or {}) do refused=refused+count end
    local offensive={"shadow_word_pain","devouring_plague",
                     "mind_blast","mind_flay","smite","shoot",
                     "vampiric_embrace","shadow_word_death"}
    local attacks=0
    for _,key in ipairs(offensive) do attacks=attacks+(m[key] or 0) end
    local afterDot=0
    local seenDot=false
    for i=1,rr.combat do
        local key=rr.pressed[i]
        if key=="shadow_word_pain" or key=="devouring_plague" then
            seenDot=true
        elseif seenDot and type(key)=="string" then
            afterDot=afterDot+1
        end
    end
    print(("SHADOW_BREADTH_V011 profile=%s seed=%d distance=%d manaStart=%.1f accepted=%d refused=%d attacks=%d swp=%d plague=%d blast=%d flay=%d afterDot=%d manaEnd=%.1f"):format(
        profile,seed,distance,world.power,rr.presses,refused,attacks,
        m.shadow_word_pain or 0,m.devouring_plague or 0,
        m.mind_blast or 0,m.mind_flay or 0,afterDot,rr.us.power))
    return {refused=refused,attacks=attacks,presses=rr.presses,
        swp=m.shadow_word_pain or 0,plague=m.devouring_plague or 0,
        flay=m.mind_flay or 0,afterDot=afterDot}
end
describe("Shadow Priest v0.11 source-native DoT/channel/final fallback breadth",function()
    for _,seed in ipairs({30417,30437}) do
        it("full Mana at 20yd compares shipped and protected Current "..seed,function()
            local shipped=one("shipped",seed,20,nil,65)
            local currentRun=one("current",seed,20,nil,65)
            assert.is_true(shipped.presses>=3,"shipped source world did not advance")
            assert.is_true(currentRun.presses>=3,"Current source world did not advance")
            assert.are.equal(0,currentRun.refused,
                "Current repeatedly recommended source-refused combat actions")
            assert.is_true(currentRun.swp>=1,
                "Current failed first Source-landed Shadow Word: Pain cast")
            assert.is_true(currentRun.afterDot>=3,
                "Current lost three real accepted follow-on actions after upkeep")
        end)
        it("naturally regenerating low starting Mana at 20yd "..seed,function()
            local initial=stock.WORLD.max*0.25
            local shipped=one("shipped",seed,20,initial,90)
            local currentRun=one("current",seed,20,initial,90)
            assert.are.equal(0,currentRun.refused,
                "low-Mana Current recommended an unaffordable cast")
            assert.is_true(currentRun.presses>=3,
                "low-Mana Current failed to progress through three real accepted actions")
        end)
        it("exposes published Priest source-world range fidelity limit at 60yd "..seed,function()
            local shipped=one("shipped",seed,60,nil,28)
            local currentRun=one("current",seed,60,nil,28)
            -- Published Priest world.resolve/usability do not encode cast
            -- range. It source-accepts even 60yd attacks at WORLD.distance=60.
            -- No in-game out-of-range success or actual APL fault can be
            -- inferred from these source-world accepted casts.
            assert.is_true(currentRun.attacks>0,
                "published out-of-range fidelity limitation changed; investigate")
            assert.are.equal(0,currentRun.refused,
                "Current source-world range-independent diagnostic changed")
            print(("SHADOW_RANGE_ENGINE_LIMIT_V011 seed=%d distance=60 shipped=%d/%d current=%d/%d genuine_game_range=UNVERIFIED"):format(
                seed,shipped.attacks,shipped.refused,currentRun.attacks,currentRun.refused))
        end)
    end
end)
