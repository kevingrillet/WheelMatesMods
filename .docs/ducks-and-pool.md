# Rubber ducks and pool

Research date: September 18, 2026. See [AutoDucks](../mods/AutoDucks/README.md).
The user confirmed AutoDucks works perfectly in game on September 18, 2026,
after the Backyard map-guard correction. This is functional feedback, not an
exhaustive validation of every scenario.

## Sources and scope

The user deposited two ducks in the pool before generating the local files in
`UE4SS_Dumps/ducks/`:

- `1789746021-ue4ss_actor_data.csv`: 3,709 actors, including 15 ducks.
- `1789746018-ue4ss_static_mesh_data.csv`: 1,820 StaticMeshActor entries, no ducks.
  Ducks are Blueprint actors: use the actor export.
- `CarGame-5.7.4-0+UE5-f6d5f942.jmap`: reflected types, functions and defaults.

Dumps are ignored by Git. This note preserves their useful findings. Earlier
root-level exports showed menu/lobby actors without identifiable ducks.
The exports are not a complete game catalogue; JMap defaults are not live values.

## Duck variants

Both Blueprint assets are under `/Game/Environment/PhysicsResponsiveObjects/`.

| Variant | Runtime class | Mesh under `/Game/Props/RubberDuck_01/` | Loaded count |
| --- | --- | --- | --- |
| 01 | `BP_PhysicsActor_RubberDuck_01_prp_C` | `SM_RubberDuck_01_01_prp` | 7 |
| 02 | `BP_PhysicsActor_RubberDuck_02_prp_C` | `SM_RubberDuck_01_02_prp` | 8 |

Actor CSV lines 3200-3207 contain variant 02; lines 3208-3214 contain variant 01.
Both reference `Materials/MI_RubberDuck_01_01`: distinct meshes with the same
exported material. Fifteen loaded ducks does not prove a 15-duck achievement target.

Both inherit `BP_PhysicsResponsiveActor_Base_MagnetGrab_C`, exposing `StaticMesh`,
`Targetable`, `SmoothSync`, `InitalTransform` (reflected spelling) and `Respawnable`.
Both duck defaults set `Respawnable = true`. The parent's `ReturnToInitialPosition`
references holder lookup, ability cancellation and `K2_SetActorLocationAndRotation`.
This supports actor teleportation, but does not establish native AutoDucks behaviour.

## Pool and candidate counter

These are actor origins in Unreal units, not verified water-surface or collision
centres. The pool origin must not be treated as a duck placement destination.

| Actor | Actor CSV line | X | Y | Z |
| --- | --- | ---: | ---: | ---: |
| `BP_Pool_01_01_prp_C` | 3708 | -10999.301568 | 22480.359178 | -429.733814 |
| `BP_Trigger_PhysicObject_RequiredCount_C` | 3052 | -12457.658415 | 25431.456603 | -1085.000000 |

Pool asset: `/Game/Props/Pool_01/BP_Pool_01_01_prp`. Its class exposes three mesh
components and no reflected functions of its own.

Trigger asset: `/Game/Core/ExecutionSystem/BP_Trigger_PhysicObject_RequiredCount`.
It exposes `OverlappedActors`, `CurrentCount`, `RequiredCount`, `RequieredTag`
(reflected spelling), `DoOnce`, `SendOnRelease?`, `Box` and `PuzzleSignalSource`.
Its graph references array membership/add/remove operations, increment/decrement,
threshold comparisons and `PuzzleSignalSourceComponent.SetSignal`. This is a
strong candidate for the pool counter; its achievement connection is unverified.
Its zero class-default counts must not be read as live configuration.

Two ducks near the trigger are probably those deposited by the user:

| Actor CSV row ID | Variant | X | Y | Z |
| --- | --- | ---: | ---: | ---: |
| `Row_3205` | 02 | -12661.646732 | 24650.423771 | -1579.916765 |
| `Row_3211` | 01 | -12545.080271 | 25110.159682 | -1580.804954 |

This identification is inferred from positions and user observation. The CSV
does not establish overlap membership. Row IDs are not stable runtime identities.

## Achievement evidence

The registry contains `Achievement.Activity.RubberDucksCollected` and
`Achievement.Funny.RubberDucksCollected`. Reflected achievement definitions have
`SourceActivityTag` and `RequiredCount`, but the matching definition row, required
total, Steam display name and trigger connection have not been recovered.

## AutoDucks implementation

`Ctrl+F7` gathers both variants around Player 1; `Ctrl+Shift+F7` uses Player 2.
Each press performs one action without moving vehicles or spawning ducks.

The runtime log supplied by the user at 18:47 on September 18 confirms the world
`World /Game/Maps/LVL_Backyard_01.LVL_Backyard_01`. AutoDucks now requires this exact
active GameInstance world name before scanning counters or ducks. Other maps
are rejected even if old duck objects remain loaded.

The initial guard falsely rejected this confirmed map. It combined pool/trigger
coordinates with an Outer-chain membership test; the log did not isolate which
condition failed. The correction removes the decorative pool requirement and
per-actor ownership filters, following the valid-loaded-candidate policy of the
working POCs. Fresh scans retain no actor references between presses. This does
not independently prove each candidate belongs to the active world.

The count trigger is resolved separately: prefer exactly one match within 100
units of its recorded position; otherwise accept the sole loaded candidate with
a diagnostic. Multiple unmatched candidates, multiple position matches or no
candidate stop the action. The single-candidate fallback assumes the loaded
counter is the observed pool counter; this fallback was not separately confirmed.

Ducks in that trigger's `OverlappedActors` are skipped. This preserves membership
in the candidate counter, not a proven saved completion flag. Unreadable membership
stops the action. A valid holder from `Targetable.GetHolderByComponentIndex(0)`
skips that duck; unreadable holder state or a missing mesh also skips it.

The ring has minimum radius 300 units, minimum neighbour spacing 200 units and
height offset 100 units. `K2_SetActorLocation` uses teleport with sweep disabled;
its boolean result is checked before clearing linear/angular physics velocities.
There is no ground or obstacle check. Console output reports moved, preserved,
held, unreadable and failed counts, plus physics-reset warnings.

Unreal access runs on the game thread with fresh actors per press and no retained
actor references. AutoDucks does not call achievement APIs or write saves directly;
normal game-side progression may still be saved.

## Validation and remaining regression checks

[Automated tests](../tests/test_auto_ducks.lua) cover both players and variants,
exclusions, map rejection and partial failures using mocked UE4SS. The full
validator passed after implementation and the map-guard fix. The user then
confirmed the mod works perfectly in game. The following remain the regression
checklist; individual results were not reported for every scenario:

1. Both variants move around the selected player; vehicles stay stationary.
2. Deposited ducks remain in the pool; held ducks are skipped.
3. Other maps are rejected before scans, including after travel; validate loaded
   candidate behaviour when returning to Backyard.
4. Reload, streaming, collisions, physics and respawn behave correctly.
5. Live counter membership/counts and normal delivery confirm the achievement
   connection, including exit/re-entry after TP.
6. Host/client authority is verified if network play is used.
