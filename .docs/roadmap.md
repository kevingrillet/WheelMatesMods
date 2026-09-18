# Roadmap

Current state after the September 18, 2026 user checks. The refactor was reported
working after the loaded-actor filter regressions were corrected. This does not
claim every lifecycle, collision or multiplayer scenario has been exercised.

| Module | Current implementation | Remaining work |
| --- | --- | --- |
| ModKit | Loader logs, owned-overlay cleanup and saved POCWallHack state recovery | Maintain runtime/build compatibility notes |
| POCCoordinates | Live per-player UMG position, rotation and velocity; shared HUD container | Retain lifecycle regression checks |
| POCCheckList | Console report of loaded mini-games, Gears and missing narrative items using the active save | Full persistent catalogue, additional categories, completion status and UI |
| POCCompass | Per-player direction, 3D distance and UP/DOWN/LEVEL height to the nearest loaded Gear; cached scan | Target selection and other collectible types |
| POCTP | Fixed RiftX approach route and return for both local screens | Destination UI/catalogue; collision, respawn and network-authority validation |
| POCWallHack | WIP Custom Depth/stencil toggle with reload restoration and streamed-Gear refresh | Validate actual through-wall rendering and expand categories |
| [Tweaks](../mods/Tweaks/README.md) | Design documented; shared foundations extracted into POCs | In-game POC validation, then compact overlays, missing-item table, targeting and TP/return; WallHack later |

POCCompass height uses the target's Z minus the player's Z in metres. The LEVEL band
is +/-2 m; horizontal direction and 3D distance retain their previous meaning.
The user confirmed the height addition working in game and approved the first
refactor for commit. POCWallHack remains WIP independently of that validation.
