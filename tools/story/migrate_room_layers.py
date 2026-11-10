"""Migrate detached town houses and lighthouse rooms to retained interior layers.

Run after legacy generation/art passes. Idempotent on migrated maps. Existing
exterior ground stays at its global height; the lighthouse expands upward.
"""
import argparse
from copy import deepcopy
import json
from pathlib import Path

HOUSES = ("h1_villager_house", "h2_quest_house")
STAIRS = "lh1_lighthouse_stairs"
TOP = "s3_lighthouse_top"


def passage(entity, destination_layer, destination):
    entity.update(t="layer_passage", to_layer=destination_layer, to=destination)


def pad_layer(data, width, height, dx=0):
    out = deepcopy(data)
    out["legacy_room"] = data.get("legacy_room", "")
    out["legacy_offset"] = [dx, 0]
    out.update(w=width, h=height)
    out["tiles"] = ["1" * width for _ in range(height)]
    for y, row in enumerate(data["tiles"]):
        out["tiles"][y] = "1" * (dx // 8) + row + "1" * (width - dx // 8 - len(row))
    for entity in out["entities"]:
        entity["x"] += dx
    return out


def migrate_town(town, sources):
    town["layers"] = town.get("layers", {})
    for index, name in enumerate(HOUSES, 1):
        inner = pad_layer(sources[name], town["w"], town["h"], 40)
        inner["legacy_room"] = name
        for entity in inner["entities"]:
            if entity["t"] == "house_door":
                passage(entity, "main", f"h{index}")
                entity.update(y=72, h=24)
            if entity["t"] == "note":
                entity.update(t="dialogue_npc", id=f"resident_{index}", kind="elf", name="Villager" if index == 1 else "Town elder", text="The lighthouse watches the coast." if index == 1 else "The keeper lives in the lighthouse. Climb the stairs to find them.", y=76)
        inner["entities"].append(dict(t="spawn", x=56, y=88))
        town["layers"][name] = inner
        entrance = next(e for e in town["entities"] if e.get("id") == f"h{index}")
        passage(entrance, name, "out")


def tower_tiles(width, height):
    rows = []
    for y in range(height):
        row = ["0"] * width
        if 3 <= y <= 51:
            for x in range(44, 53):
                row[x] = "1" if y in (3, 51) or x in (44, 52) else "0"
        rows.append("".join(row))
    return rows


def migrate_shore(shore, sources):
    padding = 32
    shore["h"] += padding
    shore["tiles"] = ["1" + "0" * (shore["w"] - 2) + "1" for _ in range(padding)] + shore["tiles"]
    # Preserve IDs for legacy coordinate-based pickups when moving the exterior upward.
    for entity in shore["entities"]:
        if entity["t"] == "strawberry":
            entity.setdefault("persistent_id", f'{entity["x"]}_{entity["y"]}')
        entity["y"] += padding * 8
    tower = next(e for e in shore["entities"] if e["t"] == "building" and e.get("style") == "tower")
    tower.update(x=352, y=40, w=72, h=368)
    bottom = next(e for e in shore["entities"] if e.get("id") == "lh")
    passage(bottom, STAIRS, "bottom")
    shore["entities"].extend([
        dict(t="jumpthru", x=344, y=40, w=96, h=8),
        dict(t="layer_passage", id="lh_top", to_layer=STAIRS, to="top", x=364, y=16, w=16, h=24),
        dict(t="island_prop", kind="beacon", x=388, y=8, variant=0, art_tag="lighthouse-layers-v1"),
        dict(t="island_prop", kind="mirror", x=416, y=16, variant=0, art_tag="lighthouse-layers-v1"),
    ])
    # Local coordinates match the exterior tower silhouette: 9 tiles wide, 46 tall.
    inner = dict(name="Lighthouse interior", w=shore["w"], h=shore["h"], environment="temple", legacy_room=STAIRS,
                 legacy_offset=[352, 40], tiles=[], entities=[])
    inner["tiles"] = tower_tiles(inner["w"], inner["h"])
    inner["entities"] = [dict(t="spawn", x=364, y=400),
                         dict(t="layer_passage", id="bottom", to_layer="main", to="lh", x=364, y=384, w=16, h=24),
                         dict(t="layer_passage", id="top", to_layer="main", to="lh_top", x=364, y=24, w=16, h=24)]
    for i, y in enumerate(range(384, 47, -24)):
        inner["entities"].append(dict(t="jumpthru", x=360 if i % 2 == 0 else 392, y=y, w=24, h=8))
    # Five mages inhabit different landings, leaving the narrow stairs clear.
    people = [e for e in sources[TOP]["entities"] if e["t"] == "village_mage"]
    for i, floor in enumerate((360, 288, 216, 144, 72)):
        step = (384 - floor) // 24
        x = 364 if step % 2 == 0 else 396
        person = deepcopy(people[i]) if i < len(people) else {"variant": i}
        person.update(t="lighthouse_keeper" if i == 4 else "dialogue_npc", id=f"lighthouse_mage_{i}", kind="mage",
                      name="Lighthouse keeper" if i == 4 else f"Lighthouse mage {i + 1}", text="...", x=x, y=floor - 20)
        person.pop("art_tag", None)
        inner["entities"].append(person)
    shore.setdefault("layers", {})[STAIRS] = inner
    shore["legacy_exterior_rooms"] = {TOP: {"layer": "main", "spawn": [372, 40]}}
    return padding


def apply(root):
    root = Path(root)
    world_path = root / "world.json"
    world = json.loads(world_path.read_text())
    old = [name for name in (*HOUSES, STAIRS, TOP) if name in world["rooms"]]
    if not old:
        return
    if len(old) != 4:
        raise ValueError("Expected all four legacy rooms; refusing a partial migration")
    sources = {name: json.loads((root / f"{name}.json").read_text()) for name in old}
    town = json.loads((root / "t1_cove_town.json").read_text())
    shore = json.loads((root / "s2_shore.json").read_text())
    migrate_town(town, sources)
    padding = migrate_shore(shore, sources)
    world["rooms"]["s2_shore"][1] -= padding
    for name in old:
        del world["rooms"][name]
    for region in world.get("regions", []):
        region["rooms"] = [name for name in region["rooms"] if name not in old]
    outputs = {root / "t1_cove_town.json": town, root / "s2_shore.json": shore, world_path: world}
    originals = {path: path.read_bytes() for path in [*outputs, *(root / f"{name}.json" for name in old)]}
    try:
        for path, data in outputs.items():
            path.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n")
        for name in old:
            (root / f"{name}.json").unlink()
    except OSError:
        for path, data in originals.items():
            path.write_bytes(data)
        raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("world", type=Path)
    apply(parser.parse_args().world)
