# Coordinates

## Functional overlay

`Coordinates` is a read-only Lua module. Press `Ctrl+F1` to toggle a live four-line UMG overlay for every local player. Players are enumerated from `GameInstance.LocalPlayers`, so local Player 1 and Player 2 see their own transform independently. WheelMates currently uses `BP_VehiclePlayerController_C` with a `BP_Traxxas_X_Maxx_C` Pawn for both players.

- world position (`X`, `Y`, `Z`), in Unreal units;
- actor rotation (`Pitch`, `Yaw`, `Roll`), in degrees;
- current linear velocity (`X`, `Y`, `Z`).

The implementation follows UE4SS's generic `UEHelpers:GetPlayerController()` → `Pawn` → `K2_GetActorLocation()` pattern. It performs no state mutation. It refreshes the visible values every 150 ms.

## Verified WheelMates integration

The reliable local-player chain is `GameInstance.LocalPlayers:ForEach(index, player_param)` → `player_param:get()` → `LyraLocalPlayer.PlayerController` → `BP_VehiclePlayerController_C.Pawn`. The indices are 1-based in this session. `GetPawn()` is not exposed for this controller, while the reflected `Pawn` property is valid.

WheelMates uses two `WBP_PlayerHUDLayout_Split_C` UMG layouts. Their root is a single-child `SafeZone`, so runtime text must be attached to the existing `OverlayContent` property instead. Layout enumeration is opposite to the visible split-screen order: the first layout is Player 2 on the left and the second is Player 1 on the right. `Coordinates` deliberately reverses that association.

`widget_library` and `WidgetTree:ConstructWidget` are not exposed by the installed UE4SS build. Use `StaticConstructObject` for a basic `TextBlock` with the layout's existing `WidgetTree` as outer, then add it to `OverlayContent`.

## Diagnostics

Console probes belong to the separate `CoordinatesDiagnostics` module. It is disabled in `mods/mods.txt` by default. Enable it only when investigating an implementation issue, reload with `Ctrl+R`, then use:

- `Ctrl+NumPad 1`: player transforms and identities;
- `Ctrl+Shift+NumPad 1`: HUD topology;
- `Ctrl+Shift+NumPad 2`: UMG widget topology.

## Validation

1. Start a local/offline game and wait until the car is controllable.
2. Focus the game or the UE4SS console.
3. Press `Ctrl+F1`.
4. Verify each local viewport shows its own compact `COORDINATES P#` overlay and that its values update while driving.

The successful Pawn class and its full name are recorded in `class-registry.md`.
