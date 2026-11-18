-- Warrior Fury v1.0 -> guarded APL hypothesis, dual-state source ON/OFF,
-- out-of-combat Charge vs in-combat Intercept at honest native distances.
-- Released v0.8.6: real state, source cast events, independent shipped baseline.
-- Test fixture's 8-25 yd mobility bounds are pinned to two dated Forever
-- spellbook exports in docs/Tests_Warrior_Fury_v1.1.md; no in-game assertion.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local ws = require("Forever.helpers.wowsims")
local ww = require("Forever.helpers.warrior_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function read(path)
    local f = assert(io.open(path, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end

local function selected()
    for _, x in ipairs(manifest) do
        if x.apl_name == "Warrior_Fury" then
            assert.are.equal("roles/Warrior/Current/APL_Warrior_Fury_DPS_v1.0_Draft.txt", x.apl_file)
            assert.are.equal("bff9e4ecfac234f58d7057f47c1c1c4ef047f8d98f9018c506530d143e5d5b23", x.sha256)
            return x
        end
    end
    error("Fury protected Current not found in manifest")
end

local function guard(text)
    local edits = {
        {
            "actions.precombat+=/charge,use_off_gcd=1,if=buff.battle_stance.up",
            "actions.precombat+=/charge,use_off_gcd=1,if=toggle.movement&buff.battle_stance.up",
        },
        {
            "actions.engage+=/charge,use_off_gcd=1,if=combat=0&buff.battle_stance.up",
            "actions.engage+=/charge,use_off_gcd=1,if=toggle.movement&combat=0&buff.battle_stance.up",
        },
        {
            "actions.engage+=/intercept,use_off_gcd=1,if=combat>0&buff.berserker_stance.up",
            "actions.engage+=/intercept,use_off_gcd=1,if=toggle.movement&combat>0&buff.berserker_stance.up",
        },
    }
    for _, pair in ipairs(edits) do
        local n = 0
        local i = assert(text:find(pair[1], 1, true), "missing exact original movement action")
        local j = assert(text:find(pair[1], i + 1, true) == nil,
            "original movement action duplicated")
        text = text:sub(1, i - 1) .. pair[2] .. text:sub(i + #pair[1])
    end
    return text
end

local function install(H, C, source, entry)
    local text = read(root .. "/" .. entry.apl_file)
    if source == "guarded" or source == "candidate" then
        local expected = guard(text)
        local file = "roles/Warrior/Archive/APL_Warrior_Fury_v1.1_Draft.txt"
        if source == "candidate" then
            local n
            expected, n = expected:gsub("rage.lo>=action.bloodthirst.cost",
                "rage.lo>=action.bloodthirst.cost+5")
            assert.are.equal(2, n,
                "new v1.2 must alter exactly ST+AoE Bloodthirst Rage buffers")
            file = "roles/Warrior/Candidates/APL_Warrior_Fury_v1.2_Draft.txt"
        end
        text = read(root .. "/" .. file)
        assert.are.equal(expected, text,
            "full standalone Fury movement/BT Candidate differs from protected Current")
    end
    local lists, warnings = H.Hekili:ImportSimcAPL(entry.apl_name,
        "APLForever", text, C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_true(#lists.default > 0)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local p = assert(H.Hekili.DB.profile.packs[C.PACK])
    p.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for key in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK, key), key)
    end
    assert.are.same({}, H.errors)
end

local function runCase(source, spell, yards, mobility)
    local level = spell == "charge" and 10 or 60
    local C = ws.content(ww.Fury, {
        pack = "Fury (wowsims.com)",
        level = level,
        talents = ws.header("warrior_fury").talents,
        learn = ws.learn("WARRIOR"),
        race = ws.race("warrior_fury"),
        kit = { "berserker_rage", "reckless_swings" },
    })
    local baseCharacter = C.character
    function C.character()
        local c = baseCharacter()
        c.form = spell == "charge" and 1 or 3
        -- The real 8–25yd minimum/maximum values of both movement spells,
        -- absent from the default Fury headless character, on every trainer
        -- rank the simulated character could use. This is an explicit
        -- fixed-fixture client spellbook, not an APL expression or hidden read.
        c.ranges = c.ranges or {}
        for _, id in ipairs({100, 6178, 11578, 20252, 20616, 20617}) do
            c.ranges[id] = { 8, 25 }
        end
        return c
    end
    local baseResolve = C.resolve
    function C.resolve(key, H)
        local p = baseResolve(key, H)
        if key == "charge" or key == "intercept" then
            p.range = { 8, 25 } -- real world-source W.press now rejects illegal yards
        end
        return p
    end
    C.WORLD = setmetatable({
        mobHealth = 1000000000,
        attackers = 1,
        mobDamage = { 2, 3 },
        mobPeriod = 2,
        distance = yards,
        power = spell == "charge" and 0 or 50,
    }, { __index = C.WORLD })
    local L = loop.new(C)
    local H = L.us
    local entry = selected()
    assert.are.same({}, H.loadErrors)
    -- Set toggles BEFORE compiling/importing any custom APL. The native
    -- compiler may capture a static condition during LoadScripts.
    local toggles = H.Hekili.DB.profile.toggles
    toggles.movement.value = mobility
    toggles.cooldowns.value = false
    toggles.minor_cooldowns.value = false
    toggles.defensives.value = false
    if toggles.interrupts then toggles.interrupts.value = false end
    if source ~= "shipped" then install(H, C, source, entry) end
    if yards == 12 then
        local stateToggle = H.Hekili.State.toggle.movement
        local cachedToggles = H.Hekili.Engine.settings.toggles
        local stateSpec = H.Hekili.State.spec
        print("FURY_MOVE_TOGGLE_V086 " .. source .. " " .. spell ..
            " mobility=" .. tostring(mobility) ..
            " profile=" .. tostring(toggles.movement.value) ..
            " engine=" .. tostring(cachedToggles and cachedToggles.movement
                and cachedToggles.movement.value) ..
            " state=" .. tostring(stateToggle) ..
            " specid=" .. tostring(stateSpec and stateSpec.id))
    end

    assert.are.equal(spell == "charge" and 1 or 3, L.form)
    assert.is_true(H.Hekili.State:IsKnown(spell))
    local move, accepted, cursor = 0, 0, 0
    local rangeSamples, stage, seenDistance = {}, {}, false
    local harnessForcedOff, firstOnTick = nil, nil
    local result = loop.run(L, 30417, {
        duration = 9,
        on = function(r, _, t)
            -- The RELEASED source's tests/Game/harness/loop.lua:390
            -- explicitly sets movement.value=(R~=nil), forcing OFF
            -- for any non-replay world, regardless of the player's setting.
            -- Restore the requested ON/OFF setting on the source hook
            -- AFTER this harness-only reset, before subsequent combat polls.
            -- Do NOT change the addon, ability/World presses or APL.
            if harnessForcedOff == nil then
                harnessForcedOff = toggles.movement.value == false
                firstOnTick = t
            end
            toggles.movement.value = mobility
            if r.W.distance == yards then seenDistance = true end
            local S = H.Hekili.State
            if r.W.distance then
                local form = r.us.form
                local inRange = S.action[spell].in_range
                local pos = (inRange and "in" or "out")
                if not rangeSamples[pos] then rangeSamples[pos] = t end
                if not stage[form] then stage[form] = t end
            end
            for i = cursor + 1, #r.W.truth do
                local e = r.W.truth[i]
                if e.src == r.us and
                    (e.kind == "cast" or e.kind == "queue") then
                    accepted = accepted + 1
                    if e.spell == H.ns.VirtualState.KnownID(
                        H.Hekili.Class.abilities[spell].id) then
                        move = move + 1
                    end
                end
            end
            cursor = #r.W.truth
        end,
    }, {{ H = H }})
    local n = result.pressedBy[spell] or 0
    assert.are.equal(n, move, "actual source events must equal counted accepted mobility")
    assert.is_true(seenDistance, "actual world distance not propagated")
    assert.are.equal(0, result.errors)
    assert.are.equal(0, result.raises)
    assert.is_true(accepted >= 0)
    print("WARRIOR_FURY_MOVE_V086 " .. source .. " " .. spell ..
        " " .. yards .. "yd movement=" .. tostring(mobility) ..
        " " .. pretty.write({
            acceptedMobility = move, acceptedTotal = accepted,
            firstTargetRangeRead = rangeSamples,
            observedForms = stage,
            sourceRefusals = result.refused,
            sourcePresses = result.pressedBy,
            harnessForcedOff = harnessForcedOff,
            resetRestoredAt = firstOnTick,
        }, ""))

    -- Exact original is intentionally the red baseline: OFF really allows
    -- movement. Do not incorrectly count this as a safety pass.
    if source == "current" and yards == 12 and not mobility then
        assert.is_true(move >= 1,
            "red baseline must reproduce custom Fury v1.0's movement-off breach")
    end
    assert.is_true(harnessForcedOff,
        "source loop's non-replay Movement OFF reset changed; inspect native harness")
    assert.are.equal(mobility, toggles.movement.value,
        "on callback must restore user toggle for subsequent source polls")
    if source == "guarded" or source == "candidate" then
        if not mobility or yards == 3 or yards == 30 then
            assert.are.equal(0, move,
                "guarded Fury must never accept disabled/out-of-range movement")
        elseif yards == 12 then
            assert.is_true(H.Hekili.State.toggle.movement,
                "Movement ON flag unexpectedly false after restoration")
            assert.is_true(move >= 1,
                "guarded Fury must preserve valid intended movement when ON")
        end
    end
    if yards == 3 or yards == 30 then
        assert.are.equal(0, move,
            "actual world W.press must reject outside 8-25 yd in every profile")
    end
end

describe("Warrior Fury movement toggle source-visible valid-distance gate v0.8.6", function()
    for _, spell in ipairs({ "charge", "intercept" }) do
        for _, yards in ipairs({ 3, 12, 30 }) do
            for _, mobility in ipairs({ false, true }) do
                for _, source in ipairs({ "current", "guarded", "candidate", "shipped" }) do
                    it(source .. " " .. spell .. " " .. yards .. "yd movement=" ..
                        tostring(mobility), function()
                        runCase(source, spell, yards, mobility)
                    end)
                end
            end
        end
    end
end)
