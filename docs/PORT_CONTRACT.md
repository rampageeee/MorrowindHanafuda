# Hanafuda Defold port contract

This project ports the MIT-licensed Koi-Koi model from longod/Hanafuda while
removing dependencies on Morrowind, MWSE, and the separately licensed textures
and sounds. `logic.tavern` provides a standalone purse and wager transaction.

## Product slice

- One human player against a local weighted, simple, or random AI.
- Standard 48-card Koi-Koi deck and the combinations present in the source.
- Multi-round match, dealer selection, dealing, hand play, draw/capture,
  Koi-Koi/Shobu choice, scoring, and match restart.
- Mouse and single-touch input through one Defold GUI.
- Responsive landscape-first layout that remains operable on portrait screens.
- Optional even-money wagers and a local gold purse.
- Configurable round count and house rules.
- Hover help, scoring guide, and procedural card faces made from GUI nodes.

The standalone tavern flow replaces NPC service activation and gold transfer.
It does not alter a Morrowind save or use MWSE.

## Module boundary

`logic/` must be pure Lua 5.1-compatible code. It must not access Defold globals.

The GUI owns only rendering and input. It talks to `logic.session` through:

```lua
local session = require "logic.session"
local match = session.new({ rounds = 3, seed = 12345 })
match:start()
local view = match:view()
local ok, error_message = match:act({ type = "select_card", card_id = 1 })
```

`act()` accepts the context-sensitive actions `select_card`, `koi_koi`,
`shobu`, `next_round`, `new_match`, and concession actions. With
`presentation_steps=true`, it also accepts `confirm_play`, `cancel_play`,
`draw_card`, `confirm_draw`, and `advance`. The session automatically advances
deterministic, non-interactive steps and AI turns until human input is needed.

`view()` returns an immutable-by-convention table containing at least:

```lua
{
  phase = "player_hand", -- or player_match, player_decision, round_over, match_over
  prompt = "Choose a card from your hand",
  round = 1,
  rounds = 3,
  dealer = "you",
  current = "you",
  deck_count = 24,
  hand = { 1, 2 },
  opponent_hand_count = 8,
  field = { 3, 4 },
  captured = { you = {}, opponent = {} },
  scores = { you = 0, opponent = 0 },
  round_points = { you = 0, opponent = 0 },
  selectable = { [1] = true },
  new_combinations = {},
  winner = nil,
  can_koi_koi = false,
  can_shobu = false,
  can_continue = false,
}
```

If the translated core needs a slightly richer field set, it may add fields,
but these names remain the stable UI contract.
