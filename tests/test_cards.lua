local a = require "tests.assertions"
local cards = require "logic.cards"

local T, S = cards.type, cards.symbol

local expected = {
    {1,T.bright,S.crane}, {1,T.ribbon,S.red_poetry}, {1,T.chaff,S.none}, {1,T.chaff,S.none},
    {2,T.animal,S.warbler}, {2,T.ribbon,S.red_poetry}, {2,T.chaff,S.none}, {2,T.chaff,S.none},
    {3,T.bright,S.curtain}, {3,T.ribbon,S.red_poetry}, {3,T.chaff,S.none}, {3,T.chaff,S.none},
    {4,T.animal,S.cuckoo}, {4,T.ribbon,S.red}, {4,T.chaff,S.none}, {4,T.chaff,S.none},
    {5,T.animal,S.bridge}, {5,T.ribbon,S.red}, {5,T.chaff,S.none}, {5,T.chaff,S.none},
    {6,T.animal,S.butterfly}, {6,T.ribbon,S.blue}, {6,T.chaff,S.none}, {6,T.chaff,S.none},
    {7,T.animal,S.boar}, {7,T.ribbon,S.red}, {7,T.chaff,S.none}, {7,T.chaff,S.none},
    {8,T.bright,S.moon}, {8,T.animal,S.geese}, {8,T.chaff,S.none}, {8,T.chaff,S.none},
    {9,T.animal,S.sake_cup}, {9,T.ribbon,S.blue}, {9,T.chaff,S.none}, {9,T.chaff,S.none},
    {10,T.animal,S.deer}, {10,T.ribbon,S.blue}, {10,T.chaff,S.none}, {10,T.chaff,S.none},
    {11,T.bright,S.rainman}, {11,T.animal,S.swallow}, {11,T.ribbon,S.red}, {11,T.chaff,S.none},
    {12,T.bright,S.phoenix}, {12,T.chaff,S.none}, {12,T.chaff,S.none}, {12,T.chaff,S.none},
}

return function()
    a.equal(#cards.data, 48, "there are exactly 48 cards")
    local ids, suit_count, type_count, symbol_count = {}, {}, {}, {}
    for id = 1, 48 do
        local card = cards.get(id)
        local spec = expected[id]
        a.truthy(card, "card " .. id .. " exists")
        a.equal(card.id, id, "card id is stable")
        a.equal(card.suit, spec[1], "card suit")
        a.equal(card.kind, spec[2], "card type")
        a.equal(card.symbol, spec[3], "card symbol")
        a.falsy(ids[card.id], "every card id is unique")
        ids[card.id] = true
        suit_count[card.suit] = (suit_count[card.suit] or 0) + 1
        type_count[card.kind] = (type_count[card.kind] or 0) + 1
        symbol_count[card.symbol] = (symbol_count[card.symbol] or 0) + 1
    end
    for suit = 1, 12 do a.equal(suit_count[suit], 4, "each month has four cards") end
    a.table_equal(type_count, { [T.bright]=5, [T.animal]=9, [T.ribbon]=10, [T.chaff]=24 }, "type distribution")
    a.equal(symbol_count[S.none], 24, "all unmarked cards are chaff")
    a.equal(#cards.by_symbol(S.red_poetry), 3, "three poetry ribbons")
    a.equal(#cards.by_symbol(S.blue), 3, "three blue ribbons")
    a.equal(#cards.by_symbol(S.rainman), 1, "one rainman")
    a.truthy(cards.same_month(1, 4), "cards of a month match")
    a.falsy(cards.same_month(1, 5), "cards of different months do not match")

    local deck, seen = cards.deck(), {}
    a.equal(#deck, 48, "fresh deck has every card")
    for index, id in ipairs(deck) do
        a.equal(id, index, "fresh deck is ordered")
        a.falsy(seen[id], "deck has no duplicates")
        seen[id] = true
    end
end
