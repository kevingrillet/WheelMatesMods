# CheckList

This module is the player-facing compact checklist.

It matches loaded narrative collectibles with the player's saved collection state and prints only missing items with their world positions. It also lists loaded mini-game entry points and loaded Gears; collected Gears are no longer loaded by the level.

## Current command

Press `Ctrl + F2` for the compact checklist probe. It reports loaded mini-games and only narrative collectibles that are absent from the saved collection, including their tags and world positions. This is the diagnostic used to map a missing saved item to a world position.

Exploration and reverse-engineering helpers are intentionally isolated in the disabled-by-default `CheckListDiagnostics` module. Its NumPad shortcuts are documented in that module's README.

## Expected test result

Paste the block beginning with `[CheckList]` from the console after testing in a level containing collectibles. A report immediately after picking up one known item is also useful.
