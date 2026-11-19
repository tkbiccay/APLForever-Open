-- Hunter Beast Mastery v0.9.0 Turret — client-state pet icon regression only.
-- SOURCE-PIN: Hekili Forever v0.9.0 8f95f2ea0a45428554c1e938ed7357b870030514.
-- This intentionally does NOT model a successful Call/Revive Pet cast, ownership
-- transition or three actual state-advanced presses. No in-game approval follows.
local headless = require("Game.harness.headless")
local hunter = require("Forever.helpers.hunter_world")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local root = assert(os.getenv("APLFOREVER_ROOT"))
local C = assert(hunter.BeastMasteryTurret, "released v0.9.0 Turret source fixture absent")

local function selected()
    for _, entry in ipairs(manifest) do
        if entry.apl_name == "Hunter_BeastMastery" then
            assert.are.equal("v1.1", entry.revision,
                "v0.9.0 must select the source-compatible BM v1.1 Draft for testing, not Approved")
            return entry
        end
    end
    error("BM role absent from exact immutable source manifest")
end

local function read(path)
    local f = assert(io.open(path, "rb"))
    local bytes = assert(f:read("*a"))
    f:close()
    return bytes
end

local function first(mode, state)
    local character = C.character()
    -- The published Turret loop kit omits pet-recovery spells because its
    -- source-world tamed pet starts alive. Add source-registered learned 883/982
    -- for this controlled CLIENT usability test only, NOT a low-level assertion.
    character.known[#character.known + 1] = 883
    character.known[#character.known + 1] = 982

    local H = headless.new({ character = character, pack = C.PACK })
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    H.ctl.exists.pet = state.out
    H.ctl.dead.pet = state.dead
    H.ctl.usable[883] = { state.callUsable ~= false, false }
    H.ctl.usable[982] = { state.reviveUsable ~= false, false }

    if mode ~= "shipped" then
        local src = mode == "archived"
            and "roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt"
            or selected().apl_file
        local parsed, warnings = H.Hekili:ImportSimcAPL(
            "Hunter_BeastMastery", "APLForever", read(root .. "/" .. src), C.PACK)
        assert.is_table(parsed)
        assert.is_table(parsed.precombat)
        assert.is_table(parsed.default)
        assert.is_falsy((warnings or ""):find("Unsupported action", 1, true),
            "Unrecognised action in native Hunter BM APL")
        if mode == "candidate" then
            assert.are.equal("call_pet", parsed.precombat[1].action)
            assert.are.equal("revive_pet", parsed.precombat[2].action)
            assert.are.equal("call_pet", parsed.default[1].action)
            assert.are.equal("revive_pet", parsed.default[2].action)
        end
        local pack = assert(H.Hekili.DB.profile.packs[C.PACK])
        pack.lists = parsed
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        assert.is_true(H.Hekili:IsListActive(C.PACK, "default"))
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
    local output = assert(H.Hekili.Engine.Output.Primary)
    local firstAction = output.count > 0 and output.recs[1].actionName or nil
    print(string.format("BM_V090_PET mode=%s state=%s first=%s count=%s",
        mode, state.label, tostring(firstAction), tostring(output.count)))
    return firstAction
end

local function noRecovery(action)
    return action ~= "call_pet" and action ~= "revive_pet"
end

describe("BM v0.9.0 Turret main-pet client recommendation (NOT cast success)", function()
    it("missing, usable main pet selects Call Pet in shipped and v1.1 Draft", function()
        local state = { label = "missing", out = false, dead = false }
        assert.are.equal("call_pet", first("shipped", state))
        assert.are.equal("call_pet", first("candidate", state))
        assert.is_true(noRecovery(first("archived", state)))
    end)

    it("dead, revivable main pet selects Revive Pet in shipped and v1.1 Draft", function()
        local state = { label = "dead", out = true, dead = true }
        assert.are.equal("revive_pet", first("shipped", state))
        assert.are.equal("revive_pet", first("candidate", state))
        assert.is_true(noRecovery(first("archived", state)))
    end)

    it("living main pet does not issue recovery icon", function()
        local state = { label = "living", out = true, dead = false }
        for _, mode in ipairs({ "shipped", "archived", "candidate" }) do
            assert.is_true(noRecovery(first(mode, state)), mode)
        end
    end)

    it("missing pet but Call Pet unusable does not suggest recovery", function()
        local state = { label = "call-unusable", out = false, dead = false,
            callUsable = false, reviveUsable = false }
        assert.is_true(noRecovery(first("shipped", state)))
        assert.is_true(noRecovery(first("candidate", state)))
    end)

    it("dead pet but Revive Pet unusable does not suggest recovery", function()
        local state = { label = "revive-unusable", out = true, dead = true,
            reviveUsable = false }
        assert.is_true(noRecovery(first("shipped", state)))
        assert.is_true(noRecovery(first("candidate", state)))
    end)
end)
