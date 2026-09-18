# TP

Fixed RiftX Gear approach route for local split-screen testing.

| Shortcut | Action |
| --- | --- |
| `Ctrl+F5` | Left screen (local index 2) to Gear approach point |
| `Ctrl+F6` | Right screen (local index 1) to Gear approach point |
| `Ctrl+F7` | Return left screen |
| `Ctrl+F9` | Return right screen |

The route requires a valid loaded Gear near the recorded target coordinates, as in
the working prototype. Render flags and per-Gear world identity are not filters.
The fixed destination is 600 Unreal units beside and 100 above the recorded Gear
location; this is not a
collision check and should be tested offline.

Only a successful `K2_SetActorLocation` result replaces a return point. Failed moves
retain it; successful returns consume it. Return points are invalidated by world
changes, map-load notifications, mod reloads and restarts. Unreal calls run on the
game thread. The mod does not write save files.

The user confirmed TP working again after the loaded-target filter correction on
September 18, 2026. This does not establish multiplayer authority or collision safety
for arbitrary future destinations.
