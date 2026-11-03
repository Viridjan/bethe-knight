# Review: whole codebase sweep (2026-11-03)

Swept every script recursively: 16k lines of GDScript (`scripts/`, `tools/`) and 5.6k of Python. Method:
gdtoolkit `gdlint` (correctness rules only, style off) and `gdradon` (complexity) on all `.gd`; `pyflakes` on all
`.py`; greps for risky patterns (in-place file writes, unchecked loads, awaits, per-frame scans, signal connects);
`tests/bench.tscn` for performance; headless probes for each suspicion. Full suite green before the sweep
(`sh tools/verify.sh` → 0 failing). Skills: code-review, systematic-debugging, verification-before-completion,
godot-best-practices, save-systems, performance-optimization, ponytail-audit (fallback). The Ape slice is covered
separately in `docs/reviews/ape-composition/REVIEW.md`. **Headline: 1 blocking, 1 major, 4 minor; performance OK.**

## Findings

1. **[BLOCKING] A save cut short wipes all progress on the next save.** `Game.save_adventure()` (and
   `submit_record`, `save_settings`) do `cf.load(save_path)` without checking the result, then `cf.save(save_path)`
   in place (`scripts/game.gd` ~454-457). If the file was left half-written (crash, power loss, full disk), the load
   fails silently, the ConfigFile is empty, and the next save writes only the current run. Probe: a save truncated
   to half, then one `save_adventure()` → `levels_kept=false other_run_kept=false keys=["adventure"]`: every level
   record and the other worlds' runs are gone.
2. **[MAJOR] World Editor files are written in place, unchecked.** `Adventure.save_world` (`scripts/adventure.gd:108`)
   and `Game.save_level` (`scripts/game.gd:312`) open the real file for writing and ignore `store_string`'s result;
   `save_level` returns the filename even when the write failed. A crash mid-save truncates `worlds/story/*.json`,
   your hand-made rooms (git can recover them, but only if committed).
3. **[MINOR] Respawning into another room builds it twice.** `World.respawn()` calls `enter_room(spawn_room, spawn)`
   (which builds the room) and then `_build()` again (`scripts/world.gd` ~956-960). About 1-2 ms wasted per such
   respawn; harmless otherwise.
4. **[MINOR] Dead code in `tools/world_fixups.py`:** the old `add_spawns` (lines 355-~420) is shadowed by
   `add_spawns = add_respawns` at line 504 and never runs.
5. **[MINOR] Unused leftovers** (pyflakes): `inward` (`tools/story/build_drafts.py:80`), `sill` (`:204`),
   `import tempfile` (`tests/test_progression.py:1`).
6. **[MINOR] The room editor is slow zoomed out on very large rooms:** 112 ms per redraw at zoom 0.5 on the
   benchmark's 400×400 room (fine at zoom 2-3: 4-7 ms). Real rooms are far smaller, so only noticeable if you build
   a huge one.

**Checked and fine:** gameplay frames in real rooms cost 0.2-0.5 ms of physics and under 0.1 ms of drawing
(`bench`: normal, moving, large_blocks); the 2,500-entity stress room draws in 30 ms with off-screen culling already
on. The linter's other hits are harmless: repeated `load()` of cached scripts, unused arguments in test stubs, one
ternary used as a statement. High complexity sits in `player.gd`'s ported Celeste movement and `World.update`
(expected; not worth splitting for its own sake).

## Fix prompt

```text
Save-safety and cleanup fixes. Read AGENTS.md and docs/reviews/codebase-2026-11-03/REVIEW.md first. Stay inside
this repository. Keep gameplay identical. Don't edit worlds/ content.

Context: player progress (adventure runs, level records, settings) is a ConfigFile at Game.save_path
(scripts/game.gd: save_adventure, submit_record, save_settings and the other cf.load/cf.save pairs). World Editor
saves: Adventure.save_world (scripts/adventure.gd) writes world.json; Game.save_level (scripts/game.gd) writes
each room JSON.

Tasks (one commit each; write the test first and see it fail):
1. Crash-safe progress saves: one helper (e.g. Game.write_config(cf, path)) that saves to path + ".tmp", keeps the
   previous file as ".bak", then renames; and one loader that tries path, then ".bak", and refuses to save
   (push_error + no write) when both fail to load, instead of starting from an empty file. Use it everywhere the
   save file is loaded then saved. Test (tests/test_runner.gd): write a save with a level record and another
   world's run, truncate it to half, call save_adventure(): the record and the other run are still there
   (from .bak) and the new run is saved.
2. Same for World Editor files: save_world and save_level write to a .tmp, check store_string / get_error, keep a
   .bak, rename; return false / "" on any failure. Test: a write into a read-only directory returns failure and
   leaves the old file intact.
3. World.respawn(): don't _build() again after enter_room() has built the target room (keep the spawn position and
   the base-stamina refill). Test: respawning into another room builds it once and puts the player on the spawn.
4. Remove the dead add_spawns body in tools/world_fixups.py (keep the alias), the unused 'inward' and 'sill'
   variables in tools/story/build_drafts.py, and the unused tempfile import in tests/test_progression.py.

Verification: sh tools/verify.sh → 0 failing; python3 -m unittest discover -s tests -p 'test_*.py' → OK.
One dated line in gdd.txt per task.
```

## Suggestions for the future

- **Add the linters to `tools/verify.sh`** (`gdlint` with the correctness rules used here, `pyflakes`): they found
  the dead code in seconds and would catch new leftovers on every run.
- **One save module** for every file the game writes (progress, rooms, world, CSVs, profiles): the Monster Editor
  already has temp + backup + rollback; the rest should share it.
- **Bench a real story room** in `tests/bench.gd` (e.g. the Ape arena with its effects) next to the synthetic ones,
  so performance numbers track what players actually see.
