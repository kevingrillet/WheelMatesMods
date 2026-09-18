# Compass

`Ctrl+F3` toggles a direction and distance HUD for the nearest loaded Gear, relative
to each local vehicle's yaw. It shares a vertical HUD container with Coordinates.
The target list is scanned once per second for both players; direction and distance
update every 200 ms. Invalid targets are skipped between scans. Loaded Gears are
not filtered by render visibility or per-actor world metadata, which incorrectly
rejected targets in the first refactor.

Reload starts the overlay off and removes previous widgets. An enabled overlay
rebuilds after the player's HUD changes. Owner matching uses `GetOwningPlayer`;
layouts without a ready local owner are retried rather than guessed by array order.

This remains a loaded-Gear navigator, not a complete collectible catalogue.
The user confirmed Compass working again after the loaded-target filter correction
on September 18, 2026.

## Vertical direction

The third line shows `UP`, `DOWN` or `LEVEL` and the signed height difference
between the Gear and each player's Pawn, in metres. `LEVEL` includes differences
from -2 m to +2 m; larger differences show `UP` or `DOWN`. This is the actor's height,
not a route instruction or a floor identifier. The main distance remains 3D.

Examples: `UP  Height delta +12.5 m`, `DOWN  Height delta -8.0 m`.
This addition is covered by regression tests and was confirmed working in game
by the user on September 18, 2026.
