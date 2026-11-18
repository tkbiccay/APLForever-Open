-- Hekili Forever v0.8.5 targeted Hunter pet recommendation experiment.
-- Tests exact v1.0 Hunter baselines, untouched shipped priorities, BM
-- v1.1 Draft and in-memory variants for MM/SV. Does not model pet casting,
-- ownership changes or actual recovery in Game.harness.world.
-- Never mistake a recommended icon for an accepted in-game action.
local headless = require("Game.harness.headless")
local hunter = require("Forever.helpers.hunter_world")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local root = assert(os.getenv("APLFOREVER_ROOT"))

local roles = {
    { key = "Hunter_BeastMastery", content = hunter.BeastMastery },
    { key = "Hunter_Marksmanship", content = hunter.Marksmanship },
    { key = "Hunter_Survival", content = hunter.Survival },
}

local function selected(role)
    for _, entry in ipairs(manifest) do
        if entry.apl_name == role then
            return entry
        end
    end
    error("missing exact native manifest entry: " .. role)
end

local function read(path)
    local f = assert(io.open(path, "rb"))
    local text = assert(f:read("*a"))
    f:close()
    return text
end

local PET_PRE = "actions.precombat=call_pet,if=!pet_out&!pet.dead&!talent.lone_wolf.enabled\n"
    .. "actions.precombat+=/revive_pet,if=pet.dead\n"
local PET_DEFAULT = "actions=call_pet,if=!pet_out&!pet.dead&!talent.lone_wolf.enabled\n"
    .. "actions+=/revive_pet,if=pet.dead\n"

local function testOnlyCandidate(apl)
    -- Explicitly turn each original list's first action into an appended
    -- action, preserving every other line/branch verbatim.
    local pre, npre = apl:gsub("^actions%.precombat=", "actions.precombat+=/", 1)
    assert.are.equal(1, npre, "unexpected precombat list syntax")
    local body, ndef = pre:gsub("\nactions=", "\nactions+=/", 1)
    assert.are.equal(1, ndef, "unexpected default list syntax")
    return PET_PRE .. PET_DEFAULT .. body
end

local function recommend(row, variant, state)
    local entry = selected(row.key)
    local char = row.content.character()
    -- The source hunter_world's legacy kit omits new Call/Revive actions.
    -- Explicitly give this level-60 character the source-known spells.
    -- This is a controlled learned-kit case, NOT a level/unlock assertion.
    char.known[#char.known + 1] = 883
    char.known[#char.known + 1] = 982
    if state.loneWolf then
        -- Preserve the fixture rather than mutating a shared P.talents table.
        local talents = {}
        for key, value in pairs(char.talents or {}) do talents[key] = value end
        talents[415370] = 1 -- source-registers lone_wolf at 415370
        char.talents = talents
    end
    local H = headless.new({ character = char, pack = row.content.PACK })
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})

    H.ctl.exists.pet = state.out or false
    H.ctl.dead.pet = state.dead or false
    H.ctl.usable[883] = { state.callUsable ~= false, false }
    H.ctl.usable[982] = { state.reviveUsable ~= false, false }

    if variant ~= "shipped" then
        local text = read(root .. "/" .. entry.apl_file)
        if row.key == "Hunter_BeastMastery" then
            assert.are.equal("v1.1", entry.revision,
                "v0.8.5 must select the new BM candidate")
            if variant == "original" then
                -- Source-compatible v1.0 is the exact archived comparator,
                -- verified by the manifest builder across all catalogue hashes.
                text = read(root .. "/roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt")
            end
        end
        if variant == "hypothesis" and row.key ~= "Hunter_BeastMastery" then
            text = testOnlyCandidate(text)
        end
        local parsed, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", text, row.content.PACK)
        assert.is_table(parsed)
        assert.is_table(parsed.precombat)
        assert.is_table(parsed.default)
        assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
        if variant == "hypothesis" then
            -- BM uses the actual complete v1.1 imported file. Other Hunter
            -- specs retain their unchanged v1.0 files plus memory-only guards.
            assert.are.equal("call_pet", parsed.precombat[1].action)
            assert.are.equal("revive_pet", parsed.precombat[2].action)
            assert.are.equal("call_pet", parsed.default[1].action)
            assert.are.equal("revive_pet", parsed.default[2].action)
        end
        local pack = assert(H.Hekili.DB.profile.packs[row.content.PACK])
        pack.lists = parsed
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        assert.is_true(H.Hekili:IsListActive(row.content.PACK, "default"))
    end
    assert.are.same({}, H.errors)
    assert.is_true(H.Hekili.Engine.Subscribe("Primary", function() end))
    H.ctl.inRange.target = true
    H.ctl.level.target = 60
    H.Fire("PLAYER_TARGET_CHANGED")
    H.Fire("SPELL_UPDATE_USABLE")
    local ok, err = headless.cycle(H, H.ctl.now + 0.2)
    assert.is_true(ok, tostring(err))
    assert.are.same({}, H.errors)
    local out = assert(H.Hekili.Engine.Output.Primary)
    local count = assert(out.count)
    local action = count > 0 and out.recs[1] and out.recs[1].actionName or nil
    print(string.format(
        "HUNTER_PET_V085 role=%s variant=%s state=%s known=883,982 pet_out=%s pet_dead=%s count=%s first=%s",
        row.key, variant, state.label, tostring(state.out), tostring(state.dead),
        tostring(count), tostring(action)
    ))
    return action
end

describe("Hunter v0.8.5 source-native pet upkeep recommendation, no world casts", function()
    local cases = {
        { label = "missing-pet", out = false, dead = false, expected = "call_pet" },
        { label = "dead-pet", out = true, dead = true, expected = "revive_pet" },
    }

    for _, row in ipairs(roles) do
        for _, state in ipairs(cases) do
            it(row.key .. " " .. state.label .. " selects correct test-only pet upkeep", function()
                local baseline = recommend(row, "original", state)
                local shipped = recommend(row, "shipped", state)
                local hypothesis = recommend(row, "hypothesis", state)
                assert.is_true(baseline ~= "call_pet" and baseline ~= "revive_pet",
                    "original unexpectedly contains new pet upkeep")
                assert.are.equal(state.expected, shipped, "source-shipped pet opener")
                assert.are.equal(state.expected, hypothesis, "test-only pet opener")
            end)
        end
        it(row.key .. " keeps normal priority with living pet", function()
            local action = recommend(row, "hypothesis",
                { label = "living-pet", out = true, dead = false })
            assert.is_true(action ~= "call_pet" and action ~= "revive_pet",
                "healthy pet must not be re-called or revived")
        end)
        it(row.key .. " rejects unlearned pet skills", function()
            -- Source kit still marks known, but the client explicitly says
            -- both actions unusable. Real low-level unlocks remain Not Run.
            local action = recommend(row, "hypothesis",
                { label = "unusable", out = false, dead = false, callUsable = false, reviveUsable = false })
            assert.is_true(action ~= "call_pet" and action ~= "revive_pet",
                "unusable pet action was selected")
        end)
    end

    it("Hunter Marksmanship Lone Wolf does not call absent pet", function()
        local row = roles[2]
        local action = recommend(row, "hypothesis",
            { label = "lone-wolf", out = false, dead = false, loneWolf = true })
        assert.is_true(action ~= "call_pet" and action ~= "revive_pet")
    end)
end)
