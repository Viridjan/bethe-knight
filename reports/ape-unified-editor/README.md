# Unified Ape loadout

Both phases share one Enemy loadout page. Attack mechanics appear once; redundant phase boxes on the right were removed. The editor opens on Enemy loadouts. Numeric inputs and card spacing are compact, with existing names preserved. Binding rows keep phase-specific priority, range and skip chance. New bindings can target either phase or both.

Visual checks: attacks.png, compact-details.png and effects.png, captured with capture.tscn.

Verification: catalogue, phase listing/binding regressions, live effect tooltip regressions, smoke and GDScript lint. Full gameplay runner has one failure in the story bot's Jungle Falls traversal; the two jungle room files had existing local modifications and were left untouched. Catalogue test also reports renderer resource leaks on shutdown.
