-- Feral DPS v0.11.0 form-intent experiment; no APL revision or automatic promotion.
-- Compare immutable v1.3, shipped source, and ONE in-memory travel-only
-- combat transition. A source-native accepted cast is NOT evidence that the
-- addon can infer the player's intention to flee or that the change is safe.
local loop = require("Game.harness.loop")
local fake = require("Game.State.helpers.fake_api")
local druid = require("Forever.helpers.druid_loop_world")
local stock = assert(druid.Feral)
local root = assert(os.getenv("APLFOREVER_ROOT"))

local function read(path)
    local file = assert(io.open(root .. "/" .. path, "rb"))
    local text = assert(file:read("*a"))
    file:close()
    return text
end

local v13 = read("roles/Druid/Archive/APL_Druid_Feral_v1.3_Draft.txt")
local current = read("roles/Druid/Archive/APL_Druid_Feral_DPS_v1.0_Draft.txt")
local old = "actions+=/cat_form,if=action.cat_form.known&!buff.cat_form.up&!buff.bear_form.up&!buff.travel_form.up&!buff.aquatic_form.up&!buff.moonkin_form.up"
local proposed = "actions+=/cat_form,if=action.cat_form.known&!buff.cat_form.up&!buff.bear_form.up&!buff.aquatic_form.up&!buff.moonkin_form.up&(!buff.travel_form.up|combat>0&target.within5&!moving)"
local first = assert(v13:find(old, 1, true), "protected form anchor changed")
assert.is_nil(v13:find(old, first + #old, true), "ambiguous source replacement")
local experiment = v13:sub(1, first - 1) .. proposed .. v13:sub(first + #old)
local v14 = read("roles/Druid/Archive/APL_Druid_Feral_v1.4_Draft.txt")
assert.are.equal(experiment, v14, "Complete stored v1.4 differs from independently tested one-line hypothesis")

local function import(H, source, pack)
    local lists, warnings = H.Hekili:ImportSimcAPL(
        "Druid_Feral", "APLForever-Feral-Travel-Experiment", source, pack)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.cat)
    assert.is_table(lists.cat_melee)
    assert.is_table(lists.caster)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    assert.is_falsy((warnings or ""):find("Unknown key", 1, true))
    H.Hekili.DB.profile.packs[pack].lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({}, H.errors)
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(pack, name), name)
    end
end

local function newContent(form)
    local C = {
        character = function()
            local c = stock.character()
            if form == "travel" then
                local index
                for i, id in pairs(c.forms) do
                    if id == 783 then index = i end
                end
                assert.is_number(index, "published source fixture did not learn Travel Form")
                c.form = index
            else
                assert.are.equal("cat", form)
            end
            return c
        end,
        WORLD = setmetatable({
            distance = 4,
            attackers = 2,
            mobHealth = 1000000000,
        }, { __index = stock.WORLD }),
    }
    return setmetatable(C, { __index = stock })
end

local function scenario(name, form, seconds, moving)
    local C = newContent(form)
    -- The released engine snapshots the facade's GetUnitSpeed when the client
    -- is initialised. Install the controlled client response BEFORE loop.new,
    -- not by patching an already-booted Hekili. Never synthesise rage/energy.
    local realNew = fake.new
    fake.new = function(...)
        local api, ctl = realNew(...)
        local realSpeed = api.GetUnitSpeed
        api.GetUnitSpeed = function(unit)
            if unit == "player" then return moving and 7 or 0 end
            return realSpeed(unit)
        end
        return api, ctl
    end
    local ok, L = pcall(loop.new, C)
    fake.new = realNew
    assert.is_true(ok, tostring(L))
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    if name ~= "shipped" then
        import(H, name == "v13" and v13 or name == "v14" and v14 or experiment, C.PACK)
    end
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.minor_cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    local stats = { inCombatTicks = 0, formTicks = 0, everObservedTravel = false, playerMovingTicks = 0 }
    local run = loop.run(L, 30417, {
        duration = seconds,
        on = function(r)
            local state = H.Hekili.State
            if r.combat > 0 then
                stats.inCombatTicks = stats.inCombatTicks + 1
                if state.buff.travel_form.up then stats.everObservedTravel = true end
                if state.moving then stats.playerMovingTicks = stats.playerMovingTicks + 1 end
                if state.buff.cat_form.up then stats.formTicks = stats.formTicks + 1 end
            end
        end,
    }, { { H = H } })

    local presses = run.pressedBy or {}
    local cats = presses.cat_form or 0
    local attacks = (presses.claw or 0) + (presses.shred or 0)
        + (presses.rake or 0) + (presses.rip or 0)
        + (presses.ferocious_bite or 0)
    local refusals = 0
    for _, n in pairs(run.refused or {}) do refusals = refusals + n end
    print(("FERAL_TRAVEL_V011 profile=%s source_form=%s moving=%s accepted=%d cat_form=%d attack=%d refuses=%d errors=%d raises=%d combat_ticks=%d cat_ticks=%d moving_ticks=%d saw_travel=%s truth=%d"):format(
        name, form, tostring(moving == true), run.presses, cats, attacks, refusals, run.errors, run.raises,
        stats.inCombatTicks, stats.formTicks, stats.playerMovingTicks, tostring(stats.everObservedTravel),
        #run.W.truth))
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    return { cats = cats, attacks = attacks, refuses = refusals,
        accepted = run.presses, stats = stats, world = #run.W.truth }
end

describe("Feral v0.11 source-native Travel Form final fallback, no APL promotion", function()
    it("static source and escape intent negative: original and Current do not force a Travel shift", function()
        assert.is_truthy(v13:find(old, 1, true))
        assert.is_truthy(current:find("!buff.travel_form.up", 1, true))
        assert.is_nil(v13:find("settings.", 1, true))
        assert.is_truthy(experiment:find(proposed, 1, true))
        assert.is_truthy(proposed:find("combat>0&target.within5&!moving", 1, true))
        assert.is_truthy(proposed:find("!buff.aquatic_form.up&!buff.moonkin_form.up", 1, true))
    end)

    it("normal Cat baseline remains source-accepted with the in-memory change", function()
        local base = scenario("v13", "cat", 30)
        local alternative = scenario("hypothesis", "cat", 30)
        local stored = scenario("v14", "cat", 30)
        assert.are.equal(alternative.attacks, stored.attacks)
        assert.are.equal(alternative.cats, stored.cats)
        assert.are.equal(0, stored.refuses)
        assert.are.equal(0, base.refuses)
        assert.are.equal(0, alternative.refuses)
        assert.is_true(base.attacks >= 3, "source control must perform several actual attacks")
        assert.are.equal(base.attacks, alternative.attacks,
            "unrelated normal Cat rotation must remain exactly equal")
        assert.are.equal(base.cats, alternative.cats,
            "do not create unnecessary extra shifts in normal Cat form")
    end)

    it("Travel source-world comparator: no-action observation versus optional shift", function()
        local shipped = scenario("shipped", "travel", 38)
        local base = scenario("v13", "travel", 38)
        local alternative = scenario("hypothesis", "travel", 38)
        local stored = scenario("v14", "travel", 38)
        assert.are.equal(alternative.attacks, stored.attacks)
        assert.are.equal(alternative.cats, stored.cats)
        assert.are.equal(alternative.refuses, stored.refuses)
        assert.are.equal(0, alternative.stats.playerMovingTicks, "stationary test reports moving")
        assert.is_true(base.stats.inCombatTicks > 0,
            "cannot claim combat-form issue if the source world never entered combat")
        assert.is_true(base.stats.everObservedTravel,
            "client observer did not genuinely report Travel Form; experiment blocked")
        assert.is_true(base.world > 3,
            "no natural world progression; experiment blocked")
        assert.are.equal(0, alternative.refuses,
            "in-memory recovery recommendation was actually refused")
        print(("FERAL_TRAVEL_COMPARISON shipped=%d/%d protected=%d/%d hypothesis=%d/%d"):format(
            shipped.cats, shipped.attacks, base.cats, base.attacks,
            alternative.cats, alternative.attacks))
        -- No mandatory positive proof here: whether a safe switch can be
        -- triggered without losing travel/escape intent is a separate human
        -- decision. Report the native facts, not an unearned approval.
    end)

    it("actual source client movement signal prevents involuntary escape-form cancellation", function()
        local movingBase = scenario("v13", "travel", 20, true)
        local movingAlternative = scenario("hypothesis", "travel", 20, true)
        local movingStored = scenario("v14", "travel", 20, true)
        assert.are.equal(movingAlternative.cats, movingStored.cats)
        assert.are.equal(movingAlternative.attacks, movingStored.attacks)
        assert.is_true(movingStored.stats.playerMovingTicks > 0)
        assert.is_true(movingBase.stats.inCombatTicks > 0, "source did not enter combat")
        assert.is_true(movingAlternative.stats.playerMovingTicks > 0,
            "controlled GetUnitSpeed did not reach released-state moving expression")
        assert.is_true(movingAlternative.stats.everObservedTravel,
            "source did not observe the intended Travel Form")
        assert.are.equal(0, movingAlternative.cats,
            "moving player MUST NOT be urged to leave escape-oriented Travel Form")
        assert.are.equal(0, movingAlternative.refuses)
        assert.are.equal(0, movingBase.cats)
    end)
end)
