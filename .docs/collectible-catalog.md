# Collectible catalog discovery

## Confirmed primary collectible tags

The packaged game data and the loaded `VehicleSaveGame` agree on these primary categories:

- `Collectable.Neurocore`
- `Collectable.Plate`
- `Collectable.Gear`

These are the three counters shown in the collection summary UI.

## Separate progression families found in packaged data

The following names occur alongside level and narrative data. They must be treated as separate checklist families until their runtime classes and save records are mapped:

- `MemoryCard`
- `ScanObject`
- `Node`
- `CustomParts`
- `DataBank.Item.Spot`

`BP_NarrativeItem_Scannable_C` is confirmed as a runtime actor class for scannable objects. The original Backyard discovery session contained eight instances; this is not a current-session count.

## Mini-games

The historical discovery save had completed results for four mini-games, but that is not an exhaustive catalog. A completed-result entry proves completion only; it does not prove that no other mini-game definition exists.

## Implication for CheckList

The future complete catalogue should cover these families separately (the current console report covers loaded Gears, missing narrative actors and mini-game entry points):

1. primary items (Neurocores, Plates, Gears);
2. narrative items (Memory Cards, Scan Objects, Nodes, Data Bank entries);
3. custom parts;
4. mini-games.

The next data-mapping step is to resolve a persistent identifier and a world location for each family, then subtract the relevant saved set from that catalog.
