-- Experimental, test-only source-native comparison for Hunter BM, Hekili Forever v0.10.0.
-- The imported BM v1.2 Candidate is byte-for-byte unchanged, no selected APL is promoted.
-- HHA is a source-registered 3-step combat window: Hawk, Hawk, Arcane Shot.
-- We compare the released engine's *actual accepted casts*, refusals and final tail
-- at 12 yards (shots legal) versus 6 yards (Hawk legal, shots illegal).
-- These are not DPS, pet-damage, player-live, or approved APL results.
local loop = require("Game.harness.loop")
local hunter = require("Forever.helpers.hunter_world")
local root = assert(os.getenv("APLFOREVER_ROOT"), "APLFOREVER_ROOT missing")
local C = assert(hunter.BeastMasteryTurret, "published BeastMasteryTurret fixture missing")
local path = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt"

local function read()
    local file = assert(io.open(root .. "/" .. path, "rb"))
    local src = assert(file:read("*a"))
    file:close()
    return src
end

local function swapExactlyOnce(source, before, after)
    local start = assert(source:find(before, 1, true),
        "existing v1.2 priority anchor changed")
    assert.is_nil(source:find(before, start + #before, true),
        "ambiguous anchor; do not edit two action lines")
    return source:sub(1, start - 1) .. after .. source:sub(start + #before)
end

local function sourceFor(mode)
    local src = read()
    if mode == "hha-gated" or mode == "hha-range-hybrid" then
        -- Two IN-MEMORY architecture hypotheses; no file is written.
        -- Pure HHA can freeze at its Arcane step in the 5-8yd dead zone.
        -- A hybrid deliberately bypasses HHA only when the game reports
        -- Arcane Shot out of range, retaining the source-registered
        -- zero-settings/Hawk-count priority for that tactical gap.
        local hawkPolicy = mode == "hha-gated"
            and "window.hha.next.summon_hawk"
            or "(!action.arcane_shot.in_range|window.hha.next.summon_hawk)"
        src = swapExactlyOnce(src,
            "actions+=/summon_hawk,if=action.summon_hawk.in_range&pet.hawk.count<2",
            "actions+=/summon_hawk,if=action.summon_hawk.in_range&pet.hawk.count<2&" .. hawkPolicy)
        src = swapExactlyOnce(src,
            "actions+=/arcane_shot,if=target.outside8&action.arcane_shot.in_range",
            "actions+=/arcane_shot,if=window.hha.next.arcane_shot&target.outside8&action.arcane_shot.in_range")
    else
        assert.are.equal("candidate-v1.2", mode)
    end
    return src
end

local function install(H, mode)
    local imported, warnings = H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery", "APLForever-HHA-Experiment", sourceFor(mode), C.PACK)
    assert.is_table(imported, "released native importer rejected file")
    assert.is_table(imported.precombat)
    assert.is_table(imported.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true),
        "unknown Hekili ability")
    assert.is_falsy((warnings or ""):find("Unknown key", 1, true),
        "engine did not recognise one of the syntax expressions")
    H.Hekili.DB.profile.packs[C.PACK].lists = imported
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({}, H.errors)
    assert.is_true(H.Hekili:IsListActive(C.PACK, "default"))
end

local function scenario(mode, distance)
    local world = setmetatable({ distance = distance }, { __index = C.WORLD })
    local content = setmetatable({ WORLD = world }, { __index = C })
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    install(H, mode)
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false
    local samples = {}
    local run = loop.run(L, 30417, {
        duration = 42,
        on = function(r, _, t)
            if r.combat <= 0 then return end
            local pressed = r.pressed[r.combat]
            if pressed and #samples < 30 then
                samples[#samples + 1] = { time = t, action = pressed }
            end
        end,
    }, { { H = H } })
    local casts = run.pressedBy or {}
    local first = {}
    for i = 1, math.min(run.combat, 3) do
        first[#first + 1] = run.ours[i] or "NO_ACTION"
    end
    local tail = {}
    for i = math.max(1, run.combat - 10), run.combat do
        local key = run.ours[i]
        if key then tail[#tail + 1] = key end
    end
    print(string.format(
        "HHA_V010 mode=%s distance=%s accepted=%s hawks=%d arcane=%d mana_final=%s events=%d errors=%d raises=%d first=%s last=%s",
        mode, tostring(distance), tostring(run.presses), casts.summon_hawk or 0,
        casts.arcane_shot or 0, tostring(run.us.power), #run.W.truth,
        run.errors or -1, run.raises or -1, table.concat(first, ","),
        table.concat(tail, ",")))
    for reason, count in pairs(run.refused or {}) do
        print(string.format("HHA_V010_REFUSED mode=%s distance=%d reason=%s count=%s",
            mode, distance, tostring(reason), tostring(count)))
    end
    assert.are.equal(0, run.errors, "native engine errors")
    assert.are.equal(0, run.raises, "native engine Lua raises")
    assert.are.same({}, run.refused, "native source rejected a recommended press")
    assert.is_true(run.combat >= 20 and #run.W.truth > 3,
        "fixture must advance actual world time and cast/swing events")
    assert.is_true((casts.summon_hawk or 0) >= 1,
        "zero source-accepted Hawk casts: regression or unusable HHA window")
    if distance == 6 then
        for _, ranged in ipairs({ "arcane_shot", "serpent_sting", "aimed_shot", "multi_shot" }) do
            assert.are.equal(0, casts[ranged] or 0,
                "out-of-range ranged shot accepted at 6 yards")
        end
    else
        assert.is_true((casts.arcane_shot or 0) >= 1,
            "no source-accepted Arcane Shot at legal 12-yard range")
    end
    return {
        mode = mode, distance = distance, hawks = casts.summon_hawk or 0,
        arcane = casts.arcane_shot or 0, accepted = run.presses,
        samples = samples, tail = tail
    }
end

describe("Hunter BM v0.10.0 source-native HHA capability and dead-zone risk", function()
    it("12 yd baseline vs HHA condition on fully imported independent v1.2", function()
        local baseline = scenario("candidate-v1.2", 12)
        local hha = scenario("hha-gated", 12)
        local hybrid = scenario("hha-range-hybrid", 12)
        -- These are capability comparisons, not speed/DPS rankings.
        assert.is_true(baseline.accepted >= 3 and hha.accepted >= 3 and hybrid.accepted >= 3)
        print(string.format("HHA_V010_12Y_DIFFERENCE hawk_delta=%d arcane_delta=%d accepted_delta=%d hybrid_hawk_delta=%d hybrid_arcane_delta=%d hybrid_accepted_delta=%d",
            hha.hawks - baseline.hawks, hha.arcane - baseline.arcane,
            hha.accepted - baseline.accepted,
            hybrid.hawks - baseline.hawks, hybrid.arcane - baseline.arcane,
            hybrid.accepted - baseline.accepted))
    end)

    it("6 yd confirms or rejects HHA full-sequence gating without a rejected shot", function()
        local baseline = scenario("candidate-v1.2", 6)
        local hha = scenario("hha-gated", 6)
        local hybrid = scenario("hha-range-hybrid", 6)
        -- The baseline v1.2 can safely use Hawk in the 5-8 yard ranged/melee
        -- dead zone; an HHA sequence's Arcane Shot step CANNOT be cast there.
        -- Record whether HHA holds at the Arcane step and costs future Hawks.
        -- A slower/blocked HHA must NOT displace the baseline.
        print(string.format("HHA_V010_6Y_RISK hawk_delta=%d accepted_delta=%d baseline_tail=%d hha_tail=%d",
            hha.hawks - baseline.hawks, hha.accepted - baseline.accepted,
            #baseline.tail, #hha.tail))
        print(string.format("HHA_V010_6Y_HYBRID hawk_delta=%d accepted_delta=%d hybrid_tail=%d",
            hybrid.hawks - baseline.hawks, hybrid.accepted - baseline.accepted,
            #hybrid.tail))
        assert.is_true(baseline.hawks >= 1, "existing six-yard castability lost")
        -- This hypothesis is tested without forcing a pass on equivalence;
        -- acceptance or rejection requires inspecting the actual cast counts.
        assert.is_true(hybrid.hawks >= 1, "hybrid removed all source-accepted Hawk casts")
        -- SOURCE-PINNED negative comparator: the pure HHA-gated experiment
        -- currently loses three source-accepted Hawks and three total presses
        -- by blocking at its uncastable Arcane step. Keep this regression
        -- explicit and fail for re-review if the actual native result changes.
        assert.is_true(hha.hawks < baseline.hawks,
            "HHA no longer loses Hawk upkeep in the six-yard gap; re-evaluate design")
        assert.is_true(hha.accepted < baseline.accepted,
            "HHA no longer loses accepted casts in the six-yard gap; re-evaluate design")
    end)
end)
