# Observed class registry

## Player and HUD runtime notes

| Purpose | Verified runtime class / property | Notes |
| --- | --- | --- |
| Local player source | `BP_VehicleGameInstance_C.LocalPlayers` | `ForEach` indices are 1-based in this session. |
| Controller | `BP_VehiclePlayerController_C` | Available through `LyraLocalPlayer.PlayerController`. |
| Vehicle Pawn | `BP_Traxxas_X_Maxx_C` | Read through the controller's `Pawn` property; `GetPawn()` is not exposed. |
| Split HUD | `WBP_PlayerHUDLayout_Split_C` | Two layouts, enumerated opposite to the visual left/right split order. |
| Overlay panel | `WBP_PlayerHUDLayout_Split_C.OverlayContent` | Safe for runtime `TextBlock` attachment; root `SafeZone` is single-child. |

After the first UE4SS launch, record only classes, objects, and paths verified by dumps/logs. Do not write feature code against assumed names.

| Steam build | Class / object | Role | Evidence | Notes |
| --- | --- | --- | --- | --- |
| `25208735` | `BP_VehiclePlayerController_C` | Local player controller | Coordinates console test, 13:50 | Two separate instances observed in local split-screen |
| `25208735` | `BP_Traxxas_X_Maxx_C` | Local player Pawn / RC car | Coordinates console test, 13:50 | One Pawn observed per local player |
