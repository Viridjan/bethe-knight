# Retained room layers

Implemented 2026-11-08. A room can contain up to eight planes, including `main`. Use them for house interiors, caverns, narrow towers and secret areas behind the exterior. A layer change stays in the same world room; it does not unload/rebuild the room just left.

## Runtime behavior

- Every plane's terrain, entities and trigger state is instantiated when its parent room loads. Only one player is controlled; passages transfer that player to the active plane.
- Inactive planes remain in memory and stop simulation, input and interaction. Their enemies, mechanisms, transient effects and pickup state do not advance while inactive. Returning resumes the same objects. A normal death still rebuilds the relevant active plane; leaving the parent room releases its planes.
- Visited planes behind the active one receive a **90% black overlay**. The active plane's walls, objects and player draw above it; empty space reveals the darkened exterior. Unvisited planes remain concealed. Returning to an earlier plane hides the later visual stack while retaining those objects in memory.
- Old SFX voices are **stopped**, not paused; attack sounds and cave echoes cannot resume on return. The one shared music engine stops and starts the active plane's environment music. Inactive planes cannot emit new sounds because their simulation is stopped.
- Only the active plane supplies collision, hazards, doors, camera and HUD. Physics/input retain their normal update rate and precision. This feature does not implement the pending resource tick.
- Only `main` uses physical edge transitions to adjacent world rooms. Interior planes use explicit passages or ordinary room-link doors. The in-game map uses the active plane's terrain for the current room.
- Entering an authored [checkpoint area](RESPAWN_POINTS.md) records its grounded anchor, parent room and plane together. An unconfigured layer entrance retains the previous checkpoint. Continue restores the checkpoint plane. Persistent pickup/wall IDs are namespaced by plane; existing main-plane IDs keep their old format.

## Room editor

1. Use **Room layer** in the left palette to choose the plane to paint. **+ Layer** adds an empty plane with a unique identifier such as `cavern` (maximum eight planes total).
2. Paint terrain and place safe landings/start markers with the ordinary tools. Planes share their parent's width, height and local coordinate grid; their occupied areas can have different shapes and sizes. Leave tiles empty outside an enclosed interior so the previous plane can remain visible behind it.
3. Choose **Layer Passage** from Doors & people, drag its rectangle, and enter its own ID, destination passage ID and **Destination layer**. Configure the corresponding passage in the destination plane. Click it again with the Layer Passage tool to edit it.
4. Stand at a passage and press Interact during play. Invalid, blocked or missing destinations do not switch layers. The arrival is locked against an immediate return until the player steps away; a held button does not bounce between planes.
5. Save writes every plane into the one parent room file. Playtest begins in the selected plane. Layer addition and edits use undo; edge/corner resizing resizes all planes and translates their objects together. A resize which breaks a retained path or passage is refused.

Passage IDs must be unique within their plane. Destination IDs are local to the chosen plane. Layer IDs are identifiers (up to 40 characters); `main` is reserved for the exterior. Layers cannot recursively contain more layers.

## Data format

The existing room remains the main plane. Additional definitions live in `layers`:

```json
{
  "name": "Coast",
  "w": 40,
  "h": 30,
  "tiles": ["...40 cells per row; 30 rows..."],
  "entities": [
    {"t":"layer_passage","id":"mouth","to_layer":"cave","to":"exit","x":80,"y":184,"w":16,"h":40}
  ],
  "layers": {
    "cave": {
      "name":"Coastal cave",
      "w":40,
      "h":30,
      "environment":"cavern",
      "tiles":["...its own 40 by 30 tile grid..."],
      "entities":[
        {"t":"layer_passage","id":"exit","to_layer":"main","to":"mouth","x":120,"y":184,"w":16,"h":40}
      ]
    }
  }
}
```

Tile strings above are schematic; real grids contain only `0`/`1` and must match dimensions. Passage bottoms are the destination standing position; place them on a clear, supported landing. The room loader validates every plane and cross-plane link.

## Shipped map conversion

| Parent room | Layer / exterior content |
| --- | --- |
| `t1_cove_town` | `h1_villager_house` and `h2_quest_house` are retained interior layers. The two exterior house entrances switch planes. Each interior contains an interactable resident. |
| `s2_shore` | `lh1_lighthouse_stairs` is a narrow, nine-tile-wide tower interior with alternating landings. Five mages occupy different heights; the keeper near the top supplies the existing crystal quest. |
| `s2_shore`, main | The rooftop, magic flame and mirror are in the Shore exterior. Bottom and top passages enter/leave the interior; there is no separate `s3_lighthouse_top` world room. |

Shore grew upward by 32 tiles; its world origin moved upward by the same amount. Its original ground, water and neighbouring entrances retain their global positions. Detached house/stairs/top files and their world/region entries were removed after embedding their content. Old detached-room saves migrate to the parent/layer; invalid old interior positions fall back to safe starts. The old top-room checkpoint maps to the Shore roof.

`python3 tools/story/migrate_room_layers.py worlds/story` reapplies the migration after legacy generators/art passes. It is idempotent on the migrated map and refuses a partial four-room source set. It preserves the old exterior star ID when moving its coordinates. Legacy generators themselves still describe the detached layout; run this migration after them.

## Verification and limits

`tests/room_layers.tscn` covers retained objects, inactive simulation/UI, darkness/concealment, player transfer, old sound shutdown, invalid links/arrivals, checkpoint/continue, room release, editor planes/packing/resize/undo, and the actual lighthouse climb using jump-only physics with safe recovery pauses. `tests/test_room_layers_migration.py` checks the shipped conversion and repeatability. They run through `tools/verify.sh`.

The layer editor does not expose layer renaming/removal yet; undo can remove a newly added layer. General offline progression/accessibility tools still primarily analyze exterior room graphs, so their room-level reachability output alone does not prove interior routes. Use the layer/link validation and runtime checks as well. Room variants and custom third-party generation need to preserve the embedded `layers` data when rewriting parent files.
