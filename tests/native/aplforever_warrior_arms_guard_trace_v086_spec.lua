-- Focused source-native Arms AoE/stance guard trace at L40 and L60.
-- No guessed enemy count, added Rage, cooldown reset, target auras or forced casts.
-- Diagnostic snapshots are after the engine cycle/press, so they are
-- supporting evidence, NOT a replacement for engine per-action evaluation.
local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local ws = require("Forever.helpers.wowsims")
local ww = require("Forever.helpers.warrior_world")
local manifest = assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local root = assert(os.getenv("APLFOREVER_ROOT"))

local function imported(H, C)
    local entry
    for _, e in ipairs(manifest) do
        if e.apl_name == "Warrior_Arms" then
            assert.is_nil(entry)
            entry = e
        end
    end
    assert.is_table(entry)
    assert.are.equal("v1.0", entry.revision)
    assert.are.equal("3bb923e9b071a3d9432471731ce609a3e8852741364ce4334d136e4509335f2c",
        entry.sha256)
    local f = assert(io.open(root .. "/" .. entry.apl_file, "rb"))
    local source = f:read("*a")
    f:close()
    local lists, warnings = H.Hekili:ImportSimcAPL(
        entry.apl_name, "APLForever", source, C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.cleave_and_aoe)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    assert.is_true(#lists.default > 0)
    local pack = assert(H.Hekili.DB.profile.packs[C.PACK])
    pack.lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    assert.are.same({}, H.errors)
end

local function runCase(level)
    local C = ws.content(ww, {
        pack = "Arms (wowsims.com)", level = level,
        talents = ws.header("warrior_arms").talents,
        learn = ws.learn("WARRIOR"),
        race = ws.race("warrior_arms"),
    })
    C.WORLD = setmetatable({
        mobHealth = 1000000000,
        attackers = 2, mobPeriod = 2,
        mobDamage = { 2, 3 },
    }, { __index = C.WORLD })
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    imported(H, C)
    local toggle = H.Hekili.DB.profile.toggles
    toggle.movement.value = false
    toggle.cooldowns.value = false
    toggle.minor_cooldowns.value = false
    toggle.defensives.value = false

    local S = H.Hekili.State
    local spec = assert(S.spec.id)
    local opts = assert(H.Hekili.DB.profile.specs[spec])
    local live = assert(H.Hekili.Engine.settings.specs[spec])
    opts.nameplates, live.nameplates = true, true
    opts.nameplateRange, live.nameplateRange = 10, 10
    opts.cycle, live.cycle = false, false
    H.ctl.cvars.nameplateShowEnemies, H.ctl.cvars.nameplateShowAll = "1", "1"
    H.ctl.exists.nameplate1, H.ctl.exists.nameplate2 = true, true
    assert.is_true(S:IsKnown("whirlwind"))
    assert.is_true(S:IsKnown("berserker_stance"))

    local count, castCount, formCount, cursor = 0, 0, 0, 0
    local passing = {targets=0, spellReady=0, rage25=0, kept25=0,
        rageCeiling=0, noProc=0, msGap=0, rendGap=0, all=0}
    local windows = {ready={},near={},full={}}
    local blockers = {}
    local spellId = H.ns.VirtualState.KnownID(
        assert(H.Hekili.Class.abilities.whirlwind).id)
    local rank = S.talent.improved_tactical_mastery.rank
    local retentionCap = 10 + 5 * rank
    local firstIcon = {}
    local function safeRow(t, rage, kept, ms, rend, rendGCD,
        wwReady, overpower, stance, allGood, blocked)
        return {t=t, rageLo=rage, kept=kept, msRemains=ms,
            rendRemains=rend, rendGCD=rendGCD,
            wwReady=wwReady, overpower=overpower,
            berserkerUp=stance, all=allGood, blocked=blocked}
    end
    local run = loop.run(L, 30417, {
        duration = 75,
        on = function(r, steps, t)
            if not r.W.combat then return end
            local active = S.active_enemies
            local targets = H.Hekili:GetNumTargets()
            if active ~= 2 or targets ~= 2 then
                return
            end
            count = count + 1
            passing.targets = passing.targets + 1

            local rage = S.rage.lo
            local kept = S.stance_rage_kept
            local ms = S.cooldown.mortal_strike.remains
            local rend = S.debuff.rend.remains
            local rendGCD = S.action.rend.gcd
            local wwReady = S.cooldown.whirlwind.ready
            local overpower = S.buff.overpower_ready.up
            local stance = S.buff.berserker_stance.up
            assert.is_number(rage)
            assert.is_number(kept)
            assert.is_number(ms)
            assert.is_number(rend)
            assert.is_number(rendGCD)
            assert.is_boolean(wwReady)
            assert.is_boolean(overpower)
            assert.is_boolean(stance)
            assert.is_true(kept <= retentionCap + 0.001,
                "retained Rage exceeded source's maximum")
            -- The APL Whirlwind stance switch is a strict conjunction:
            -- WW ready + not already Berserker/Overpower + known ST/AoE +
            -- retained >=25; 25<=belief rage<=retained+5;
            -- MS CD >2 at L60, Rend duration >GCD (outside execute).
            local tests = {
                spellReady = wwReady,
                rage25 = rage >= 25,
                kept25 = kept >= 25,
                rageCeiling = rage <= kept + 5,
                noProc = not overpower,
                msGap = (not S.action.mortal_strike.known) or ms > 2,
                rendGap = (not S.action.rend.known)
                    or rend > rendGCD or S.execute_phase,
            }
            for k,v in pairs(tests) do
                if v then passing[k] = passing[k] + 1 end
            end
            local blocked = {}
            local allGood = not stance
            if stance then blocked[#blocked+1] = "already_berserker" end
            for _, k in ipairs({"spellReady","rage25","kept25",
                "rageCeiling","noProc","msGap","rendGap"}) do
                if not tests[k] then
                    allGood=false
                    blocked[#blocked+1]=k
                    blockers[k]=(blockers[k] or 0)+1
                end
            end
            if allGood then passing.all = passing.all + 1 end
            local row = safeRow(t,rage,kept,ms,rend,rendGCD,
                wwReady,overpower,stance,allGood,table.concat(blocked,"+"))
            if allGood and #windows.full < 12 then
                windows.full[#windows.full+1] = row
            end
            if rage >= 25 and rage <= 30 and #windows.near < 20 then
                windows.near[#windows.near+1] = row
            end
            if wwReady and kept>=25 and not overpower and
                #windows.ready < 14 then
                windows.ready[#windows.ready+1] = row
            end
            local rec=H.Hekili.Engine.Output.Primary
            local action=rec.count>0 and rec.recs[1].actionName or "NO_ACTION"
            firstIcon[action] = (firstIcon[action] or 0) + 1
            for i=cursor+1,#r.W.truth do
                local ev=r.W.truth[i]
                if ev.src==r.us and ev.kind=="cast" and ev.spell==spellId then
                    castCount=castCount+1
                end
                if ev.kind=="form" and ev.t>=loop.PULL and ev.t<r.W.stopAt then
                    formCount=formCount+1
                end
            end
            cursor=#r.W.truth
        end,
    }, {{H=H}})
    print("WARRIOR_ARMS_GUARD_L"..level.." "..pretty.write({
        addon="zmsl/hekili v0.8.6", level=level, seed=30417,
        firstIcon=firstIcon, count=count, talentRank=rank,
        retentionCap=retentionCap, passCount=passing,
        blockers=blockers, cases=windows, accepted=run.pressedBy,
        acceptedWhirlwindEvents=castCount, stanceEvents=formCount,
        refused=run.refused, errors=run.errors, raises=run.raises,
    },""))
    assert.is_true(count >= 200,
        "source counted two targets in too few normal ticks")
    assert.are.same({}, run.refused)
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    assert.are.equal(3, rank)
    if level==40 then
        assert.is_true(castCount>=1,
            "previously demonstrated level-40 cast lost from exact source fixture")
        assert.is_true(formCount>=2)
    elseif level==60 then
        assert.are.equal(0, castCount,
            "baseline level-60 zero-Whirlwind symptom is not reproduced")
        assert.are.equal(0, formCount,
            "baseline level-60 no-stance-switch symptom is not reproduced")
    end
end

describe("Arms natural L40/L60 compound WW guard diagnostic v0.8.6",function()
    it("level 40 (positive native Whirlwind control)",function()runCase(40)end)
    it("level 60 (source-counted AoE activation gap)",function()runCase(60)end)
end)
