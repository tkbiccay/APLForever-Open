-- Feral DPS source-native final-fallback and finisher coverage.
-- Published Hekili Forever v0.11.0, full shipped, exact current v1.0 and
-- complete unselected v1.4.  The only controlled world variable is the
-- number of naturally attacking mobs.  No injected resources/points/damage.
local loop=require("Game.harness.loop")
local stock=assert(require("Forever.helpers.druid_loop_world").Feral)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local roles={
    current="roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt",
    candidate="roles/Druid/Candidates/APL_Druid_Feral_v1.4_Draft.txt",
}
local function loadFile(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local v=assert(f:read("*a"));f:close();return v
end
local function worldFor(attackers)
    return setmetatable({
        -- Published default source loop scenario ("sim"), not the game-mode
        -- override.  Game-mode full Current v1.0 import raised three literal
        -- Forever error-template records in red CI 44903123945; preserve
        -- that separate unresolved engine/fixture diagnostic, not a pass.
        WORLD=setmetatable({
            distance=4,attackers=attackers,mobHealth=1000000000
        },{__index=stock.WORLD})
    },{__index=stock})
end
local function import(H,C,name)
    if name=="shipped" then return end
    local lists,warnings=H.Hekili:ImportSimcAPL(
        "Druid_Feral","APLForever-Feral-Combo-Tail",
        loadFile(roles[name]),C.PACK)
    for _,key in ipairs({"precombat","default","cat","cat_melee",
        "finish","procs","builders","defensives","caster"}) do
        assert.is_table(lists[key],"missing whole APL list "..key)
    end
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[C.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for k in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(C.PACK,k),"inactive "..k)
    end
    if #H.errors>0 then
        print(("FERAL_IMPORT_ERRORS profile=%s count=%d warnings=%s"):format(name,#H.errors,tostring(warnings)))
        for i,e in ipairs(H.errors) do
            print(("FERAL_IMPORT_ERR profile=%s index=%d value=%s"):format(name,i,tostring(e)))
        end
    end
    assert.are.same({},H.errors)
end
local function run(name,attackers,seed)
    local C=worldFor(attackers)
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    import(H,C,name)
    local toggles=H.Hekili.DB.profile.toggles
    toggles.cooldowns.value=false
    toggles.minor_cooldowns.value=false
    toggles.defensives.value=false
    toggles.movement.value=false
    local lowEnergy=0
    local lowStart=nil
    local lowActions=0
    local checkpoints={}
    local lastCheck=-1e9
    local firstThree={}
    local minTrueEnergy=1e9
    local maxTruePoints=0
    local cpAtRip={}
    local oldPress=0
    local naturalWorldEvents=0
    local rr=loop.run(L,seed,{
        duration=120,
        on=function(w,_,t)
            if w.combat<=0 then return end
            naturalWorldEvents=#w.W.truth
            local energy=w.us.power
            minTrueEnergy=math.min(minTrueEnergy,energy)
            -- The SOURCE's real combo-point pool, not a fabricated CP state.
            -- A source-accepted Rip spends its points before the tick callback;
            -- record post-press true points, never claim pre-cast CP from this.
            local trueCP=w.W.res(w.us,4)
            if type(trueCP)=="number" then
                maxTruePoints=math.max(maxTruePoints,trueCP)
            end
            if w.pressed[w.combat] then
                local accepted=w.pressed[w.combat]
                if #firstThree<3 then firstThree[#firstThree+1]=accepted end
                if accepted=="rip" then cpAtRip[#cpAtRip+1]=trueCP end
            end
            if not lowStart and energy<=20 then
                lowStart=t
            end
            if lowStart then
                local accepted=w.pressed[w.combat]
                if accepted and w.combat~=oldPress then
                    lowActions=lowActions+1
                    oldPress=w.combat
                end
                if #checkpoints<3 and t-lastCheck>=0.8 and #w.W.truth>0 then
                    local out=H.Hekili.Engine.Output.Primary
                    local rec=out and out.recs and out.recs[1]
                    checkpoints[#checkpoints+1]={
                        t=t,events=#w.W.truth,
                        action=w.ours[w.combat],wait=rec and rec.wait,
                        accepted=accepted,energy=energy
                    }
                    lastCheck=t
                end
            end
        end
    },{{H=H}})
    local by=rr.pressedBy or {}
    local refused=0
    for _,n in pairs(rr.refused or {}) do refused=refused+n end
    local repeatedReady=false
    if #checkpoints==3 then
        local a=checkpoints[1].action
        repeatedReady=a~=nil
        for _,c in ipairs(checkpoints) do
            if c.action~=a or c.accepted or
                type(c.wait)~="number" or c.wait>0.05 then
                repeatedReady=false
            end
        end
    end
    print(("FERAL_COMBO_V011 profile=%s attackers=%d seed=%d accepted=%d refused=%d rip=%d bite=%d rake=%d shred=%d claw=%d minEnergy=%.2f maxTrueCP=%d lowStart=%s lowActions=%d checkpoints=%d repeatReady=%s first=%s events=%d"):format(
        name,attackers,seed,rr.presses,refused,by.rip or 0,
        by.ferocious_bite or 0,by.rake or 0,by.shred or 0,
        by.claw or 0,minTrueEnergy,maxTruePoints,
        tostring(lowStart),lowActions,#checkpoints,
        tostring(repeatedReady),table.concat(firstThree,","),
        naturalWorldEvents))
    for i,c in ipairs(checkpoints) do
        print(("FERAL_COMBO_TAIL profile=%s attackers=%d seed=%d idx=%d t=%.2f events=%d action=%s wait=%s accepted=%s energy=%.2f"):format(
            name,attackers,seed,i,c.t,c.events,tostring(c.action),
            tostring(c.wait),tostring(c.accepted),c.energy))
    end
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.is_true(naturalWorldEvents>=3,
        "world did not actually advance to several combat events")
    if name~="shipped" then
        assert.are.same({},rr.refused,"complete custom source refused a cast")
        assert.is_true(rr.presses>=3,"no 3 actual successful casts")
        assert.is_false(repeatedReady,
            "triple immediately ready identical first icon without accepted cast")
    end
    return {by=by,total=rr.presses,refused=refused,
        lowStart=lowStart,lowActions=lowActions,checkpoints=#checkpoints,
        maxTruePoints=maxTruePoints}
end

describe("Feral v0.11 full APL finisher/fallback with 1 or 3 source attackers",function()
    for _,attackers in ipairs({1,3}) do
        for _,seed in ipairs({30417,30418}) do
            it(("natural melee attackers=%d seed=%d"):format(attackers,seed),function()
                local shipped=run("shipped",attackers,seed)
                -- Observe independent v1.4 source import/casts before protected
                -- Current v1.0 import diagnostics can fail this same case.
                local candidate=run("candidate",attackers,seed)
                local current=run("current",attackers,seed)
                assert.is_true((current.by.claw or 0)+(current.by.shred or 0)>=2)
                assert.is_true((candidate.by.claw or 0)+(candidate.by.shred or 0)>=2)
                -- Complete v1.4 differs from Current on finish threshold,
                -- shred and procs, so no bogus action parity expectation.
                print(("FERAL_COMBO_COMPARE attackers=%d seed=%d shipped=%d/%d current=%d/%d v14=%d/%d rip=%d/%d/%d"):format(
                    attackers,seed,shipped.total,shipped.refused,
                    current.total,current.refused,candidate.total,candidate.refused,
                    shipped.by.rip or 0,current.by.rip or 0,candidate.by.rip or 0))
            end)
        end
    end
end)
