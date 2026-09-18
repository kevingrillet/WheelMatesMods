# Shared libraries

Libraries are loaded with `require` from the workshop `mods/shared/?/?.lua` path.
They are not UE4SS mods and must not appear in `mods.txt`. POC entry points own
keybinds, hooks, scheduling and presentation choices. Tweaks will reuse these
contracts after in-game validation of the POCs.

| Library | Contract and current consumers |
| --- | --- |
| `WMRuntime` | UObject validity, wrappers, iteration, scalar identity, current world, local players and loaded Gears; runtime POCs |
| `WMCollectibles` | `scan()` returns fresh `gears`, `narrative`, `minigames`, `narrative_loaded`, `narrative_known`; POCCheckList |
| `WMNavigation` | `nearest(origin, actors)` returns actor, dx/dy/dz and squared 3D distance, or nil; relative yaw, direction and vertical labels; POCCompass |
| `WMCoordinates` | `text(player_index, pawn)` preserves the detailed coordinates formatter; POCCoordinates |
| `WMTeleport` | `new(log)` creates an independent session with `move`, `return_player`, `refresh_world`, `reset`; POCTP |
| `WMOverlay` | Shared split-screen HUD container, toggle/update and owned-widget cleanup; coordinates, compass and ModKit |
| `WMRenderState` | Reversible depth/stencil capture and restoration across reload; POCWallHack and ModKit |

`WMCollectibles` entries contain `actor`, `type`, `status` and `label`. They hold
transient UObject references: discard snapshots on travel and recheck validity
before use. Labels such as “Loaded Gear 1” are display text, not persistent IDs.
Missing narrative items require the current game instance's active save. Mini-games
are only Loaded; an unavailable save leaves `narrative_known` false. No render
visibility or per-actor world filter is applied to loaded collectible candidates.

`WMTeleport` methods run on the game thread. The consumer registers the load-map
reset hook and world polling; constructing a session registers no callbacks.
Each successful outbound move replaces that player's return point; failed moves
preserve it, successful returns consume it, reset/world change clears all points.
The caller chooses and validates the destination; this library performs no
collision sweep or target discovery.

Widget ownership names (`Coordinates`, `Compass`) and the WallHack shared-state
key deliberately retain their original identifiers. Renaming the POC folders must
not strand old widgets or lose pending render restorations. They are internal
compatibility keys, not obsolete module paths.

After changing helpers, use a full UE4SS reload so all modules use the same version.
Diagnostics stay independent raw Unreal probes rather than depending on the
business logic they are intended to investigate. The planned compact presentation,
selection modes and refresh orchestration belong to the next
[Tweaks phase](../Tweaks/README.md).
