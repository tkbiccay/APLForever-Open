-- Guardian/BM P0 are unchanged. Current-release compatibility probe for
-- the exact protected Warrior Arms v1.0 precombat Bloodrage health safeguard.
-- RUN AGAINST THE REAL PUBLIC Hekili Forever v0.10.0 source, never retail.
--
-- The upstream source warns on any condition containing "health.pct"
-- without checking the list. The player's health is observable PREcombat
-- but is 100/hidden IN combat. This test preserves the original APL and
-- inspects the *precisely scoped* warning and state. Not DPS/cast proof.
local headless = require("Game.harness.headless")
local C = require("Forever.helpers.warrior_world")
local root = assert(os.getenv("APLFOREVER_ROOT"), "APLFOREVER_ROOT required")
local sourcePath = "roles/Warrior/Current/APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt"

local f = assert(io.open(root .. "/" .. sourcePath, "rb"))
local source = assert(f:read("*a"))
f:close()

local exact = "actions.precombat+=/bloodrage,use_off_gcd=1,if=action.bloodrage.known&toggle.minor_cooldowns&target.is_boss&health.pct>=95&rage.lo<=10&!buff.bloodrage.up"
local expectedErrorFormat = "Forever: %s; `%s` in pack `%s` list `%s` entry %d (%s): %s."

describe("Protected Warrior Arms v1.0 v0.10.0 precombat health warning", function()
    it("pins source and proves no reachable combat-line player health dependence", function()
        local count = 0
        for line in source:gmatch("[^\n]+") do
            if line:find("health.pct", 1, true) then
                count = count + 1
                assert.are.equal(exact, line, "unexpected new health-dependent priority")
            end
        end
        assert.are.equal(1, count, "exact one health condition, only precombat")
        assert.is_nil(source:find("target.health.pct", 1, true),
            "target health also secret, do not misclassify it")
    end)

    it("imports exact file and categorises only the actual precombat warning", function()
        local H = headless.new({ character = C.character(), pack = C.PACK })
        assert.are.same({}, H.loadErrors)
        assert.are.same({}, H.Hekili.Class.loadErrors or {})
        local lists, importWarnings = H.Hekili:ImportSimcAPL(
            "Warrior_Arms", "APLForever", source, C.PACK)
        assert.is_table(lists)
        assert.is_table(lists.default)
        assert.is_table(lists.precombat)
        assert.are.equal("bloodrage", lists.precombat[2].action)
        assert.is_falsy((importWarnings or ""):find("Unsupported action", 1, true))
        H.Hekili.DB.profile.packs[C.PACK].lists = lists
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(C.PACK, name),
                "complete APL list inactive " .. name)
        end
        assert.are.same({ expectedErrorFormat }, H.errors,
            "do not excuse actual compiler errors or a second warning")
        assert.are.equal(1, #H.Hekili.ErrorKeys)
        local expectedKey = ("Forever: your health is hidden in combat; `health.pct` in pack `%s` list `precombat` entry 2 (bloodrage): your health reads full in combat, so a low-health check never passes there."):format(C.PACK)
        assert.are.same({ expectedKey }, H.Hekili.ErrorKeys,
            "warning was not EXACTLY the precombat-only Bloodrage scanner warning")

        -- The condition is NOT safe in combat merely because this warning
        -- was classified: verify the released facade's health visibility.
        H.ctl.inRange.target, H.ctl.level.target = true, -1
        H.ctl.healthMax, H.ctl.health = 1000, 700
        H.Fire("PLAYER_TARGET_CHANGED")
        local ok, err = headless.cycle(H, H.ctl.now + 0.2)
        assert.is_true(ok, tostring(err))
        local outOfCombat = H.Hekili.State.health.pct
        assert.are.equal(70, outOfCombat,
            "actual player health should remain readable before a fight")
        H.ctl.combat = true
        H.Fire("PLAYER_REGEN_DISABLED")
        ok, err = headless.cycle(H, H.ctl.now + 0.4)
        assert.is_true(ok, tostring(err))
        local inCombat = H.Hekili.State.health.pct
        assert.are.equal(100, inCombat,
            "combat health is hidden/full and never a valid low-HP trigger")
        assert.are.same({ expectedErrorFormat }, H.errors,
            "unexpected additional engine/script errors")
        print("ARMS_V010_PRECOMBAT_SCANNER only_precombat=true warning=EXPECTED_NOT_SILENCED out_of_combat_health=70 in_combat_health=100 native_import=PASS actual_bloodrage_cast=NOT_TESTED")
    end)
end)
