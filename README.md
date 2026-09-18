# WheelMatesMods

Personal WheelMates mod workshop using UE4SS and Unreal Engine 5.7.

The pre-refactor modules are recorded in Conventional Commits. On September 18,
2026, the user confirmed POCCompass/POCTP and then POCCheckList working again after the
loaded-actor filter fixes, and reported that the refactor looks good. This is
functional feedback, not an exhaustive validation of every lifecycle edge case.
The user also confirmed the new POCCompass height indicator working and approved
committing this first refactor.

## Preparing Tweaks

The previous modules and their diagnostics now use the `POC` prefix. Their presentation remains unchanged for validation against the extracted
[shared libraries](mods/shared/README.md). Restart the game once after the folder
rename; subsequent shared-code changes require a full UE4SS reload.

[Tweaks](mods/Tweaks/README.md) documents the planned combined module, compact HUD,
missing-item table, automatic/manual targeting, refresh and TP/return. Its runtime
is deliberately not implemented until the POCs are verified in game. WallHack is
reserved for a later Tweaks version. The manifest retains the POC test profile.

## Modules

| Module | Status | Controls |
| --- | --- | --- |
| ModKit | Loader diagnostics and reload cleanup | Automatic |
| POCCoordinates | Functional split-screen overlay; shared container and reload cleanup | `Ctrl+F1` |
| POCCheckList | Functional loaded-item console report; active-save filtering | `Ctrl+F2` |
| POCCompass | Functional Gear direction HUD with UP/DOWN/LEVEL height indication | `Ctrl+F3` |
| POCTP | Functional fixed RiftX route and return for both screens | See below |
| POCWallHack | **WIP**: reversible Gear Custom Depth; through-wall visual result unvalidated | `Ctrl+F4` |
| [Tweaks](mods/Tweaks/README.md) | Design and shared foundations prepared; awaiting POC validation | None |

`POCCoordinatesDiagnostics`, `POCCheckListDiagnostics` and `POCWallHackDiagnostics` are
optional investigation modules, disabled in the current manifest.

POCCheckList, POCCompass and POCTP use valid loaded actor candidates. They do not reject
them by render visibility or per-actor world identity: those extra filters removed
real targets in this game. POCCheckList subtracts collected narrative tags using the
active save; it lists mini-games as loaded, without claiming completion status.
These modules do not yet provide a complete catalogue across unloaded areas.
POCCompass now also shows the signed height difference to the Gear for each player,
with `UP`/`DOWN` outside a +/-2 m `LEVEL` band. Its distance remains three-dimensional.
The user confirmed this height-line addition working in game on September 18, 2026.

### Teleport controls

| Shortcut | Action |
| --- | --- |
| `Ctrl+F5` | Player 1 (LocalPlayers index 1): RiftX Gear approach point |
| `Ctrl+Shift+F5` | Player 2 (LocalPlayers index 2): RiftX Gear approach point |
| `Ctrl+F6` | Return Player 1 |
| `Ctrl+Shift+F6` | Return Player 2 |

Player numbers match LocalPlayers indices and HUD labels. In the observed setup,
Player 1 is on the right and Player 2 on the left. Use the same function key for
both players: Ctrl for Player 1, Ctrl+Shift for Player 2.
POCTP stores a return point only after a successful move. A successful return consumes
that point. Travel and mod reload invalidate return points. The fixed route still
requires its Gear to be loaded and does not perform a collision sweep.

## Loading and reloading

[`mods/mods.txt`](mods/mods.txt) is the canonical load manifest; preserve its order.
Keep ModKit enabled: it cleans up this workshop's previous overlays and restores
saved POCWallHack render settings on reload, including when those modules are disabled.
The helpers under `mods/shared/` are libraries, not manifest entries.

`Ctrl+R` in UE4SS reloads the mods. POCCoordinates, POCCompass and POCWallHack restart **off**;
use their shortcuts to enable them again. POCCoordinates and POCCompass share a vertical
container inside the HUD's single-child `OverlayContent` slot, so both can be shown.
Active overlays recover when a new HUD becomes available after travel.

The runtime can also auto-reload edited scripts. Shared helper changes should be
followed by a full `Ctrl+R` so every module loads the same helper version.

For the first test after upgrading the old POCWallHack prototype, restart the game:
that older code did not retain its original render values across reloads.
Legacy coordinate/compass text is cleaned up by the new loader when identifiable.

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
