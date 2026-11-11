# Fallen traveller — source artwork

32×16 pixels per state; eight opaque colours plus transparency; one-pixel dark outline; upper-left light; warm bone, faded cloth and cool steel. The corpse lies on its side, with far arm/leg shaded behind the ribs and near limbs. Native game scale, nearest-neighbour filtering. Two static states, not an animation.

`build.py` is the source of truth and writes the runtime sheet into `assets/props/`. Requires Pillow and the installed Pixel Art Studio helper. `with_sword.png` and `taken.png` are native-size exports; `preview.png` compares states at 8×.

Pass 1: skull, ribs and grounded pose read clearly; the one-pixel sword blade was too thin and its metal ramp collapsed to a single pixel. FIX: widen blade with a steel plane and lit edge.

Pass 2: enlarged blade reads as a sword, separated from the bones by its cool ramp and gold crossguard. The eight-colour budget is met; hard alpha, no orphan clusters and no near-duplicate colours. Both arms and legs are represented; far limbs use cooler shadows. Frame origins and bone positions remain fixed when the sword is removed. SHIP: in-game before/after captures were inspected and confirmed the scale, silhouette, prompt, fixed origin and sword removal; see `reports/sword-skeleton-2026-11-10/`.
