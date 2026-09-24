# Hanafuda Koi-Koi (Defold)

Standalone Koi-Koi for desktop and mobile, ported from the MIT-licensed
gameplay model in longod's Hanafuda: Akaviri Playing Cards. The Morrowind and
MWSE integration is intentionally excluded.

This repository deliberately contains no original card textures, background
images, or sound effects: those assets are separately licensed and are not
part of the port. Card faces are drawn with Defold GUI boxes and text.

## Requirements

- Defold editor or a Defold Bob JAR (current stable release recommended).
- OpenJDK 25 when invoking the tested Defold 1.13.1 Bob directly.

Open the repository directory in Defold and run the project. The project is
landscape-first at 1280x720, supports high-DPI displays and resizable desktop
windows, and can rotate between landscape and portrait through the responsive GUI.

See [docs/BUILDING.md](docs/BUILDING.md) for reproducible command-line builds.

## Included build status

The package includes fresh Bob 1.13.1 bundles under `dist/` for Windows x64,
Linux x64, Android ARM64 (APK and AAB), unsigned iOS ARM64, and HTML5/Wasm.
The Android artifacts use a disposable debug signature; sign a release bundle
before store distribution. The iOS IPA requires Apple signing before
installation. The generated `build/` intermediates are omitted.

Run the pure-Lua parity suite from the project root with:

```sh
texlua tests/run.lua .
```

See [docs/VALIDATION.md](docs/VALIDATION.md) for the verified scope and limits.

## License

The port and translated gameplay code are available under the MIT License;
see [LICENSE](LICENSE). Third-party attribution and excluded media are listed
in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
