-- Hunter BM P0 independent cooldown architecture, v0.11.0 source-native.
-- Exact full v1.2 protected vs full v1.3 unselected candidate.
-- Actual Hekili source-world accepted casts only, no pet damage or live DPS.
local loop = require("Game.harness.loop")
local hunter = require("Forever.helpers.hunter_world")
local C = assert(hunter.BeastMasteryTurret)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb")); local s=assert(f:read("*a"));f:close();return s
end
local old=read("roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt")
local candidate=read("roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.3_Draft.txt")
local function swapOnce(s,a,b)
    local i=assert(s:find(a,1,true),"missing expected exact source line")
    assert.is_nil(s:find(a,i+#a,true),"ambiguous priority source")
    return s:sub(1,i-1)..b..s:sub(i+#a)
end
local beforeCall="actions+=/call_action_list,name=major_cooldowns,if=toggle.cooldowns&combat>0&target.outside8"
local afterCall="actions+=/bestial_wrath,use_off_gcd=1,if=toggle.cooldowns&combat>0&pet_out\n"..beforeCall
local beforeMajor="actions.major_cooldowns=bestial_wrath,use_off_gcd=1,if=pet_out\nactions.major_cooldowns+=/rapid_fire,use_off_gcd=1"
local afterMajor="actions.major_cooldowns=rapid_fire,use_off_gcd=1"
assert.are.equal(swapOnce(swapOnce(old,beforeCall,afterCall),beforeMajor,afterMajor),candidate,
    "full v1.3 has an unreviewed additional APL delta")
local function run(profile, distance, major)
    local world=setmetatable({distance=distance},{__index=C.WORLD})
    local content=setmetatable({WORLD=world},{__index=C})
    local L=loop.new(content)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    assert.is_true(H.Hekili.State:IsKnown("bestial_wrath"))
    local s=profile=="v1.2" and old or candidate
    local parsed,warnings=H.Hekili:ImportSimcAPL("Hunter_BeastMastery",
        "APLForever-BM-Bestial-Range",s,C.PACK)
    assert.is_table(parsed);assert.is_table(parsed.default);assert.is_table(parsed.major_cooldowns)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=parsed
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(parsed) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,name),"inactive "..name)
    end
    assert.are.same({},H.errors)
    H.Hekili.DB.profile.toggles.cooldowns.value=major
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local rr=loop.run(L,30417,{duration=42},{{H=H}})
    local casts=rr.pressedBy or {}
    local wrath=casts.bestial_wrath or 0
    local hawks=casts.summon_hawk or 0
    local rapid=casts.rapid_fire or 0
    local after=0
    if wrath>0 then
        local first
        for i=1,rr.combat do if rr.pressed[i]=="bestial_wrath" then first=i;break end end
        assert.is_truthy(first,"accepted Bestial Wrath missing actual pressed sequence")
        for i=first+1,rr.combat do
            if type(rr.pressed[i])=="string" then
                assert.is_true(rr.pressed[i]~="bestial_wrath",
                    "repeated cooldown before post-cast progression")
                after=after+1
                if after==3 then break end
            end
        end
    end
    print(("BM_BESTIAL_RANGE_V011 profile=%s distance=%d major=%s wrath=%d rapid=%d hawks=%d following=%d accepted=%d mana_end=%.2f errors=%d raises=%d refused=%s"):format(
        profile,distance,tostring(major),wrath,rapid,hawks,after,rr.presses,
        rr.us.power,rr.errors,rr.raises,tostring(next(rr.refused)~=nil)))
    assert.are.equal(0,rr.raises)
    assert.are.equal(0,rr.errors)
    assert.are.same({},rr.refused)
    assert.is_true(rr.presses>=3 and #rr.W.truth>3,"world never advanced three legal presses")
    assert.is_true(hawks>=1,"lost safe source-accepted Hawk spell")
    if wrath>0 then assert.are.equal(3,after,"no three post-cooldown accepted casts") end
    if distance==6 then
        for _,key in ipairs({"arcane_shot","aimed_shot","multi_shot","serpent_sting"}) do
            assert.are.equal(0,casts[key] or 0,"6yd accepted an illegal minimum-8yd ranged shot")
        end
        assert.are.equal(0,rapid,"Rapid Fire should remain gated from six-yard no-Auto-Shot world")
    end
    if not major then assert.are.equal(0,wrath,"Major OFF must suppress Bestial Wrath") end
    return {wrath=wrath,hawks=hawks,rapid=rapid,accepted=rr.presses}
end
describe("Hunter BM v0.11.0 pet cooldown independent of minimum ranged-shot range",function()
    it("at 6yd Major ON, v1.2 wrongly holds while full v1.3 casts pet buff",function()
        local oldRun=run("v1.2",6,true)
        local newRun=run("v1.3",6,true)
        assert.are.equal(0,oldRun.wrath,"expected source-backed old gap disappeared")
        assert.is_true(newRun.wrath>=1,"pet Bestial Wrath still absent at legal 6yd")
        assert.is_true(newRun.hawks>=oldRun.hawks,"new cooldown must not lose Hawk casts")
    end)
    it("at 12yd Major ON, preserve ready Bestial Wrath and castability",function()
        local oldRun=run("v1.2",12,true)
        local newRun=run("v1.3",12,true)
        assert.is_true(oldRun.wrath>=1 and newRun.wrath>=1)
        assert.is_true(newRun.hawks>=1)
    end)
    it("at 6yd Major OFF, no forced pet cooldown and safe ranged fallback",function()
        local oldRun=run("v1.2",6,false)
        local newRun=run("v1.3",6,false)
        assert.are.equal(0,newRun.wrath)
        assert.is_true(newRun.hawks>=oldRun.hawks)
    end)
    it("at 12yd Major OFF, preserve original ranged throughput castability",function()
        local oldRun=run("v1.2",12,false)
        local newRun=run("v1.3",12,false)
        assert.are.equal(0,newRun.wrath)
        assert.is_true(newRun.hawks>=oldRun.hawks)
    end)
end)
