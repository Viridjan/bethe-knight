# Story traversal isolation and deferred-work audit

The jump-only traversal bot now receives a deep copy of the world without boss entities/gates, Ape chases, auto-walk, linked triggers/pressure plates, rock-fall events or notes. Conditional encounter variants are disabled in that copy. Source story files, ordinary terrain/water/platforms/spikes and dedicated encounter tests are preserved.

A blocked-jump fallback previously kept resetting its walk timer without ever allowing another jump at that position. The bot now retries after the short walk. The route terminates on arrival in Jungle Hills, before the optional downward branch that removing its gates exposes; the separate planner checks still cover its local jump geometry.

West/East Shore use manually shaped pools, like the already exempt meadow/caves. Their entity layouts are preserved and no longer required to follow the generated wall-to-wall liquid convention.

The Python island checker now derives its landing from the current raft doorway instead of the pre-move global coordinate (706, 65). The room/star/return-route assertions remain intact.

Conditional-room resizing is fixed and covered by the updated room-resize suite, including unique variant object translation, undo, and refusal to partially save when a variant-only path would be cut.

`docs/DEFERRED_WORK.md` distinguishes the explicitly postponed Ape true form, unfinished requested systems, open design decisions and old idea/optimization lists. Stale status entries for traps/triggers, input, basic attack costs and hidden walls have been corrected.

`verification.log` records the complete run and its Python follow-up: all Godot runners and linters passed; after replacing the stale island landing coordinate, all 76 Python tests passed.
