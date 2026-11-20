-- Hekili Forever v0.10.0, exact Guardian v1.4 source-world exploration.
-- This is a *read-only in-memory* alternative, NOT a new APL revision.
-- Hypothesis: 'tanking' is gated by CLIENT role.tank and aggro in the
-- published engine, so a Guardian APL cannot assume selecting its package
-- will turn it on. A maintained non-boss debuff may need verified group/time
-- signals instead. Ordinary attacks and Rage remain source-world events.
local loop = require("Game.harness.loop")
local druid = require("Forever.helpers.druid_loop_world")
local stock = assert(druid.Guardian)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local path = "roles/Druid/Candidates/APL_Druid_Guardian_v1.4_Draft.txt"

local function read()
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local s = assert(f:read("*a"))
    f:close()
    return s
end
local source = read()
local function readReportedWorking()
    local filePath = "roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt"
    local f = assert(io.open(root .. "/" .. filePath, "rb"))
    local s = assert(f:read("*a"))
    f:close()
    return s
end
local from = "((group&tanking&time>=5)|(target.is_boss&time>=4)|(solo&tanking&time>=12))"
local to = "((group&time>=5)|(target.is_boss&time>=4)|(solo&time>=12))"

local function variant(which)
    if which == "shipped" then return nil end
    if which == "reported-v1.0" then return readReportedWorking() end
    if which == "baseline-v1.4" then return source end
    assert.are.equal("role-free-hypothesis", which)
    local at = assert(source:find(from, 1, true),
        "Guardian original anchor changed, no silent patch")
    assert.is_nil(source:find(from, at + #from, true), "ambiguous anchor")
    return source:sub(1,at-1) .. to .. source:sub(at+#from)
end

local function import(H, text)
    local imported, warnings = H.Hekili:ImportSimcAPL("Druid_Guardian", "APLForever", text, stock.PACK)
    assert.is_table(imported)
    assert.is_table(imported.default)
    assert.is_table(imported.precombat)
    assert.is_table(imported.mitigation)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[stock.PACK].lists = imported
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(imported) do
        assert.is_true(H.Hekili:IsListActive(stock.PACK,name),"inactive standalone list "..name)
    end
    assert.are.same({},H.errors,"source script must compile without warning")
end

local function scenario(which,group,seconds)
    -- The Guardian fixture's published Rage model, hostile attacks and
    -- returned pressed actions remain authoritative. Only client-reported
    -- group size and the source-world enemy's 4yd/normal-level geometry
    -- are controlled. NO synthetic Rage, aggression, HP or DPS.
    local content = setmetatable({
        WORLD = setmetatable({
            distance = 4, targetLevel = 60, attackers = 2,
            mobHealth = 1000000000,
        },{ __index = stock.WORLD }),
    },{ __index = stock })
    local L = loop.new(content)
    local H = L.us
    assert.are.same({},H.loadErrors)
    local proposed = variant(which)
    if proposed then import(H,proposed) end
    H.ctl.groupMembers = group and 2 or 0
    H.ctl.inGroup = group
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    assert.is_false(H.Hekili.State.role.tank,
        "published source world is DAMAGER-role client, not true tank-role")
    local stats = {maxRageLoPost12=0, maxTruthRagePost12=0, post12Ticks=0, observedSolo=false}
    local run = loop.run(L,30417,{
        duration=seconds,
        on=function(r, _, t)
            if r.combat <= 0 then return end
            local elapsed = H.Hekili.State.time or 0
            if elapsed < 12 then return end
            stats.post12Ticks = stats.post12Ticks + 1
            stats.observedSolo = stats.observedSolo or (H.Hekili.State.solo == true)
            local p = H.ns.VirtualState.Power(1, H.ctl.now)
            stats.maxRageLoPost12 = math.max(stats.maxRageLoPost12, (p and p.lo) or 0)
            stats.maxTruthRagePost12 = math.max(stats.maxTruthRagePost12, r.us.power or 0)
        end,
    },{ {H=H} })
    assert.are.equal(0,run.errors)
    assert.are.equal(0,run.raises)
    assert.are.same({},run.refused)
    assert.is_true(run.presses>=3,"non-vacuous accepted state-advanced combat required")
    assert.is_true(#run.W.truth>3,"source-world attacks/events must genuinely advance")
    local roar = (run.pressedBy or {}).demoralizing_roar or 0
    local barkskin = (run.pressedBy or {}).barkskin or 0
    assert.are.equal(0,barkskin,"Defensives OFF must prevent Barkskin")
    print(("GUARDIAN_ROLE_FREE_V010 which=%s group=%s duration=%d role_tank=%s accepted=%d roar=%d barkskin=%d refused=0 events=%d rage_lo_max_after12=%.3f truth_rage_max_after12=%.3f post12_ticks=%d observed_solo=%s"):format(
        which,tostring(group),seconds,tostring(H.Hekili.State.role.tank),
        run.presses,roar,barkskin,#run.W.truth,
        stats.maxRageLoPost12,stats.maxTruthRagePost12,stats.post12Ticks,tostring(stats.observedSolo)))
    return {roar=roar,accepted=run.presses,stats=stats}
end

describe("Guardian independent source-native Roar role requirement hypothesis",function()
    it("non-boss grouped encounter: old role-gated branch versus role-free alternative",function()
        local shipped=scenario("shipped",true,38)
        local working=scenario("reported-v1.0",true,38)
        local current=scenario("baseline-v1.4",true,38)
        local alternative=scenario("role-free-hypothesis",true,38)
        print(("GUARDIAN_ROLE_FREE_COMPARATORS shipped_roar=%d reported_working_roar=%d v14_roar=%d experimental_roar=%d shipped_accepted=%d working_accepted=%d v14_accepted=%d alternative_accepted=%d"):format(
            shipped.roar,working.roar,current.roar,alternative.roar,
            shipped.accepted,working.accepted,current.accepted,alternative.accepted))
        assert.are.equal(0,current.roar,
            "the published fake client now supplies actual tank-role eligibility, reassess")
        assert.is_true(alternative.roar>=1,
            "role-free branch did not produce a real accepted Roar at normal range")
        assert.is_true(alternative.roar<=2,
            "more than two 30-second Roars in 38 seconds implies waste or repeated upkeep")
    end)
    it("short solo mob: role-free variant does not use Roar prematurely",function()
        local current=scenario("baseline-v1.4",false,9)
        local alternative=scenario("role-free-hypothesis",false,9)
        assert.are.equal(0,current.roar)
        assert.are.equal(0,alternative.roar)
    end)
    it("long solo normal mob: role-free variant can maintain Roar after 12 seconds",function()
        local current=scenario("baseline-v1.4",false,35)
        local alternative=scenario("role-free-hypothesis",false,35)
        assert.are.equal(0,current.roar)
        assert.is_true(alternative.stats.post12Ticks>0,
            "no real source advancement through the 12s solo gating window")
        assert.is_true(alternative.stats.observedSolo,
            "source client did not report solo, cannot test the branch")
        if alternative.stats.maxRageLoPost12 < 20 then
            -- Condition requires 10 Rage for Roar PLUS a real 10 Rage
            -- conservative reserve. A zero-Roar outcome is correctly
            -- unaffordable, not proof of a broken time/solo branch.
            assert.are.equal(0,alternative.roar,
                "accepted Roar despite believing Rage insufficient")
        else
            assert.is_true(alternative.roar>=1,
                "role-free normal solo branch had eligible Rage but no accepted Roar")
        end
        assert.is_true(alternative.roar<=1,
            "normal solo combat should not consume Roar multiple times in 35 seconds")
    end)
end)
