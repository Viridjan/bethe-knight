# Configurable Ape attack conditions

Each normal/enraged binding row now has a Trigger selector. Retreat leap exposes its previous hidden cornered-player rule; conditions can be independently changed per phase and saved in the catalogue CSV. The selector also offers normal rules, vertical alignment, nearby/far and always. Explicit conditions replace per-attack heuristics while preserving selection priority, maximum range, skip chance/cooldown and attack execution timing.

This does not turn selection reactions into world-editor trigger zones or landing effects. A condition makes the attack eligible on the next idle decision. Legacy catalogues retain their old behavior through the default migration.

Verification: new `tests/ape_attack_triggers.tscn` covers the real Ape decision path, cornered/vertical/always changes, range and skip policy, unknown-condition rejection, picker visibility, per-phase save/reload and old-CSV migration; 0 failures. Gameplay runner: 0 failures. Catalogue: ATTACK CATALOG OK. Ape follow-ups: 0 failures. Smoke: SMOKE OK. GDScript lint and diff whitespace checks pass. Catalogue/follow-up shutdown resource warnings remain.

`capture.tscn` renders the production editor; `editor.png` shows the retreat's per-phase triggers.

The later [coverage-based corner definition](../cornered-coverage-2026-11-06/README.md) supersedes the original horizontal wall probe described in this first trigger slice.
