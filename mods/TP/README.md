# TP

The initial Teleport module validates safe local-Pawn relocation before adding an in-game destination window.

## Current test destination

The module targets an approach point 600 Unreal units beside the loaded missing Gear identified by CheckList in RiftX, and only enables that route while the matching Gear actor is loaded. The vehicle arrives 100 Unreal units above the recorded ground position so its existing physics can settle without spawning inside the Gear or nearby geometry.

| Shortcut | Action |
| --- | --- |
| `Ctrl + F5` | Teleport local Player 1 to the RiftX Gear. |
| `Ctrl + F6` | Teleport local Player 2 to the RiftX Gear. |
| `Ctrl + F7` | Return local Player 1 to the last location saved by this module. |

The module only moves local Pawns, performs all Unreal calls on the game thread, and does not change the save data. The return location is held in memory and is cleared by a mod reload or game restart.
