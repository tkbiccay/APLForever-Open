-- Hekili Forever v0.10.0 source-native BM client-state transition.
-- IMPORTANT: source-driven addon observation only, not a successful world cast.
-- The published Turret world starts with an already-living pet and omits
-- Call Pet / Revive Pet press effects. Never label this as a source-accepted
-- successful summon or live client pet arrival. It answers whether the
-- imported standalone APL STOPS offering recovery once UnitExists/UnitIsDead
-- and source-registered IsSpellUsable change to the real healthy-pet state.
local headless = require("Game.harness.headless")
local hunter = require("Forever.helpers.hunter_world")
local C = assert(hunter.BeastMasteryTurret)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local paths = {
    { name = "v1.1-current", path = "roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt" },
    { name = "v1.2-candidate", path = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt" },
}

local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local text = assert(f:read("*a"))
    f:close()
    return text
end

local function first(H)
    local output = assert(H.Hekili.Engine.Output.Primary)
    if output.count <= 0 then return "NO_ACTION" end
    return output.recs[1] and output.recs[1].actionName or "NO_ACTION"
end

local function advance(H, seconds)
    local t = H.ctl.now + seconds
    H.Fire("SPELL_UPDATE_USABLE")
    H.Fire("UNIT_PET", "player")
    local ok, err = headless.cycle(H, t)
    assert.is_true(ok, tostring(err))
    assert.are.same({}, H.errors, "native engine or script evaluation error")
    return first(H)
end

local function check(profile, mode)
    local character = C.character()
    character.known[#character.known + 1] = 883 -- released Hunter source Call Pet ID
    character.known[#character.known + 1] = 982 -- released Hunter source Revive Pet ID
    local H = headless.new({ character = character, pack = C.PACK })
    assert.are.same({}, H.loadErrors)
    local parsed, warnings = H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery", "APLForever-Pet-Observation",
        read(profile.path), C.PACK)
    assert.is_table(parsed)
    assert.is_table(parsed.default)
    assert.is_table(parsed.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    H.Hekili.DB.profile.packs[C.PACK].lists = parsed
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({}, H.errors)
    assert.is_true(H.Hekili:IsListActive(C.PACK, "default"))
    assert.is_true(H.Hekili.Engine.Subscribe("Primary", function() end))

    H.ctl.inRange.target = true
    H.ctl.level.target = 60
    H.ctl.exists.pet = mode ~= "absent"
    H.ctl.dead.pet = mode == "dead"
    H.ctl.usable[883] = { mode == "absent", false }
    H.ctl.usable[982] = { mode == "dead", false }
    H.Fire("PLAYER_TARGET_CHANGED")
    local need = mode == "absent" and "call_pet" or "revive_pet"
    local before = advance(H, 0.2)
    assert.are.equal(need, before,
        "unmet companion requirement must recommend correct recovery")

    -- EXPLICIT synthetic client event: assume the pet actually arrived alive
    -- and the client now says recovery spells are unusable. No fake W.press,
    -- no fabricated source-accepted Call/Revive, no damage estimates.
    H.ctl.exists.pet = true
    H.ctl.dead.pet = false
    H.ctl.usable[883] = { false, false }
    H.ctl.usable[982] = { false, false }
    local after1 = advance(H, 0.2)
    local after2 = advance(H, 1.6)
    local after3 = advance(H, 1.6)
    for _, action in ipairs({ after1, after2, after3 }) do
        assert.is_true(action ~= "call_pet" and action ~= "revive_pet",
            "stale pet recovery icon persisted after simulated healthy-pet event")
    end
    print(string.format(
        "BM_PET_V010_OBSERVATION profile=%s start=%s initial=%s after_arrival_1=%s after_arrival_2=%s after_arrival_3=%s kind=CONTROLLED_CLIENT_EVENT actual_pet_cast=NOT_TESTED",
        profile.name, mode, before, after1, after2, after3))
end

describe("Hunter BM v0.10.0 APL reaction to source-readable pet unit state", function()
    for _, profile in ipairs(paths) do
        for _, state in ipairs({ "absent", "dead" }) do
            it(profile.name .. " changes " .. state .. " recovery icon after healthy-pet state", function()
                check(profile, state)
            end)
        end
    end
end)
