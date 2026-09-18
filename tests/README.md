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

Tweaks tests additionally cover shared scan cadence, independent player inputs/HUDs,
automatic and manual targets, wraparound, refresh/collection, sort orders, approach
positions, hidden-HUD teleporting, travel invalidation and profile cleanup.

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

The latest lifecycle/performance regressions simulate two consecutive map changes
with poisoned old wrappers, verify no full Actor scans during automatic updates,
no collectible scans for coordinates-only/hidden HUDs, and no target position reads
between refreshes. Mini-game tests distinguish saved results, missing results and
unknown/missing identifiers. These are operation-count and lifecycle tests, not
native frame-time measurements or proof that an access violation cannot recur.

The surviving-HUD regression retains the same native widget tree across travel,
injects a stale owned block, and verifies reuse/removal without reconstructing a
live named widget. It also checks that pre-LoadMap suspends native world reads and
that transient catalogue text stays hidden during post-travel/teleport refresh.
