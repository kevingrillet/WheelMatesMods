# Coordinates

Live, read-only coordinate overlay for WheelMates.

`Ctrl+F1` toggles a compact four-line in-game overlay for every local split-screen player. It refreshes position, rotation, and velocity from that player's currently controlled Pawn.

The overlay is a lightweight UMG widget and changes no game state. Its font is scaled down so it remains readable without dominating the HUD.

Console investigation helpers were intentionally moved to the disabled-by-default `CoordinatesDiagnostics` module. See its README for the temporary NumPad shortcuts.
