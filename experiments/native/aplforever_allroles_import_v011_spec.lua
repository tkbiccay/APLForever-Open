-- Pinned Hekili Forever v0.11.0 23-role current-reference import/compile preflight.
-- The legacy v0.9.0 all-role native suite is NOT proof for current source.
-- Test REAL full selected APL bytes through ImportSimcAPL/LoadScripts/
-- ReviewPacks on the published source, never promote a Candidate.
-- This is an IMPORT/COMPILER gate only, NOT accepted-cast, DPS, or gameplay.
local headless=require("Game.harness.headless")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local manifest=assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local sourceRelease=assert(os.getenv("APLFOREVER_SOURCE_RELEASE"))
assert.are.equal("v0.11.0",sourceRelease)
local worlds={
    Druid=require("Forever.helpers.druid_loop_world"),
    Hunter=require("Forever.helpers.hunter_world"),
    Mage=require("Forever.helpers.mage_world"),
    Paladin=require("Forever.helpers.paladin_world"),
    Priest=require("Forever.helpers.priest_world"),
    Rogue=require("Forever.helpers.rogue_world"),
    Shaman=require("Forever.helpers.shaman_world"),
    Warlock=require("Forever.helpers.warlock_world"),
    Warrior=require("Forever.helpers.warrior_world"),
}
local function fixture(entry)
    if entry.apl_name=="Warrior_Protection" then
        return assert(require("Forever.helpers.protection_gate").content())
    end
    local base=assert(worlds[entry.class],"missing released class world "..entry.class)
    if entry.class=="Warrior" and entry.spec=="Arms" then return base end
    if entry.class=="Hunter" and (entry.spec=="BeastMastery" or entry.spec=="Marksmanship") then
        return assert(base[entry.spec.."Turret"],"missing published Hunter turret "..entry.spec)
    end
    return assert(base[entry.spec],"missing published world "..entry.apl_name)
end
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local data=assert(f:read("*a"));f:close();return data
end
local function selectCurrent()
    local rows={}
    for _,r in ipairs(manifest) do
        if not rows[r.apl_name] or r.apl_file:find("/Current/",1,true) then
            rows[r.apl_name]=r
        end
    end
    local sorted={}
    for _,r in pairs(rows) do sorted[#sorted+1]=r end
    table.sort(sorted,function(a,b) return a.apl_name<b.apl_name end)
    assert.are.equal(23,#sorted,"published Supported-role manifest changed")
    return sorted
end
local function one(entry)
    local C=fixture(entry)
    local H=headless.new({character=C.character(),pack=C.PACK})
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    local lists,warnings=H.Hekili:ImportSimcAPL(entry.apl_name,
        "APLForever-v011-Catalogue-Import",read(entry.apl_file),C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_true(#lists.default>0,"empty default list")
    local rejects={}
    for msg in (warnings or ""):gmatch("[^\n]+") do
        if msg:find("Unsupported action",1,true) or msg:find("Unknown key",1,true) then
            rejects[#rejects+1]=msg
        end
    end
    local pack=assert(H.Hekili.DB.profile.packs[C.PACK])
    pack.lists=lists
    H.Hekili:LoadScripts()
    H.Hekili:ReviewPacks()
    local inactive={}
    for name in pairs(lists) do
        if not H.Hekili:IsListActive(C.PACK,name) then inactive[#inactive+1]=name end
    end
    table.sort(inactive)
    local count=0
    for _ in pairs(lists) do count=count+1 end
    local errors={}
    for _,e in ipairs(H.errors) do errors[#errors+1]=tostring(e) end
    print(("ALLROLE_V011 role=%s revision=%s file=%s sha256=%s lists=%d compiler_errors=%d importer_rejects=%d inactive_lists=%d"):format(
        entry.apl_name,entry.revision,entry.apl_file,entry.sha256,count,
        #errors,#rejects,#inactive))
    for i,e in ipairs(errors) do print(("ALLROLE_COMPILER_DETAIL role=%s i=%d info=%s"):format(entry.apl_name,i,e:sub(1,250))) end
    for i,e in ipairs(rejects) do print(("ALLROLE_IMPORT_REJECT role=%s i=%d detail=%s"):format(entry.apl_name,i,e:sub(1,250))) end
    if #inactive>0 then print("ALLROLE_INACTIVE role="..entry.apl_name.." lists="..table.concat(inactive,",")) end
    return {compiler=#errors,rejects=#rejects,inactive=#inactive}
end
describe("All 23 protected Current/Archive role profiles on released Forever v0.11.0",function()
    it("imports and compiles exact catalogue-selected source with separate known errors",function()
        local selected=selectCurrent()
        local failed={}
        local knownLegacy={}
        local okCount=0
        for _,r in ipairs(selected) do
            local ok,result=pcall(one,r)
            if not ok then
                failed[#failed+1]=r.apl_name..": harness/engine exception "..tostring(result)
                print("ALLROLE_V011_EXCEPTION role="..r.apl_name.." detail="..tostring(result))
            elseif result.compiler>0 or result.rejects>0 or result.inactive>0 then
                if r.apl_name=="Druid_Feral" and result.compiler==3 and result.rejects==0
                    and result.inactive==0 then
                    knownLegacy[#knownLegacy+1]=r.apl_name
                    print("ALLROLE_V011_KNOWN_COMPILER_DEBT role=Druid_Feral count=3 source=hidden-health.pct")
                else
                    failed[#failed+1]=r.apl_name..": compiler="..result.compiler..
                        " rejected="..result.rejects.." inactive="..result.inactive
                end
            else
                okCount=okCount+1
            end
        end
        print(("ALLROLE_V011_SUMMARY source=v0.11.0 total=%d clean=%d known_legacy=%d unexpected=%d scope=IMPORT_COMPILE_ONLY"):format(
            #selected,okCount,#knownLegacy,#failed))
        for _,f in ipairs(failed) do print("ALLROLE_V011_UNEXPECTED "..f) end
        assert.are.equal(23,#selected)
        assert.are.same({"Druid_Feral"},knownLegacy,
            "Feral historical health compiler diagnostic unexpectedly changed")
        assert.are.same({},failed,
            "current v0.11.0 Supported-role importer/compile regressions; see per-role logs")
    end)
end)
