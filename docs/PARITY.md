# Source feature map

Reference: [longod/Hanafuda](https://github.com/longod/Hanafuda), an MWSE
mod for Morrowind. This project runs as a separate Defold game.

| Source feature | Standalone implementation |
| --- | --- |
| 48 Hanafuda cards and Koi-Koi captures | `logic/cards.lua` and `logic/session.lua` |
| Yaku, lucky hands, round scoring, Koi-Koi/Shobu | `logic/combinations.lua` and `logic/session.lua` |
| Random, simple, weighted rivals | Selectable in the opening Settings screen |
| House rules and match length | Selectable in Settings before the next match |
| NPC gambling arrangement and result | Local tavern purse, wager escrow, win/loss/tie settlement; gold persists between launches |
| Card guide and contextual controls | In-game guide, prompts, hover tooltips, portrait menu |
| Original textures, audio, MWSE dialogue, Morrowind world state | Standalone procedural UI and local purse; no Morrowind process or save integration |

The upstream mod requires Morrowind and MWSE. This source-only Defold project
is the playable replacement for that environment. Building a platform bundle
requires Defold or Bob; bundles are not stored in this repository.
