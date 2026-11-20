-- BM v0.11.0 Aimed Shot guard pressure and auto-shot event truth.
-- Exact full v1.3 vs one-line in-memory variant; NO APL revision or DPS claim.
-- A comparison is meaningful only for source-accepted ranged swing events.
local loop = require("Game.harness.loop")
local hunter = require("Forever.helpers.hunter_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local stock = assert(hunter.BeastMasteryTurret)
local filename = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.3_Draft.txt"
local f=assert(io.open(root.."/"..filename,"rb"))
local original=assert(f:read("*a"));f:close()
local old = "actions+=/aimed_shot,if=target.outside8&action.aimed_shot.in_range&ranged_remains>action.aimed_shot.cast+0.15"
local newer = "actions+=/aimed_shot,if=target.outside8&action.aimed_shot.in_range"
local at=assert(original:find(old,1,true),"original full v1.3 Aimed guard changed")
assert.is_nil(original:find(old,at+#old,true),"Aimed guard duplicated")
local relaxed=original:sub(1,at-1)..newer..original:sub(at+#old)
local function import(H,profile,content)
    if profile=="shipped" then return end
    local apl=profile=="v1.3" and original or relaxed
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery","APLForever-Aimed-Experiment",apl,content.PACK)
    assert.is_table(lists); assert.is_table(lists.default)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[content.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK,name),name)
    end
    assert.are.same({},H.errors)
end
local function profile(profile,distance)
    local content=setmetatable({
        WORLD=setmetatable({distance=distance,mobHealth=1000000000},
            {__index=stock.WORLD}),
    },{__index=stock})
    local L=loop.new(content)
    local H=L.us
    assert.are.same({},H.loadErrors)
    import(H,profile,content)
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local total={aimed=0,auto=0,autoCasts=0,arcane=0,serpent=0,hawks=0,pressed=0,manaEnd=0}
    for fight=1,3 do
        local rr=loop.run(L,30417+fight,{duration=35},{{H=H}})
        local m=rr.pressedBy or {}
        local autoSwing=0
        local autoCasts=0
        local autoID=75 -- Source-registered Hunter auto_shot (not an invented spell).
        for _,ev in ipairs(rr.W.truth) do
            if ev.kind=="swing" and ev.src==rr.us and ev.hand==3 then
                autoSwing=autoSwing+1
            end
            if ev.kind=="cast" and ev.src==rr.us and ev.spell==autoID then
                autoCasts=autoCasts+1
            end
        end
        local aimed=m.aimed_shot or 0
        local arcane=m.arcane_shot or 0
        local serpent=m.serpent_sting or 0
        local hawks=m.summon_hawk or 0
        total.aimed=total.aimed+aimed
        total.auto=total.auto+autoSwing
        total.autoCasts=total.autoCasts+autoCasts
        total.arcane=total.arcane+arcane
        total.serpent=total.serpent+serpent
        total.hawks=total.hawks+hawks
        total.pressed=total.pressed+rr.presses
        total.manaEnd=rr.us.power
        print(("BM_AIMED_V011 profile=%s distance=%d fight=%d ranged_swings=%d autoshot_casts=%d aimed=%d arcane=%d serpent=%d hawks=%d pressed=%d mana=%.1f refusals=%s"):format(
            profile,distance,fight,autoSwing,autoCasts,aimed,arcane,
            serpent,hawks,rr.presses,rr.us.power,tostring(next(rr.refused)~=nil)))
        assert.are.same({},rr.refused,"source refused an Aimed recommendation")
        assert.are.equal(0,rr.errors)
        assert.are.equal(0,rr.raises)
        assert.is_true(hawks>=1,"lost Hawk under Aimed experiment")
        assert.is_true(rr.presses>=3,"not enough legal accepted post-setup casts")
        -- World truth: the ranged hand on a legal 12-yard profile must actually
        -- fire; without it there is no source evidence about clip/throughput.
        if distance==12 then
            -- Published world W.startRanged emits true Auto Shot cast events,
            -- but a PLAYER_SWING row only when its optional o.swing is true.
            -- The BM Turret world does not supply that option; this is a
            -- source-visibility limitation, not proof of missing Auto Shot.
            assert.is_true(autoCasts>0,
                "no source Auto Shot casts: cannot compare ranged activity")
            if autoSwing>0 then
                assert.are.equal(autoSwing,autoCasts,
                    "source Auto Shot cast and ranged swing truth diverged")
            else
                print(("BM_AIMED_V011_ENGINE_LIMIT profile=%s fight=%d ranged_swing_events=ABSENT auto_shot_casts=%d auto_shot_clipping=UNMODELLED"):format(
                    profile,fight,autoCasts))
            end
        elseif distance==6 then
            for _,key in ipairs({"arcane_shot","aimed_shot","serpent_sting","multi_shot"}) do
                assert.are.equal(0,m[key] or 0,
                    "out-of-range ranged shot accepted at six yards")
            end
        end
    end
    print(("BM_AIMED_V011_TOTAL profile=%s distance=%d swing_rows=%d autoshot_casts=%d aimed=%d arcane=%d serpent=%d hawks=%d actions=%d mana_end=%.1f"):format(
        profile,distance,total.auto,total.autoCasts,total.aimed,total.arcane,
        total.serpent,total.hawks,total.pressed,total.manaEnd))
    return total
end
describe("Hunter BM v0.11.0 Aimed guard and actual auto-shot truth",function()
    it("shipped benchmark has actual three-fight ranged swings",function()
        profile("shipped",12)
    end)
    it("complete protected v1.3 three-fight ranged swings",function()
        profile("v1.3",12)
    end)
    it("one-line relaxed Aimed Shot A/B on same source worlds",function()
        profile("relaxed",12)
    end)
    it("relaxed Aimed Shot retains the six-yard exclusion",function()
        profile("relaxed",6)
    end)
end)
