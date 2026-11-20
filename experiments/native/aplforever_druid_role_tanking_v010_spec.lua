-- Published Hekili Forever v0.10.0 P0/P1 source contract for the
-- 'tanking' expression. This is NOT a synthetic damage/survival simulation.
-- Forever defines 'tanking' = role.tank AND aggro. The game-facing client
-- pseudo-specialisation's role is used, not necessarily selected APL role.
--
-- The source Feral DPS world has DAMAGER role; Guardian's selector chooses
-- the Guardian package, but the fake client itself remains DAMAGER. The
-- consequences for actual live client role are explicitly NOT inferred.
local headless = require("Game.harness.headless")
local druid = require("Forever.helpers.druid_loop_world")
local root = assert(os.getenv("APLFOREVER_ROOT"))
local feralPath = "roles/Druid/Candidates/APL_Druid_Feral_v1.2_Draft.txt"

local function text(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local data = assert(f:read("*a"))
    f:close()
    return data
end

describe("v0.10.0 role-bound tanking state on the shipped DRUID fake client", function()
    for _, spec in ipairs({ "Feral", "Guardian" }) do
        it(spec .. " selected package does not secretly change the client DAMAGER role", function()
            local C = assert(druid[spec])
            local H = headless.new({ character = C.character(), pack = C.PACK })
            assert.are.same({}, H.loadErrors)
            assert.are.same({}, H.Hekili.Class.loadErrors or {})
            assert.are.equal("DAMAGER", H.ctl.role,
                "published fake client's role contract changed")
            assert.is_true(H.Hekili.State.role.attack)
            assert.is_false(H.Hekili.State.role.tank,
                "role.tank must reflect the CLIENT role, not selected APL name")
            assert.is_false(H.Hekili.State.tanking,
                "tanking=role.tank&aggro cannot be true in DAMAGER role")
            print(string.format(
                "DRUID_ROLE_V010 spec=%s selected_apl=%s client_role=%s role_tank=%s tanking=%s",
                spec, C.PACK, H.ctl.role,
                tostring(H.Hekili.State.role.tank),
                tostring(H.Hekili.State.tanking)))
        end)
    end
    it("Feral v1.2 has a likely unreachable positive Barkskin branch for DAMAGER-role clients", function()
        local s = text(feralPath)
        local needle = "actions.defensives=barkskin,if="
        local found, matches = nil, 0
        for line in s:gmatch("[^\n]+") do
            if line:sub(1,#needle) == needle then
                found = line
                matches = matches + 1
            end
        end
        assert.are.equal(1, matches)
        assert.is_truthy(found:find("&tanking&", 1, true),
            "Feral's originally documented reactive guard changed: reassess")
        assert.is_nil(s:find("health.pct", 1, true),
            "candidate cannot reintroduce hidden player HP")
        -- Since the released fake client's role.tank is false for Feral,
        -- the conjunction cannot be true regardless of health, range or
        -- aggro, and therefore the v1.2 positive defensive is *not proved*.
        -- A future candidate must use only a meaningful observable condition
        -- or keep the health-dependent defensive manual.
    end)
end)
