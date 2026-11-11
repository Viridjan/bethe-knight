# Sword skeleton and Treetop branch — 2026-11-10

The designer accepted point 3 with three corrections: Sword comes after Sand Cave from a dead skeleton, Climb belongs to the opposite Treetop Village branch, and dash crystals are removed. [Accepted design](../../docs/plans/PROGRESSION_REWARDS.md).

- `s2_shore` now contains `dead_skeleton` on the safe entrance landing at (64,312), just beyond Sand Cave. Interact takes Sword once; the remains stay visible without the sword. Existing owned swords remain owned. The keeper starts the crystal quest without granting Sword.
- `l3_treetop_village` contains a Climb pickup on its safe floor at (544,104). The obsolete Sand Cave sword and village climb placeholder notes were removed.
- Dash/double-dash crystal entity types, runtime class/consumption method and editor tools/help were removed. Legacy root/layer rooms discard the obsolete definitions and trigger links to removed crystal IDs. Normal dash recovery and reusable stamina orbs remain.
- Generic editor/motion tests now use stamina orbs instead of retired crystals. Offline progression recognizes the skeleton as the Sword source and does not invent airborne crystal dash refreshes.

## Asset

[Runtime sheet](../../assets/props/dead_skeleton.png), [manifest](../../assets/props/manifest.json), [gallery](../../assets/props/preview.html), [source/critique](../../pixel-art/dead-skeleton/README.md).

Original 32×16 pixel artwork per state, eight opaque colours plus transparency, two fixed-origin states. Two preview passes corrected an initially thin sword blade. PNG dimensions, colour budget and hard alpha were checked. The three running-game captures were visually inspected: the sword disappears while the bones stay, the prompt sits above the corpse, and the climb pickup is clear of the village floor. No third-party art was used; existing licensed files were preserved.

## Verification

A small point-2 validation regression was also reproduced and fixed: the positive-dimension helper rejected an explicitly disabled heat rate of zero. [Failing regression](zero-heat-red.txt); [passing resource checks](integer_resources-final.txt). Zero now remains valid while fractional heat rates are still rejected.

The [initial regression](red.txt) failed six checks before implementation. A [second regression](legacy-link-red.txt) reproduced a dangling trigger link after crystal removal; the loader now removes those links while retaining unrelated validation. The [targeted final checks](targeted-final.txt) exercise explicit interaction, once-only acquisition, save/continue, legacy rooms/layers, authored safe ground and walking from the actual Shore entrance. The village reward is reachable with no sword/climb prerequisite.

The [offline reward regression](progression-red.txt) failed before the power mapping update; its [passing result](progression.txt) checks the corrected source.

Full verifier output: [verification.txt](verification.txt), [exit status](verification-exit.txt). **Full verifier: 0 failing, exit 0** across 43 Godot invocations, Python unittest discovery, GDScript lint, Pyflakes and diff checks. After the zero-heat correction, resources, skeleton, gameplay and smoke checks were rerun successfully against the final source (`integer_resources-final.txt`, `sword_skeleton-final.txt`, `test-final.txt`, `smoke-final.txt`). The main gameplay log intentionally includes damaged-save errors from its corruption-recovery tests; there are zero assertion failures. Historical point 2 evidence remains unchanged.

In-game captures: [sword present](sword-present.png), [sword taken](sword-taken.png), [village climb](village-climb.png). Reproduce with `godot --path . res://reports/sword-skeleton-2026-11-10/capture.tscn`; the scene uses disposable adventure state.

Only the requested sword/climb placements and crystal removal are implemented here. Accepted Ape dash, later island rewards, village quests/points and wider route authoring remain in their planned stages. No full chapter playthrough, commit or deployment was performed.
