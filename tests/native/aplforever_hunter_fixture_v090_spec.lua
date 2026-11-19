-- Hekili Forever v0.9.0 at exact published commit
-- 8f95f2ea0a45428554c1e938ed7357b870030514.
-- The retired Beast Mastery / Marksmanship weave source worlds no longer
-- exist: this is a harness compatibility contract, NOT an APL change.
local hunter = require("Forever.helpers.hunter_world")

describe("Published v0.9.0 Hunter native fixture names", function()
    it("retired BM/MM weave worlds must not accidentally be used", function()
        assert.is_nil(hunter.BeastMastery)
        assert.is_nil(hunter.Marksmanship)
    end)

    it("retained exact BM/MM turret worlds and their source packs", function()
        assert.is_table(hunter.BeastMasteryTurret)
        assert.is_table(hunter.MarksmanshipTurret)
        assert.are.equal("Beast Mastery Turret (wowsims.com)",
            hunter.BeastMasteryTurret.PACK)
        assert.are.equal("Marksmanship Turret (wowsims.com)",
            hunter.MarksmanshipTurret.PACK)
        assert.is_function(hunter.BeastMasteryTurret.character)
        assert.is_function(hunter.MarksmanshipTurret.character)
    end)

    it("Survival's source key remains available", function()
        assert.is_table(hunter.Survival)
        assert.is_table(hunter.SurvivalTurret)
    end)
end)
