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

4. **Blocked split children:** validate each proposed child position against real
   terrain and the effect lifetime bounds. A blocked child emits one cancellation
   event; the Ape consumes it as a visible burst, without a floor spike. Fully
   free, one-sided blocked, and fully blocked cases pass, along with actual burst
   feedback. Seven initial assertions failed before the fix. Composition, physics,
   smoke, and gdlint checks pass; `split-blocked.png` records a disposable game fixture.

5. **First-save rollback:** records prior existence and successful replacements,
   restores existing files exactly, removes newly created finals, and cleans staged
   temporary files on failure. Stale backups are preserved without being mistaken
   for prior live files; recovery failures cannot be labelled successful rollback.
   Nine failure assertions were observed before the fix. Fresh/existing/stale-backup
   failure cases, later-stage failure cleanup, and successful first saves now pass.

All five tasks are complete in separate commits. Final `sh tools/verify.sh` output
is recorded in `final-verify.txt`: **0 failing**, including all follow-up regression
scenes, physics, smoke, the catalogue, Python tests, gdlint, and pyflakes. The suite
reports shutdown resource warnings in the discoveries and follow-up fixtures;
verbose follow-up inspection identifies audio stream/playback resources, with no
runtime/script errors. The blocked-spawn and both phase hover captures were inspected.

No authored room files are modified. This completes this five-task prompt; other
items in the broader recursive audit remain tracked there. Catalogue crash recovery
on load is separate from the synchronous failed-save rollback fixed here.
