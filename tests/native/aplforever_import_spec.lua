-- This spec is copied into the exact pinned Hekili checkout by native-preflight.yml.
-- ImportSimcAPL, ParseActionList, LoadScripts and headless.cycle are upstream code;
-- this file only supplies APLForever bytes and asserts their native outcomes.
local headless = require("Game.harness.headless")
local root = assert(os.getenv("APLFOREVER_ROOT"), "APLFOREVER_ROOT is required")
local manifestPath = assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"), "APLFOREVER_NATIVE_MANIFEST is required")
local manifest = assert(dofile(manifestPath), "native manifest did not return entries")
local failures = {}

local fixture = {
    Druid = require("Forever.helpers.druid_loop_world"),
    Hunter = require("Forever.helpers.hunter_world"),
    Mage = require("Forever.helpers.mage_world"),
    Paladin = require("Forever.helpers.paladin_world"),
    Priest = require("Forever.helpers.priest_world"),
    Rogue = require("Forever.helpers.rogue_world"),
    Shaman = require("Forever.helpers.shaman_world"),
    Warlock = require("Forever.helpers.warlock_world"),
    Warrior = require("Forever.helpers.warrior_world"),
}

local function contentFor(entry)
    if entry.apl_name == "Warrior_Protection" then
        return require("Forever.helpers.protection_gate").content()
    end
    local byClass = assert(fixture[entry.class], "no source fixture for " .. entry.class)
    if entry.class == "Warrior" and entry.spec == "Arms" then
        return byClass
    end
    -- Exact published v0.9.0 retired BM/MM weave worlds and ships only
    -- BeastMasteryTurret / MarksmanshipTurret. Older pinned v0.8.x
    -- workflows must retain their original BeastMastery / Marksmanship
    -- fixtures, not silently compare unlike reference builds.
    if entry.class == "Hunter"
        and (entry.spec == "BeastMastery" or entry.spec == "Marksmanship") then
        if os.getenv("APLFOREVER_SOURCE_RELEASE") == "v0.9.0" then
            return assert(byClass[entry.spec .. "Turret"],
                "v0.9.0 source lacks retired Hunter replacement world for " .. entry.apl_name)
        end
        return assert(byClass[entry.spec],
            "legacy source lacks Hunter world for " .. entry.apl_name)
    end
    return assert(byClass[entry.spec], "no source fixture for " .. entry.apl_name)
end

local function read(path)
    local handle = assert(io.open(path, "rb"))
    local value = handle:read("*a")
    handle:close()
    return value
end

local function entriesForRole(aplName)
    local rows = {}
    for _, entry in ipairs(manifest) do
        if entry.apl_name == aplName then
            rows[#rows + 1] = entry
        end
    end
    return rows
end

local function unsupportedWarnings(warnings)
    local unsupported = {}
    for line in (warnings or ""):gmatch("[^\n]+") do
        local trinkets = line:find("This profile is missing support for generic trinkets", 1, true)
        local itemAdvice = line:find(" - [Use Items]", 1, true) or line:find(" - [Trinket", 1, true)
        if not line:match("^Imported %d+ action lists%.$") and not trinkets and not itemAdvice then
            unsupported[#unsupported + 1] = line
        end
    end
    return unsupported
end

-- Engine/Output.lua preallocates twelve rec tables. Only recs[1..count]
-- were actually published; inspecting three slots blindly manufactures false
-- "record-without-actionName" findings when fewer than three were published.
local function recommendationNames(H)
    local output = H.Hekili.Engine.Output.Primary
    local result, missing = {}, 0
    local count = assert(output and output.count, "native output count is missing")
    assert.is_true(count >= 0 and count <= 12, "invalid native output count")
    for i = 1, 3 do
        if i > count then
            result[i] = "<not-published>"
        else
            local rec = output.recs[i]
            if rec and rec.actionName then
                result[i] = rec.actionName
            else
                result[i] = "<published-without-actionName>"
                missing = missing + 1
            end
        end
    end
    return result, count, missing
end

local function importAndEvaluate(entry, H, content)
    local path = root .. "/" .. entry.apl_file
    local text = read(path)
    assert.equal(entry.class .. "_" .. entry.spec, entry.apl_name)

    -- This is the production importer entry point in src/Hekili/Options/Options.lua.
    local imported, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", text, content.PACK)
    assert.is_table(imported, entry.apl_name .. " " .. entry.apl_file .. ": importer returned no lists")
    assert.is_table(imported.default, entry.apl_name .. ": native importer omitted default list")
    assert.is_table(imported.precombat, entry.apl_name .. ": native importer omitted precombat list")
    assert.is_true(#imported.default > 0, entry.apl_name .. ": default list was empty")
    local rejects = unsupportedWarnings(warnings)
    local importStatus = #rejects == 0 and "PASS" or "FAIL"
    if #rejects > 0 then
        failures[#failures + 1] = string.format("%s %s native importer: %s",
            entry.apl_name, entry.apl_file, table.concat(rejects, "; "))
    end

    -- LoadScripts compiles the import through Hekili's source Script engine.
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK], "missing native source pack " .. content.PACK)
    pack.lists = imported
    H.Hekili:LoadScripts()
    local compileStatus = #H.errors == 0 and "PASS" or "FAIL"
    if #H.errors > 0 then
        failures[#failures + 1] = string.format("%s %s native script compilation: %s",
            entry.apl_name, entry.apl_file, table.concat(H.errors, "; "))
    end
    assert.is_true(H.Hekili.Engine.Subscribe("Primary", function() end))

    H.ctl.inRange.target, H.ctl.level.target = true, 60
    H.Fire("PLAYER_TARGET_CHANGED")
    H.Fire("PLAYER_REGEN_DISABLED")
    local ok, err = headless.cycle(H, H.ctl.now + 0.2)
    assert.is_true(ok, entry.apl_name .. ": native recommendation update failed: " .. tostring(err))
    local evaluationStatus = #H.errors == 0 and "PASS" or "FAIL"
    if #H.errors > 0 then
        failures[#failures + 1] = string.format("%s %s native engine evaluation: %s",
            entry.apl_name, entry.apl_file, table.concat(H.errors, "; "))
    end
    local names, published, unresolved = recommendationNames(H)
    -- This test is importer/one-update validation only. Zero published icons
    -- can be a legitimate wait; count or unresolved fields are diagnostics,
    -- NOT proof of castability or an executed recommendation sequence.

    local actionCount = 0
    for _, list in pairs(imported) do
        actionCount = actionCount + #list
    end
    print(string.format(
        "NATIVE_IMPORT role=%s revision=%s file=%s sha256=%s lists=%d actions=%d importer=%s compile=%s engine_update=%s loop=NOT_RUN published=%d unresolved_in_published_first3=%d warnings=%s recs=%s,%s,%s",
        entry.apl_name, entry.revision, entry.apl_file, entry.sha256,
        (function() local n = 0; for _ in pairs(imported) do n = n + 1 end; return n end)(),
        actionCount, importStatus, compileStatus, evaluationStatus,
        published, unresolved,
        warnings and warnings:gsub("\n", " | ") or "<none>",
        names[1], names[2], names[3]
    ))
    return names
end

local function verifyNativeRole(aplName)
    local rows = entriesForRole(aplName)
    assert.is_true(#rows > 0, "no manifest revisions for " .. aplName)
    local entry = rows[1]
    local content = contentFor(entry)
    local character = content.character()
    local H = headless.new({ character = character, pack = content.PACK })
    assert.are.same({}, H.loadErrors, aplName .. ": headless Hekili did not initialize")
    assert.are.same({}, H.Hekili.Class.loadErrors or {}, aplName .. ": Hekili class kit did not load")
    for _, revision in ipairs(rows) do
        local ok, err = pcall(importAndEvaluate, revision, H, content)
        if not ok then
            failures[#failures + 1] = string.format("%s %s native harness execution: %s",
                revision.apl_name, revision.apl_file, tostring(err))
        end
    end
end

describe("APLForever profiles through pinned native Hekili importer and engine", function()
    it("checks every supported role and reports native compatibility findings", function()
        local ordered = { "Warrior_Protection", "Druid_Guardian", "Warlock_Demonology" }
        local visited = {}
        for _, aplName in ipairs(ordered) do
            visited[aplName] = true
        end
        for _, entry in ipairs(manifest) do
            if not visited[entry.apl_name] then
                visited[entry.apl_name] = true
                ordered[#ordered + 1] = entry.apl_name
            end
        end
        for _, aplName in ipairs(ordered) do
            verifyNativeRole(aplName)
        end

        assert.are.same({}, failures, "native preflight findings:\n" .. table.concat(failures, "\n"))
    end)
end)
