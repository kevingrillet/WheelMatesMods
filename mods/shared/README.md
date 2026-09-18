# Shared libraries

Libraries are loaded with `require` from the workshop `mods/shared/?/?.lua` path.
They are not UE4SS mods and must not appear in `mods.txt`. POC entry points own
keybinds, hooks, scheduling and presentation choices. Tweaks reuses these contracts after the user confirmed the shared POCs working.

| Library | Contract and current consumers |
| --- | --- |
| `WMRuntime` | UObject validity, wrappers, iteration, scalar identity, current world, local players and loaded Gears; runtime POCs |
| `WMCollectibles` | `scan()` returns fresh `gears`, `narrative`, `minigames`, `narrative_loaded`, `narrative_known`; POCCheckList and Tweaks |
| `WMNavigation` | `nearest(origin, actors)` returns actor, dx/dy/dz and squared 3D distance, or nil; relative yaw, direction and vertical labels; POCCompass and Tweaks |
| `WMCoordinates` | Detailed `text` and one-line `compact` coordinate formatters; POCCoordinates and Tweaks |
| `WMTargets` | Session catalogue, per-player nearest/manual selection, stable cycling and sorted distance rows; Tweaks |
| `WMTeleport` | `new(log)` creates an independent session with `move`, `return_player`, `refresh_world`, `reset`; POCTP and Tweaks |
| `WMOverlay` | Shared HUD, optional player predicate, toggle/update/clear and cleanup; POCs, Tweaks and ModKit |
| `WMRenderState` | Reversible depth/stencil capture and restoration across reload; POCWallHack and ModKit |

`WMCollectibles` entries contain `actor`, `type`, `status` and `label`. They hold
transient UObject references: discard snapshots on travel and recheck validity
before use. Labels such as “Loaded Gear 1” are display text, not persistent IDs.
Missing narrative items require the current game instance's active save. Mini-games retain Loaded for the POC and expose a separate `progress` field
(Recorded, No result, Unknown) based on their MinigameId and the active save's
LastMinigameResultById. An unavailable narrative save leaves `narrative_known` false. No render
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
business logic they are intended to investigate. [Tweaks](../Tweaks/README.md) owns refresh cadence, input bindings and the compact
presentation. `WMTargets` registers no callbacks; its consumer calls `reset()` on
travel and discards all actor identities at that point. `WMOverlay.new` accepts an
optional player predicate; `clear()` detaches widgets while preserving enablement.

`WMTargets` copies positions, names and path/address references, never actor
userdata, into its persistent snapshot. Rendering uses that snapshot until the
next refresh; TP resolves the current actor again. `refresh()` uses known narrative
classes; `refresh(true)` retains the full Actor scan for explicit discovery.
`WMOverlay` also stores scalar path/address references, resolves widgets afresh,
and skips unchanged SetText calls. `forget()` abandons old-world entries without
native access; `clear()` actively detaches widgets during ordinary hide/reload.
`WMRuntime.world_id()` reads GameInstance's world without enumerating controllers.

`WMOverlay.recover()` cleans surviving owned widgets after travel has settled and
forgets old entries. Attachment reuses live named text/container objects instead
of reconstructing them. `WMTeleport.move()` and `return_player()` return true only
after successful movement, allowing Tweaks to schedule a post-teleport refresh.
