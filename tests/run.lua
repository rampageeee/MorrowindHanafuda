-- Run from the project root: lua tests/run.lua
local root = (... and ... ~= "") and ... or "."
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local suites = { "tests.test_cards", "tests.test_combinations", "tests.test_session", "tests.test_tavern" }
local passed = 0
for _, name in ipairs(suites) do
    io.write("[TEST] " .. name .. "\n")
    local suite = require(name)
    local ok, err = xpcall(suite, debug.traceback)
    if not ok then
        io.stderr:write("[FAIL] " .. name .. "\n" .. tostring(err) .. "\n")
        os.exit(1)
    end
    passed = passed + 1
end
local assertions = require("tests.assertions").count
io.write(string.format("[PASS] %d suites, %d assertions\n", passed, assertions))
