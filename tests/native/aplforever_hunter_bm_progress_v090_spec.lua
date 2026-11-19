-- Hekili Forever v0.9.0 source-native BM Turret combat progression.
-- Exact upstream tag: 8f95f2ea0a45428554c1e938ed7357b870030514.
-- This is NOT a DPS simulation or proof of in-game pet recovery/range/facing.
-- No mutation of any APL; compare shipped, archived v1.0 and draft v1.1.
local loop = require("Game.harness.loop")
local hunter = require("Forever.helpers.hunter_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local C = assert(hunter.BeastMasteryTurret, "released BM Turret world required")

local function draft()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Hunter_BeastMastery" then
            assert.are.equal("v1.1", entry.revision,
                "source-compatible BM revision is only a testing Draft")
            return entry
        end
    end
    error("Hunter BM missing from verified manifest")
end

local function readFile(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local bytes = assert(f:read("*a"))
    f:close()
    return bytes
end

local profiles = {
    { name = "shipped" },
    { name = "archived-v1.0", path = "roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt" },
    { name = "draft-v1.1", path = draft().apl_file },
}

local function install(H, profile)
    if not profile.path then return end
    local parsed, warnings = H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery", "APLForever", readFile(profile.path), C.PACK)
    assert.is_table(parsed)
    assert.is_table(parsed.default)
    assert.is_table(parsed.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true),
        "release importer rejected a priority action")
    local pack = assert(H.Hekili.DB.profile.packs[C.PACK])
    pack.lists = parsed
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(parsed) do
        assert.is_true(H.Hekili:IsListActive(C.PACK, name),
            "inactive independent list " .. name)
    end
    assert.are.same({}, H.errors)
end

local function exercise(profile, cooldowns)
    -- Actual published source-world BM build: level 60, living main pet,
    -- 12 yd, 3330 natural Mana, 1 target and normal auto-shot mechanics.
    -- No forced resource refill/drain, extra pet recovery, fake damage or
    -- unsupported low-level rank overrides.
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    install(H, profile)

    local toggles = H.Hekili.DB.profile.toggles
    assert.is_table(toggles.cooldowns)
    toggles.cooldowns.value = cooldowns
    toggles.defensives.value = false
    toggles.movement.value = false
    assert.is_true(H.Hekili.State:IsKnown("bestial_wrath"),
        "published BM Turret build must actually know Bestial Wrath")
    assert.is_true(H.Hekili.State:IsKnown("arcane_shot"),
        "published BM Turret build must actually know Arcane Shot")

    local run = loop.run(L, 30417, { duration = 40 }, { { H = H } })
    local presses = run.pressedBy or {}
    local major = (presses.bestial_wrath or 0) + (presses.rapid_fire or 0)
        + (presses.blood_fury or 0) + (presses.elunes_light or 0)
        + (presses.berserking or 0)
    local ranged = (presses.arcane_shot or 0) + (presses.aimed_shot or 0)
        + (presses.summon_hawk or 0)

    print(string.format(
        "BM_V090_PROGRESS profile=%s major_on=%s accepted=%s ranged=%d major=%d bestial_wrath=%d rapid_fire=%d start_mana=%s end_mana=%s",
        profile.name, tostring(cooldowns), tostring(run.presses), ranged, major,
        presses.bestial_wrath or 0, presses.rapid_fire or 0,
        tostring(C.WORLD.power), tostring(run.us.power)))

    assert.are.equal(0, run.errors, "source engine errors")
    assert.are.equal(0, run.raises, "source engine raises")
    assert.are.same({}, run.refused, "real source-world refused a recommended ability")
    assert.is_true(run.presses >= 3, "non-vacuous accepted combat progression required")
    assert.is_true(ranged > 0, "no actual accepted ranged BM damage actions")
    if not cooldowns then
        assert.are.equal(0, major, "Major OFF must prevent real offensive CD casts")
    elseif profile.name ~= "archived-v1.0" then
        -- Positive current-engine toggle check, rather than a vacuous OFF test.
        -- A failure may mean world pet exposure/pack conditions need diagnosis;
        -- do NOT weaken this to an icon-only recommendation.
        assert.is_true((presses.bestial_wrath or 0) >= 1,
            "Major ON never produced source-accepted Bestial Wrath with living pet")
    end
end

describe("Hunter BM v0.9.0 source-native combat and Major toggle", function()
    for _, profile in ipairs(profiles) do
        for _, cooldowns in ipairs({ false, true }) do
            it(profile.name .. " real casts with Major " .. (cooldowns and "ON" or "OFF"), function()
                exercise(profile, cooldowns)
            end)
        end
    end
end)
