-- Tiny Lua 5.1 test helpers.  Keep this file free of Defold dependencies.
local M = { count = 0 }

local function fail(message, level)
    error(message, (level or 1) + 1)
end

function M.truthy(value, message)
    M.count = M.count + 1
    if not value then fail(message or "expected a truthy value", 2) end
    return value
end

function M.falsy(value, message)
    M.count = M.count + 1
    if value then fail(message or "expected a falsy value", 2) end
end

function M.equal(actual, expected, message)
    M.count = M.count + 1
    if actual ~= expected then
        fail((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

function M.table_equal(actual, expected, message, path)
    M.count = M.count + 1
    path = path or "value"
    if type(actual) ~= type(expected) then
        fail((message or "tables differ") .. " at " .. path, 2)
    end
    if type(actual) ~= "table" then
        if actual ~= expected then fail((message or "values differ") .. " at " .. path, 2) end
        return
    end
    for key, value in pairs(expected) do
        M.table_equal(actual[key], value, message, path .. "." .. tostring(key))
    end
    for key in pairs(actual) do
        if expected[key] == nil then fail((message or "tables differ") .. " has unexpected key " .. path .. "." .. tostring(key), 2) end
    end
end

function M.raises(fn, message)
    M.count = M.count + 1
    local ok = pcall(fn)
    if ok then fail(message or "expected an error", 2) end
end

return M
