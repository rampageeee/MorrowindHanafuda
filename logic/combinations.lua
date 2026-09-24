-- Derived from longod/Hanafuda KoiKoi combination rules (MIT, 2023 longod).
local cards = require "logic.cards"
local M = {}
M.names = { "Five Brights", "Four Brights", "Rainy Four Brights", "Three Brights",
 "Boar-Deer-Butterfly", "Animals", "Poetry and Blue Ribbons", "Poetry Ribbons",
 "Blue Ribbons", "Ribbons", "Flower Viewing Sake", "Moon Viewing Sake", "Chaff" }
local base = {10,8,7,5,5,1,10,5,5,1,5,5,1}
local T,S=cards.type,cards.symbol
local function contains(a,id) for _,v in ipairs(a or {}) do if v==id then return true end end end
local function all(a, ids) for _,id in ipairs(ids) do if not contains(a,id) then return false end end return true end
local function count(a) return a and #a or 0 end
local rain, curtain, moon = 41,9,29
local boar,deer,butterfly,sake = 25,37,21,33
local poetry,blue = cards.by_symbol(S.red_poetry),cards.by_symbol(S.blue)

function M.calculate(captured, rules)
 rules=rules or {}; local out={}; local bright=captured[T.bright] or {}
 if #bright==5 then out[1]=base[1]
 elseif #bright==4 then out[contains(bright,rain) and 3 or 2]=base[contains(bright,rain) and 3 or 2]
 elseif #bright==3 and not contains(bright,rain) then out[4]=base[4] end
 local has_curtain,has_moon=contains(bright,curtain),contains(bright,moon)
 local animal=captured[T.animal] or {}
 if all(animal,{boar,deer,butterfly}) then out[5]=base[5] end
 if #animal>=5 then out[6]=base[6]+#animal-5 end
 if contains(animal,sake) then
  if has_curtain and rules.flower_viewing_sake then out[11]=base[11] end
  if has_moon and rules.moon_viewing_sake then out[12]=base[12] end
 end
 local ribbon=captured[T.ribbon] or {}
 if all(ribbon,poetry) and all(ribbon,blue) then out[7]=base[7]+#ribbon-6
 elseif all(ribbon,poetry) then out[8]=base[8]+#ribbon-3
 elseif all(ribbon,blue) then out[9]=base[9]+#ribbon-3
 elseif #ribbon>=5 then out[10]=base[10]+#ribbon-5 end
 local chaff=captured[T.chaff] or {}; if #chaff>=10 then out[13]=base[13]+#chaff-10 end
 return next(out) and out or nil
end
function M.difference(current, previous)
 if not current then return nil end; local d={}
 for k,v in pairs(current) do if not previous or not previous[k] or v>previous[k] then d[k]=v end end
 return next(d) and d or nil
end
function M.total(c) local n=0; for _,v in pairs(c or {}) do n=n+v end; return n end
-- Teyaku: dealt-only lucky hands from the source rules.  Both may apply.
function M.lucky_hands(hand, enabled)
 if enabled == false then return nil,0 end
 local suits={}; for _,id in ipairs(hand) do local m=cards.get(id).suit; suits[m]=(suits[m] or 0)+1 end
 local four,pair_count=false,0; for _,n in pairs(suits) do if n>=4 then four=true end; if n>=2 then pair_count=pair_count+1 end end
 local out={}; if four then out[1]=6 end; if pair_count>=4 then out[2]=6 end
 return next(out) and out or nil, M.total(out)
end
function M.labels(c)
 local out={}; for k,v in pairs(c or {}) do out[#out+1]={ id=k, name=M.names[k], points=v } end
 table.sort(out,function(a,b)return a.id<b.id end); return out
end
return M
