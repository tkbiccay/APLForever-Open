-- v0.12.1 strict released-source import/compile triage, every manifest entry.
-- Historical compiler allowances are deliberately not carried forward.
-- No mutation, combat validation, promotion or breadth credit.
local headless=require("Game.harness.headless")
local root=assert(os.getenv("APLFOREVER_ROOT"))
local manifest=assert(dofile(assert(os.getenv("APLFOREVER_NATIVE_MANIFEST"))))
local sourceRelease=assert(os.getenv("APLFOREVER_SOURCE_RELEASE"))
assert.are.equal("v0.12.1",sourceRelease)
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
local function one(entry)
    local C=fixture(entry)
    local H=headless.new({character=C.character(),pack=C.PACK})
    assert.are.same({},H.loadErrors)
    assert.are.same({},H.Hekili.Class.loadErrors or {})
    local apl=read(entry.apl_file)
    local lists,warnings=H.Hekili:ImportSimcAPL(entry.apl_name,
        "APLForever-v0121-Catalogue-Import",apl,C.PACK)
    assert.is_table(lists)
    assert.is_table(lists.default)
    assert.is_table(lists.precombat)
    assert.is_true(#lists.default>0,"empty default list")
    local rejects={}
    -- Record all importer warning text, not only hard failures.
    for msg in (warnings or ""):gmatch("[^\n]+") do
        print("V0121_IMPORT_WARNING",entry.apl_name,entry.revision,msg)
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
    print(("ALLROLE_V0121 role=%s revision=%s file=%s bytes=%s lists=%d compiler_errors=%d importer_rejects=%d inactive_lists=%d"):format(
        entry.apl_name,entry.revision,entry.apl_file,
        entry.sha256,count,
        #errors,#rejects,#inactive))
    for i,e in ipairs(errors) do print(("ALLROLE_COMPILER_DETAIL role=%s i=%d info=%s"):format(entry.apl_name,i,e:sub(1,250))) end
    for i,e in ipairs(rejects) do print(("ALLROLE_IMPORT_REJECT role=%s i=%d detail=%s"):format(entry.apl_name,i,e:sub(1,250))) end
    if #inactive>0 then print("ALLROLE_INACTIVE role="..entry.apl_name.." lists="..table.concat(inactive,",")) end
    -- Separate conservative syntax audit of explicit self-health predicates.
    -- This is a source-documented guard convention, not runtime health proof.
    -- Exclude target.health.* and other qualified namespaces.
    local guardDebt=0
    local lineNo=0
    for line in (apl.."\n"):gmatch("([^\n]*)\n") do
        lineNo=lineNo+1
        local cond=line:match(",if=([^,\r]+)")
        if cond then
            local selfHealth=false
            for expr in cond:gmatch("[%a_][%w_.]*") do
                if expr=="health.pct" or expr=="health.current" then selfHealth=true end
            end
            if selfHealth and not cond:match("^health%.known&") then
                guardDebt=guardDebt+1
                print("V0121_HEALTH_GUARD_REVIEW",entry.apl_file,lineNo,cond)
            end
        end
    end
    return {compiler=#errors,rejects=#rejects,inactive=#inactive,guardDebt=guardDebt}
end
describe("v0.12.1 all manifest-selected exact profiles, strict import/compile",function()
    it("checks every manifest row and reports health guard debt separately",function()
        local roles,seen,failed={}, {}, {}
        local clean,guardDebt=0,0
        for _,r in ipairs(manifest) do
            assert.is_nil(seen[r.apl_file],"duplicate manifest file")
            seen[r.apl_file]=true
            roles[r.apl_name]=true
            local ok,result=pcall(one,r)
            local key=r.apl_name.."/"..r.revision
            if not ok then
                failed[#failed+1]=key..": harness/engine exception "..tostring(result)
                print("ALLROLE_V0121_EXCEPTION",key,tostring(result))
            else
                guardDebt=guardDebt+result.guardDebt
                if result.compiler>0 or result.rejects>0 or result.inactive>0 then
                    failed[#failed+1]=key..": compiler="..result.compiler..
                        " rejected="..result.rejects.." inactive="..result.inactive
                else clean=clean+1 end
            end
        end
        local roleCount=0;for _ in pairs(roles) do roleCount=roleCount+1 end
        assert.are.equal(23,roleCount,"Supported role count changed, review support")
        print(("ALLROLE_V0121_SUMMARY roles=%d revisions=%d clean=%d failures=%d guard_review_lines=%d scope=IMPORT_COMPILE_ONLY"):format(
            roleCount,#manifest,clean,#failed,guardDebt))
        for _,v in ipairs(failed) do print("ALLROLE_V0121_FAILURE "..v) end
        -- No old Feral/Arms waiver and no synthetic negative-control replacement.
        assert.are.same({},failed,"v0.12.1 import/compile diagnostics require triage")
    end)
end)
