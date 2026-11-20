-- Hekili Forever v0.10.0: test-only Feral DPS Barkskin reachability.
-- A complete immutable Feral v1.2 Draft is imported twice, unchanged and
-- with exactly ONE conditional substituted IN MEMORY. No APL promotion.
--
-- Source facts: player health is hidden/full in combat; `tanking` is
-- role.tank AND aggro and the published Feral client is DAMAGER.
-- The native registration for Barkskin (22812) requires Defensives and has
-- a 60s cooldown. The stock Feral world omits Barkskin from its spellbook
-- and effect map; this test adds only those exact already-registered facts.
-- A controlled UnitThreatSituation client response is installed BEFORE
-- Hekili's Facade captures that API. It is not observed live threat.
local loop = require("Game.harness.loop")
local fake = require("Game.State.helpers.fake_api")
local pretty = require("pl.pretty")
local druid = require("Forever.helpers.druid_loop_world")
local stock = assert(druid.Feral)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local path = "roles/Druid/Candidates/APL_Druid_Feral_v1.2_Draft.txt"
local BARKSKIN = 22812
local f = assert(io.open(root .. "/" .. path, "rb"))
local source = assert(f:read("*a"))
f:close()

local before = "&combat>0&tanking&target.within5&!buff.barkskin.up"
local after = "&combat>0&aggro&target.within5&(group|active_enemies>=2)&!buff.barkskin.up"

local function profile(which)
    if which == "feral-v1.2" then return source end
    if which == "feral-v1.3" then
        local c = assert(io.open(root .. "/roles/Druid/Candidates/APL_Druid_Feral_v1.3_Draft.txt", "rb"))
        local full = assert(c:read("*a"))
        c:close()
        assert.are.equal(profile("aggro-gcd-hypothesis"), full,
            "catalogued full v1.3 differs from source-accepted one-line hypothesis")
        return full
    end
    assert.is_true(which == "aggro-hypothesis" or which == "aggro-linecd-hypothesis"
        or which == "aggro-gcd-hypothesis",
        "unregistered in-memory Feral experiment")
    local start = assert(source:find(before, 1, true), "Feral v1.2 Barkskin anchor changed")
    assert.is_nil(source:find(before, start + #before, true), "ambiguous substitution")
    local altered = source:sub(1, start - 1) .. after .. source:sub(start + #before)
    if which == "aggro-gcd-hypothesis" then
        -- Explicit *now* GCD guard from the published expression reference.
        -- If the source engine still forecasts through it, this proposal
        -- FAILS. Do not use use_off_gcd=1 to bypass a real spell GCD.
        local anchor = "&!buff.barkskin.up"
        local at = assert(altered:find(anchor, 1, true))
        assert.is_nil(altered:find(anchor, at + #anchor, 1))
        altered = altered:sub(1, at + #anchor - 1)
            .. "&gcd.remains<=0" .. altered:sub(at + #anchor)
    end
    if which == "aggro-linecd-hypothesis" then
        -- Released Forever APL line_cd is an after-CAST line refractory,
        -- not a fake cooldown, hidden-health approximation or new checkbox.
        local exact = "actions.defensives=barkskin,if="
        local prefix = "actions.defensives=barkskin,line_cd=2,if="
        local first = assert(altered:find(exact, 1, true))
        assert.is_nil(altered:find(exact, first + #exact, true))
        altered = altered:sub(1, first - 1) .. prefix .. altered:sub(first + #exact)
    end
    return altered
end

-- Development fixture extension is source-grounded, NOT a combat-survival
-- oracle: no player health, predicted hits, avoidance or actual mitigation.
assert.is_nil(druid.MAP.barkskin, "upstream Feral fixture changed; re-review")
druid.MAP.barkskin = {
    effect = function(W, e, _, X)
        local aura = assert(X.aura.barkskin)
        W.applyAura(e, aura.id, aura.duration)
    end,
}
local originalCharacter = stock.character
stock.character = function()
    local c = originalCharacter()
    c.known[#c.known + 1] = BARKSKIN -- registered spell, learnt by lvl44
    stock.IDS.barkskin = { BARKSKIN }
    return c
end

local function createWorld(content, sourceThreat)
    -- State.lua stores local UnitThreatSituation=Facade.UnitThreatSituation
    -- at class load. Patching it later would make an invalid test.
    local realNew = fake.new
    fake.new = function(...)
        local api, ctl = realNew(...)
        api.UnitThreatSituation = function(unit)
            if unit == "player" then return sourceThreat and 3 or 0 end
        end
        return api, ctl
    end
    local ok, world = pcall(function() return loop.new(content) end)
    fake.new = realNew
    assert.is_true(ok, tostring(world))
    return world
end

local function import(H, content, name)
    local imported, warnings = H.Hekili:ImportSimcAPL(
        "Druid_Feral", "APLForever-Aggro-Experiment", profile(name), content.PACK)
    assert.is_table(imported)
    assert.is_table(imported.precombat)
    assert.is_table(imported.default)
    assert.is_table(imported.defensives)
    assert.are.equal(1, #imported.defensives,
        "full Feral standalone defensive fallback unexpectedly changed")
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    assert.is_falsy((warnings or ""):find("Unknown key", 1, true))
    H.Hekili.DB.profile.packs[content.PACK].lists = imported
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({}, H.errors)
    for list in pairs(imported) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, list), list)
    end
end

local function scenario(name, threat, defensives, group)
    local content = setmetatable({
        WORLD = setmetatable({
            mobHealth = 1000000000, attackers = 2,
        }, { __index = stock.WORLD }),
    }, { __index = stock })
    local L = createWorld(content, threat)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    assert.are.equal("DAMAGER", H.ctl.role)
    assert.is_false(H.Hekili.State.role.tank)
    assert.is_true(H.Hekili.State:IsKnown("barkskin"))
    import(H, content, name)
    H.ctl.groupMembers = group and 2 or 0
    H.ctl.inGroup = group
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.minor_cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = defensives
    H.Hekili.DB.profile.toggles.movement.value = false
    local run = loop.run(L, 30417, { duration = 38 }, { { H = H } })
    -- Print diagnostics even for a losing experimental branch. A red GCD
    -- refusal is evidence; never waive it or claim DPS/castability improvement.
    local acceptedHead = {}
    for i = 1, math.min(run.combat or 0, 16) do
        acceptedHead[#acceptedHead + 1] = run.ours[i] or "NO_ACTION"
    end
    print("FERAL_AGGRO_DIAGNOSTIC " .. pretty.write({
        profile=name, clientRole=H.ctl.role, threat=threat,
        defensives=defensives, group=group, pressed=run.pressedBy,
        refused=run.refused, acceptedHead=acceptedHead,
        attempts=run.attempts, worldEvents=#run.W.truth,
    }, ""))
    assert.are.equal(0, run.raises)
    assert.are.equal(0, run.errors)
    if (name == "aggro-hypothesis" or name == "aggro-linecd-hypothesis")
        and threat and defensives and group then
        -- The first trace was a LOSING design: after its real accepted
        -- Barkskin, the source suggested it once again during GCD.
        -- Preserve this exact red comparator; never classify it as safe.
        assert.are.same({ gcd = 1 }, run.refused,
            "historical aggro-only repeat/refusal changed; re-evaluate hypothesis")
    else
        assert.are.same({}, run.refused,
            "new/refined design must never produce a refused press")
    end
    assert.is_true(run.presses >= 3, "must advance real accepted attacks")
    assert.is_true(#run.W.truth >= 3, "world must advance real events")
    local barkskin = (run.pressedBy or {}).barkskin or 0
    local auraID = assert(H.Hekili.Class.auras.barkskin).id
    local auraCount = 0
    for _, ev in ipairs(run.W.truth) do
        if ev.kind == "aura" and ev.aura == auraID and ev.dst == run.us
            and (ev.stacks or 0) > 0 then
            auraCount = auraCount + 1
        end
    end
    assert.are.equal(barkskin, auraCount, "accepted cast did not apply modelled aura")
    print(string.format(
        "FERAL_AGGRO_V010 profile=%s client_role=%s group=%s api_threat=%s defensives=%s tanking=%s aggro=%s accepted=%d barkskin=%d aura=%d refusals=0 events=%d",
        name, H.ctl.role, tostring(group), tostring(threat),
        tostring(defensives), tostring(H.Hekili.State.tanking),
        tostring(H.Hekili.State.aggro), run.presses,
        barkskin, auraCount, #run.W.truth))
    return { cast = barkskin, total = run.presses, aura = auraCount }
end

describe("Feral DPS controlled source-native aggro and Barkskin v0.10.0", function()
    it("does not depend on invented health or on a setting checkbox", function()
        assert.is_nil(source:find("health.pct", 1, true))
        assert.is_nil(source:find("settings.", 1, true))
        assert.is_truthy(source:find(before, 1, true))
    end)
    it("original tanking comparator and rejected aggro-only repeat-refusal", function()
        local existing = scenario("feral-v1.2", true, true, true)
        local unsafe = scenario("aggro-hypothesis", true, true, true)
        assert.are.equal(0, existing.cast,
            "published client role changed, reassess before selecting any design")
        assert.are.equal(1, unsafe.cast,
            "rejected aggro-only hypothesis's historical outcome changed")
        -- Scenario also asserts exactly one GCD refusal, explicitly REJECT.
    end)
    it("line_cd=2 records a known unsafe GCD refusal (not a fix)", function()
        local alternative = scenario("aggro-linecd-hypothesis", true, true, true)
        assert.are.equal(1, alternative.cast)
        assert.are.equal(1, alternative.aura)
        -- The scenario explicitly expects { gcd = 1 }, so no one can
        -- call line_cd safe just because the diagnostic test is green.
    end)
    it("entire v1.3 Candidate must make one legal Barkskin with NO refused press", function()
        local alternative = scenario("feral-v1.3", true, true, true)
        assert.are.equal(1, alternative.cast,
            "documented gcd.remains guard starved the needed Barkskin")
        assert.are.equal(1, alternative.aura)
    end)
    it("observed group threat but Defensives OFF suppresses Barkskin", function()
        assert.are.equal(0, scenario("feral-v1.3", true, false, true).cast)
    end)
    it("no observed threat never triggers Barkskin", function()
        assert.are.equal(0, scenario("feral-v1.3", false, true, true).cast)
    end)
    it("solo single-target observed threat does not waste Barkskin", function()
        assert.are.equal(0, scenario("feral-v1.3", true, true, false).cast)
    end)
end)
