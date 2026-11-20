-- Guardian Maul queue ordering at high kit under true natural Rage (v0.11).
-- Complete v1.5 source unchanged on disk, compare ONLY one list reorder in memory.
-- No fake Rage, no player health, no synthetic queue success or DPS model claim.
local loop=require("Game.harness.loop")
local ws=require("Forever.helpers.wowsims")
local stock=require("Forever.helpers.druid_loop_world").Guardian
local root=assert(os.getenv("APLFOREVER_ROOT"))
local f=assert(io.open(root.."/roles/Druid/Candidates/APL_Druid_Guardian_v1.5_Draft.txt","rb"))
local old=assert(f:read("*a"));f:close()
local from="actions+=/call_action_list,name=damage\nactions+=/call_action_list,name=rage_dump,if=buff.bear_form.up"
local to="actions+=/call_action_list,name=rage_dump,if=buff.bear_form.up\nactions+=/call_action_list,name=damage"
local pos=assert(old:find(from,1,true),"Guardian v1.5 call list order changed")
assert.is_nil(old:find(from,pos+#from,true))
local alternative=old:sub(1,pos-1)..to..old:sub(pos+#from)
local learn=setmetatable({
    [417141]=math.huge,[1328617]=math.huge,[1328616]=34,
},{__index=ws.learn("DRUID")})
local function run(profile,attackers)
    local content=ws.content(stock,{
        pack=stock.PACK,level=60,learn=learn,
        talents=ws.header("druid_guardian").talents,
        race=ws.race("druid_guardian"),
        gear=ws.gear("druid_guardian"),
    })
    content.WORLD.attackers=attackers
    content.WORLD.mobHealth=1000000000
    local L=loop.new(content)
    local H=L.us
    assert.are.same({},H.loadErrors)
    local lists,warnings=H.Hekili:ImportSimcAPL("Druid_Guardian",
        "APLForever-Maul-Order",profile=="original" and old or alternative,
        content.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.rage_dump)
    assert.is_falsy((warnings or ""):find("Unsupported action",1,true))
    assert.is_falsy((warnings or ""):find("Unknown key",1,true))
    H.Hekili.DB.profile.packs[content.PACK].lists=lists
    H.Hekili:LoadScripts();H.Hekili:ReviewPacks()
    for name in pairs(lists) do
        assert.is_true(H.Hekili:IsListActive(content.PACK,name))
    end
    assert.are.same({},H.errors)
    H.Hekili.DB.profile.toggles.cooldowns.value=false
    H.Hekili.DB.profile.toggles.defensives.value=false
    H.Hekili.DB.profile.toggles.movement.value=false
    local maxTrue,maxLo,maxMismatch,reserveTicks=0,0,0,0
    local cursor,naturalMobSwings=0,0
    local rr=loop.run(L,30417,{
        duration=70,
        on=function(r,_,t)
            for i=cursor+1,#r.W.truth do
                local ev=r.W.truth[i]
                if ev.kind=="swing" and ev.src and ev.src.kind=="mob"
                    and ev.dst and ev.dst.guid==r.us.guid then
                    naturalMobSwings=naturalMobSwings+1
                end
            end
            cursor=#r.W.truth
            if r.combat>0 and r.us.form==1 then
                local belief=H.ns.VirtualState.Power(L.power.type,H.ctl.now)
                local lo=belief and belief.lo or 0
                maxTrue=math.max(maxTrue,r.us.power)
                maxLo=math.max(maxLo,lo)
                if r.us.power>=35 and lo<35 then maxMismatch=maxMismatch+1 end
                if lo>=35 then reserveTicks=reserveTicks+1 end
            end
        end,
    },{{H=H}})
    local maulID=H.ns.VirtualState.KnownID(H.Hekili.Class.abilities.maul.id)
    local queue,strikes,unqueues,paid=0,0,0,0
    for _,ev in ipairs(rr.W.truth) do
        if ev.src==rr.us and ev.spell==maulID then
            if ev.kind=="queue" then queue=queue+1 end
            if ev.kind=="strike" then
                strikes=strikes+1
                paid=paid+(ev.cost or 0)
            end
            if ev.kind=="unqueue" then unqueues=unqueues+1 end
        end
    end
    local pressed=rr.pressedBy or {}
    local core=(pressed.primal_bite or 0)+(pressed.lacerate or 0)
        +(pressed.swipe_bear or 0)
    print(("GUARDIAN_MAUL_V011 profile=%s attackers=%d true_max=%.2f beliefLo_max=%.2f highTruthLowBelief=%d beliefReserveTicks=%d mobSwings=%d maulQueue=%d maulStrikes=%d maulUnqueue=%d paidRage=%d core=%d accepted=%d refused=%s errors=%d raises=%d"):format(
        profile,attackers,maxTrue,maxLo,maxMismatch,reserveTicks,
        naturalMobSwings,queue,strikes,unqueues,paid,core,rr.presses,
        tostring(next(rr.refused)~=nil),rr.errors,rr.raises))
    assert.are.equal(0,rr.errors)
    assert.are.equal(0,rr.raises)
    assert.are.same({},rr.refused,"source rejected a natural Maul/damage action")
    assert.is_true(naturalMobSwings>=3,"no 3 genuine enemy swing events")
    assert.is_true(core>=3,"new Maul ordering starved source-true core GCD")
    assert.is_true(queue>=strikes,"more Maul strikes than actual source queues")
    if strikes>0 then assert.is_true(paid>0,"source strike paid no Rage") end
    return {queue=queue,strikes=strikes,paid=paid,core=core,
            maxTrue=maxTrue,maxLo=maxLo,reserve=reserveTicks,
            pressed=rr.presses}
end
describe("Guardian v1.5 natural 70s Rage and Maul list-order A/B",function()
    for _,attackers in ipairs({2,3,4}) do
        it("complete original and test-only reordered candidate, "..attackers.." attackers",function()
            local baseline=run("original",attackers)
            local variant=run("reordered",attackers)
            assert.is_true(variant.core>=3,"test-only order lost minimum GCD progress")
            -- A positive candidate queue requires source-earned Rage, later
            -- STRIKE and payment, not just an action recommendation.
            if variant.strikes>baseline.strikes then
                assert.is_true(variant.paid>baseline.paid,"extra Maul strikes lacked true payment")
            end
        end)
    end
end)
