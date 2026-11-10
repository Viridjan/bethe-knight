"""Retained interiors replace detached map rooms without losing exterior floor alignment."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class RoomLayersMigration(unittest.TestCase):
    def test_migration_module_exists(self):
        self.assertTrue((ROOT / "tools/story/migrate_room_layers.py").exists())

    def test_shipped_interiors_and_lighthouse_are_layers(self):
        world = json.loads((ROOT / "worlds/story/world.json").read_text())
        town = json.loads((ROOT / "worlds/story/t1_cove_town.json").read_text())
        shore = json.loads((ROOT / "worlds/story/s2_shore.json").read_text())
        self.assertIn("h1_villager_house", town.get("layers", {}))
        self.assertIn("h2_quest_house", town.get("layers", {}))
        self.assertIn("lh1_lighthouse_stairs", shore.get("layers", {}))
        for old in ("h1_villager_house", "h2_quest_house", "lh1_lighthouse_stairs", "s3_lighthouse_top"):
            self.assertNotIn(old, world["rooms"])
        self.assertTrue(any(e.get("kind") == "beacon" for e in shore["entities"]))
        inner = shore["layers"]["lh1_lighthouse_stairs"]
        people = [e for e in inner["entities"] if e["t"] in ("dialogue_npc", "lighthouse_keeper")]
        self.assertEqual(len(people), 5)
        self.assertEqual(len({e["y"] for e in people}), 5)
        self.assertTrue(any(e["t"] == "lighthouse_keeper" for e in people))

    def test_apply_is_idempotent_on_current_map_copy(self):
        module_path = ROOT / "tools/story/migrate_room_layers.py"
        if not module_path.exists():
            self.fail("Migration module missing")
        spec = importlib.util.spec_from_file_location("migrate_room_layers", module_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for source in (ROOT / "worlds/story").glob("*.json"):
                (root / source.name).write_bytes(source.read_bytes())
            before = {p.name: p.read_bytes() for p in root.glob("*.json")}
            module.apply(root)
            self.assertEqual(before, {p.name: p.read_bytes() for p in root.glob("*.json")})
