# POCWallHackDiagnostics

Proof of concept retained for independent validation before [Tweaks](../Tweaks/README.md).

Optional, read-only rendering investigation tools for `POCWallHack`. It is disabled by default in `mods/mods.txt`.

To enable it temporarily, change `POCWallHackDiagnostics : 0` to `POCWallHackDiagnostics : 1` in `mods/mods.txt`, then press `Ctrl+R` in UE4SS to reload the modules.

- `Ctrl+F8`: reports Custom Depth and stencil values of local player static-mesh components. These are clues for investigating the existing outline, not proof of the material or channel responsible for it.
- `Ctrl+Shift+F4`: reports the loaded Gear render components and their current depth/stencil state.

The diagnostic module never changes actors, saves, input, or rendering state.
