# Observed class registry

## Player and HUD runtime notes

| Purpose | Verified runtime class / property | Notes |
| --- | --- | --- |
| Local player source | `BP_VehicleGameInstance_C.LocalPlayers` | `ForEach` indices are 1-based in this session. |
| Controller | `BP_VehiclePlayerController_C` | Available through `LyraLocalPlayer.PlayerController`. |
| Vehicle Pawn | `BP_Traxxas_X_Maxx_C` | Read through the controller's `Pawn` property; `GetPawn()` is not exposed. |
| Split HUD | `WBP_PlayerHUDLayout_Split_C` | Match layouts by GetOwningPlayer; observed enumeration order is not an ownership contract. |
| Overlay panel | `WBP_PlayerHUDLayout_Split_C.OverlayContent` | Single-child `NamedSlot` (jmap confirmed); host a shared `VerticalBox` for multiple overlays. |

Record only classes, objects, and paths verified by dumps/logs. Do not write feature code against assumed names.

| Steam build | Class / object | Role | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `25208735` | `BP_VehiclePlayerController_C` | Local player controller | Coordinates console test, 13:50 | Two separate instances observed in local split-screen |
| `25208735` | `BP_Traxxas_X_Maxx_C` | Local player Pawn / RC car | Coordinates console test, 13:50 | One Pawn observed per local player |

## September 18 reflection and integration findings

- `VehicleSaveGameSubsystem.CurrentSaveGame`: active save source used by CheckList;
  select the subsystem belonging to the current GameInstance.
- `VehicleSaveGame.CollectedNarrativeItems`: narrative tag map used to omit collected items.
- `BP_Collectable_Gear_C` inherits `BP_Collectable_OutlineBubble_C`, which exposes
  `StaticMesh`, `Sphere`, `OutlineColor` and `MeshSizePcnt`.
- `Actor.K2_SetActorLocation` returns a boolean: a successful Lua call alone does
  not prove that teleportation succeeded.
- The jmap exports reflected types and class defaults, not live component values.
  Use runtime probes for the actual depth, stencil and material settings.
- Per-actor world-identity and Gear visibility filters rejected real loaded targets
  in this game. CheckList/Compass/TP use valid loaded candidates instead. TP still
  tracks the session world separately to invalidate return points after travel.
