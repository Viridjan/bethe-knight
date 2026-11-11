# Room cosmetics — 2026-11-10

Added 12 background families with two parallax planes each, plus eight roof attachments and eight underwater props for every terrain theme (14 themes). The original stepped pixel artwork uses muted background values to preserve the player/terrain read. Native sizes: 320×180 backdrops and 16×24 prop cells. Runtime textures are cached; props use retained terrain chunks.

The editor exposes a separate **Backdrop (cosmetic)** selector with undo. Cave/ruin environments select enclosed defaults; story house/lighthouse layers, forest hollows, Sand Cave and specific island interiors have explicit scenery choices. Water decorations clip to authored water/thick-water rectangles. Existing outdoor scenery remains selectable.

Only `backdrop` fields were assigned in story data. `metadata-only.json` records matching before/after fingerprints with those fields excluded. Terrain, entities, water, collision, upgrades and resource values were preserved by this dressing pass. No new interaction or progression content was introduced.

## Review

- [Art gallery](../../assets/room-scenery/preview.html)
- [House](house.png), [lighthouse](tower.png), [cave](cave.png), [forest hollow](root-interior.png), [flooded hall](flooded-hall.png), [underwater fixture](underwater.png)
- `capture.gd` reproduces captures with disposable adventure state.
- `raster-qa.json`: 64 images checked for dimensions/transparency; all eight cells in each prop atlas contain artwork.
- `red.txt`: initial missing-backdrop/validation checks failed before implementation.
- `targeted-final.txt`: placement clipping/anchoring, immutable gameplay data, all backdrop sizes, chunk invalidation, editor selection and undo.
- `verify.txt`: full repository verification output.

Original source and provenance: [asset README](../../assets/room-scenery/README.md), [manifest](../../assets/room-scenery/manifest.json). No third-party imagery was added.

## Verification caveat

The complete verifier reports an existing Shore liquid-layout assertion: five hand-shaped liquid rectangles do not individually satisfy the test's wall-to-wall requirement. Shore's gameplay fingerprint still exactly matches the pre-cosmetics fingerprint in `metadata-only.json`; this art pass changed only the lighthouse layer backdrop. The map geometry and test expectation were left intact because this request is cosmetic. The dedicated cosmetics checks and visual captures pass. See `verify.txt` for the final full-suite results.

Final verification: 48 checks passed; 1 suite failed solely on the Shore liquid-layout assertion above. Python unit tests, both linters and whitespace checks passed.
