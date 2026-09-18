# Regression tests

These tests execute the real Lua mod entry points with Lua 5.4 (Lupa) and a small
UE4SS model. They cover failed teleports, cross-world return invalidation, both
overlays sharing a single-child HUD slot, reload cleanup, HUD reconstruction,
active-save selection, POCCompass scan frequency and POCWallHack state restoration.
They also cover loaded Gears with unsuitable render/world metadata and narrative
items/mini-games whose reported world differs from the helper's selected world.
POCCompass tests cover UP/DOWN per player, both LEVEL tolerance boundaries and 3D distance.

They do not validate Unreal rendering, native binding availability, garbage
collection or multiplayer authority. Use the in-game checklist in the root README.

The shared-API tests also exercise mixed-type nearest targets, invalidated actors,
independent teleport sessions, failed returns and explicit reset.

## Local setup (Windows)

```powershell
python -m venv tools/test-python-env
./tools/test-python-env/Scripts/python.exe -m pip install -r tests/requirements.txt
./scripts/test.ps1
```

The environment stays inside the ignored `tools/` directory. The test script also
requires StyLua, installed with `./scripts/install-stylua.ps1`.

To run only the behavior tests:

```powershell
./tools/test-python-env/Scripts/python.exe tests/run.py
```
