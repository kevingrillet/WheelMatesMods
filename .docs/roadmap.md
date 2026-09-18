# Roadmap

Current state after the September 18, 2026 user checks. The refactor was reported
working after the loaded-actor filter regressions were corrected. This does not
claim every lifecycle, collision or multiplayer scenario has been exercised.

| Module | Current implementation | Remaining work |
| --- | --- | --- |
| ModKit | Loader logs, owned-overlay cleanup and saved WallHack state recovery | Maintain runtime/build compatibility notes |
| Coordinates | Live per-player UMG position, rotation and velocity; shared HUD container | Retain lifecycle regression checks |
| CheckList | Console report of loaded mini-games, Gears and missing narrative items using the active save | Full persistent catalogue, additional categories, completion status and UI |
| Compass | Per-player direction, 3D distance and UP/DOWN/LEVEL height to the nearest loaded Gear; cached scan | Target selection and other collectible types |
| TP | Fixed RiftX approach route and return for both local screens | Destination UI/catalogue; collision, respawn and network-authority validation |
| WallHack | WIP Custom Depth/stencil toggle with reload restoration and streamed-Gear refresh | Validate actual through-wall rendering and expand categories |
| Tweaks | Not started | Unified configuration window after component stabilization |

Compass height uses the target's Z minus the player's Z in metres. The LEVEL band
is +/-2 m; horizontal direction and 3D distance retain their previous meaning.
The user confirmed the height addition working in game and approved the first
refactor for commit. WallHack remains WIP independently of that validation.
