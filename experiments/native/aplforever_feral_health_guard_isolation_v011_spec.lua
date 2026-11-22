-- Published Forever v0.11.0: isolate EACH of three protected Feral Current
-- health.pct guards without modifying the original file or inventing a health API.
-- This proves importer/compiler diagnostics only, NOT combat safety or live HP.
local loop = require("Game.harness.loop")
local C = assert(require("Forever.helpers.druid_loop_world").Feral)
local root = assert(os.getenv("APLFOREVER_ROOT"))
local function read(path)
  local f = assert(io.open(root .. "/" .. path, "rb"))
  local s = assert(f:read("*a")); f:close(); return s
end
local current = read("roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt")
local candidate = read("roles/Druid/Candidates/APL_Druid_Feral_v1.4_Draft.txt")
local guards = {"health.pct<=65", "health.pct<=45"}
local function change(original, mode)
  local n = 0
  local lines = {}
  for line in (original .. "\n"):gmatch("(.-)\n") do
    if line:find("actions.defensives", 1, true) and line:find("health.pct<=", 1, true) then
      n = n + 1
      if mode == "all" or mode == n then
        local count
        line, count = line:gsub("health%.pct<=%d+", "0")
        assert.are.equal(1, count, "exactly one health guard per defensive action")
      end
    end
    lines[#lines + 1] = line
  end
  assert.are.equal(3, n, "protected Current health guard count changed")
  return table.concat(lines, "\n")
end
local function compile(text, label)
  local L = loop.new(C)
  local H = L.us
  assert.are.same({}, H.loadErrors)
  local lists, warnings = H.Hekili:ImportSimcAPL("Druid_Feral", label, text, C.PACK)
  assert.is_table(lists)
  assert.is_table(lists.default)
  assert.is_falsy((warnings or ""):find("Unsupported action", 1, true))
  assert.is_falsy((warnings or ""):find("Unknown key", 1, true))
  H.Hekili.DB.profile.packs[C.PACK].lists = lists
  H.Hekili:LoadScripts()
  H.Hekili:ReviewPacks()
  local count = #H.errors
  print(("FERAL_HEALTH_ISOLATION variant=%s compile_errors=%d"):format(label,count))
  return count
end
describe("Feral Current independent legacy health.pct compile diagnostics, v0.11.0", function()
  it("distinguishes all three independent predicates from clean v1.4", function()
    assert.are.equal(3, compile(current, "protected-current"))
    for n = 1, 3 do
      assert.are.equal(2, compile(change(current, n), "one-guard-" .. n))
    end
    assert.are.equal(0, compile(change(current, "all"), "all-three-removed"))
    assert.are.equal(0, compile(candidate, "full-unselected-v1.4"))
    -- This deliberately does not call the combat loop: replacing health
    -- predicates with zero is a parser diagnostic, never a defensive fix.
  end)
end)
