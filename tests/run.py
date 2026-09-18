"""Execute the actual mod entry points against an isolated, minimal UE4SS model."""
from pathlib import Path
import os
import sys

try:
    from lupa.lua54 import LuaRuntime
except ImportError:
    sys.exit("Missing lupa. See tests/README.md to install the isolated test runtime.")

root = Path(__file__).resolve().parents[1]
os.chdir(root)
for path in sorted((root / "tests").glob("test_*.lua")):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((root / "tests/harness.lua").read_text(encoding="utf-8"))
    try:
        lua.execute(path.read_text(encoding="utf-8"))
    except Exception as error:
        sys.exit(f"FAIL {path.name}: {error}")
    print(f"PASS {path.name}")
