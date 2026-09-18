# Roadmap

| Milestone | Goal | Exit criterion |
| --- | --- | --- |
| ModKit | UE4SS, logs, mod sources, reproducible deployment | log contains `[ModKit]` |
| Coordinates | live local-player position, rotation, and velocity | compact UMG overlay is visible and updates for each local viewport |
| CheckList | window for collected / missing collectibles | known save source, IDs, and categories |
| TP | destination UI and local Pawn teleport | collision, respawn, and authority verified offline; initial RiftX Gear route ready for test |
| Compass | arrow to a coordinate / collectible | console bearing for the RiftX Gear ready for validation; HUD arrow follows a validated render hook |
| WallHack | categorized collectible highlighting through walls | non-destructive actor/render approach validated |
| Tweaks | single window combining all features | every component stable and configurable |

This is a technical order: CheckList, Compass, and WallHack need the identifiers that ModKit must observe first.
