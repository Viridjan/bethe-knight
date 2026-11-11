# Room scenery

Original pixel art authored in `scripts/room_scenery_art.gd`, following the existing stepped, muted terrain artwork. No external images or licenses are introduced. These assets belong to this project under the same terms as its source code.

12 backdrop families provide timber interiors, towers, ruins, flooded ruins, underwater spaces, four cave materials, forest hollows, marsh and plateau scenery. Existing outdoor paintings remain available. Each backdrop has a 320×180 opaque background and a transparent foreground. Decorations use eight 16×24 cells in each 128×24 transparent atlas, with ceiling and underwater sets for all 14 terrain themes. Nearest-neighbor filtering, integer pixel edges, no mipmaps; decorations have no collision.

Runtime textures are generated once and cached from the GDScript source. PNGs are exported references, not a second source of truth. Regenerate with:

```sh
godot --headless --path . --script tools/export_room_scenery.gd
```

In the level editor, choose **Backdrop (cosmetic)** independently of **Environment**. `auto` uses enclosed scenery for cave/ruin environments and the existing outdoor art elsewhere. Story house/lighthouse layers and enclosed jungle/sand/ruin rooms specify their own cosmetic backdrop. The assignment tool changes only `backdrop` fields and verifies identical gameplay fingerprints.

Ceiling decorations require clear space under solid tiles. Underwater decorations attach above solid floor tiles and are clipped to authored water/thick-water rectangles. They do not create collectibles, lights, hazards or interactive objects. The terrain, water entity, collision and resource settings retain their gameplay roles.

[Browse the art](preview.html). In-game captures and verification live in `reports/room-cosmetics-2026-11-10/`.
