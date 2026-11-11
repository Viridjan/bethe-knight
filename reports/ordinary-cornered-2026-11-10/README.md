# Ordinary-enemy cornered coverage — 2026-11-10

Point 6 of the [delivery queue](../../docs/plans/REMAINING_WORK.md).

Hornback families and grounded library monsters can now select **Charge** as their cornered-coverage reference and use **Player cornered** on attack bindings. Both the fixed-family `atk_ready()` path and the library selector receive the condition. Existing bindings/profiles retain their defaults; this delivery does not retune story encounters or add a new enemy/upgrade.

## Actual coverage

The forecast replays the existing floor movement controller in disposable state with the actor's real body size, speed/assist scale, maximum charge distance and fractional movement remainder. It uses the same solid, support and acid/spike safety checks as actual walking. Walls, ledges and hazards stop its swept body. It neither moves the live enemy nor invokes contact damage.

The search envelope spans both possible charge directions and accounts for the final physics-frame distance; it is candidate discovery only. The hit predicate uses the actual one-direction, obstacle-clipped swept rectangle. Every clear standing position must overlap that sweep through the existing shared corridor detector. No broad travel box is substituted for flying, leaping or projectile damage.

The actor must be supported on solid ground, the player grounded, floors compatible, and the corridor wall beyond the player. Coverage can be disabled. Moving trajectories without an accurate adapter stay unsupported. Grounded library instances must actually possess charge; hover instances cannot claim floor-charge coverage. Excessive or too-slow forecasts return unsupported within a fixed work budget.

This predicts coverage against the current world, facing and movement settings. It is a standing-corridor condition, not proof that every timed jump/dash escape is impossible or that future moving obstacles remain fixed throughout wind-up.

## Editor / persistence

The ordinary pages expose a coverage selector and Normal rules / Player cornered trigger controls. The existing Ape options are retained. Family profile validation rejects unsupported coverage IDs; binding validation exposes only the implemented condition choices for each family. Missing family profiles are created on edit, and editing health before coverage preserves both fields. Real catalogue save/reload retains health, coverage and the reaction binding.

[Hornback editor](enemy_hornback-editor.png) and [library editor](enemy_monster-editor.png) were captured from the real menu and visually inspected: controls fit their rows, labels remain legible, and existing attack layout is retained. [Capture source](capture.gd) uses a disposable in-memory catalogue and does not save authored values.

## Verification

[Initial regression](red.txt) failed because ordinary conditions/profiles/adapters were unsupported. The [editor regression](ui-red.txt) exposed the newly created-profile reference issue before its fix; its intermediate open-corridor fixture also needed its terrain supplied before World construction rather than mutating a different source copy.

[Targeted checks](targeted.txt) cover covered/open corridors, both wall sides, airborne players, short actual reach, ledges/spikes, prediction immutability, live AI selection in both enemy paths, unsupported hovering, real-runner sweep parity with fractional remainder, explicit disable, profile editing and actual catalogue save/reload.

**Full verifier: 0 failing, exit 0** — 44 Godot invocations, Python unittest discovery, GDScript lint, Pyflakes and diff checks. See [output](verification.txt) and [exit status](verification-exit.txt). The shared corridor and Ape regression suites passed alongside the new ordinary suite. Shutdown resource warnings from editor-backed tests/captures are retained, not claimed fixed. No new full chapter playthrough was performed.

Remaining trajectory adapters belong with the corresponding shared attack runners: flying charges, leaps and projectiles remain unsupported for cornered coverage. The Ape circular-scream adapter is unchanged.
