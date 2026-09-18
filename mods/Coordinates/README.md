# Coordinates

`Ctrl+F1` toggles position, rotation and velocity for each local split-screen player,
updated every 150 ms. Coordinates and Compass share a vertical HUD container and
can be toggled independently.

Reload removes previous widgets and starts the overlay off. An enabled overlay
rebuilds when the HUD is recreated. Layouts are matched by their owning controller;
layouts without a ready local owner are retried. No gameplay or save state is changed.

The user reported the refactor looks good on September 18, 2026. The root README
keeps the lifecycle regression checklist for future changes. Read-only investigation
helpers remain in the disabled-by-default `CoordinatesDiagnostics` module.
