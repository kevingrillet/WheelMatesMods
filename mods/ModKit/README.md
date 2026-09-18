# ModKit

Loader diagnostic and reload recovery module. Keep it enabled in `mods/mods.txt`.
It removes Coordinates/Compass widgets left by previous Lua states and restores
WallHack's saved render settings, even if those modules were disabled in the new
manifest. It never writes game saves.

Shared render state contains scalar paths, addresses and original values rather
than transient UObject references. Invalid or replaced components are skipped.
