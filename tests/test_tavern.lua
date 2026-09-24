local a = require "tests.assertions"
local tavern = require "logic.tavern"

return function()
    local purse = tavern.new(100)
    a.falsy(purse:reserve(0), "a wager must be positive")
    a.falsy(purse:reserve(2.5), "a wager must use whole gold")
    a.falsy(purse:reserve(101), "a wager cannot exceed the purse")
    a.truthy(purse:reserve(25), "an affordable wager is accepted")
    a.equal(purse:view().gold, 75, "the stake is held before play")
    a.falsy(purse:reserve(5), "a second stake cannot overwrite the first")
    a.falsy(purse:settle("stranger"), "an invalid winner cannot settle a wager")
    a.truthy(purse:settle("you"), "a match win pays the stake and even-money winnings")
    a.equal(purse:view().gold, 125, "winning adds a net 25 gold")
    a.equal(purse:view().last_result.change, 25, "the result shows the net gain")
    a.falsy(purse:settle("you"), "a wager can only be settled once")

    a.truthy(purse:reserve(10), "another wager can be started")
    a.truthy(purse:settle("opponent"), "a match loss forfeits its stake")
    a.equal(purse:view().gold, 115, "losing subtracts the stake")
    a.equal(purse:view().last_result.change, -10, "the result shows the net loss")

    a.truthy(purse:reserve(5), "a third wager can be started")
    a.truthy(purse:settle(nil), "a tied match refunds the stake")
    a.equal(purse:view().gold, 115, "a draw leaves the purse unchanged")
    a.truthy(purse:reserve(5), "a fourth wager can be started")
    purse:refund()
    a.equal(purse:view().gold, 115, "a failed match setup refunds its stake")
end
