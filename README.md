# WheelMatesMods

Personal WheelMates mod workshop using UE4SS and Unreal Engine 5.7.

> [!NOTE]
> **Educational purpose — exploring modding**
> This project is a personal learning space for discovering game modding,
> experimenting with Lua and UE4SS, and understanding Unreal Engine systems.
> The code and prototypes are shared for educational purposes and experimentation.
> This is an unofficial community project, unaffiliated with the developers or
> publishers of WheelMates.

The pre-refactor modules are recorded in Conventional Commits. On September 18,
2026, the user confirmed POCCompass/POCTP and then POCCheckList working again after the
loaded-actor filter fixes, and reported that the refactor looks good. This is
functional feedback, not an exhaustive validation of every lifecycle edge case.
The user also confirmed the new POCCompass height indicator working and approved
committing this first refactor.

## Tweaks

[Tweaks](mods/Tweaks/README.md) is enabled alongside [SkipStartup](mods/SkipStartup/README.md) and
[AutoDucks](mods/AutoDucks/README.md) in the canonical
[manifest](mods/mods.txt). It combines compact coordinates, a missing-item table,
a compass, automatic/manual target selection and teleport/return for each local
player. WallHack is deferred. The shared-library refactor was confirmed working
in game by the user. Following the input, travel, stale-HUD and performance fixes,
the user reports Tweaks looking good and authorizes commits. This covers the tested
scenarios, not every possible native lifecycle or physics edge case.

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Coordinates | `Ctrl+F1` | `Ctrl+Shift+F1` |
| Missing-item table | `Ctrl+F2` | `Ctrl+Shift+F2` |
| Compass | `Ctrl+F3` | `Ctrl+Shift+F3` |
| Toggle type/distance vs distance sort | `Ctrl+F4` | `Ctrl+Shift+F4` |
| Teleport to selected target | `Ctrl+F5` | `Ctrl+Shift+F5` |
| Return | `Ctrl+F6` | `Ctrl+Shift+F6` |
| [AutoDucks](mods/AutoDucks/README.md): gather ducks on the pool map | `Ctrl+F7` | `Ctrl+Shift+F7` |
| Refresh shared catalogue | `Ctrl+F8` | `Ctrl+Shift+F8` |
| Next target, manual mode | `Ctrl+F10` | `Ctrl+Shift+F10` |
| Nearest target, automatic mode | `Ctrl+F12` | `Ctrl+Shift+F12` |

Player numbers match LocalPlayers indices and HUD labels: Player 1 is on the right
and Player 2 on the left in the observed setup. All displays start off. The table,
compass and TP share a selection per player; manual selection survives movement
and refresh, while next-target cycles through a stable order.

Targets include loaded missing Gears, narrative items and mini-games without a saved result. Narrative status uses
the active save; unavailable status remains Unknown. Loaded mini-games now show saved-result status: Recorded, No result or Unknown.
Only games with a known identifier and no saved result are targetable; this does
not infer victories or full completion. There is no catalogue of unloaded areas.
TP uses an initial approach offset without a ground/collision test; see the Tweaks
README for its placement policy and the in-game validation checklist.

## SkipStartup

[SkipStartup](mods/SkipStartup/README.md) automatically skips the Unreal/FMOD logo,
Firevolt logo and photosensitivity disclaimer at launch. It is enabled in
`mods/mods.txt`, requires no shortcut, and respects each screen's 0.5-second skip
cooldown. The normal transition to the menu and story/lobby cinematics are preserved.

The user confirmed all three skips and watcher shutdown in game on September 18,
2026. The subsequent reload fix remembers shutdown for the current game process:
`Ctrl+R` then starts no timer and performs no startup scan. Restart the game once
when upgrading from the initial version. This reload fix passes automated tests;
in-game confirmation remains pending. See the [technical notes](.docs/skip-startup.md)
for dump findings, lifecycle details and validation steps.

## Prototypes and shared libraries

The former modules and diagnostics use the `POC` prefix. They remain independent
regression/investigation tools and are disabled in the Tweaks profile.

| Module | Purpose |
| --- | --- |
| ModKit | Cleanup and loader diagnostics for the POC profile |
| POCCoordinates | Detailed split-screen coordinates overlay |
| POCCheckList | Loaded mini-games, Gears and missing narrative console report |
| POCCompass | Nearest loaded Gear direction, distance and height |
| POCTP | Fixed RiftX route and return, using F5/F6 with the player modifiers |
| POCWallHack | Experimental reversible Gear Custom Depth, visual result unvalidated |
| POCCoordinatesDiagnostics / POCCheckListDiagnostics / POCWallHackDiagnostics | Optional raw Unreal probes |

[Shared libraries](mods/shared/README.md) supply runtime access, collection scans,
selection, navigation, coordinates, teleport sessions, overlays and render-state
restoration. They are not manifest entries. POCs keep their existing global display
toggles; Tweaks adds independent player controls.

## Loading and reloading

`Ctrl+R` reloads UE4SS mods. Use a full reload after shared helper or manifest
changes. Tweaks owns cleanup, including removing old POC overlays and restoring
pending POCWallHack render changes; ModKit is not needed alongside Tweaks.

To return to the POC profile, disable Tweaks and enable ModKit plus the required
POCs in `mods/mods.txt`, then reload. Never enable both profiles together: their
shortcuts overlap. Enable only one diagnostics module at a time.

Reload clears all display preferences, selections and return points. Map changes
clear selections/returns and rebuild active displays on the new HUD. A successful
return consumes its point; failed movement preserves the previous return.

## Local development

```powershell
./scripts/setup-tools.ps1
./scripts/install-stylua.ps1
python -m venv tools/test-python-env
./tools/test-python-env/Scripts/python.exe -m pip install -r tests/requirements.txt
./scripts/test.ps1
```

StyLua **2.5.2** installs to `tools/stylua/stylua.exe`, with its archive SHA-256
verified. No administrator access or global PATH change is required. The source is
the [official StyLua release](https://github.com/JohnnyMorganz/StyLua/releases/tag/v2.5.2).

```powershell
./tools/stylua/stylua.exe --check mods tests  # Validate syntax and formatting
./tools/stylua/stylua.exe mods tests         # Apply formatting
```

`stylua.toml` defines the shared formatting rules. VS Code already recommends the
StyLua extension; the command-line installation is what `scripts/test.ps1` uses.
The test script runs manifest checks, StyLua and the [Lua regression tests](tests/README.md).
It fails when required validation tools are missing.

`setup-tools.ps1 -InstallUE4SS` is a first-install script, not an updater. Its local
bundle path still names `g35d1795d`; the supplied September 18 jmap was generated by
`f6d5f942`. Do not use the older bundle to replace the working runtime without checking
compatibility. See [.docs/README.md](.docs/README.md) for installation context.

## In-game regression checklist

Keep these checks for future changes. The functional feedback above does not imply
that every scenario below has been individually tested.

For Tweaks, use its [dedicated validation checklist](mods/Tweaks/README.md#validation-en-jeu).
The following checks apply to the optional POC profile.

1. Start a fresh local session. Show POCCoordinates and POCCompass together; hide each
   independently, then repeat in the opposite order on both screens.
2. Reload with `Ctrl+R` while both are visible. They should disappear, then toggle
   normally without duplicate or stuck text. Repeat after changing level.
3. Test POCTP and return for both screens. After a level change, old return points must
   be unavailable. Verify the RiftX approach position and vehicle behavior.
4. Run POCCheckList with a loaded save and during loading. Missing narrative entries
   should use only the active save; unavailable state should say `Unknown`.
5. Enable POCWallHack, move to load another Gear, disable it, then repeat across `Ctrl+R`.
   Use `POCWallHackDiagnostics` to compare original/restored depth and stencil values.
   This does not yet guarantee a visible through-wall effect.

## Repository policy

`UE4SS_Dumps/`, `UE4SS_SDK/`, `save/` and `tools/` remain local and ignored by Git.
A jmap provides reflected classes and defaults, not live actor property snapshots.
Use runtime diagnostics when inspecting current meshes, materials and render state.

Use Conventional Commits, with separate module-focused changes where practical.
The first refactor was approved for commit after the user's in-game checks.
