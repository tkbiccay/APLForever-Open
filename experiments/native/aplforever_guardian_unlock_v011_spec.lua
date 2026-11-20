-- Hekili Forever v0.11.0: P0 Guardian levelling unlock and final-tail gate.
-- Compare shipped, protected v1.0 Reported Working, full unselected v1.5.
-- True source-game accepted/refused presses with unlocked level-bound kit;
-- NO fake Rage/health, forced auras, source-core rewrites or DPS claims.
local loop = require("Game.harness.loop")
local ws = require("Forever.helpers.wowsims")
local druid = require("Forever.helpers.druid_loop_world")
local stock = assert(druid.Guardian)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local learn = setmetatable({
    -- Explicit released Guardian source/test pin: remove endgame-only talent
    -- shortcuts at low levels; Primal Bite's authoring unlock remains level 34.
    [417141] = math.huge, [1328617] = math.huge, [1328616] = 34,
}, { __index = ws.learn("DRUID") })
local files = {
    working = "roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt",
    candidate = "roles/Druid/Candidates/APL_Druid_Guardian_v1.5_Draft.txt",
}
local cases = {
    { level = 9,  label = "caster-before-bear", attackers = 1 },
    { level = 10, label = "bear-first-rank", attackers = 1 },
    { level = 20, label = "mid-level-bear", attackers = 1 },
    { level = 31, label = "pre-high-kit", attackers = 2 },
    { level = 34, label = "primal-bite-boundary", attackers = 2 },
    { level = 60, label = "high-kit", attackers = 2 },
}
local function read(file)
    local f = assert(io.open(root .. "/" .. file, "rb"))
    local code = assert(f:read("*a"))
    f:close()
    return code
end

local function contentAt(c)
    local w = ws.content(stock, {
        pack = stock.PACK, level = c.level, learn = learn,
        talents = ws.header("druid_guardian").talents,
        race = ws.race("druid_guardian"),
        gear = c.level == 60 and ws.gear("druid_guardian") or nil,
    })
    -- Actual Forever Guardian source knows unshifted caster at level 9.
    -- The stock Guardian fixture defaults to Bear; correct this one source
    -- client observation without adding an unlearned spell or injected mana.
    if c.level < 10 then
        local character = w.character
        w.character = function()
            local ch = character()
            ch.form = 0
            return ch
        end
    end
    w.WORLD.attackers = c.attackers
    w.WORLD.mobHealth = 1000000000 -- no forced early death
    return w
end
local function install(H, w, which)
    if which == "shipped" then return end
    local lists, warnings = H.Hekili:ImportSimcAPL("Druid_Guardian",
        "APLForever-Guardian-LevelGate", read(files[which]), w.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    assert.is_falsy((warnings or ""):find("Unknown key", 1, true))
    H.Hekili.DB.profile.packs[w.PACK].lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do assert.is_true(H.Hekili:IsListActive(w.PACK,name),name) end
    assert.are.same({}, H.errors)
end
local function run(c, which)
    local w = contentAt(c)
    local L = loop.new(w)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    install(H, w, which)
    H.Hekili.DB.profile.toggles.cooldowns.value = false
    H.Hekili.DB.profile.toggles.defensives.value = false
    H.Hekili.DB.profile.toggles.movement.value = false

    local S = H.Hekili.State
    local known = {
        bear = S:IsKnown("bear_form"), maul = S:IsKnown("maul"),
        lacerate = S:IsKnown("lacerate"), bite = S:IsKnown("primal_bite"),
        roar = S:IsKnown("demoralizing_roar"), wrath = S:IsKnown("wrath"),
    }
    assert.are.equal(c.level >= 10, known.bear,
        "released source's Bear Form unlock boundary changed")
    local rr = loop.run(L, 30417, { duration = 36 }, { { H = H } })
    local by = rr.pressedBy or {}
    local first = {}
    for i = 1, math.min(rr.combat or 0, 5) do
        if rr.pressed[i] then first[#first+1] = rr.pressed[i] end
    end
    local bad, n = {}, 0
    for reason, count in pairs(rr.refused or {}) do
        n=n+count
        bad[#bad+1] = reason .. ":" .. count
    end
    print(("GUARDIAN_LEVEL_V011 level=%d label=%s pack=%s bear=%s maulKnown=%s lacerateKnown=%s biteKnown=%s accepted=%d refused=%d first=%s form=%s trueRage=%.2f events=%d"):format(
        c.level,c.label,which,tostring(known.bear),tostring(known.maul),
        tostring(known.lacerate),tostring(known.bite),rr.presses,n,
        table.concat(first,","),tostring(rr.us.form),rr.us.power or -1,#rr.W.truth))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    -- The source game, not output icons, decides whether a press was castable.
    -- All third-party profiles are observed as comparators; a known shipped
    -- refusal is recorded, never incorrectly classified as candidate PASS.
    if which == "candidate" then
        assert.are.same({},rr.refused,
            "new Guardian v1.5 has a source-refused levelling recommendation")
        assert.is_true(rr.presses >= 3,
            "no three accepted casts/queue actions by the source-world level gate")
        assert.is_true(#first >= 3,
            "test cannot establish three state-advanced accepted actions")
        assert.is_true(#rr.W.truth >= 3,
            "fake world never advanced legitimate combat events")
    end
    if not known.bear then
        assert.are.equal(0,by.bear_form or 0,
            "no automatic suggestion of unlearned Bear Form")
        assert.are.equal(0,by.maul or 0,
            "no illegal unlearned Maul at pre-Bear level")
    end
    if not known.lacerate then assert.are.equal(0,by.lacerate or 0) end
    if not known.bite then assert.are.equal(0,by.primal_bite or 0) end
    return {accepted=rr.presses,refused=n,by=by,known=known}
end

describe("Guardian v0.11.0 source-native level 9/10/20/31/34/60 and post-setup tail", function()
    for _,c in ipairs(cases) do
        it(c.label..": shipped, exact working rollback, full v1.5",function()
            local shipped=run(c,"shipped")
            local working=run(c,"working")
            local candidate=run(c,"candidate")
            assert.is_true(candidate.accepted>=3)
            -- No damage/TPS ranking: source valid cast sequences differ.
            print(("GUARDIAN_LEVEL_COMPARISON level=%d shipped=%d working=%d v15=%d shippedRefused=%d workingRefused=%d v15Refused=%d"):format(
                c.level,shipped.accepted,working.accepted,candidate.accepted,
                shipped.refused,working.refused,candidate.refused))
        end)
    end
end)
