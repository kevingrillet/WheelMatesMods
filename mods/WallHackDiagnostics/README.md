# WallHackDiagnostics

Optional, read-only rendering investigation tools for `WallHack`. It is disabled by default in `mods/mods.txt`.

To enable it temporarily, change `WallHackDiagnostics : 0` to `WallHackDiagnostics : 1` in `mods/mods.txt`, then press `Ctrl+R` in UE4SS to reload the modules.

- `Ctrl+F8`: reports Custom Depth and stencil values of each local player vehicle mesh. This identifies the channel used by WheelMates' existing outline.
- `Ctrl+Shift+F4`: reports the loaded Gear render components and their current depth/stencil state.

The diagnostic module never changes actors, saves, input, or rendering state.
