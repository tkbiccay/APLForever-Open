local loop = require("Game.harness.loop")
local pretty = require("pl.pretty")
local ws = require("Forever.helpers.wowsims")
local stock = require("Forever.helpers.druid_loop_world").Guardian
local root = assert(os.getenv("APLFOREVER_ROOT"))
local manifest = dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST")))

-- The pinned wowsims_druid_spec.lua applies these hotfix learn overrides.
local learn = setmetatable({ [417141] = math.huge, [1328617] = math.huge, [1328616] = 34 },
    { __index = ws.learn("DRUID") })
local cases = {
    { name = "pre-bear", level = 9, attackers = 1, defensives = false, cooldowns = false },
    { name = "bear-unlock", level = 10, attackers = 1, defensives = false, cooldowns = false },
    { name = "single-off", level = 60, attackers = 1, defensives = false, cooldowns = false },
    { name = "single-on", level = 60, attackers = 1, defensives = true, cooldowns = true },
    { name = "pair", level = 60, attackers = 2, defensives = false, cooldowns = true },
    { name = "pack", level = 60, attackers = 3, defensives = true, cooldowns = false },
    { name = "enqueue-clearcasting", level = 10, attackers = 1, defensives = false, cooldowns = false,
        seedClearcasting = true },
}

local function observe(case, profile, entry)
    local content = ws.content(stock, {
        pack = stock.PACK, level = case.level, learn = learn,
        talents = ws.header("druid_guardian").talents,
        race = ws.race("druid_guardian"), gear = ws.gear("druid_guardian"),
    })
    content.WORLD.attackers = case.attackers
    if case.level == 9 then
        local character = content.character
        content.character = function()
            local c = character()
            c.form = 0
            return c
        end
    end
    local L = loop.new(content)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    if entry then
        local file = assert(io.open(root .. "/" .. entry.apl_file, "rb"))
        local raw = file:read("*a")
        file:close()
        local lists, warnings = H.Hekili:ImportSimcAPL(entry.apl_name, "APLForever", raw, content.PACK)
        assert.is_table(lists)
        assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
        H.Hekili.DB.profile.packs[content.PACK].lists = lists
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        for name in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(content.PACK, name), name)
        end
    end
    local toggles = H.Hekili.DB.profile.toggles
    toggles.defensives.value = case.defensives
    toggles.cooldowns.value = case.cooldowns
    local state = H.Hekili.State
    local known = { bear = state:IsKnown("bear_form"), maul = state:IsKnown("maul"),
        wrath = state:IsKnown("wrath"), roar = state:IsKnown("demoralizing_roar") }
    assert.are.equal(case.level >= 10, known.bear)
    assert.are.equal(case.level >= 10, known.maul)
    local cursor, sample = 0, {}
    local roar = assert(H.Hekili.Class.auras.demoralizing_roar).id
    local cc = assert(H.Hekili.Class.auras.clearcasting).id
    local seeded, maulAttempts = false, {}
    local run = loop.run(L, 30417, {
        duration = 40,
        on = function(r, _, t)
            if case.seedClearcasting and not seeded and t >= 2.8 then
                -- Controlled registered aura, applied through the source world's observer events.
                -- No edits to the action, power estimator, spell kit or swing scheduler.
                r.W.applyAura(r.us, cc, H.Hekili.Class.auras.clearcasting.duration)
                seeded = true
                local press = r.W.press
                r.W.press = function(player, key, resolved)
                    if player ~= r.us or key ~= "maul" then return press(player, key, resolved) end
                    local power = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                    local before, aura, pending = player.power, player.auras[cc], player.queued ~= nil
                    local accepted, reason = press(player, key, resolved)
                    maulAttempts[#maulAttempts + 1] = {
                        t = r.W.t, before = before, after = player.power, cost = resolved.cost,
                        lo = power.lo, estimate = power.est, hi = power.hi,
                        charges = aura and aura.stacks or 0, pendingBefore = pending,
                        pendingAfter = player.queued ~= nil, accepted = accepted, reason = reason,
                    }
                    return accepted, reason
                end
            end
            local output = H.Hekili.Engine.Output.Primary
            local rec = output.count > 0 and output.recs[1] or {}
            local press = r.pressed[r.combat]
            local events = {}
            for i = cursor + 1, #r.W.truth do
                local e = r.W.truth[i]
                if (e.src == r.us and (e.kind == "queue" or e.kind == "strike" or e.kind == "unqueue"))
                    or (e.kind == "aura" and (e.aura == roar or e.aura == cc)) then
                    events[#events + 1] = { t = e.t, kind = e.kind, spell = e.spell,
                        cost = e.cost, outcome = e.act, aura = e.aura, stacks = e.stacks }
                end
            end
            cursor = #r.W.truth
            if press or #events > 0 then
                local p = H.ns.VirtualState.Power(L.power.type, H.ctl.now)
                sample[#sample + 1] = {
                    t = t, action = rec.actionName, wait = rec.wait, script = rec.script,
                    press = press, events = events, floor = rec.floors and rec.floors.rage,
                    rageAfterPoll = r.us.power, lo = p.lo, estimate = p.est, hi = p.hi,
                    form = r.us.form, pending = r.us.queued and r.us.queued.key,
                }
            end
        end,
    }, { { H = H } })
    print("GUARDIAN_V083 " .. profile .. " " .. case.name .. " " .. pretty.write({
        inputs = case, sha256 = entry and entry.sha256, known = known,
        accepted = run.pressedBy, refused = run.refused, decisions = sample,
        seededClearcasting = seeded, maulAttempts = maulAttempts,
    }, ""))
    assert.are.equal(0, run.errors)
    assert.are.equal(0, run.raises)
    if case.seedClearcasting then
        assert.is_true(seeded)
        assert.is_true(#maulAttempts > 0, "seeded scenario never attempted Maul")
        for _, attempt in ipairs(maulAttempts) do
            if attempt.accepted then
                assert.are.equal(attempt.before, attempt.after, "queue spent Rage before the swing")
                assert.is_false(attempt.pendingBefore, "accepted a duplicate queue")
                assert.is_true(attempt.pendingAfter)
            end
        end
        if profile == "v1.1" then
            -- The point of this controlled case must be observed, not just printed.
            -- Without these assertions, an empty attempt/strike trace would also pass.
            local first = maulAttempts[1]
            assert.is_true(first.accepted, "free Maul was not queued")
            assert.are.equal(0, first.before)
            assert.are.equal(0, first.after)
            assert.are.equal(1, first.charges)
            assert.are.equal(0, first.cost)
            local freeStrikeAt, consumedAt, waited = nil, nil, false
            for _, decision in ipairs(sample) do
                if decision.t >= first.t and decision.t <= first.t + 4 then
                    if decision.action == "maul" and (decision.wait or 0) > 0 and not decision.press then
                        waited = true
                    end
                    for _, event in ipairs(decision.events) do
                        if event.kind == "strike" and event.cost == 0 and event.t >= first.t then
                            freeStrikeAt = event.t
                        elseif event.kind == "aura" and event.aura == cc
                            and event.stacks == 0 and event.t >= first.t then
                            consumedAt = event.t
                        end
                    end
                end
            end
            assert.is_not_nil(freeStrikeAt, "queued free Maul never landed")
            assert.are.equal(freeStrikeAt, consumedAt, "Clearcasting was not consumed on the free strike")
            assert.is_true(waited, "no post-strike positive wait observed")
        end
    end
end

describe("Guardian v0.8.3 matched source worlds", function()
    local profiles = { { name = "shipped" } }
    for _, entry in ipairs(manifest) do
        -- Historical v0.8.3 Guardian gate preserves the exact original
        -- v1.0/v1.1 comparators; v1.2 has its own v0.8.6 native gate.
        if entry.apl_name == "Druid_Guardian" and
            (entry.revision == "v1.0" or entry.revision == "v1.1") then
            profiles[#profiles + 1] = { name = entry.revision, entry = entry }
        end
    end
    assert.are.equal(3, #profiles)
    for _, case in ipairs(cases) do
        for _, profile in ipairs(profiles) do
            it(case.name .. " " .. profile.name, function()
                observe(case, profile.name, profile.entry)
            end)
        end
    end
end)

