-- Standalone Koi-Koi session model.
-- Card definitions, yaku values, and weighted-AI priorities are derived from
-- longod/Hanafuda (MIT, Copyright (c) 2023 longod). No MWSE code or assets.
local cards = require "logic.cards"
local combinations = require "logic.combinations"

local M, Session = {}, {}
Session.__index = Session
local T = cards.type
local weights = {50,30,5,5,20,30,0,0,70,30,0,0,20,10,0,0,20,10,0,0,
 40,30,0,0,40,10,0,0,70,20,5,5,100,30,5,5,40,30,0,0,30,20,10,0,50,0,0,0}

local function copy(a) if type(a)~="table" then return a end; local b={} for k,v in pairs(a) do b[k]=type(v)=="table" and copy(v) or v end return b end
local function remove(a, x) for i,v in ipairs(a) do if v==x then table.remove(a,i); return true end end return false end
local function contains(a, x) for _,v in ipairs(a) do if v==x then return true end end return false end
local function pool() return { hand={}, [T.bright]={}, [T.animal]={}, [T.ribbon]={}, [T.chaff]={} } end
local function other(p) return p=="you" and "opponent" or "you" end
local function flat_captured(p)
 local out={}; for kind=T.bright,T.chaff do for _,id in ipairs(p[kind]) do out[#out+1]=id end end; return out
end
local function matching(id, field)
 local out={} for _,v in ipairs(field) do if cards.same_month(id,v) then out[#out+1]=v end end; return out
end

local function combo_labels(combo) return combinations.labels(combo or {}) end
local lucky_names={"Four of a Kind","Four Pairs"}
local function lucky_labels(combo)
 local out={}; for id,points in pairs(combo or {}) do out[#out+1]={id=id,name=lucky_names[id] or "Lucky Hand",points=points} end
 table.sort(out,function(a,b) return a.id<b.id end); return out
end

function Session:_random(max)
 self.rng = (self.rng * 16807) % 2147483647
 return (self.rng % max) + 1
end
function Session:_shuffle(deck)
 for i=#deck,2,-1 do local j=self:_random(i); deck[i],deck[j]=deck[j],deck[i] end
end
function Session:_take()
 return table.remove(self.deck)
end
function Session:_capture(player, id, from_field)
 if from_field then assert(remove(self.field,id), "field card missing") end
 local c=cards.get(id); self.pools[player][c.kind][#self.pools[player][c.kind]+1]=id
end
function Session:_record_move(player, id, drawn, hits, captured, target)
 local targets={}
 if captured then
  if #hits>=3 then targets=copy(hits) else targets={target or hits[1]} end
 end
 self.last_move={player=player,card_id=id,drawn=drawn==true,
  outcome=captured and "capture" or "discard",targets=targets}
end
function Session:_resolve(player, id, drawn, target)
 local p=self.pools[player]
 local hits=matching(id,self.field)
 assert(target==nil or contains(hits,target), "target is not on the field")
 if not drawn then assert(remove(p.hand,id), "hand card missing") end
 if #hits==0 then self.field[#self.field+1]=id; self:_record_move(player,id,drawn,hits,false); return end
 self:_capture(player,id,false)
 if #hits>=3 then for _,v in ipairs(hits) do self:_capture(player,v,true) end
 else self:_capture(player,target or hits[1],true) end
 self:_record_move(player,id,drawn,hits,true,target)
end
function Session:_multiplier(player)
 local points=combinations.total(self.combos[player])
 if self.rules.each_time_koi_koi then return 1+self.calls.you+self.calls.opponent end
 if self.rules.double_points_over_7 and points>=7 then return 2 end
 return 1
end
function Session:_reset_round()
 self.deck=cards.deck(); self:_shuffle(self.deck); self.field={}; self.pools={you=pool(),opponent=pool()}
 self.combos={you=nil,opponent=nil}; self.calls={you=0,opponent=0}; self.round_points={you=0,opponent=0}
 -- Re-deal a pathological four-of-one-month field, matching the source's rule.
 repeat
  self.deck=cards.deck(); self:_shuffle(self.deck); self.field={}; self.pools={you=pool(),opponent=pool()}
  local first,second=other(self.dealer),self.dealer
  while #self.pools[first].hand<8 do
   for i=1,2 do self.pools[first].hand[#self.pools[first].hand+1]=self:_take() end
   for i=1,2 do self.field[#self.field+1]=self:_take() end
   for i=1,2 do self.pools[second].hand[#self.pools[second].hand+1]=self:_take() end
  end
  local bad=false; for m=1,12 do local n=0; for _,id in ipairs(self.field) do if cards.get(id).suit==m then n=n+1 end end; if n>=4 then bad=true end end
 until not bad
 self.current=self.dealer; self.phase=""; self.pending=nil; self.new_combinations={}; self.winner=nil; self.lucky_hands={}
 self.round_result=nil; self.last_move=nil
end
function Session:_finish_round(winner, settled_points, reason)
 self.winner=winner
 local base_points,multiplier,awarded=0,1,0
 if winner then
  local points=combinations.total(self.combos[winner]); local mult=self:_multiplier(winner)
  if settled_points then
   base_points=settled_points; awarded=settled_points
   self.round_points[winner]=settled_points; self.scores[winner]=self.scores[winner]+settled_points
  else
   base_points=points; multiplier=mult; awarded=points*mult
   self.round_points[winner]=awarded; self.scores[winner]=self.scores[winner]+awarded
  end
  self.dealer=winner
 end
 self.round_result={round=self.round,winner=winner,reason=reason or (winner and "shobu" or "deck_empty"),
  base_points=base_points,multiplier=multiplier,awarded_points=awarded,round_points=copy(self.round_points),
  scores=copy(self.scores),combinations={you=combo_labels(self.combos.you),opponent=combo_labels(self.combos.opponent)},
  koi_calls=copy(self.calls),lucky_hands=copy(self.lucky_hands or {}),lucky_hand_details={you=lucky_labels(self.lucky_hands and self.lucky_hands.you),opponent=lucky_labels(self.lucky_hands and self.lucky_hands.opponent)},next_dealer=self.dealer}
 if self.round>=self.rounds then
  self.phase="match_over"
  if self.scores.you==self.scores.opponent then self.winner=nil
  elseif self.scores.you>self.scores.opponent then self.winner="you" else self.winner="opponent" end
  self.match_result={winner=self.winner,reason="completed",scores=copy(self.scores),rounds=self.rounds}
 else self.phase="round_over" end
end
function Session:_settle_lucky_hands()
 local you,you_points=combinations.lucky_hands(self.pools.you.hand,self.rules.lucky_hands)
 local opponent,opponent_points=combinations.lucky_hands(self.pools.opponent.hand,self.rules.lucky_hands)
 if not you and not opponent then return false end
 self.lucky_hands={you=you,opponent=opponent}
 if you and not opponent then self:_finish_round("you",you_points,"lucky_hand")
 elseif opponent and not you then self:_finish_round("opponent",opponent_points,"lucky_hand")
 else self:_finish_round(nil,nil,"lucky_hand_tie") end -- simultaneous lucky hands are a dealt-round tie.
 return true
end
function Session:_after_draw(player)
 local current=combinations.calculate(self.pools[player],self.rules)
 local diff=combinations.difference(current,self.combos[player]); self.combos[player]=current
 if diff then
  self.new_combinations=combinations.labels(diff)
  if player=="you" then self.phase="player_decision" else self:_ai_call() end
 else self:_next_turn() end
end
function Session:_after_hand_play(player)
 -- The original UI visibly moves a hand card, then has the player turn the
 -- deck card.  Keep that cadence opt-in so a headless caller can still use
 -- the compact one-action flow, while the GUI can present each move clearly.
 if self.presentation_steps then
  self.phase=(player=="you") and "player_draw" or "opponent_draw"
 else self:_draw(player) end
end
function Session:_draw(player)
 local id=self:_take(); if not id then self:_finish_round(nil,nil,"deck_empty"); return end
 local hits=matching(id,self.field)
 if self.presentation_steps then
  self.pending={card=id,drawn=true,player=player}
  self.phase=(player=="you") and "player_drawn" or "opponent_drawn"
  return
 end
 if player=="you" and #hits==2 then self.pending={card=id,drawn=true}; self.phase="player_match"; return end
 local target=#hits>0 and hits[1] or nil; if player=="opponent" and #hits>1 then target=self:_best_target(id,hits) end
 self:_resolve(player,id,true,target); self:_after_draw(player)
end
function Session:_next_turn()
 if #self.pools.you.hand==0 and #self.pools.opponent.hand==0 then self:_finish_round(nil,nil,"hands_empty"); return end
 self.current=other(self.current); self.pending=nil; self.new_combinations={}
 if self.current=="you" then self.phase="player_hand" else self:_ai_turn() end
end
function Session:_best_target(id,hits)
 if self.ai=="random" then return hits[self:_random(#hits)] end
 if self.ai=="simple" then return hits[1] end
 local best,bw=hits[1],-1; for _,v in ipairs(hits) do if weights[v]>bw then best,bw=v,weights[v] end end; return best
end
function Session:_ai_turn()
 local hand=self.pools.opponent.hand; if #hand==0 then self:_next_turn(); return end
 if self.ai=="random" then
  local chosen=hand[self:_random(#hand)]
  local hits=matching(chosen,self.field)
  self:_resolve("opponent",chosen,false,#hits>0 and self:_best_target(chosen,hits) or nil)
  self:_after_hand_play("opponent"); return
 end
 if self.ai=="simple" then
  local chosen,target=hand[1],nil
  for _,id in ipairs(hand) do
   local hits=matching(id,self.field)
   if #hits>0 then chosen,target=id,hits[1]; break end
  end
  self:_resolve("opponent",chosen,false,target)
  self:_after_hand_play("opponent"); return
 end
 local chosen,target,best,discard,low=nil,nil,-1,nil,nil
 for _,id in ipairs(hand) do
  local hits=matching(id,self.field)
  if #hits>0 then local t=self:_best_target(id,hits); local value=weights[id]+weights[t]
   if value>best then chosen,target,best=id,t,value end
  elseif low==nil or weights[id]<low then low,discard = weights[id],id end
 end
 chosen=chosen or discard; self:_resolve("opponent",chosen,false,target); self:_after_hand_play("opponent")
end
function Session:_ai_call()
 if self.ai=="random" and #self.pools.opponent.hand>0 and self:_random(2)==1 then
  self.calls.opponent=self.calls.opponent+1; self:_next_turn(); return
 end
 -- The source's weighted brain always chooses Shobu.
 self:_finish_round("opponent",nil,"shobu")
end
function Session:_confirm_pending()
 local pending=self.pending
 if not pending then return false,"There is no pending card." end
 local player=pending.player or "you"
 local hits=matching(pending.card,self.field)
 local target=nil
 if #hits==2 then
  if player=="you" then return false,"Choose one of the matching field cards first." end
  target=self:_best_target(pending.card,hits)
 end
 self:_resolve(player,pending.card,pending.drawn,target)
 self.pending=nil
 if pending.drawn then self:_after_draw(player) else self:_after_hand_play(player) end
 return true
end
function Session:start()
 if self.started then return true end
 self.started=true; self:_reset_round()
 if self:_settle_lucky_hands() then return true end
 if self.current=="you" then self.phase="player_hand" else self:_ai_turn() end
 return true
end
function Session:act(action)
 if type(action)~="table" or type(action.type)~="string" then return false,"Action must have a type." end
 if action.type=="new_match" then
  self.rng=self.seed; self.round=1; self.scores={you=0,opponent=0}; self.dealer=(self:_random(2)==1) and "you" or "opponent"; self.started=false; self.match_result=nil; self.confirmation=nil; return self:start()
 end
 if not self.started then return false,"Start the match first." end
 if action.type=="request_concede" then
  if self.phase=="match_over" or self.phase=="conceded" then return false,"There is no active match to concede." end
  if self.confirmation then return false,"A confirmation is already open." end
  self.confirmation={kind="concede",resume_phase=self.phase,title="Concede match?",message="Conceding ends this match and awards it to the opponent."}
  self.phase="confirm_concede"; return true
 end
 if action.type=="cancel_concede" then
  if self.phase~="confirm_concede" or not self.confirmation then return false,"There is no concession to cancel." end
  self.phase=self.confirmation.resume_phase; self.confirmation=nil; return true
 end
 if action.type=="confirm_concede" then
  if self.phase~="confirm_concede" or not self.confirmation then return false,"There is no concession to confirm." end
  self.confirmation=nil; self.phase="conceded"; self.winner="opponent"
  self.match_result={winner="opponent",reason="conceded",scores=copy(self.scores),rounds=self.rounds}
  return true
 end
 if action.type=="next_round" then
  if self.phase~="round_over" then return false,"The current round is not over." end
  self.round=self.round+1; self:_reset_round(); if self:_settle_lucky_hands() then return true end; if self.current=="you" then self.phase="player_hand" else self:_ai_turn() end; return true
 end
 if action.type=="draw_card" then
  if self.phase~="player_draw" then return false,"A deck card cannot be drawn right now." end
  self:_draw("you"); return true
 end
 if action.type=="advance" then
  if self.phase=="opponent_draw" then self:_draw("opponent"); return true end
  if self.phase=="opponent_drawn" then return self:_confirm_pending() end
  return false,"There is no opponent move to continue."
 end
 if action.type=="cancel_play" then
  if self.phase~="player_play" or not self.pending then return false,"There is no selected hand card to cancel." end
  self.pending=nil; self.phase="player_hand"; return true
 end
 if action.type=="confirm_play" then
  if self.phase~="player_play" then return false,"There is no selected hand card to confirm." end
  return self:_confirm_pending()
 end
 if action.type=="confirm_draw" then
  if self.phase~="player_drawn" then return false,"There is no drawn card to confirm." end
  return self:_confirm_pending()
 end
 if action.type=="select_card" then
  local id=action.card_id
  if self.phase=="player_hand" then
   if not contains(self.pools.you.hand,id) then return false,"That card is not in your hand." end
   local hits=matching(id,self.field)
   if self.presentation_steps then self.pending={card=id,drawn=false,player="you"}; self.phase="player_play"; return true end
   if #hits==2 then self.pending={card=id,drawn=false}; self.phase="player_match"; return true end
   self:_resolve("you",id,false,hits[1]); self:_after_hand_play("you"); return true
  elseif self.phase=="player_play" then
   local p=self.pending; if not p then return false,"There is no selected hand card." end
   if contains(self.pools.you.hand,id) then self.pending={card=id,drawn=false,player="you"}; return true end
   if #matching(p.card,self.field)~=2 or not remove(matching(p.card,self.field),id) then return false,"Choose a highlighted matching card." end
   self:_resolve("you",p.card,false,id); self.pending=nil; self:_after_hand_play("you"); return true
  elseif self.phase=="player_drawn" then
   local p=self.pending; if not p or #matching(p.card,self.field)~=2 or not remove(matching(p.card,self.field),id) then return false,"Choose a highlighted matching card." end
   self:_resolve("you",p.card,true,id); self.pending=nil; self:_after_draw("you"); return true
  elseif self.phase=="player_match" then
   local p=self.pending; if not p or not remove(matching(p.card,self.field),id) then return false,"Choose a highlighted matching card." end
   self:_resolve("you",p.card,p.drawn,id); self.pending=nil
   if p.drawn then self:_after_draw("you") else self:_after_hand_play("you") end
   return true
  end
  return false,"A card cannot be selected right now."
 end
 if action.type=="koi_koi" or action.type=="shobu" then
  if self.phase~="player_decision" then return false,"There is no Koi-Koi decision now." end
  if action.type=="shobu" then self:_finish_round("you",nil,"shobu")
  else
   if #self.pools.you.hand==0 then return false,"Koi-Koi is unavailable when your hand is empty." end
   self.calls.you=self.calls.you+1; self:_next_turn()
  end
  return true
 end
 return false,"Unknown action."
end
function Session:view()
 local selectable={}; if self.phase=="player_hand" then for _,id in ipairs(self.pools.you.hand) do selectable[id]=true end
 elseif self.phase=="player_play" and self.pending then
  for _,id in ipairs(self.pools.you.hand) do selectable[id]=true end
  if #matching(self.pending.card,self.field)==2 then for _,id in ipairs(matching(self.pending.card,self.field)) do selectable[id]=true end end
 elseif self.phase=="player_match" and self.pending then for _,id in ipairs(matching(self.pending.card,self.field)) do selectable[id]=true end
 elseif self.phase=="player_drawn" and self.pending and #matching(self.pending.card,self.field)==2 then for _,id in ipairs(matching(self.pending.card,self.field)) do selectable[id]=true end end
 local prompt={player_hand="Choose a card from your hand",player_play="Confirm this hand card, or choose a matching field card",player_match="Choose a matching field card",player_draw="Draw a card from the deck",player_drawn="Confirm the drawn card, or choose a matching field card",opponent_draw="Opponent played a card — reveal the draw",opponent_drawn="Opponent drew a card — continue",player_decision="Koi-Koi or Shobu?",round_over="Round over",match_over="Match over",confirm_concede="Confirm concession",conceded="Match conceded"}
 local base_points=combinations.total(self.combos.you)
 local multiplier=self:_multiplier("you")
 local decision=nil
 if self.phase=="player_decision" then
  decision={player="you",combinations=combo_labels(self.combos.you),new_combinations=copy(self.new_combinations),base_points=base_points,multiplier=multiplier,projected_points=base_points*multiplier,koi_calls=copy(self.calls),can_koi_koi=#self.pools.you.hand>0}
 end
 return { phase=self.phase,prompt=prompt[self.phase] or "",round=self.round,rounds=self.rounds,dealer=self.dealer,current=self.current,
  deck_count=#self.deck,hand=copy(self.pools.you.hand),opponent_hand_count=#self.pools.opponent.hand,field=copy(self.field),
  captured={you=flat_captured(self.pools.you),opponent=flat_captured(self.pools.opponent)},captured_groups={you=copy(self.pools.you),opponent=copy(self.pools.opponent)},scores=copy(self.scores),round_points=copy(self.round_points),
  selectable=selectable,new_combinations=copy(self.new_combinations),winner=self.winner,can_koi_koi=self.phase=="player_decision" and #self.pools.you.hand>0,can_shobu=self.phase=="player_decision",
  can_continue=self.phase=="round_over",can_draw=self.phase=="player_draw",can_advance=self.phase=="opponent_draw" or self.phase=="opponent_drawn",can_confirm_play=self.phase=="player_play" and self.pending and #matching(self.pending.card,self.field)~=2,can_cancel_play=self.phase=="player_play",can_confirm_draw=self.phase=="player_drawn" and self.pending and #matching(self.pending.card,self.field)~=2,can_concede=self.phase~="match_over" and self.phase~="conceded" and self.phase~="confirm_concede",can_new_match=true,
  cards=cards.data,pending_card=self.pending and self.pending.card or nil,pending_drawn=self.pending and self.pending.drawn or false,pending_targets=self.pending and matching(self.pending.card,self.field) or {},lucky_hands=copy(self.lucky_hands or {}),lucky_hand_details={you=lucky_labels(self.lucky_hands and self.lucky_hands.you),opponent=lucky_labels(self.lucky_hands and self.lucky_hands.opponent)},
  combinations={you=combo_labels(self.combos.you),opponent=combo_labels(self.combos.opponent)},decision=decision,round_result=copy(self.round_result),match_result=copy(self.match_result),last_move=copy(self.last_move),confirmation=copy(self.confirmation),rules=copy(self.rules),ai=self.ai }
end
function M.new(options)
 options=options or {}; local seed=tonumber(options.seed) or 1; seed=math.floor(seed)%2147483647; if seed<=0 then seed=1 end
 local given=options.rules or {}; local each=given.each_time_koi_koi==true; local rules={ double_points_over_7=(given.double_points_over_7~=false) and not each, flower_viewing_sake=given.flower_viewing_sake~=false, moon_viewing_sake=given.moon_viewing_sake~=false, lucky_hands=given.lucky_hands~=false, each_time_koi_koi=each }
 local ai=options.ai or "weighted"; assert(ai=="weighted" or ai=="simple" or ai=="random", "unknown AI mode")
 local s=setmetatable({rounds=math.max(1,math.floor(tonumber(options.rounds) or 3)),seed=seed,rng=seed,round=1,scores={you=0,opponent=0},rules=rules,ai=ai,started=false,presentation_steps=options.presentation_steps==true},Session)
 s.dealer=(s:_random(2)==1) and "you" or "opponent"; return s
end
return M
