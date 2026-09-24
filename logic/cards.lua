-- Derived from longod/Hanafuda (MIT, Copyright (c) 2023 longod).
-- Data only; no original artwork is included or referenced.
local M = {}

M.type = { bright = 1, animal = 2, ribbon = 3, chaff = 4 }
M.symbol = { crane=1, curtain=2, moon=3, rainman=4, phoenix=5, warbler=6,
  cuckoo=7, bridge=8, butterfly=9, boar=10, geese=11, sake_cup=12,
  deer=13, swallow=14, red_poetry=15, red=16, blue=17, none=18 }

local T, S = M.type, M.symbol
local ref = {
 {1,T.bright,S.crane},{1,T.ribbon,S.red_poetry},{1,T.chaff,S.none},{1,T.chaff,S.none},
 {2,T.animal,S.warbler},{2,T.ribbon,S.red_poetry},{2,T.chaff,S.none},{2,T.chaff,S.none},
 {3,T.bright,S.curtain},{3,T.ribbon,S.red_poetry},{3,T.chaff,S.none},{3,T.chaff,S.none},
 {4,T.animal,S.cuckoo},{4,T.ribbon,S.red},{4,T.chaff,S.none},{4,T.chaff,S.none},
 {5,T.animal,S.bridge},{5,T.ribbon,S.red},{5,T.chaff,S.none},{5,T.chaff,S.none},
 {6,T.animal,S.butterfly},{6,T.ribbon,S.blue},{6,T.chaff,S.none},{6,T.chaff,S.none},
 {7,T.animal,S.boar},{7,T.ribbon,S.red},{7,T.chaff,S.none},{7,T.chaff,S.none},
 {8,T.bright,S.moon},{8,T.animal,S.geese},{8,T.chaff,S.none},{8,T.chaff,S.none},
 {9,T.animal,S.sake_cup},{9,T.ribbon,S.blue},{9,T.chaff,S.none},{9,T.chaff,S.none},
 {10,T.animal,S.deer},{10,T.ribbon,S.blue},{10,T.chaff,S.none},{10,T.chaff,S.none},
 {11,T.bright,S.rainman},{11,T.animal,S.swallow},{11,T.ribbon,S.red},{11,T.chaff,S.none},
 {12,T.bright,S.phoenix},{12,T.chaff,S.none},{12,T.chaff,S.none},{12,T.chaff,S.none},
}
for i, v in ipairs(ref) do v.id=i; v.suit=v[1]; v.kind=v[2]; v.symbol=v[3] end
M.data = ref

function M.get(id) return ref[id] end
function M.same_month(a,b) return ref[a].suit == ref[b].suit end
function M.deck() local d={} for i=1,48 do d[i]=i end return d end
function M.by_symbol(symbol)
 local out={} for i,c in ipairs(ref) do if c.symbol == symbol then out[#out+1]=i end end; return out
end
return M
