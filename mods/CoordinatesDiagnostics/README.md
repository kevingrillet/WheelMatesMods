# CoordinatesDiagnostics

Optional, read-only investigation tools for `Coordinates`. It is disabled by default in `mods/mods.txt`.

To enable it temporarily, change `CoordinatesDiagnostics : 0` to `CoordinatesDiagnostics : 1` in `mods/mods.txt`, then press `Ctrl+R` in UE4SS to reload the modules.

- `Ctrl+NumPad 1`: `GameInstance → LocalPlayers → PlayerController → Pawn` chain and player identities.
- `Ctrl+NumPad 2`: active HUD objects and inherited drawing functions.
- `Ctrl+NumPad 3`: loaded UMG widget classes and instance counts.
- `Ctrl+NumPad 4`: active split HUD roots and their writable UMG properties.

The diagnostic module never changes actors, saves, input, or UI state.
