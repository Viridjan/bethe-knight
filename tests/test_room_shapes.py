"""tools/room_shapes.py: every type builds a room whose doors connect, repeatably; reshape keeps the border and objects."""
import json, os, sys, unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import room_shapes as rs


class RoomShapes(unittest.TestCase):
    def test_every_type_builds_and_repeats(self):
        for kind, (w, h, doors) in rs.DEMO.items():
            doors = [rs.parse_door(d, w, h) for d in doors]
            room, seed = rs.build(kind, w, h, doors, 1, kind, rs.ENV[kind])
            self.assertIsNotNone(room, kind)  # build() only returns rooms whose doors reach each other
            self.assertEqual((len(room["tiles"]), {len(r) for r in room["tiles"]}), (h, {w}), kind)
            for side, lo, hi in doors:
                cells = [room["tiles"][y][0 if side == "L" else w - 1] for y in range(lo, hi)] if side in "LR" else list(room["tiles"][0 if side == "T" else h - 1][lo:hi])
                self.assertEqual(set(cells), {"0"}, "%s door %s is open" % (kind, side))
            self.assertEqual(room, rs.build(kind, w, h, doors, seed, kind, rs.ENV[kind])[0], kind + " repeats")
            self.assertLess(sum(r.count("0") for r in room["tiles"]), 0.9 * (w - 2) * (h - 2), kind + " is not an empty box")

    def test_reshape_keeps_border_and_objects(self):
        old = json.load(open(os.path.join(ROOT, "worlds/story/c2_cave_teeth.json")))
        w, h = old["w"], old["h"]
        room, _ = rs.build("cave", w, h, rs.find_doors(old), 1, old["name"], old["environment"], old["tiles"])
        self.assertIsNotNone(room)
        ring = lambda t: [t[y][x] for y in range(h) for x in range(w) if x in (0, w - 1) or y in (0, h - 1)]
        self.assertEqual(ring(room["tiles"]), ring(old["tiles"]))
        rs.carry_objects(old, room)
        kept = [e["t"] for e in room["entities"] if e["t"] != "jumpthru"]
        keep = lambda t: t != "jumpthru" and not t.startswith("spikes_")
        self.assertEqual(sorted(filter(keep, kept)), sorted(e["t"] for e in old["entities"] if keep(e["t"])))


if __name__ == "__main__":
    unittest.main()
