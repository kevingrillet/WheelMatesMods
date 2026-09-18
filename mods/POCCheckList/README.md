# POCCheckList

Proof of concept retained for independent validation before [Tweaks](../Tweaks/README.md).

This module is the player-facing compact checklist.

It matches loaded narrative collectibles with the player's saved collection state and prints only missing items with their world positions. It also lists loaded mini-game entry points and loaded Gears; collected Gears are no longer loaded by the level.

## Save selection

Narrative progress comes from `VehicleSaveGameSubsystem.CurrentSaveGame` belonging
to the current GameInstance. Other loaded saves are ignored. If the active save
cannot be read, narrative status is `Unknown`, not a fabricated missing-item list.
Narrative actors, mini-game owners and Gears use valid loaded objects without a
per-actor world-identity filter, which rejected live entries in the first refactor.
The active-save comparison still excludes collected narrative items.
This remains a loaded-item report, not a complete catalogue of all collectibles.
The user confirmed the restored narrative/mini-game report on September 18, 2026.

## Current command

Press `Ctrl + F2` for the compact checklist probe. It reports loaded mini-games and only narrative collectibles that are absent from the saved collection, including their tags and world positions. This is the diagnostic used to map a missing saved item to a world position.

Exploration and reverse-engineering helpers are intentionally isolated in the disabled-by-default `POCCheckListDiagnostics` module. Its NumPad shortcuts are documented in that module's README.

## Expected test result

The report includes loaded mini-game entry points, valid loaded Gears and missing
loaded narrative items (including Memory Cards). Narrative totals count loaded and
missing items; already collected narrative items are omitted. Mini-games have
`Loaded` status, not a completion result. Missing save data produces `Unknown`.

For future regressions, capture the `[POCCheckList]` block before and after collecting
a known item in the same area.
