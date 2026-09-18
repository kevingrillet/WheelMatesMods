# Roadmap

Current state after the September 18, 2026 user checks and initial Tweaks implementation.
The user confirmed the shared POC refactor, then reported Tweaks looking good after
the input, travel, stale-HUD and scan optimizations and authorized commits. The refactor was reported
working after the loaded-actor filter regressions were corrected. This does not
claim every lifecycle, collision or multiplayer scenario has been exercised.

| Module | Current implementation | Remaining work |
| --- | --- | --- |
| [AutoDucks](ducks-and-pool.md) | Both duck variants gathered around P1/P2 with F7; exact Backyard world guard, pool membership and holder exclusions; automated tests pass | Validate native TP, map guard, preservation of deposited ducks and achievement progression |
| ModKit | Loader logs, owned-overlay cleanup and saved POCWallHack state recovery | Maintain runtime/build compatibility notes |
| POCCoordinates | Live per-player UMG position, rotation and velocity; shared HUD container | Retain lifecycle regression checks |
| POCCheckList | Console report of loaded mini-games, Gears and missing narrative items using the active save | Full persistent catalogue, additional categories, completion status and UI |
| POCCompass | Per-player direction, 3D distance and UP/DOWN/LEVEL height to the nearest loaded Gear; cached scan | Target selection and other collectible types |
| POCTP | Fixed RiftX approach route and return for both local screens | Destination UI/catalogue; collision, respawn and network-authority validation |
| POCWallHack | WIP Custom Depth/stencil toggle with reload restoration and streamed-Gear refresh | Validate actual through-wall rendering and expand categories |
| [Tweaks](../mods/Tweaks/README.md) | Compact per-player HUD, missing table, auto/manual targets, TP/return and lifecycle cleanup | Retain travel/HUD regression checks and native placement checks; WallHack later |
| [SkipStartup](skip-startup.md) | Automatic launch-screen skip and Ctrl+R fix confirmed in game; automated regression checks pass | Retain lifecycle regression checks, including mid-intro reload and timeout/error paths |

POCCompass height uses the target's Z minus the player's Z in metres. The LEVEL band
is +/-2 m; horizontal direction and 3D distance retain their previous meaning.
The user confirmed the height addition working in game and approved the first
refactor for commit. POCWallHack remains WIP independently of that validation.
