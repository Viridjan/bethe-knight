# Consistency check: docs vs code, and ideas not yet applied (2026-11-07)

Sources: tracked Markdown files, code constants, graphify graph (docs + Python tools only; GDScript isn't indexed),
LightRAG (only 6 of 50 docs indexed when checked, so not used). Complements `docs/DOCUMENT_CONFLICTS.md`, which
records today's designer decisions.

## Docs that contradict the code
1. `docs/STORY_DESIGN.md` (stamina section): "base of 32, each block adds 20, regen 2/s empty, 6/s at half" and
   "1 block = 100 stamina in code". Code: base 27, +17 per block, regen 4/8/3 (`scripts/adventure.gd`).
2. `Stress.kraken_requirements` (`scripts/progression/stress.gd`): the old full-energy / max-stress / underwater Kraken
   gate was dropped (DOCUMENT_CONFLICTS), but the function remains; only `tests/stress.gd` uses it (dead code).
3. Whole-numbers rule (AGENTS.md) vs code: stamina, stress (`MAX_PENALTY := 0.30`) and heat (`2.0`) are still floats;
   tracked by the approved plan `docs/plans/WHOLE_NUMBERS_TICK.md` (not started).

## Ideas decided or suggested but not tracked in TODO.md / DEFERRED_WORK.md / IMPLEMENTATION_STATUS.md
- Calibrated enemy placement per region by danger budget, replacing the random library monsters
  (`docs/reviews/monsters/CODEX_PROMPT.md` task 7): 43 random library monsters are still placed in the story world.
- Stress HUD writes "/250" as a literal (review codex-2026-11-07); rest relief trusts the system clock;
  stress farming on respawned monsters (by design per BE_THE_KNIGHT_DESIGN.md:94; the designer may want a limit).
- Ape: phase two hops only once on entry, thrown logs leave floor spikes, stones became logs
  (docs/reviews/ape-composition, three designer questions): no recorded answer.
- Monster Editor suggestions: test-fight button, trajectory preview, "used by" line per attack, per-variant
  overrides, splitting the 1,000-line editor file.
- Tooling: graphify can't index GDScript; Claude Context (needs Milvus running) is the planned code index.
