-- Breadth #20/21: released-source stateful Shadow Mind Flay channel truth
-- and Affliction real DoT ticks / extreme-Mana terminal fallback.
-- Exact Hekili Forever v0.11.0: 86b739cbc4e6afbcbc693c3790ee81197fc6234b.
-- TWO complete original profiles (shipped and protected Current) independently.
-- No invented health reads, DPS model, action outcome, APL candidate or source edits.
local loop=require("Game.harness.loop")
local shadow=assert(require("Forever.helpers.priest_world").Shadow)
local aff=assert(require("Forever.helpers.warlock_world").Affliction)
local root=assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=assert(f:read("*a"));f:close();return s
end
local apl={
    shadow=read("roles/Priest/Current/APL_Priest_Shadow_v1.0_Draft.txt"),
    aff=read("roles/Warlock/Current/APL_Warlock_Affliction_DPS_v1.0_Draft.txt"),
}
local function positiveAura(H,key)
    local aura=H.Hekili.Class.auras[key]
    return aura and aura.id or nil
end
local function run(kind,profile,seed,percent)
    local C0=kind=="shadow" and shadow or aff
    local world=setmetatable({
        power=C0.WORLD.max*percent,
        mobHealth=1000000000,
        distance=kind=="shadow" and 20 or 25,
    },{__index=C0.WORLD})
    local C=setmetatable({WORLD=world},{__index=C0})
    local L=loop.new(C)
    local H=L.us
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    if profile=="current" then
        local spec=kind=="shadow" and "Priest_Shadow" or "Warlock_Affliction"
        local lists,warnings=H.Hekili:ImportSimcAPL(spec,
            "APLForever-Breadth-Channel-Dot-v011-"..kind,apl[kind],C.PACK)
        assert.is_table(lists)
        assert.is_table(lists.precombat)
        assert.is_table(lists.default)
        assert.is_table(lists.final_fallback)
        assert.is_table(lists.upkeep)
        assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
        assert.is_falsy((warnings or ""):find("Unknown key",1,true))
        H.Hekili.DB.profile.packs[C.PACK].lists=lists
        H.Hekili:LoadScripts()
        H.Hekili:ReviewPacks()
        assert.are.same({},H.errors)
        for key in pairs(lists) do
            assert.is_true(H.Hekili:IsListActive(C.PACK,key), "inactive full list "..key)
        end
    end
    local t=H.Hekili.DB.profile.toggles
    t.cooldowns.value=false
    t.minor_cooldowns.value=false
    t.defensives.value=false
    t.interrupts.value=false
    if t.movement then t.movement.value=false end
    local duration=percent==1 and 90 or percent==0.25 and 105 or 115
    local attempted={}
    local refusedSample={}
    local hook=false
    local rr=loop.run(L,seed,{
        duration=duration,
        on=function(w)
            if hook then return end
            local original=w.W.press
            w.W.press=function(player,key,resolved)
                local stamp=w.W.t
                local power=player.power
                local castUntil=player.castUntil or 0
                local ok,why=original(player,key,resolved)
                if player==w.us and stamp>=loop.PULL then
                    attempted[#attempted+1]={t=stamp,key=key,ok=ok,why=why,castRemain=castUntil-stamp}
                    if not ok and #refusedSample<6 then
                        refusedSample[#refusedSample+1]={
                            t=stamp,key=key,why=why,power=power,
                            cost=resolved and resolved.cost,
                            castRemain=castUntil-stamp
                        }
                    end
                end
                return ok,why
            end
            hook=true
        end
    },{{H=H}})
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    local accepted=rr.pressedBy or {}
    local refused,substantive,epsilonBoundary=0,0,0
    for _,attempt in ipairs(attempted) do
        if not attempt.ok then
            if attempt.why=="casting" and attempt.castRemain
              and math.abs(attempt.castRemain)<=1e-8 then
                epsilonBoundary=epsilonBoundary+1
            else
                substantive=substantive+1
            end
        end
    end
    for reason,count in pairs(rr.refused or {}) do
        refused=refused+count
        print(("BREADTH_STATE_REFUSED role=%s profile=%s seed=%d percent=%.2f reason=%s count=%d"):format(
            kind,profile,seed,percent,tostring(reason),count))
    end
    for _,e in ipairs(refusedSample) do
        print(("BREADTH_STATE_REFUSED_TRACE role=%s profile=%s seed=%d percent=%.2f t=%.3f action=%s cause=%s trueMana=%.3f resolvedCost=%s castRemain=%.12g"):format(
            kind,profile,seed,percent,e.t,tostring(e.key),tostring(e.why),
            e.power,tostring(e.cost),e.castRemain))
    end
    local later=0
    local prior=false
    for i=1,rr.combat do
        local key=rr.pressed[i]
        if key=="shadow_word_pain" or key=="devouring_plague"
          or key=="corruption" or key=="bane_of_agony" then
            prior=true
        elseif prior and type(key)=="string" then
            later=later+1
        end
    end
    local state={presses=rr.presses,refused=refused,
        substantive=substantive,boundary=epsilonBoundary,later=later,
        manaEnd=rr.us.power,low=percent,traceCount=#attempted}
    assert.are.equal(refused,substantive+epsilonBoundary,
      "source W.press hook disagreements with authoritative rr.refused")
    if kind=="shadow" then
        local flay=H.Hekili.Class.abilities.mind_flay
        local flayId=assert(H.ns.VirtualState.KnownID(flay.id))
        local flayStarts,full,clip,cutoff,open,totalTicks,validTickTriples=0,0,0,0,0,0,0
        local active=nil
        local ticksBy={0,0,0,0}
        local dotsApplied=0
        local swp=positiveAura(H,"shadow_word_pain")
        local plague=positiveAura(H,"devouring_plague")
        for _,e in ipairs(rr.W.truth) do
            if e.kind=="aura" and e.dst and e.dst.kind=="mob"
              and (e.aura==swp or e.aura==plague)
              and (e.stacks or 0)>0 then
                dotsApplied=dotsApplied+1
            end
            if e.src==rr.us then
                if e.kind=="cast" and e.spell==flayId and e.chanEnds then
                    flayStarts=flayStarts+1
                    active={at=e.t,untilT=e.chanEnds,hits=0}
                elseif e.kind=="spell" and active
                  and e.t>active.at+0.5 and e.t<=active.untilT+0.00001
                  and ((e.amount or 0)==330 or (e.amount or 0)==660
                     or ((e.amount or 0)==0 and e.act~="WOUND")) then
                    active.hits=active.hits+1
                    totalTicks=totalTicks+1
                elseif e.kind=="channelStop" and e.spell==flayId and active then
                    if e.t<active.untilT-0.02 then
                        if math.abs(e.t-rr.W.t)<=1e-6 then
                            cutoff=cutoff+1
                        else
                            clip=clip+1
                            print(("SHADOW_REAL_CLIP role=%s profile=%s seed=%d startMana=%.2f stopAt=%.4f expectedAt=%.4f sourceEnd=%.4f"):format(
                                kind,profile,seed,percent,e.t,active.untilT,rr.W.t))
                        end
                    else
                        full=full+1
                        if active.hits==3 then validTickTriples=validTickTriples+1 end
                    end
                    ticksBy[math.min(4,active.hits)+1]=(ticksBy[math.min(4,active.hits)+1] or 0)+1
                    active=nil
                end
            end
        end
        if active then open=open+1 end
        state.flay=flayStarts;state.full=full;state.clip=clip
        state.cutoff=cutoff;state.ticks=totalTicks;state.triples=validTickTriples
        state.dotAuras=dotsApplied
        print(("SHADOW_CHANNEL_TRUTH profile=%s seed=%d manaStart=%.2f fullAction=%d flayAccepted=%d channelStarts=%d fullChannels=%d combatClips=%d simulationCutoffs=%d openAtEnd=%d tickSpellHits=%d completeThreeTick=%d trueDotAuras=%d postDot=%d refused=%d substantive=%d epsilon=%d trueManaEnd=%.2f"):format(
            profile,seed,percent,rr.presses,accepted.mind_flay or 0,
            flayStarts,full,clip,cutoff,open,totalTicks,validTickTriples,dotsApplied,
            later,refused,substantive,epsilonBoundary,rr.us.power))
        if profile=="current" then
            assert.are.equal(0,state.substantive,
                "Shadow complete Current source refused a genuine cast")
            assert.are.equal(0,state.clip,
                "Shadow actually clipped Mind Flay during combat; investigate")
            assert.is_true(state.presses>=3,"Shadow source stopped before three accepted casts")
            if percent>=0.25 then
                assert.is_true(dotsApplied>=2,"Shadow complete APL DoT casts never actually applied")
                assert.is_true(flayStarts>=2,"Shadow never truly channelled Mind Flay")
                assert.is_true(full>=1,"Shadow lacked completed full channel")
                assert.is_true(validTickTriples>=1,"full Shadow channel lacked 3 true spell tick events")
                assert.is_true(later>=3,"Shadow lost true follow-on combat after DoT")
            end
        end
    else
        local auraKeys={"corruption","bane_of_agony","siphon_life"}
        local auraIds={}
        for _,key in ipairs(auraKeys) do
            auraIds[key]=assert(positiveAura(H,key),"unknown source aura "..key)
        end
        local positive={corruption=0,bane_of_agony=0,siphon_life=0}
        local trueTicks,shadowTicks,firstDotAt,firstTickAt=0,0,nil,nil
        local nightfall=0
        local tranceId=positiveAura(H,"shadow_trance")
        for _,e in ipairs(rr.W.truth) do
            if e.kind=="aura" and e.dst then
                for _,key in ipairs(auraKeys) do
                    if e.aura==auraIds[key] and e.dst.kind=="mob"
                      and (e.stacks or 0)>0 then
                        positive[key]=positive[key]+1
                        if not firstDotAt then firstDotAt=e.t end
                    end
                end
                if e.aura==tranceId and e.dst==rr.us and (e.stacks or 0)>0 then
                    nightfall=nightfall+1
                end
            end
            if e.kind=="tick" and e.src==rr.us and e.dst
              and e.dst.kind=="mob" then
                trueTicks=trueTicks+1
                if e.school==32 and (e.amount or 0)>0 then
                    shadowTicks=shadowTicks+1
                    if not firstTickAt then firstTickAt=e.t end
                end
            end
        end
        state.positive=positive;state.ticks=trueTicks;state.shadowTicks=shadowTicks
        state.trance=nightfall
        print(("AFF_DOT_TRUTH profile=%s seed=%d manaStart=%.2f accepted=%d rejected=%d substantive=%d epsilon=%d corAura=%d baneAura=%d siphonAura=%d actualTick=%d shadowTick=%d nightfallAura=%d bolt=%d wrack=%d pain=%d lifeTap=%d postDot=%d firstDot=%s firstTick=%s trueManaEnd=%.2f"):format(
            profile,seed,percent,rr.presses,refused,substantive,epsilonBoundary,
            positive.corruption,positive.bane_of_agony,positive.siphon_life,trueTicks,
            shadowTicks,nightfall,accepted.shadow_bolt or 0,
            accepted.wrack or 0,accepted.searing_pain or 0,
            accepted.life_tap or 0,later,tostring(firstDotAt),
            tostring(firstTickAt),rr.us.power))
        if profile=="current" then
            assert.are.equal(0,state.substantive,
                "Affliction protected Current had a genuine refused action")
            assert.are.equal(0,accepted.life_tap or 0,
                "protected Affliction unexpectedly started spending player HP")
            assert.is_true(rr.presses>=2,"current Affliction failed two real advances")
            if percent>=0.25 then
                assert.is_true(positive.corruption>=1,
                    "Affliction source Corruption accepted but never actually applied")
                assert.is_true(positive.bane_of_agony>=1,
                    "Affliction source Bane accepted but never actually applied")
                assert.is_true(shadowTicks>=5,
                    "Affliction did not deliver 5 actual shadow periodic ticks")
                assert.is_true(later>=3,"Affliction lost 3 real later accepted actions")
            end
        end
    end
    return state
end
describe("Breadth 20 Shadow Priest actual channel duration/ticks and severe resource tail",function()
    for _,seed in ipairs({30417,30437}) do
        for _,percent in ipairs({1,0.25,0.05}) do
            it(("seed %d start fraction %.2f full shipped and protected Current"):format(seed,percent),function()
                local shipped=run("shadow","shipped",seed,percent)
                local current=run("shadow","current",seed,percent)
                assert.is_true(shipped.presses>=2)
                assert.is_true(current.traceCount>=2)
                print(("SHADOW_CHANNEL_COMPARE seed=%d pct=%.2f shippedAccepted=%d curAccepted=%d curFlayFull=%d curFlayClipped=%d curRefused=%d"):format(
                    seed,percent,shipped.presses,current.presses,current.full,current.clip,current.refused))
            end)
        end
    end
end)
describe("Breadth 21 Affliction actual DoT periodic ticks and extreme Mana tail",function()
    for _,seed in ipairs({30417,30437}) do
        for _,percent in ipairs({1,0.25,0.05}) do
            it(("seed %d start fraction %.2f full shipped and protected Current"):format(seed,percent),function()
                local shipped=run("aff","shipped",seed,percent)
                local current=run("aff","current",seed,percent)
                assert.is_true(shipped.presses>=2)
                assert.is_true(current.traceCount>=2)
                print(("AFF_DOT_COMPARE seed=%d pct=%.2f shippedAccepted=%d currentAccepted=%d currentShadowTicks=%d currentTap=%d refused=%d"):format(
                    seed,percent,shipped.presses,current.presses,
                    current.shadowTicks,current.positive and 0 or -1,current.refused))
            end)
        end
    end
end)
