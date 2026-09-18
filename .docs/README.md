# WheelMatesMods

## Verified state — September 17, 2026

| Item | Value |
| --- | --- |
| Game | WheelMates — Steam `3905450` |
| Steam build | `25208735` |
| Game directory | `C:\Program Files (x86)\Steam\steamapps\common\WheelMates` |
| Game executable | `CarGame\Binaries\Win64\LyraGameSteam-Win64-Shipping.exe` |
| Engine | Unreal Engine 5, likely 5.7 |
| Mod loader | UE4SS developer build, supplied under `tools/` |

WheelMates is not a Unity game, so BepInEx is not appropriate. The game install has no usable official SDK or ModKit (`LogicMods` is empty). This repository uses UE4SS, starting with read-only Lua observation.

Discovery references: [collectible catalog](collectible-catalog.md), [checklist research](checklist.md), and [class registry](class-registry.md).

## Getting started

```powershell
.\scripts\setup-tools.ps1                  # diagnostics only; does not write to the game
.\scripts\setup-tools.ps1 -InstallUE4SS    # only after backing up saves
.\scripts\test.ps1                         # manifest and optional Lua validation
```

The script uses the pinned UE4SS bundle under `tools/`. Lua mods do not need CMake, Ninja, xmake, or MSVC. FModel, RePak, and retoc are optional reverse-engineering tools and are not installed automatically.

## Mod loading

`mods/mods.txt` is the canonical, source-controlled UE4SS load manifest. Its order is the module load order; add a module only after its `Scripts/main.lua` has been implemented and tested. The repository does not use per-module `enabled.txt` files.

Press `Ctrl + R` in the UE4SS console to reload the manifest and source files while the game is running.

## Safety notes

- Back up `%LOCALAPPDATA%\CarGame\Saved` before testing.
- Test alone or with explicitly consenting players; disable mods in public sessions.
- Do not edit `.pak`, `.utoc`, or `.ucas` files; this keeps Steam verification viable.
- After every Steam update, validate ModKit first and record the build in `class-registry.md`.

References: [UE4SS installation](https://docs.ue4ss.com/installation-guide), [Lua mods](https://docs.ue4ss.com/guides/creating-a-lua-mod.html), [C++ mods](https://docs.ue4ss.com/dev/guides/creating-a-c%2B%2B-mod.html).
