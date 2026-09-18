# AutoDucks

See [duck and pool research](../../.docs/ducks-and-pool.md) for dump sources,
actor paths, coordinates and evidence limits.

`Ctrl+F7` gathers loaded rubber ducks around Player 1; `Ctrl+Shift+F7` uses
Player 2. A press moves both variants once, leaving the vehicles in place.
Enabled in the repository manifest; press `Ctrl+R` to load the new mod.

The September 18 duck actor dump contains seven variant-01 and eight variant-02
actors. Both derive from `BP_PhysicsResponsiveActor_Base_MagnetGrab_C`, whose
return function already uses actor teleportation. This is not a verified total
or achievement requirement.

Before scanning, AutoDucks checks the exact active world name:
`World /Game/Maps/LVL_Backyard_01.LVL_Backyard_01`, confirmed by the user's log.
The initial landmark/Outer-chain guard falsely rejected that map and was replaced.
Decorative pool presence and per-actor ownership are no longer prerequisites.

The pool counter is selected separately: one position match within 100 units of
`(-12457.658, 25431.457, -1085)`, or the only loaded count trigger with a diagnostic.
Missing or ambiguous counters stop the action. The user confirmed the corrected
mod works in game on September 18, 2026; the unique-candidate fallback was not
reported as a separately tested scenario.

Ducks listed in that trigger's `OverlappedActors` are preserved. Ducks held at
Targetable component index 0 are skipped; unreadable holder/mesh state is skipped.
Unreadable pool membership stops the action. All Unreal access occurs on the game
thread, with fresh actors on every press and no retained UObject references.

The ring has a minimum radius of 300 units, minimum neighbour spacing of 200 units
and height offset of 100 units. Physics velocities are cleared after successful
teleports. Placement has no ground or obstacle sweep: use an open, flat area.
Failures and physics warnings are reported in the `[AutoDucks]` console summary.
The mod does not spawn ducks, call achievement APIs, or edit save files.

The user confirmed on September 18, 2026 that the mod works perfectly after the
Backyard map-guard correction. This confirms the observed gameplay use, not an
exhaustive matrix of both players, held/delivered exclusions, other maps, travel,
reload and network play. Keep those scenarios as regression checks. The trigger's
link to achievement progression and network-client authority remain unverified.
Automated tests use mocked UE4SS.
