-- Source-native, isolated Life Tap HEALTH/ MANA mechanics contract.
-- Distinct from APL castability: does NOT run a synthetic combat driver,
-- invent an in-combat HP guard, or claim low-level realistic stats.
local sourceWorld = require("Game.harness.world")
local ws = require("Forever.helpers.wowsims")
local model = require("Forever.aplforever_warlock_lifetap_model")

local learn = ws.learn("WARLOCK")

local function controlledUnit(hp, mana)
    local W = sourceWorld.new(30417)
    local us = {
        pt = 0, health = hp, healthMax = hp,
        power = mana, powerMax = mana + 1000,
        res = {}, auras = {}, target = nil,
        spentAt = {}, heldUntil = {}, weapons = { { 0, 0, 2 } },
        dmgMult = 1,
    }
    W.add(us)
    return W, us
end

describe("DEMO-006 Forever Life Tap payment by learned rank", function()
    it("matches the pinned DB2 six-rank unlock ladder", function()
        for i, row in ipairs({
            { 1454, 6 }, { 1455, 16 }, { 1456, 26 },
            { 11687, 36 }, { 11688, 46 }, { 11689, 56 },
        }) do
            assert.are.equal(row[2], learn[row[1]],
                "Source DB2 learn table changed; re-pin first")
            local a = model.amount(row[2], 0, 0)
            assert.are.equal(i, a.rank)
            assert.are.equal(row[1], a.spell)
        end
    end)

    it("matches rank points and up-to-ten level scaling", function()
        for _, row in ipairs({
            { 6, 1, 20 }, { 10, 1, 24 }, { 15, 1, 29 },
            { 16, 2, 65 }, { 25, 2, 74 },
            { 26, 3, 130 }, { 36, 4, 210 },
            { 46, 5, 300 }, { 56, 6, 420 }, { 60, 6, 424 },
        }) do
            local a = model.amount(row[1], 0, 0)
            assert.are.equal(row[2], a.rank)
            assert.are.equal(row[3], a.health)
            assert.are.equal(row[3], a.mana)
        end
    end)

    it("does not allow unlearned rank or impossible talent/Spirit", function()
        assert.has_error(function() model.amount(5, 30, 0) end)
        assert.has_error(function() model.amount(6, -1, 0) end)
        assert.has_error(function() model.amount(6, 30, 3) end)
    end)

    for _, row in ipairs({
        { level = 6, spirit = 35, improved = 0, hp = 300 },
        { level = 16, spirit = 50, improved = 0, hp = 450 },
        { level = 26, spirit = 65, improved = 1, hp = 900 },
        { level = 36, spirit = 80, improved = 2, hp = 1200 },
        { level = 46, spirit = 85, improved = 2, hp = 1600 },
        { level = 56, spirit = 90, improved = 0, hp = 2000 },
        { level = 60, spirit = 255, improved = 2, hp = 3000 },
    }) do
        it(("debits source-world HP and credits Mana: L%d I%d"):format(
            row.level, row.improved), function()
            local W, us = controlledUnit(row.hp, 0)
            local records = {}
            local amount = model.amount(row.level, row.spirit, row.improved)
            local before = us.health
            model.pay(W, us, amount, 0, records, row.improved)
            assert.are.equal(1, #records)
            local ev = records[1]
            assert.are.equal(before, ev.before)
            assert.are.equal(before - amount.health, us.health)
            assert.are.equal(us.health, ev.after)
            assert.are.equal(amount.health, ev.health)
            assert.are.equal(amount.mana, ev.mana)
            assert.are.equal(amount.mana, us.power)
            assert.are.equal(amount.rank, ev.rank)
            assert.is_true(ev.health > 0)
            print(("DEMO006_PAYMENT L%d rank%d spirit%d improved%d HPspent=%.2f ManaGained=%.2f HPremaining=%.2f"):format(
                row.level, amount.rank, row.spirit, row.improved,
                amount.health, amount.mana, us.health))
        end)
    end

    it("shows that Improved Life Tap increases only Mana, never health price", function()
        local same = {}
        for improved = 0, 2 do
            local a = model.amount(60, 100, improved)
            same[#same + 1] = a
            assert.are.equal(524, a.health)
            assert.is_true(math.abs(a.mana - 524 * (1 + 0.1 * improved)) < 0.001)
        end
        assert.is_true(same[3].mana > same[2].mana)
        assert.is_true(same[2].mana > same[1].mana)
    end)

    it("shows a controlled two-tap low-health scenario can exhaust HP", function()
        -- A COUNTERFACTUAL model, not verified live game permissibility:
        -- rank-1 at level 6 with Spirit 35 pays 55 HP per successful cast.
        local W, us = controlledUnit(100, 0)
        local a = model.amount(6, 35, 0)
        local records = {}
        model.pay(W, us, a, 0, records, 0)
        assert.are.equal(45, us.health)
        model.pay(W, us, a, 0, records, 0)
        assert.are.equal(0, us.health)
        assert.is_true(us.dead)
        assert.are.equal(2, #records)
        -- This does not claim a real Warlock can or should Life Tap twice at 100 HP.
    end)
end)
