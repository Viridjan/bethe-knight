# Review: Codex's commits 2026-11-04 → 11-06 (2026-11-07)

Reviewed the 10 Codex commits after `d5d1b5f` up to `c042f5a` (64 code/data files, +4.2k lines): Ape follow-ups
and triggers, save rollback, stress, traps and trigger router, patrols, punch, room resize, world selection.
Method: full suite with linters on `c042f5a` + the stamina change (`sh tools/verify.sh` → 0 failing, gdlint and
pyflakes clean), then read the new runtime modules (`scripts/progression/stress.gd`,
`scripts/interaction/trap_cycle.gd`, `trigger_router.gd`, `trigger_settings.gd`, `scripts/motion/patrol_runtime.gd`)
and the `game.gd` / `world.gd` diffs. Codex's uncommitted, in-progress work (story progress, sea crossing, UI) was
not reviewed. **Headline: 0 blocking, 0 major, 2 minor, 1 question.** The code is careful: every loop is bounded
(64 trap iterations, 512 pending commands, 1024 patrol steps), trigger links are validated against existing targets
and supported actions before a room loads, and saves go through the crash-safe writer with failed writes changing
nothing.

## Findings

1. **[QUESTION] Stress can be farmed by killing respawned monsters.** `World.killed_enemy` removes 50 stress per kill
   (`scripts/world.gd` ~854) and enemies come back whenever the room is rebuilt, so leaving and re-entering a room
   (or dying: +20, then the kill: -50) lowers stress without limit. `docs/BE_THE_KNIGHT_DESIGN.md:94` says respawned
   monsters may count, so this is by design. Options: keep it; count each placed enemy once per visit; or a
   cooldown per enemy.
2. **[MINOR] The HUD writes "/250" as a literal** (`world.gd` stress HUD) instead of `Stress.MAX_STRESS`; changing
   the bar count or capacity would leave it wrong.
3. **[MINOR] Rest relief trusts the system clock** (`Game.claim_stress_rest`, unix time): moving the clock forward
   12 hours gives -100 stress at the next Continue. Harmless for a single-player game; worth knowing.

## Fix prompt

```text
Small follow-ups to the stress system. Read AGENTS.md and docs/reviews/codex-2026-11-07/REVIEW.md. Stay inside this
repository; keep gameplay identical; leave finding 1 to the designer.
1. scripts/world.gd stress HUD: build "%d/%d" from Adventure.Stress.MAX_STRESS instead of the literal 250. Test:
   the HUD text uses MAX_STRESS.
2. Optional: document in docs/BE_THE_KNIGHT_DESIGN.md that rest relief uses the system clock.
Verification: sh tools/verify.sh → 0 failing. One dated line in gdd.txt.
```

## Suggestions for the future

- Commit finished slices before starting the next one: right now 13 files of in-progress work sit uncommitted in the
  shared checkout, which makes concurrent edits (Claude and Codex) risky.
