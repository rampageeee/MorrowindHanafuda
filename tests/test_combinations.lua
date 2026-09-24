local a = require "tests.assertions"
local cards = require "logic.cards"
local combos = require "logic.combinations"
local T = cards.type

local function captured(bright, animal, ribbon, chaff)
    return { [T.bright]=bright or {}, [T.animal]=animal or {}, [T.ribbon]=ribbon or {}, [T.chaff]=chaff or {} }
end

local function only(actual, id, points, title, rules)
    local result = combos.calculate(actual, rules)
    a.truthy(result, title .. " exists")
    a.equal(result[id], points, title .. " points")
    for key in pairs(result) do a.equal(key, id, title .. " is exclusive here") end
end

return function()
    a.falsy(combos.calculate(captured()), "no captured cards score no combination")

    only(captured({1,9,29,41,45}), 1, 10, "five brights")
    only(captured({1,9,29,45}), 2, 8, "four brights")
    only(captured({1,9,29,41}), 3, 7, "rainy four brights")
    only(captured({1,9,29}), 4, 5, "three brights")
    a.falsy(combos.calculate(captured({1,9,41})), "three brights including rainman do not score")

    only(captured(nil, {25,37,21}), 5, 5, "boar deer butterfly")
    only(captured(nil, {5,13,17,21,25}), 6, 1, "five animals")
    only(captured(nil, {5,13,17,21,25,33}), 6, 2, "additional animal point")

    only(captured(nil, nil, {2,6,10,22,34,38}), 7, 10, "poetry and blue ribbons")
    only(captured(nil, nil, {2,6,10,14,18,26,42}), 8, 9, "poetry ribbons include extras")
    only(captured(nil, nil, {22,34,38,14}), 9, 6, "blue ribbons include extras")
    only(captured(nil, nil, {2,14,18,26,42}), 10, 1, "five ordinary ribbons")
    only(captured(nil, nil, nil, {3,4,7,8,11,12,15,16,19,20}), 13, 1, "ten chaff")
    only(captured(nil, nil, nil, {3,4,7,8,11,12,15,16,19,20,23}), 13, 2, "additional chaff point")

    a.falsy(combos.calculate(captured({9}, {33})), "sake viewing rules are opt-in")
    only(captured({9}, {33}), 11, 5, "flower viewing sake", { flower_viewing_sake=true })
    only(captured({29}, {33}), 12, 5, "moon viewing sake", { moon_viewing_sake=true })

    local current = { [6]=2, [13]=1 }
    a.table_equal(combos.difference(current, { [6]=1 }), { [6]=2, [13]=1 }, "changed points and new scores are deltas")
    a.falsy(combos.difference(current, current), "unchanged scores have no delta")
    a.falsy(combos.difference(nil, current), "no score has no delta")
    a.equal(combos.total({ [1]=10, [6]=2, [13]=1 }), 13, "scores sum correctly")

    local lucky, lucky_points = combos.lucky_hands({1,2,3,4}, true)
    a.table_equal(lucky, { [1]=6 }, "four cards of one month is Teshi")
    a.equal(lucky_points, 6, "Teshi points")
    lucky, lucky_points = combos.lucky_hands({1,2,5,6,9,10,13,14}, true)
    a.table_equal(lucky, { [2]=6 }, "four distinct month pairs are Kuttsuki")
    a.equal(lucky_points, 6, "Kuttsuki points")
    lucky, lucky_points = combos.lucky_hands({1,2,3,4,5,6,9,10,13,14}, true)
    a.table_equal(lucky, { [1]=6, [2]=6 }, "lucky hands stack as in the source")
    a.equal(lucky_points, 12, "stacked lucky-hand points")
    lucky, lucky_points = combos.lucky_hands({1,2,3,4}, false)
    a.falsy(lucky, "lucky hands can be disabled")
    a.equal(lucky_points, 0, "disabled lucky hands score zero")
end
