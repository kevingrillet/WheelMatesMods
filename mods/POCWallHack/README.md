# POCWallHack (WIP)

Proof of concept retained for independent validation before [Tweaks](../Tweaks/README.md).

`Ctrl+F4` toggles Custom Depth and stencil 1 on the loaded Gears' `StaticMesh` and
`Sphere` components. These fields come from `BP_Collectable_OutlineBubble_C`.
While enabled, a one-second refresh includes newly loaded Gears.

Original depth/stencil values are stored in UE4SS shared scalar variables before
mutation. They survive Lua reloads. POCWallHack restores them when disabled, and ModKit
restores them after a full reload even if POCWallHack is disabled in the manifest.
Failed restorations are retained for retry while POCWallHack is loaded.

Restart the game once when upgrading from the old prototype: originals lost by that
version cannot be reconstructed. The visible through-wall effect remains unvalidated;
this module currently controls the render-buffer flags, not a complete outline shader.

Optional `POCWallHackDiagnostics` controls:

- `Ctrl+Shift+F4`: Gear component probe.
- `Ctrl+F8`: player outline probe.

Diagnostics are disabled by default and read-only.
