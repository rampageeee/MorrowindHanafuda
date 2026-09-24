local a = require "tests.assertions"
local cards = require "logic.cards"
local session = require "logic.session"

local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = clone(item) end
    return out
end

local function legal_choice(view)
    if view.phase == "player_hand" then
        for _, id in ipairs(view.hand) do
            if view.selectable[id] then return { type="select_card", card_id=id } end
        end
    elseif view.phase == "player_match" then
        for _, id in ipairs(view.field) do
            if view.selectable[id] then return { type="select_card", card_id=id } end
        end
    elseif view.phase == "player_decision" then
        -- Choosing Shobu makes an integration test finite while exercising scoring.
        return { type="shobu" }
    elseif view.phase == "round_over" then
        return { type="next_round" }
    end
    return nil
end

local function run_match(seed, rounds)
    local match = session.new({ seed=seed, rounds=rounds })
    a.truthy(match:start(), "a new session starts")
    local trace, score_before, observed_rounds = {}, { you=0, opponent=0 }, 0
    for step = 1, 500 do
        local view = match:view()
        trace[#trace+1] = clone(view)
        if view.phase == "match_over" then
            a.equal(view.scores.you - score_before.you, view.round_points.you, "final your score changes by final-round points")
            a.equal(view.scores.opponent - score_before.opponent, view.round_points.opponent, "final opponent score changes by final-round points")
            return match, trace, observed_rounds
        end
        if view.phase == "round_over" then
            observed_rounds = observed_rounds + 1
            a.equal(view.scores.you - score_before.you, view.round_points.you, "your score changes by this round's points")
            a.equal(view.scores.opponent - score_before.opponent, view.round_points.opponent, "opponent score changes by this round's points")
            score_before = { you=view.scores.you, opponent=view.scores.opponent }
        end
        local action = legal_choice(view)
        a.truthy(action, "the session exposes a finite legal action path; phase=" .. tostring(view.phase))
        local ok, message = match:act(action)
        a.truthy(ok, "legal action succeeds: " .. tostring(message))
    end
    error("autoplay did not finish within 500 player actions")
end

local function expected_winner(scores)
    if scores.you == scores.opponent then return nil end
    return scores.you > scores.opponent and "you" or "opponent"
end

return function()
    -- Seed 2 has the human as the opening dealer, so this view is immediately
    -- after the source-compatible 8/8/8 initial deal.
    local match = session.new({ seed=2, rounds=3 })
    a.falsy(match:act({ type="select_card", card_id=1 }), "actions before start are rejected")
    a.truthy(match:start(), "start returns success")
    local initial = match:view()
    a.equal(initial.phase, "player_hand", "human dealer receives the first turn")
    a.equal(initial.round, 1, "match starts on round one")
    a.equal(initial.rounds, 3, "configured round count is exposed")
    a.equal(initial.dealer, "you", "seeded dealer selection is reproducible")
    a.equal(initial.current, "you", "dealer plays first")
    a.equal(initial.deck_count, 24, "initial deal leaves 24 deck cards")
    a.equal(#initial.hand, 8, "human receives eight cards")
    a.equal(initial.opponent_hand_count, 8, "opponent receives eight cards")
    a.equal(#initial.field, 8, "field receives eight cards")
    a.equal(#initial.hand + initial.opponent_hand_count + #initial.field + initial.deck_count, 48, "initial deal accounts for all cards")
    for month = 1, 12 do
        local count = 0
        for _, id in ipairs(initial.field) do if cards.get(id).suit == month then count = count + 1 end end
        a.truthy(count < 4, "initial field never contains all four cards of a month")
    end
    for _, id in ipairs(initial.hand) do a.truthy(initial.selectable[id], "every hand card is selectable") end
    a.falsy(initial.can_koi_koi, "Koi-Koi is unavailable before scoring")
    a.falsy(initial.can_shobu, "Shobu is unavailable before scoring")
    a.falsy(initial.can_continue, "next round is unavailable before round end")
    a.truthy(initial.can_concede, "an active match can be conceded through the UI confirmation flow")
    a.truthy(initial.can_new_match, "the shell can always offer a new match action")
    a.equal(initial.pending_drawn, false, "no drawn card is pending at the start")
    a.equal(#initial.combinations.you, 0, "the view always exposes an inspectable combination list")
    a.equal(initial.last_move, nil, "an untouched session safely exposes no previous move")
    a.equal(initial.round_result, nil, "an untouched session safely exposes no round result")
    a.equal(initial.match_result, nil, "an active session safely exposes no match result")

    local ok = match:act({ type="select_card", card_id=0 })
    a.falsy(ok, "a card outside the hand is illegal")
    ok = match:act({ type="koi_koi" }); a.falsy(ok, "Koi-Koi outside a decision is illegal")
    ok = match:act({ type="shobu" }); a.falsy(ok, "Shobu outside a decision is illegal")
    ok = match:act({ type="next_round" }); a.falsy(ok, "next round before round end is illegal")
    ok = match:act({ type="not_an_action" }); a.falsy(ok, "unknown actions are illegal")

    -- The source game asks before its Concede command.  Keep the confirmation
    -- in the pure session model so a Defold modal cannot accidentally abandon
    -- a live match through a stray tap.
    a.truthy(match:act({ type="request_concede" }), "requesting concession opens a confirmation")
    local concede_prompt = match:view()
    a.equal(concede_prompt.phase, "confirm_concede", "concession has an explicit confirmation phase")
    a.equal(concede_prompt.confirmation.kind, "concede", "confirmation identifies its action")
    a.falsy(concede_prompt.can_concede, "a second concession cannot be opened over the first")
    a.truthy(match:act({ type="cancel_concede" }), "concession can be cancelled")
    a.equal(match:view().phase, "player_hand", "cancelling returns to the exact input phase")

    local first = legal_choice(initial)
    a.truthy(first, "a card can be selected from the initial hand")
    ok = match:act(first)
    a.truthy(ok, "selecting a selectable card is legal")
    local after = match:view()
    if after.phase == "player_match" then
        ok = match:act({ type="select_card", card_id=48 })
        a.falsy(ok, "only highlighted field matches may be selected")
        local target = legal_choice(after)
        a.truthy(target, "a matching target is selectable")
        ok = match:act(target)
        a.truthy(ok, "a highlighted target can be captured")
    end

    -- Same seed means same deal, AI choices, and the same observable trace.
    local left, left_trace = run_match(24680, 3)
    local right, right_trace = run_match(24680, 3)
    a.table_equal(left_trace, right_trace, "same seed produces the same complete match trace")
    a.equal(left:view().phase, "match_over", "full autoplay terminates")
    a.equal(#left_trace > 1, true, "autoplay takes real turns")
    a.equal(left:view().winner, expected_winner(left:view().scores), "match winner is determined by total score")
    a.equal(left:view().match_result.reason, "completed", "finished matches expose a result summary")
    a.equal(left:view().round_result.round, 3, "finished matches retain the final round summary")
    a.truthy(type(left:view().round_result.combinations.you) == "table", "round summaries expose combination details for UI")

    -- A multi-round trace must reach every configured round and preserve the
    -- round winner/dealer handoff whenever a round scored.
    local multi, _, completed = run_match(13579, 3)
    local final = multi:view()
    a.equal(final.round, 3, "three-round match reaches its final round")
    a.equal(completed, 2, "two intermediate rounds required explicit continuation")
    a.equal(final.phase, "match_over", "final round advances to match result")
    a.equal(final.winner, expected_winner(final.scores), "winner follows final accumulated totals")

    -- new_match resets both score and the deterministic opening state.
    local restarted = session.new({ seed=2, rounds=3 })
    restarted:start()
    local reference = clone(restarted:view())
    restarted:act({ type="select_card", card_id=restarted:view().hand[1] })
    a.truthy(restarted:act({ type="new_match" }), "new match is legal")
    a.table_equal(restarted:view(), reference, "new match resets the seeded opening state")

    local conceded = session.new({ seed=2, rounds=3 })
    conceded:start()
    a.truthy(conceded:act({ type="request_concede" }), "a separate match can request concession")
    a.truthy(conceded:act({ type="confirm_concede" }), "confirmed concession succeeds")
    local conceded_view = conceded:view()
    a.equal(conceded_view.phase, "conceded", "confirmed concession ends the current match")
    a.equal(conceded_view.match_result.reason, "conceded", "concession supplies a result reason to the UI")
    a.equal(conceded_view.winner, "opponent", "concession awards the match to the opponent")
    a.falsy(conceded:act({ type="confirm_concede" }), "a concession cannot be confirmed twice")

    -- Presentation mode exposes the same two-step hand/draw cadence as the
    -- source UI. It is opt-in so simple callers retain the compact API.
    local staged = session.new({ seed=2, rounds=3, presentation_steps=true })
    staged:start()
    local staged_view = staged:view()
    local staged_card = nil
    for _, id in ipairs(staged_view.hand) do
        local hits = 0
        for _, field_id in ipairs(staged_view.field) do
            if cards.same_month(id, field_id) then hits = hits + 1 end
        end
        if hits ~= 2 then staged_card = id; break end
    end
    a.truthy(staged_card, "the deterministic staged deal has a direct hand play")
    a.truthy(staged:act({ type="select_card", card_id=staged_card }), "staged hand play succeeds")
    staged_view = staged:view()
    a.equal(staged_view.phase, "player_play", "staged play keeps every selected hand card visible before resolution")
    a.truthy(staged_view.can_confirm_play, "a direct hand play has an explicit confirmation")
    a.truthy(staged_view.can_cancel_play, "a selected hand card can be put back")
    a.truthy(staged:act({ type="cancel_play" }), "the selected hand card can be cancelled")
    a.equal(staged:view().phase, "player_hand", "cancelling returns the card choice to the hand")
    a.truthy(staged:act({ type="select_card", card_id=staged_card }), "a cancelled hand card can be selected again")
    a.truthy(staged:act({ type="confirm_play" }), "the selected hand card can be confirmed")
    staged_view = staged:view()
    a.equal(staged_view.phase, "player_draw", "confirmed hand play pauses before drawing from the deck")
    a.truthy(staged_view.can_draw, "the deck is explicitly actionable after a hand play")
    a.equal(staged_view.last_move.player, "you", "the staged view retains the player hand move")
    a.falsy(staged_view.last_move.drawn, "the staged hand move is not marked as a draw")
    a.truthy(staged:act({ type="draw_card" }), "the player can reveal the deck card")
    a.equal(staged:view().phase, "player_drawn", "the drawn card remains visible before it resolves")
    a.falsy(staged:act({ type="draw_card" }), "a second draw cannot be requested outside the draw phase")

    -- Drive one presentation-mode match until the AI's resolved hand move is
    -- visible before its draw. This is the feedback pause the old synchronous
    -- flow could not render.
    local saw_opponent_pause = false
    for seed = 1, 32 do
        local paced = session.new({ seed=seed, rounds=3, presentation_steps=true })
        paced:start()
        for step = 1, 120 do
            local view = paced:view()
            if view.phase == "opponent_draw" then
                a.truthy(view.can_advance, "the opponent draw pause is acknowledgeable")
                a.equal(view.last_move.player, "opponent", "the pause exposes the opponent's played card")
                a.falsy(view.last_move.drawn, "the displayed opponent move precedes its draw")
                a.truthy(paced:act({ type="advance" }), "the opponent draw can be advanced")
                saw_opponent_pause = true
                break
            elseif view.phase == "player_hand" then
                paced:act(legal_choice(view))
            elseif view.phase == "player_match" then
                paced:act(legal_choice(view))
            elseif view.phase == "player_play" then
                if view.can_confirm_play then
                    paced:act({ type="confirm_play" })
                else
                    paced:act({ type="select_card", card_id=view.pending_targets[1] })
                end
            elseif view.phase == "player_draw" then
                paced:act({ type="draw_card" })
            elseif view.phase == "player_drawn" then
                if view.can_confirm_draw then
                    paced:act({ type="confirm_draw" })
                else
                    paced:act({ type="select_card", card_id=view.pending_targets[1] })
                end
            elseif view.phase == "player_decision" then
                paced:act({ type=view.can_koi_koi and "koi_koi" or "shobu" })
            elseif view.phase == "opponent_drawn" then
                paced:act({ type="advance" })
            elseif view.phase == "round_over" then
                paced:act({ type="next_round" })
            else
                break
            end
        end
        if saw_opponent_pause then break end
    end
    a.truthy(saw_opponent_pause, "presentation mode exposes an opponent action pause")

    -- A two-target hand play remains a player choice in presentation mode.
    local saw_player_target_choice = false
    for seed = 1, 64 do
        local choice_match = session.new({ seed=seed, rounds=3, presentation_steps=true })
        choice_match:start()
        local view = choice_match:view()
        if view.phase == "player_hand" then
            for _, id in ipairs(view.hand) do
                local targets = {}
                for _, field_id in ipairs(view.field) do
                    if cards.same_month(id, field_id) then targets[#targets + 1] = field_id end
                end
                if #targets == 2 then
                    a.truthy(choice_match:act({ type="select_card", card_id=id }), "a multi-match hand card can be staged")
                    local staged_choice = choice_match:view()
                    a.equal(staged_choice.phase, "player_play", "multi-match hand play stays staged")
                    a.falsy(staged_choice.can_confirm_play, "two field targets require an explicit target choice")
                    a.equal(#staged_choice.pending_targets, 2, "both legal field targets are exposed")
                    a.truthy(choice_match:act({ type="select_card", card_id=staged_choice.pending_targets[1] }), "one highlighted field target can be chosen")
                    a.equal(choice_match:view().phase, "player_draw", "choosing the target resolves the hand play")
                    saw_player_target_choice = true
                    break
                end
            end
        end
        if saw_player_target_choice then break end
    end
    a.truthy(saw_player_target_choice, "a sampled deal exposes a staged two-target hand choice")

    -- The CPU still needs a deterministic choice when its shown drawn card
    -- matches exactly two field cards; otherwise presentation mode deadlocks.
    local forced_ai_draw = session.new({ seed=2, rounds=3, presentation_steps=true })
    forced_ai_draw:start()
    forced_ai_draw.current = "opponent"
    forced_ai_draw.field = { 2, 3 } -- both match card 1 (month one)
    forced_ai_draw.pending = { card=1, drawn=true, player="opponent" }
    forced_ai_draw.phase = "opponent_drawn"
    a.truthy(forced_ai_draw:act({ type="advance" }), "the AI resolves a shown two-target draw without player input")
    local forced_ai_view = forced_ai_draw:view()
    a.equal(forced_ai_view.last_move.player, "opponent", "AI two-target draw is recorded as an opponent move")
    a.equal(#forced_ai_view.last_move.targets, 1, "AI chooses exactly one of two matching field cards")
end
