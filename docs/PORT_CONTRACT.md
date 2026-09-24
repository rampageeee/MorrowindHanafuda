# Hanafuda Defold port contract

This project ports the MIT-licensed Koi-Koi model from longod/Hanafuda while
removing every dependency on Morrowind, MWSE, and the separately licensed
textures and sounds.

## Product slice

- One human player against a local weighted AI.
- Standard 48-card Koi-Koi deck and the combinations present in the source.
- Multi-round match, dealer selection, dealing, hand play, draw/capture,
  Koi-Koi/Shobu choice, scoring, and match restart.
- Mouse and single-touch input through one Defold GUI.
- Responsive landscape-first layout that remains operable on portrait screens.
- No image or sound dependency. Card faces are rendered from GUI boxes and text.

The Morrowind gambling/service layer is intentionally not part of the
standalone game.

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
`shobu`, `next_round`, and `new_match`. The session automatically advances
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

## Ownership during parallel implementation

- Core agent: `logic/**` only.
- UI agent: `game/**` only.
- Project/build agent: root configuration, `build_tools/**`, `docs/**` except
  this file, and root `README.md`.

