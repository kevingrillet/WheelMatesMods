# SkipStartup

Automatically skips the Unreal/FMOD logo, Firevolt logo and photosensitivity
disclaimer through each widget's existing `Skip()` function. Enabled in
`mods/mods.txt`; restart the game to test the launch sequence.

The mod respects the game's `bCanSkip` gate (0.5-second default
cooldown per screen). It polls the visible `W_StartupPlayer_C` every 100 ms on
the game thread, calls each supported active widget once, and leaves the normal
fade/loading/menu transition intact. It does not skip the story/lobby intro.

The watcher cancels itself after the startup UI disappears, after 120 seconds,
or on a Lua error. It retains only widget identities, not UObject references.
Completion, timeout and errors are remembered in UE4SS shared variables for the
current game process. After shutdown, Ctrl+R creates no timer and performs no
startup scan. Reloading while the watcher is still running preserves its original
120-second deadline. A full game restart resets this state and enables skipping.
When upgrading from the first version, restart the game once so the new version
can record completion.
Set `SkipStartup : 0` in the manifest to disable it, then reload/restart.

Based on the September 18, 2026 jmap. The user confirmed all three screens skip
and the watcher stops on September 18, 2026. The user subsequently confirmed the
Ctrl+R fix working in game; automated regression tests also pass. Keep the following
checks for future changes, without treating every lifecycle case as validated:

1. Cold launch: all three screens advance automatically and the menu opens.
2. Verify menu keyboard/controller focus and normal game/session loading.
3. Check `[SkipStartup]` log lines: one skip per screen, then watcher stopped.
4. Reload during a launch screen and during gameplay; check for duplicate skips
   or errors. Story cinematics must remain unaffected.

The mocked regression checks exercise lifecycle and error handling, not Unreal
widget attachment or Blueprint execution.

See [technical notes](../../.docs/skip-startup.md) for dump evidence and the reload lifecycle.
