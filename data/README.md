# Attack catalogue

`attacks.csv` defines library/Ape attack timing, runtime parameters, and reference
scoring inputs. Its first six columns match the requested table. `score` is derived
by the Godot catalogue tool or the in-game editor when saved. `enemy_attacks.csv`
binds reusable attacks to enemies and phases with distance intervals, priority (highest first decides the order)
and `skip_chance` (percent chance an attack passes its turn to the next one).

The tables are loaded by gameplay. Edit them in **Monsters → Attacks CSV** in the
desktop source version. See [the usage guide](../docs/ATTACK_CATALOG.md) for the
fields that affect gameplay, reference-only measurements, and remaining scoring
limits. Candidate attack patterns remain in [the research notes](../docs/ENEMY_PATTERNS.md).
