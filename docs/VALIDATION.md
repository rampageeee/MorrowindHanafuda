# Validation record

This hand-off is source-only; generated platform bundles are not included.

The 2026-09-24 UI, AI mode, and tavern changes have had a source review and
`git diff --check`. They have not been run through Bob or the pure Lua suite in
this environment: the user requested no build, and no Lua interpreter is
installed here. The record below describes the earlier 2026-09-10 baseline.

Validated on 2026-09-10 with Defold/Bob 1.13.1 (`574678c`) and OpenJDK 25.

## Passed

- Pure Lua suite: 3 suites, 11,409 assertions.
- Card deck: all 48 IDs, month/type/symbol tuples, distributions, matching,
  dealing, and deck invariants.
- Scoring: every combination in the source, incremental points, viewing-sake
  prerequisites, lucky hands, Koi-Koi multipliers, and aggregate match winner.
- Sessions: legal and illegal actions, deterministic replay, AI turns,
  multi-round completion, score changes, dealer handoff, and restart.
- Defold resource and Lua compilation through Bob.
- Successful bundles: Windows x64, Linux x64, Android ARM64 APK/AAB, unsigned
  iOS ARM64 IPA, and HTML5/Wasm.

## Environment limits

The container has no graphical display, Android emulator, or Apple signing
identity. Therefore the GUI was not interactively exercised here. Final visual
and device QA remains necessary.

No card illustrations, backgrounds, or sounds from the Morrowind mod are
present. The current interface deliberately uses box-and-text card faces as a
functional replacement layer for later original artwork.
