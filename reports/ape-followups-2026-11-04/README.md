# Ape follow-up implementation

Scope: the five tasks in `docs/reviews/ape-composition/CODEX_PROMPT.md`.

1. **Effect listing:** derives phase-specific effects from the runtime profile;
   shipped CSV bindings contain selection rows only. Legacy triggered rows remain
   readable and are migrated out on save. Four initial UI assertions failed before
   the fix; migration had its own observed failing assertion. Follow-up, catalogue,
   and composition scenes pass. Full verification: `task1-verify.txt` (`0 failing`).
   Both phase pages were rendered and inspected: `normal.png`, `enraged.png`.

2. **Configurable test fixtures:** physics checks use a controlled five-HP profile
   and compare damage against the actor's starting health. Composition assertions
   isolate phase/hop settings and restore the original runtime profile afterward.
   Before the fix, valid changed HP and changed hop-count cases each failed one
   assertion. Both now pass. The main verification script includes composition,
   varied-profile, and follow-up scenes: `task2-verify.txt` (`0 failing`).

3. **Effect tooltips:** card and section help comes from the same profile graph,
   including current source names and events. Six assertions covered graph edits,
   phase-specific projectiles, source renaming, and live help refresh; all pass
   after observed failures. Catalogue/follow-up checks and gdlint pass. Actual
   wrapped hover help was inspected in `normal-tooltip.png` and `enraged-tooltip.png`.

Tasks 4–5 remain in progress. No authored room files are modified.
