# CheckList discovery notes

## Objective

Show each collectible the active player has not obtained, grouped by category, in an in-game window.

Candidate categories to validate in the game are Neuro Nodes, Neuro Cores, Neuro Memory Cards, scannable objects, and mini-game collectibles. These labels are provisional until runtime classes and save-state fields are confirmed.

## Confirmed runtime data (build 25208735)

`VehicleSaveGame.CollectablesStats` uses gameplay tags as keys:

| Tag | Meaning | Observed progress |
| --- | --- | --- |
| `Collectable.Neurocore` | Neurocore | 1520 / 1520 |
| `Collectable.Plate` | Plate | 49 / 52 |
| `Collectable.Gear` | Gear | 50 / 52 |

The player snapshot used during discovery is therefore missing three Plates and two Gears. `CollectedItems` is a `TSet` of 1,624 persistent GUIDs and is the authoritative collected-item set.

Gears are known to unlock vehicle-customization options. The next correlation probe therefore reads `VehicleSaveGame.UnlockedCustomizationOptions` alongside loaded `BP_Collectable_Gear` actors; it remains read-only and is intended to establish the identifier linking a Gear, its persistent GUID, and its unlock.

`PerLevelData` currently contains the tags `Map.Level.Tutorial`, `Map.Level.Kitchen`, `Map.Level.Backyard`, `Map.Level.Corridor`, `Map.Level.RiftX`, `Map.Level.Garage`, and `Map.Level.Shed`.

The saved mini-game result map contains completed results for Kitchen Game of Tag, Hallway Coin Rush, RiftX Coin Rush, and Garage Game of Tag. It does **not** establish the total number of mini-games in the game. Mini-game completion must remain part of the final checklist, but the saved results are not one of the five missing Plate/Gear items in this snapshot.

## First missing-item mapping

In the RiftX-loaded session, the compact runtime probe found 27 narrative items, of which 26 were saved. The remaining item was reported as `Narrative.Message.MemoryCard.RiftY.1` at `{X=-26644.862, Y=-72703.857, Z=14110.000}`. The level package is RiftX even though the raw narrative tag uses `RiftY`; retain the runtime tag verbatim until game data establishes whether this is an intentional naming convention or a game typo.

## Required evidence before UI work

The game package contains names such as `Collectable`, `MemoryCard`, and `Antenna`, but asset names alone do not establish how the runtime tracks collection. CheckList's first implementation is therefore a read-only probe:

- candidate actors loaded in the current level, found by a one-off scan of actor class and object names;
- their concrete runtime class names;
- loaded `SaveGame` instances and the reflected properties of WheelMates (`CarGame`) save classes.

Run `Ctrl + F2` in a level and record the console block beginning with `[CheckList]`. Repeat once just before and after collecting a known item if practical.

## Design constraints

- A world actor may disappear when collected, so the world alone cannot prove that an item is missing.
- The final checklist must use the player's persistent save state, not infer progress from an item simply being absent.
- Split-screen support must use the selected local player. Remote-player support must be explicitly tested on the host.
- The discovery module is diagnostic only: it never writes save data or changes game objects.
# Module split

`CheckList` contains only the player-facing compact checklist on `Ctrl+F2`.
It includes loaded Gears as missing items because collected Gears are removed from the active level.
Its exploratory runtime probes live in the disabled-by-default `CheckListDiagnostics` module:

- `Ctrl+NumPad 1`: collectible actor and property discovery;
- `Ctrl+NumPad 2`: Gear locations and customization unlock comparison.

`CoordinatesDiagnostics` shares the same NumPad shortcut family. Enable only one diagnostics module at a time, then reload UE4SS with `Ctrl+R`.
