-- Standalone replacement for the source mod's NPC gambling transaction.
-- The game world is represented by a small local purse, with a single
-- even-money stake held in escrow until the match is over.
local M, Tavern = {}, {}
Tavern.__index = Tavern

function M.new(gold)
  gold = math.floor(tonumber(gold) or 100)
  assert(gold >= 0, "gold cannot be negative")
  return setmetatable({ gold = gold, stake = 0, last_result = nil }, Tavern)
end

function Tavern:reserve(stake)
  stake = tonumber(stake)
  if not stake or stake ~= math.floor(stake) or stake < 1 then return false, "Choose a whole-gold wager." end
  if self.stake ~= 0 then return false, "A wager is already active." end
  if stake > self.gold then return false, "You do not have enough gold." end
  self.gold = self.gold - stake
  self.stake = stake
  self.last_result = nil
  return true
end

function Tavern:settle(winner)
  if self.stake == 0 then return false, "There is no wager to settle." end
  if winner ~= "you" and winner ~= "opponent" and winner ~= nil then return false, "Invalid match winner." end
  local stake = self.stake
  if winner == "you" then self.gold = self.gold + stake * 2
  elseif winner == nil then self.gold = self.gold + stake end
  self.stake = 0
  self.last_result = { winner = winner, change = winner == "you" and stake or (winner == "opponent" and -stake or 0) }
  return true
end

function Tavern:refund()
  if self.stake > 0 then self.gold = self.gold + self.stake; self.stake = 0 end
end

function Tavern:view()
  return { gold = self.gold, stake = self.stake, last_result = self.last_result }
end

return M
