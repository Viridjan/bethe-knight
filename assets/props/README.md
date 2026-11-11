# Story props

Original pixel artwork for Bethe Knight, authored with Pixel Art Studio; no third-party imagery. CC0-1.0.

`dead_skeleton.png` is a 64×16 transparent sheet with two 32×16 cells: sword present, then sword taken. Its bottom-centre pivot is (16,16). It has no solid collider; the runtime entity supplies an interaction rectangle. Use nearest-neighbour filtering, no mipmaps, and native pixel scale.

Regenerate with `python3 pixel-art/dead-skeleton/build.py` from the project root. The builder requires Pillow and the installed `pixel-art-studio` helper. `manifest.json` describes the states; `dead_skeleton.json` is the generated frame metadata. Open `preview.html` to compare both states.
