-- Hunter BM source-observable Cheetah-to-Hawk hypothesis, Forever v0.11.0.
-- This is a test-only in-memory alternative, NOT another stored APL revision.
-- Static Cheetah can daze when hit. Moving Cheetah may be deliberate escape.
-- Validate the actual source client aura and combat/movement events, not
-- fabricate a cast of Hawk or infer a real player's escape intent.
local headless=require("Game.harness.headless")
local hunter=require("Forever.helpers.hunter_world")
local C=assert(hunter.BeastMasteryTurret)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local file=assert(io.open(root.."/roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.3_Draft.txt","rb"))
local baseline=assert(file:read("*a"));file:close()
local old="actions+=/aspect_of_the_hawk,if=!buff.aspect_of_the_hawk.up&!buff.aspect_of_the_cheetah.up&!buff.aspect_of_the_beast.up"
local new="actions+=/aspect_of_the_hawk,if=!buff.aspect_of_the_hawk.up&(!buff.aspect_of_the_cheetah.up&!buff.aspect_of_the_beast.up|combat>0&!moving)"
local pos=assert(baseline:find(old,1,true),"stored full BM v1.3 changed")
assert.is_nil(baseline:find(old,pos+#old,true),"ambiguous aspect condition")
local hypothesis=baseline:sub(1,pos-1)..new..baseline:sub(pos+#old)
local function first(H)
    local output=assert(H.Hekili.Engine.Output.Primary)
    return output.count>0 and output.recs[1] and output.recs[1].actionName or "NO_ACTION"
end
local function cycle(H,t)
    local ok,err=headless.cycle(H,t)
    assert.is_true(ok,tostring(err))
    assert.are.same({},H.errors)
    return first(H)
end
local function trial(mode,combat,moving)
    local character=C.character()
    character.known[#character.known+1]=5118 -- registered Cheetah in v0.11.0
    local H=headless.new({character=character,pack=C.PACK})
    assert.are.same({},H.loadErrors)
    assert.is_true(H.Hekili.State:IsKnown("aspect_of_the_cheetah"))
    local parsed,warnings=H.Hekili:ImportSimcAPL("Hunter_BeastMastery",
        "APLForever-Cheetah-Diagnostics",
        mode=="old" and baseline or hypothesis,C.PACK)
    assert.is_table(parsed);assert.is_table(parsed.precombat);assert.is_table(parsed.default)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=parsed
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    assert.are.same({},H.errors)
    H.ctl.exists.pet=true
    H.ctl.dead.pet=false
    H.ctl.inRange.target=true
    H.ctl.level.target=60
    H.ctl.auras.player.HELPFUL={
        {spellId=5118,applications=1,duration=3600,
         expirationTime=H.ctl.now+3599,auraInstanceID=101,
         isHelpful=true,sourceUnit="player"}
    }
    H.Fire("UNIT_AURA","player")
    assert.is_true(H.Hekili.Engine.Subscribe("Primary",function() end))
    local at=H.ctl.now
    cycle(H,at+0.2)
    if moving then
        H.ctl.moving=true -- source client truth, before movement event
        H.Fire("PLAYER_STARTED_MOVING")
    end
    if combat then
        H.ctl.combat=true
        H.Fire("PLAYER_REGEN_DISABLED")
    end
    -- Inspect SOURCE CLIENT AURA before Engine.Update forecasts its first
    -- recommended cast. Post-update state can already have simulated Hawk.
    local S=H.Hekili.State
    local cheetahBefore=S.buff.aspect_of_the_cheetah.up
    local hawkBefore=S.buff.aspect_of_the_hawk.up
    local movementBefore=H.ns.VirtualState.Moving()
    local action=cycle(H,at+1.8)
    local movementAfter=H.ns.VirtualState.Moving()
    print(("BM_CHEETAH_V011 mode=%s combat=%s moving_requested=%s movement_before=%s movement_after=%s cheetah_before=%s hawk_before=%s first=%s forecast_cheetah=%s forecast_hawk=%s"):format(
        mode,tostring(combat),tostring(moving),tostring(movementBefore),
        tostring(movementAfter),tostring(cheetahBefore),tostring(hawkBefore),
        action,tostring(S.buff.aspect_of_the_cheetah.up),
        tostring(S.buff.aspect_of_the_hawk.up)))
    assert.is_true(cheetahBefore,
        "source did not observe pre-recommendation Cheetah aura; fixture inconclusive")
    assert.is_false(hawkBefore,
        "source already had Hawk before recommendation; invalid comparison")
    if moving then
        assert.is_true(movementAfter,
            "movement event not observed; do not mistake fixture for an APL failure")
    end
    return action
end
describe("Hunter BM Cheetah combat/travel guard hypothesis on published Forever v0.11",function()
    it("original BM v1.3 with stationary combat does not restore Hawk",function()
        assert.is_true(trial("old",true,false)~="aspect_of_the_hawk")
    end)
    it("test-only guard switches to Hawk when stationary and fighting",function()
        assert.are.equal("aspect_of_the_hawk",trial("guarded",true,false))
    end)
    it("test-only guard preserves Cheetah when moving inside combat",function()
        assert.is_true(trial("guarded",true,true)~="aspect_of_the_hawk")
    end)
    it("test-only guard preserves Cheetah outside combat",function()
        assert.is_true(trial("guarded",false,false)~="aspect_of_the_hawk")
    end)
end)
