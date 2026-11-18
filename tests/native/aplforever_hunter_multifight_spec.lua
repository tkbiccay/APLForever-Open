-- Three consecutive fights on one addon boot, against the released Hunter world.
-- Compare our exact selected custom BM baseline and the untouched shipped pack.
-- Simulation only; do not infer live usefulness or damage superiority from presses.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local content = require("Forever.helpers.hunter_world").BeastMastery
local root = assert(os.getenv("APLFOREVER_ROOT"), "APLFOREVER_ROOT is required")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))

local function selected()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Hunter_BeastMastery" then
            return entry
        end
    end
    error("No selected Beast Mastery testing baseline")
end

local function imported(H)
    local entry = selected()
    local path = root .. "/" .. entry.apl_file
    local fh = assert(io.open(path, "rb"))
    local apl = assert(fh:read("*a"))
    fh:close()
    local parsed, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", apl, content.PACK)
    assert.is_table(parsed)
    assert.is_table(parsed.default)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = parsed
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.is_true(H.Hekili:IsListActive(content.PACK, "default"))
    assert.are.same({}, H.errors)
end

describe("Hunter Beast Mastery three consecutive fights (v0.8.3)", function()
    for _, useCustom in ipairs({ true, false }) do
        local label = useCustom and "custom" or "shipped"
        it("exercises " .. label .. " with combat resets and no reload", function()
            local L = loop.new(content)
            local H = L.us
            if useCustom then
                imported(H)
            end
            H.Hekili.DB.profile.toggles.cooldowns.value = false
            H.Hekili.DB.profile.toggles.defensives.value = false
            local sum = { fights = 0, hawk = 0, arcane = 0, presses = 0 }
            for fight = 1, 3 do
                local run = loop.run(L, 30417 + fight, { duration = 35 }, { { H = H } })
                assert.are.equal(0, run.raises)
                assert.are.equal(0, run.errors)
                assert.is_true(run.presses > 0)
                assert.are.same({}, run.refused)
                assert.is_true((run.pressedBy.summon_hawk or 0) > 0, label .. " missing Summon Hawk on fight " .. fight)
                sum.fights = sum.fights + 1
                sum.hawk = sum.hawk + (run.pressedBy.summon_hawk or 0)
                sum.arcane = sum.arcane + (run.pressedBy.arcane_shot or 0)
                sum.presses = sum.presses + run.presses
                print("BM_THREE_FIGHTS " .. label .. " " .. pretty.write({
                    fight = fight,
                    pressed = run.pressedBy,
                    refused = run.refused,
                    raises = run.raises,
                    errors = run.errors,
                    worldEnd = run.W.t,
                }, ""))
            end
            assert.are.equal(3, sum.fights)
            print("BM_THREE_FIGHTS_TOTAL " .. label .. " " .. pretty.write(sum, ""))
        end)
    end
end)
