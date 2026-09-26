# FMOD audio

The game uses [Defold's FMOD extension](https://defold.com/extension-fmod/),
pinned to v0.1.1 in `game.project`. Fetch project libraries in Defold before
building. The integration stays silent when banks are absent, so the game can
still be developed without authored audio.

Create a project in FMOD Studio and export these three banks to `banks/`:

- `Master Bank.strings.bank`
- `Master Bank.bank`
- `Hanafuda.bank`

Assign the following events to `Hanafuda.bank` using these exact Studio paths:

| Event path | Played when |
| --- | --- |
| `event:/UI/Click` | Menus and settings are used |
| `event:/Cards/Select` | A hand or field card is selected |
| `event:/Cards/Play` | A played or drawn card is resolved |
| `event:/Cards/Draw` | A deck card is drawn |
| `event:/Cards/Deal` | A match or round begins |
| `event:/Round/KoiKoi` | The player calls Koi-Koi |
| `event:/Round/Win` | The player wins a round or match |
| `event:/Round/Lose` | The opponent wins or the player concedes |
| `event:/Round/Draw` | A round or match ends in a draw |

These are one-shot events. Missing individual events are skipped; FMOD event
lookup errors do not interrupt play. The banks are loaded once at startup and
unloaded when the GUI exits. The extension updates FMOD each frame.

Only use audio you have the right to distribute. FMOD and Firelight
Technologies Pty Ltd must be credited in a distributed game, with the FMOD
logo as required by the [FMOD license](https://www.fmod.com/legal).
