# WheelMatesMods

Personal WheelMates mod workshop based on UE4SS (Unreal Engine 5).

Read [.docs/README.md](.docs/README.md), then run:

```powershell
    .\scripts\setup-tools.ps1
```

## Mod loading

[`mods/mods.txt`](mods/mods.txt) is the source-controlled, canonical load manifest. Add a module there only after it has a working `Scripts/main.lua`; the order in this file is the UE4SS load order.

After changing source files while the game is running, press `Ctrl + R` in the UE4SS console to reload the active modules. Per-module `enabled.txt` files are not used by this repository.

## Modules

- **ModKit**: passive loader and diagnostic probe.
- **Coordinates**: live, per-local-player in-game coordinate overlay.
- **CheckList**: compact, read-only list of loaded mini-games and missing narrative collectibles.
- **TP**: local-player teleport validation and return point.
- **CoordinatesDiagnostics** and **CheckListDiagnostics**: disabled-by-default, read-only reverse-engineering probes. Enable only one when needed; their NumPad shortcuts intentionally overlap.
- **Compass**, **WallHack**, and **Tweaks**: planned modules, enabled only when implemented and tested.
