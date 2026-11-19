-- Hekili Forever v0.10.0 exact source, Feral Draft v1.2.
-- An import/real-press check: never a secret-player-health or mitigation oracle.
local loop = require("Game.harness.loop")
local druid = require("Forever.helpers.druid_loop_world")
local stock = druid.Feral
local root = assert(os.getenv("APLFOREVER_ROOT"), "APLFOREVER_ROOT is required")
local path = "roles/Druid/Candidates/APL_Druid_Feral_v1.2_Draft.txt"
local h = assert(io.open(root .. "/" .. path, "rb"))
local source = assert(h:read("*a"))
h:close()

local function install(H, content)
    local lists, warnings = H.Hekili:ImportSimcAPL("Druid_Feral", "APLForever", source, content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_table(lists.defensives)
    assert.are.equal(1, #lists.defensives, "only observable threat-gated Barkskin is APL-driven")
    assert.is_nil((warnings or ""):find("Unsupported action", 1, true))
    local pack = assert(H.Hekili.DB.profile.packs[content.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK, name), "missing standalone list " .. name)
    end
    assert.are.same({}, H.errors, "v0.10.0 must not warn about hidden player health")
end

local function scenario(defensives)
    -- Exact source loop's Feral character deliberately omits Barkskin from the
    -- fixed kit. Never claim a positive Barkskin acceptance from this scenario.
    -- This is a real spellbook-unavailable path and native DPS/fallback check.
    local L = loop.new(stock)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    install(H, stock)
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = defensives
    H.Hekili.DB.profile.toggles.movement.value = false
    local run = loop.run(L, 30417, { duration = 32 }, { { H = H } })
    local pressCount = 0
    for _, n in pairs(run.pressedBy or {}) do pressCount = pressCount + n end
    print(("FERAL_V12_V010 source=3c2cf3e defensive=%s accepted=%d barkskin=%d refused=%d"):format(
        tostring(defensives), pressCount, (run.pressedBy or {}).barkskin or 0, #run.refused))
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    assert.are.same({}, run.refused)
    assert.is_true(pressCount >= 3, "actual source combat must advance beyond three actions")
    assert.are.equal(0, (run.pressedBy or {}).barkskin or 0,
        "untrained Barkskin must never be recommended")
    assert.are.equal(0, (run.pressedBy or {}).frenzied_regeneration or 0,
        "hidden-health Frenzied Regeneration is intentionally manual")
    assert.are.equal(0, (run.pressedBy or {}).natures_grasp or 0,
        "hidden-health Nature's Grasp is intentionally manual")
end

describe("Standalone Feral v1.2 on released Forever v0.10.0", function()
    it("has no guessed health thresholds and preserves complete Cat/Bear/caster lists", function()
        assert.is_nil(source:find("health.pct", 1, true))
        assert.is_truthy(source:find("actions.cat_melee=", 1, true))
        assert.is_truthy(source:find("actions.bear_melee=", 1, true))
        assert.is_truthy(source:find("actions.caster=", 1, true))
        assert.is_truthy(source:find("actions.defensives=barkskin,", 1, true))
        assert.is_truthy(source:find("&combat>0&tanking&target.within5", 1, true))
        assert.is_nil(source:find("actions.defensives+=/", 1, true))
    end)
    for _, enabled in ipairs({ false, true }) do
        it("native source-accepted DPS and all final fallbacks, Defensives " ..
            tostring(enabled), function()
            scenario(enabled)
        end)
    end
end)
