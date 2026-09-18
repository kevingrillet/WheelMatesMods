# WheelMatesMods

## Verified state — September 17, 2026

| Item | Value |
| --- | --- |
| Game | WheelMates — Steam `3905450` |
| Steam build | `25208735` |
| Game directory | `C:\Program Files (x86)\Steam\steamapps\common\WheelMates` |
| Game executable | `CarGame\Binaries\Win64\LyraGameSteam-Win64-Shipping.exe` |
| Engine | Unreal Engine 5.7 (confirmed by September 18 jmap) |
| Mod loader | UE4SS developer build, supplied under `tools/` |

WheelMates is not a Unity game, so BepInEx is not appropriate. The game install has no usable official SDK or ModKit (`LogicMods` is empty). This repository uses UE4SS Lua modules for HUD overlays, loaded collectible reports, local teleportation and experimental render changes.

Current module status, local validator setup and the reusable in-game regression checklist are in the [root README](../README.md). The table above records the original setup, not a pin of the currently installed runtime.

Discovery references: [collectible catalog](collectible-catalog.md), [checklist research](checklist.md), [class registry](class-registry.md), [startup skip analysis](skip-startup.md), and [ducks and pool](ducks-and-pool.md).

## Getting started

```powershell
.\scripts\setup-tools.ps1                  # diagnostics only; does not write to the game
.\scripts\setup-tools.ps1 -InstallUE4SS    # only after backing up saves
# Install StyLua and the isolated Lua test runtime using the root README first.
.\scripts\test.ps1                         # manifest, required StyLua and Lua regression tests
```

The first-install script references the local `g35d1795d` UE4SS bundle under `tools/`; the September 18 runtime dump reports `f6d5f942`. It refuses to replace an existing proxy DLL and is not an updater. Keep the working runtime when following the development setup. Lua mods do not need CMake, Ninja, xmake, or MSVC. FModel, RePak, and retoc are optional reverse-engineering tools and are not installed automatically.

## Mod loading

`mods/mods.txt` is the canonical load manifest. Tweaks, SkipStartup and AutoDucks are enabled;
Tweaks owns overlay cleanup and pending POCWallHack render restoration.
WallHack functionality remains outside Tweaks. The POC modules and diagnostics are
retained but disabled. See [Tweaks](../mods/Tweaks/README.md) for controls and checks.

Press `Ctrl+R` to reload the manifest and scripts, especially after shared changes.
To test POCs independently, disable Tweaks, enable ModKit and the required POCs,
then reload. Do not mix profiles because their shortcuts overlap. Libraries under
`mods/shared/` are not manifest entries. Reload clears Tweaks overlays/selections
and TP return points; active HUDs recover after map travel.

SkipStartup handles launch screens independently of the POC/Tweaks profile. Once
its watcher stops, its session state survives `Ctrl+R` and prevents a new timer or
scan. A full game restart enables it again. See [SkipStartup](skip-startup.md) for
the launch behavior and Ctrl+R fix confirmed in game on September 18, 2026.

## Safety notes

- Back up `%LOCALAPPDATA%\CarGame\Saved` before testing.
- Test alone or with explicitly consenting players; disable mods in public sessions.
- Do not edit `.pak`, `.utoc`, or `.ucas` files; this keeps Steam verification viable.
- After every Steam update, validate ModKit first and record the build in `class-registry.md`.

References: [UE4SS installation](https://docs.ue4ss.com/installation-guide), [Lua mods](https://docs.ue4ss.com/guides/creating-a-lua-mod.html), [C++ mods](https://docs.ue4ss.com/dev/guides/creating-a-c%2B%2B-mod.html).
