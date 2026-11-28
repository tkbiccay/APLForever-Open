-- Hunter BM v0.11.0 -- published rank/unlock source-world boundary.
-- No rank or Mana injection: compare full shipped, exact protected Current v1.1,
-- unselected complete v1.4 with source-accepted actions, not repeated icon polls.
-- Pet is preexisting in the published BM Turret fixture even at level 10;
-- this cannot validate low-level pet quest, pet recovery or real Mana scaling.
local loop = require("Game.harness.loop")
local ws = require("Forever.helpers.wowsims")
local stock = assert(require("Forever.helpers.hunter_world").BeastMasteryTurret)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local learn = ws.learn("HUNTER")
local files = {
    current = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.1_Draft.txt",
    v14 = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.4_Draft.txt",
}
local levels = { 10, 24, 25, 40, 60 }
local distances = { 6, 12 }

local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local s = assert(f:read("*a"))
    f:close()
    return s
end

local function game(level, distance)
    local content = ws.content(stock, {
        pack = stock.PACK,
        level = level,
        learn = learn,
        talents = ws.header("hunter_beast_mastery_turret").talents,
        race = ws.race("hunter_beast_mastery_turret"),
        gear = level == 60 and ws.gear("hunter_beast_mastery_turret") or nil,
    })
    content.WORLD = setmetatable({
        level = level, distance = distance, mobHealth = 1000000000,
    }, { __index = content.WORLD })
    return content
end

local function install(H, pack, profile)
    if profile == "shipped" then return end
    local lists, warnings = H.Hekili:ImportSimcAPL(
        "Hunter_BeastMastery", "APLForever-BM-LevelGate",
        read(files[profile]), pack)
    assert.is_table(lists)
    assert.is_table(lists.precombat)
    assert.is_table(lists.default)
    assert.is_table(lists.melee)
    assert.is_table(lists.major_cooldowns)
    assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
    assert.is_falsy((warnings or ""):find("Unknown key", 1, true))
    H.Hekili.DB.profile.packs[pack].lists = lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(pack, name),
            "inactive imported source list " .. name)
    end
    assert.are.same({}, H.errors)
end

local function firstAccepted(run, n)
    local seq = {}
    for i = 1,run.combat or 0 do
        if run.pressed[i] then
            seq[#seq+1] = run.pressed[i]
            if #seq >= n then break end
        end
    end
    return seq
end

local function one(profile, level, distance)
    local C = game(level,distance)
    local L = loop.new(C)
    local H = L.us
    assert.are.same({}, H.loadErrors)
    assert.are.same({}, H.Hekili.Class.loadErrors or {})
    install(H,C.PACK,profile)
    local t = H.Hekili.DB.profile.toggles
    t.cooldowns.value = false
    t.defensives.value = false
    t.movement.value = false

    local S=H.Hekili.State
    local known={
        hawk = S:IsKnown("summon_hawk"),
        arcane = S:IsKnown("arcane_shot"),
        aimed = S:IsKnown("aimed_shot"),
        sting = S:IsKnown("serpent_sting"),
        aspect = S:IsKnown("aspect_of_the_hawk"),
    }
    -- Published Forever learn_HUNTER table is the only unlock authority:
    assert.are.equal(level>=25, known.hawk, "Hawk level boundary changed in released kit")
    assert.are.equal(level>=20, known.aimed, "Aimed Shot source unlock changed")
    assert.is_true(known.arcane and known.sting and known.aspect,
        "low-level source kit unexpectedly lost routine ranged abilities")

    local r=loop.run(L,30417,{ duration = 42 },{{H=H}})
    local by=r.pressedBy or {}
    local first=firstAccepted(r,5)
    local refused=0
    for _,n in pairs(r.refused or {}) do refused=refused+n end
    print(("BM_LEVEL_V011 profile=%s level=%d distance=%d hawkKnown=%s aimedKnown=%s accepted=%d refused=%d hawks=%d arcane=%d aimed=%d sting=%d major=%d first=%s mana=%.2f events=%d"):format(
        profile,level,distance,tostring(known.hawk),tostring(known.aimed),
        r.presses,refused,by.summon_hawk or 0,by.arcane_shot or 0,
        by.aimed_shot or 0,by.serpent_sting or 0,
        (by.bestial_wrath or 0)+(by.rapid_fire or 0),
        table.concat(first,","),r.us.power or -1,#r.W.truth))

    assert.are.equal(0,r.errors)
    assert.are.equal(0,r.raises)
    assert.is_true(#r.W.truth>=3, "no actual source-world progression")
    assert.are.equal(0,by.bestial_wrath or 0,
        "source-cast Bestial Wrath with native Major OFF")
    assert.are.equal(0,by.rapid_fire or 0,
        "source-cast Rapid Fire with native Major OFF")
    if not known.hawk then assert.are.equal(0,by.summon_hawk or 0) end
    if not known.aimed then assert.are.equal(0,by.aimed_shot or 0) end
    if not known.arcane then assert.are.equal(0,by.arcane_shot or 0) end
    if not known.sting then assert.are.equal(0,by.serpent_sting or 0) end

    if profile ~= "shipped" then
        assert.are.same({},r.refused,
            "source-refused full custom at learned level / real range")
        if distance==6 then
            for _,key in ipairs({ "arcane_shot","aimed_shot",
                "multi_shot","serpent_sting","rapid_fire" }) do
                assert.are.equal(0,by[key] or 0,
                    "illegal 8-35yd ranged action at six yards: "..key)
            end
        elseif level >= 10 then
            assert.is_true(r.presses>=3 and #first>=3,
                "fewer than three actually accepted source ranged/filler actions")
        end
    end
    return {n=r.presses,by=by,refused=refused,first=first}
end

describe("Hunter BM released v0.11 low-level Hawk/range final-tail regression",function()
    for _,level in ipairs(levels) do
        for _,distance in ipairs(distances) do
            it(("level=%d distance=%d exact shipped / Current v1.1 / Draft v1.4"):format(level,distance),function()
                local shipped=one("shipped",level,distance)
                local current=one("current",level,distance)
                local candidate=one("v14",level,distance)
                if distance==12 then
                    assert.are.same(current.by,candidate.by,
                        "v1.4 altered normal non-Lone-Wolf long-range progression")
                    assert.are.equal(current.n,candidate.n)
                elseif level<25 then
                    assert.are.equal(0,current.by.summon_hawk or 0)
                    assert.are.equal(0,candidate.by.summon_hawk or 0)
                else
                    -- BM v1.4 Hawk has exact 0-35yd source range, whereas
                    -- protected Current v1.1 restricts it behind outside8.
                    assert.are.equal(0,current.by.summon_hawk or 0)
                    assert.is_true((candidate.by.summon_hawk or 0)>=1,
                        "candidate did not recover any legal 6yd Hawk at this learned level")
                    assert.is_true(candidate.n>=3,
                        "new Hawk path did not produce three accepted source-world actions")
                end
                print(("BM_LEVEL_COMPARE level=%d yd=%d shipped=%d/%d current=%d/%d v14=%d/%d"):format(
                    level,distance,shipped.n,shipped.refused,
                    current.n,current.refused,candidate.n,candidate.refused))
            end)
        end
    end
end)
