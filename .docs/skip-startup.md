# SkipStartup

## Scope and status

SkipStartup is an independent UE4SS Lua mod, enabled in the canonical
[manifest](../mods/mods.txt). It skips the three launch screens and preserves the
normal menu transition. It does not use or modify the story/lobby cutscene system.

On September 18, 2026, the user confirmed the mod working and supplied this sequence:

```text
17:37:00.497  Skipped W_Splash_Unreal_C
17:37:01.016  Skipped W_Splash_Firevolt_C
17:37:01.535  Skipped W_PhotosensitivityDisclaimer_C
17:37:01.840  Startup UI closed; watcher stopped.
```

The user also confirmed the Ctrl+R fix working in game on September 18, 2026.
Automated regression tests pass. This confirmation does not imply that every
error, timeout or mid-intro reload scenario was exercised.

## Evidence from the dump

Source: the local, Git-ignored
`UE4SS_Dumps/CarGame-5.7.4-0+UE5-f6d5f942.jmap`, generated September 18, 2026.

| Object | Relevant evidence |
| --- | --- |
| `/Game/UI/W_StartupPlayer.W_StartupPlayer_C` | Holds `StartupWidgets`, `CurentIndex`, `ActiveStartup` and `FrontEndExperienceReference` |
| `W_StartupPlayer` default object | Screens ordered Unreal, Firevolt, photosensitivity; destination `B_FrontEndExperience` |
| `/Game/UI/W_SkipableStartup.W_SkipableStartup_C` | Common parent with `Skip()`, `bCanSkip`, `SkipCooldownSeconds` and `Finished` |
| Startup screen defaults | Skip cooldown is 0.5 seconds |
| `W_StartupPlayer:StartupWidgetFinished` and its ubergraph | Existing completion/advance path, fade, experience readiness and level opening |
| `/Script/CarGame.CarGameCheatManager:SkipIntroCutscene` | Separate gameplay intro mechanism; not used by this mod |

The inspected `Skip()` bytecode checks `bCanSkip`, resets it to false and broadcasts
`Finished`. The mod calls this existing path rather than removing the UI or forcing
level travel. The dump describes reflected definitions/defaults and includes
Blueprint bytecode; it does not establish live widget state or validate runtime timing.

## Implementation and reload lifecycle

[Entry point](../mods/SkipStartup/Scripts/main.lua):

1. Read the process-session state through `ModRef:GetSharedVariable`.
2. If already stopped, log once and return before creating a timer or querying widgets.
3. Otherwise, poll every 100 ms with `LoopInGameThreadWithDelay`.
4. Consider only valid, activated `W_StartupPlayer_C` instances. Read `ActiveStartup`
   and allow only the three known launch-screen classes.
5. Wait for `bCanSkip`, mark the instance processed, then call `Skip()`. Store only
   scalar identities across ticks; the call may synchronously replace the widget.
6. Cancel the timer when the observed startup UI deactivates/disappears, the original
   120-second deadline expires, or a Lua error occurs.

The initial implementation restarted a watcher for up to 120 seconds on each Ctrl+R.
The fix stores these shared scalars for the current game process:

| Key | Purpose |
| --- | --- |
| `WheelMatesMods.SkipStartup.State.v1` | `stopped` prevents any new watcher after completion, timeout or error |
| `WheelMatesMods.SkipStartup.Deadline.v1` | Preserves the original deadline if reloaded while still watching |

A full game restart resets the session state and enables launch skipping again.
When upgrading from the initial version, restart once: the old version did not
record completion. Disabling/re-enabling the mod during the same process does not
clear an already recorded stop state.

## Validation

[Automated tests](../tests/test_skip_startup.lua) cover delayed object availability,
per-screen cooldowns, synchronous replacement, one call per processed instance,
exclusion of unrelated classes, shutdown on deactivation/error/timeout, repeated
reloads without timer creation or scans, deadline preservation, and a fresh process.
These mocks do not execute the actual Unreal Blueprint or CommonUI lifecycle.

Regression checklist for future changes (launch skipping and the reload fix are
confirmed by the user; the additional lifecycle cases are not individually certified):

1. Restart the game and confirm the three skips followed by watcher shutdown.
2. Press Ctrl+R in the menu, then again during gameplay. Expect one message per reload:
   `Already finished this game session; no watcher started.` No new `Enabled` or
   delayed `Startup watch expired` message should follow from this mod.
3. Close and relaunch the game; automatic skipping should work again.
4. As an additional lifecycle check, reload while a launch screen is still active;
   verify the menu remains reachable and no errors occur.

To disable: set `SkipStartup : 0` in the manifest and reload/restart. No game assets
or saves are modified. See the [module README](../mods/SkipStartup/README.md) for usage.
