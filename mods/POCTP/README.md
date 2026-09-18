# POCTP

Proof of concept retained for independent validation before [Tweaks](../Tweaks/README.md).

Fixed RiftX Gear approach route for local split-screen testing.

| Shortcut | Action |
| --- | --- |
| `Ctrl+F5` | Player 1 (LocalPlayers index 1): RiftX Gear approach point |
| `Ctrl+Shift+F5` | Player 2 (LocalPlayers index 2): RiftX Gear approach point |
| `Ctrl+F6` | Return Player 1 |
| `Ctrl+Shift+F6` | Return Player 2 |

Player numbers match the HUD labels: index 1 (observed right screen) and index 2
(observed left screen). Ctrl selects Player 1; Ctrl+Shift selects Player 2.

The route requires a valid loaded Gear near the recorded target coordinates, as in
the working prototype. Render flags and per-Gear world identity are not filters.
The fixed destination is 600 Unreal units beside and 100 above the recorded Gear
location; this is not a
collision check and should be tested offline.

Only a successful `K2_SetActorLocation` result replaces a return point. Failed moves
retain it; successful returns consume it. Return points are invalidated by world
changes, map-load notifications, mod reloads and restarts. Unreal calls run on the
game thread. The mod does not write save files.

The user confirmed POCTP working again after the loaded-target filter correction on
September 18, 2026. This does not establish multiplayer authority or collision safety
for arbitrary future destinations.
