# Hanafuda Koi-Koi (Defold)

Standalone Koi-Koi for desktop and mobile, ported from the MIT-licensed
gameplay model in longod's Hanafuda: Akaviri Playing Cards. A local tavern
purse and rival selection replace the original Morrowind NPC service flow.

This repository contains no original card textures, background images, or
sound effects: those assets are separately licensed. Card faces are drawn
with styled Defold GUI nodes, with month, category, and motif tooltips.

## Requirements

- Defold editor or a Defold Bob JAR (current stable release recommended).
- OpenJDK 25 when invoking the tested Defold 1.13.1 Bob directly.

Open the repository directory in Defold and run the project. The project is
landscape-first at 1280x720, supports high-DPI displays and resizable desktop
windows, and can rotate between landscape and portrait through the responsive GUI.

See [docs/BUILDING.md](docs/BUILDING.md) for reproducible command-line builds.

## Play

Choose **Settings** from the opening screen to set match length, rival,
house rules, and an optional wager. The purse starts at 100 gold. A match win
pays even money, a loss forfeits the stake, and a tie refunds it. Starting
another match before the current wager finishes forfeits that stake. Gold and
Settings persist between launches; leaving during a wager loses the stake.

Select a highlighted hand card, choose a field target when prompted, then
draw from the deck. After forming a scoring combination, call Koi-Koi to
continue or Shobu to bank the points. Hover over cards and controls for help.
On desktop, Escape opens or closes the menu; Enter or Space activates the
shown primary action. Touch controls appear below the board in portrait mode.

See [docs/PARITY.md](docs/PARITY.md) for a feature map against the source mod.
This repository contains source only; no executable bundle is checked in.

Run the pure-Lua parity suite from the project root with:

```sh
texlua tests/run.lua .
```

See [docs/VALIDATION.md](docs/VALIDATION.md) for the verified scope and limits.

## License

The port and translated gameplay code are available under the MIT License;
see [LICENSE](LICENSE). Third-party attribution and excluded media are listed
in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
