# POCCheckListDiagnostics

Proof of concept retained for independent validation before [Tweaks](../Tweaks/README.md).

Optional read-only exploration tools for building future POCCheckList features. The module is disabled by default in `mods/mods.txt`.

Temporarily set `POCCheckListDiagnostics : 1`, press `Ctrl+R` in UE4SS, then use:

- `Ctrl+NumPad 1`: inventory candidate collectible runtime classes and properties.
- `Ctrl+NumPad 2`: list loaded Gear actors and compare saved customization unlock tags between two probes.

Only one diagnostic module should be enabled at a time: the NumPad shortcuts are intentionally shared with `POCCoordinatesDiagnostics`.
