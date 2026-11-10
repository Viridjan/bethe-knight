#!/usr/bin/env python3
"""Shape a room by type instead of as a box. Preview only: writes to --out, never into the world.

    python3 tools/room_shapes.py list
    python3 tools/room_shapes.py demo                          # one room of every type
    python3 tools/room_shapes.py new cave --w 60 --h 24 --door L:12 --door R:18 --door T:30
    python3 tools/room_shapes.py reshape c2_cave_teeth cave    # existing room, exits kept

Types: cave (winding stacked tunnels), city (regular buildings, floors, roofs), mountain (stepped
slopes, a peak, a tunnel into the rock), forest (trunks with leaf platforms), house (stepped
interior, wide base). A door is SIDE:POSITION: L/R with the row you stand on, T/B with the left
column; doorways are 3 tiles. The same --seed gives the same room.

Output: <out>/<name>.json and <out>/index.html (default out: reports/room-shapes). A room is written
only if the cautious movement model (tools/world_check.py) can walk between all its doors; the seed
is advanced until one passes. reshape keeps the original border cells, drops the old one-way
platforms and spikes that lost their rock, moves objects left in rock or mid-air (and respawn landing
points) to the nearest fitting spot and lists every change. Copy an approved file into the world yourself.

shortcut: reshape makes every exit reachable with plain jumps (ability gates in the old shape are
lost) and leaves layers, water and other area objects where they were; add gates and area handling
when rooms with them are reshaped for real.
"""
import argparse, html, json, os, random, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [HERE, os.path.join(HERE, "story")]
from build_drafts import check_room
from checkpoint_areas import resolve
from morph_terrain import svg

T, DOOR, TRIES = 8, 3, 40
ENV = {"cave": "cavern_deep", "city": "sea", "mountain": "sky", "forest": "forest", "house": "sky"}
DEMO = {"cave": (60, 26, ["L:8", "R:20", "T:30"]), "city": (72, 24, ["L:20", "R:20"]), "mountain": (64, 28, ["L:24", "R:20"]),
        "forest": (72, 24, ["L:19", "R:21"]), "house": (22, 14, ["L:11"])}


class Shape:
    def __init__(self, w, h, doors, rng):
        self.w, self.h, self.doors, self.rng = w, h, doors, rng
        self.t = [["1"] * w for _ in range(h)]
        self.plats = []  # (x0, x1, y) one-way platforms

    def cut(self, x, y, ch="0"):
        if 0 < x < self.w - 1 and 0 < y < self.h - 1:
            self.t[y][x] = ch

    def box(self, x0, x1, y0, y1, ch="0"):  # inclusive
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.cut(x, y, ch)

    def open(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h and self.t[y][x] == "0"

    # Row you stand on at a side: its lowest door (higher ones get ledges), else `default`.
    def sill(self, side, default):
        return max([hi - 1 for s, lo, hi in self.doors if s == side], default=default)

    # Standing rows from row a at the left to row b at the right: steps between treads of lo..hi tiles,
    # 1 tile each unless the distance forces more, with a few up-and-down wiggles.
    def walk(self, n, a, b, top, bottom, lo, hi):
        rng, d, sign = self.rng, abs(b - a), (b > a) - (b < a)
        treads = []
        while sum(treads) < n:
            treads.append(rng.randint(lo, hi))
        if len(treads) - 1 < d:
            treads = [lo] * -(-n // lo)
        steps = [0] * max(1, len(treads) - 1)
        for i in range(d):
            steps[rng.randrange(len(steps)) if i >= len(steps) else rng.sample(range(len(steps)), min(d, len(steps)))[i]] += sign
        flat = [i for i, v in enumerate(steps) if v == 0]
        rng.shuffle(flat)
        for i, j in zip(flat[0::4], flat[1::4]):
            steps[i], steps[j] = 1, -1
        out, y = [], a
        for k, length in enumerate(treads):
            out += [max(top, min(bottom, y))] * length
            y += steps[k] if k < len(steps) else 0
        return out[:n]

    # Open sky above a ground line, rock below it. stand[i] is the standing row of column 1 + i.
    def land(self, stand):
        for i, y in enumerate(stand):
            self.box(1 + i, 1 + i, 1, y)

    def plat(self, x0, x1, y):
        x0, x1 = max(1, x0), min(self.w - 1, x1)
        if x1 > x0:
            self.plats.append((x0, x1, y))


def cave(s):
    w, h, rng = s.w, s.h, s.rng
    n = max(1, min(3, (h - 4) // 8))
    bases = [3 + (i + 1) * (h - 6) // n for i in range(n)]  # standing rows of the tunnel levels
    ends = [[b, b] for b in bases]
    for side, lo, hi in s.doors:  # the nearest level bends to meet each side door
        if side in "LR":
            i = min(range(n), key=lambda k: abs(bases[k] - (hi - 1)))
            ends[i]["LR".index(side)] = hi - 1
    floors, limit = [], 2
    for (a, b), base in zip(ends, bases):
        x0 = 2 if a != base or rng.random() < .6 else rng.randint(2, w // 4)  # some levels stop short: dead ends
        x1 = w - 3 if b != base or rng.random() < .6 else rng.randint(3 * w // 4, w - 3)
        stand = s.walk(x1 - x0 + 1, a, b, max(4, min(a, b, base - 2)), min(h - 3, max(a, b, base + 2)), 2, 6)
        roof = 3
        for i, y in enumerate(stand):
            if i % 3 == 0:
                roof = max(2, min(4, roof + rng.choice([-1, 0, 1])))
            s.box(x0 + i, x0 + i, y - roof, y)
        for _ in range(rng.randint(1, 3)):  # chambers: stretches with a higher roof
            c, n, up = rng.randrange(len(stand)), rng.randint(4, 8), rng.randint(5, 7)
            for i in range(c, min(len(stand), c + n)):
                s.box(x0 + i, x0 + i, max(limit, stand[c] - up + (i in (c, c + n - 1))), stand[i])
        limit = base + 4
        floors.append((x0, stand))
    for (ax, a), (bx, b) in zip(floors, floors[1:]):  # shafts between neighbouring levels, ledges every 3 rows
        lo, hi = max(ax, bx) + 2, min(ax + len(a), bx + len(b)) - 6
        for x in rng.sample(range(lo, hi), min(2, max(0, hi - lo))) if hi > lo else []:
            top, bottom = a[x - ax], b[x - bx]
            s.box(x, x + 3, top - 1, bottom)
            for k, y in enumerate(range(bottom - 2, top, -3)):
                s.plat(x + (k % 2) * 2, x + (k % 2) * 2 + 2, y)
            s.plat(x, x + 4, top + 1)


def mountain(s):
    w, h, rng = s.w, s.h, s.rng
    a, b = s.sill("L", h - 4), s.sill("R", h - 4)
    px, peak = rng.randint(2 * w // 5, 3 * w // 5), rng.randint(4, 6)
    stand = s.walk(px, a, peak, peak, h - 3, 1, 3) + s.walk(w - 2 - px, peak, b, peak, h - 3, 1, 3)
    s.land(stand)
    # a tunnel from the foot of one flank into the rock under the peak, kept under a 2-tile roof
    side = rng.choice([-1, 1])
    y = stand[0 if side < 0 else -1] - 1
    cols = [i for i in (range(px + 4) if side < 0 else range(px - 4, len(stand))) if stand[i] + 6 <= y]
    for i in cols:
        s.box(1 + i, 1 + i, y - rng.randint(2, 3), y)
    i = (min(cols) - 1 if side < 0 else max(cols) + 1) if cols else -1
    while 0 <= i < len(stand) and stand[i] < y:  # the way in from the slope
        s.box(1 + i, 1 + i, y - 2, y)
        i += side


def city(s):
    w, h, rng = s.w, s.h, s.rng
    a, b = s.sill("L", h - 4), s.sill("R", h - 4)
    d, sign = abs(a - b), (b > a) - (b < a)
    start = (w - 2 - 2 * d) // 2  # one regular stair, 2 tiles a step, between the two street levels
    stand = [a + sign * max(0, min(d, (x - start) // 2 + 1 if x >= start else 0)) for x in range(w - 2)]
    s.land(stand)
    x = rng.randint(3, 5)
    while x + 6 < w - 2:
        bw = rng.choice([b for b in (6, 8, 10) if x + b < w - 1])
        g = max(stand[x - 1:x - 1 + bw])
        if len(set(stand[x - 1:x - 1 + bw])) == 1:  # only on level ground
            floors = rng.randint(2, max(2, min(4, (g - 4) // 4)))
            roof = g - floors * 4
            if roof >= 3:
                s.box(x - 1, x + bw, roof, roof, "1")  # roof slab with eaves
                gap = x + rng.randrange(1, bw - 2)
                s.box(gap, gap + 1, roof, roof)  # hatch up to the roof
                s.plat(gap, gap + 2, roof)
                for wall in (x, x + bw - 1):
                    s.box(wall, wall, roof, g - 3, "1")  # walls stop above a 3-tile doorway
                for k in range(1, floors):
                    s.plat(x + 1, x + bw - 1, g - k * 4 + 1)
        x += bw + rng.randint(3, 4)


def forest(s):
    w, h, rng = s.w, s.h, s.rng
    stand = s.walk(w - 2, s.sill("L", h - 4), s.sill("R", h - 4), h - 8, h - 3, 3, 7)
    s.land(stand)
    x = rng.randint(6, 9)
    while x < w - 7:
        g = max(stand[x - 1], stand[x])
        k = rng.randint(2, max(2, min(5, (g - 5) // 3)))  # trunk height in 3-tile jumps
        s.box(x, x + 1, g - 3 * k + 1, g + 1, "1")
        for j in range(1, k):  # leaves both sides of the trunk, widths uneven
            for side in (-1, 1):
                n = rng.randint(2, 4)
                s.plat(x - n if side < 0 else x + 2, x if side < 0 else x + 2 + n, g - 3 * j + 1)
        if k > 2:  # canopy
            n = rng.randint(2, 4)
            s.plat(x - n, x, g - 3 * k + 1)
            s.plat(x + 2, x + 2 + n, g - 3 * k + 1)
        x += rng.randint(7, 12)


def house(s):
    w, h = s.w, s.h
    g = max(s.sill("L", h - 3), s.sill("R", h - 3))
    x0, x1, y, inset = 1, w - 2, g, max(2, w // 6)
    while y - 3 >= 2 and x1 - x0 >= 5:  # storeys narrow towards the roof: a wide base
        s.box(x0, x1, y - 3, y)
        if y != g:
            hatch = x0 + (x1 - x0) // 2 - 1
            s.box(hatch, hatch + 2, y + 1, y + 1)
            s.plat(hatch, hatch + 3, y + 1)
        x0, x1, y = x0 + inset, x1 - inset, y - 5


TYPES = {"cave": cave, "city": city, "mountain": mountain, "forest": forest, "house": house}


# Join every door to the open space of the shape; returns the standing cells the checker must connect.
def join_doors(s):
    targets = []
    for side, lo, hi in s.doors:
        if side in "LR":
            xs = range(0, s.w - 1) if side == "L" else range(s.w - 1, 0, -1)
            for x in xs:
                if x not in (0, s.w - 1) and s.open(x, hi - 1) and s.open(x, hi - 2):
                    break
                for y in range(lo, hi):
                    s.t[y][x] = "0"
            inner, d = (1, 1) if side == "L" else (s.w - 2, -1)
            if hi < s.h - 1:
                for k in range(3):
                    s.t[hi][inner + d * k - d] = "1"  # a sill to stand on
                    s.cut(inner + d * k, hi)
                    s.t[hi][inner + d * k] = "1"
            x, y = inner + 3 * d, hi  # a raised door: ledges every 3 rows down to the ground
            while all(s.open(x + d * i, y + k) for i in range(3) for k in (1, 2, 3)):
                y += 3
                s.plat(min(x, x + 2 * d), max(x, x + 2 * d) + 1, y)
                x = max(2, min(s.w - 5, x + d * s.rng.randint(1, 3)))
            targets.append((inner, hi - 1, None))
        else:
            ys = range(0, s.h - 1) if side == "T" else range(s.h - 1, 0, -1)
            for y in ys:
                if y not in (0, s.h - 1) and all(s.open(x, y) for x in range(lo, hi)):
                    break
                for x in range(lo, hi):
                    s.t[y][x] = "0"
            if side == "T":  # ledges down from a roof door until the ground is one jump away
                y = 1
                while y < s.h - 1 and all(s.open(x, y + k) for x in range(lo, hi) for k in (1, 2, 3)):
                    s.plat(lo, hi, y)
                    y += 3
                s.plat(lo, hi, y)
            targets.append((lo + 1, 0 if side == "T" else s.h - 1, None))
    return targets


def build(kind, w, h, doors, seed, name, env, border=None):
    for attempt in range(TRIES):
        s = Shape(w, h, doors, random.Random(seed + attempt))
        TYPES[kind](s)
        targets = join_doors(s)
        if border:  # reshape: the outer ring stays exactly as it was, so neighbours still line up
            for y in range(h):
                for x in range(w):
                    if x in (0, w - 1) or y in (0, h - 1):
                        s.t[y][x] = border[y][x]
        plats = [p for p in s.plats if all(s.open(x, p[2]) for x in range(p[0], p[1]))]
        ents = [{"t": "jumpthru", "x": x0 * T, "y": y * T, "w": (x1 - x0) * T, "h": T} for x0, x1, y in plats]
        room = {"name": name, "w": w, "h": h, "environment": env, "tiles": ["".join(r) for r in s.t], "entities": ents}
        if len(targets) < 2 or check_room("room", room, targets):
            return room, seed + attempt
    return None, seed


def parse_door(text, w, h):
    side, at = text.split(":")
    at = int(at)
    if side not in "LRTB" or not (DOOR <= at + 1 <= h - 1 if side in "LR" else 1 <= at <= w - DOOR - 1):
        raise SystemExit("bad door %s" % text)
    return (side, at - DOOR + 1, at + 1) if side in "LR" else (side, at, at + DOOR)


# Doors of an existing room: every run of open cells on its border (corners belong to the sides).
def find_doors(room):
    t, w, h, out = room["tiles"], room["w"], room["h"], []
    lines = [("L", [t[y][0] for y in range(h)]), ("R", [t[y][w - 1] for y in range(h)]),
             ("T", list(t[0][1:w - 1])), ("B", list(t[h - 1][1:w - 1]))]
    for side, cells in lines:
        i = 0
        while i < len(cells):
            j = i
            while j < len(cells) and cells[j] == "0":
                j += 1
            off = 0 if side in "LR" else 1
            if j > i and not (side == "T" and j - i > len(cells) // 2):  # an open sky is not a door
                out.append((side, i + off, min(j, h - 2) if side in "LR" else j + off))
            i = max(j, i + 1)
    return out


# Keep the old room's objects. Those left inside rock or in mid-air move to the nearest fitting cell; a respawn
# keeps its zone and moves its landing point; spikes without their rock are dropped. Returns what changed.
def carry_objects(old, room):
    t, w, h = room["tiles"], room["w"], room["h"]
    plat = {(e["x"] // T + i, e["y"] // T) for e in room["entities"] for i in range(e["w"] // T)}
    free = lambda x, y: 0 < x < w - 1 and 0 < y < h - 1 and t[y][x] == "0"
    rock = lambda x, y: not (0 <= x < w and 0 <= y < h) or t[y][x] == "1"
    air = [(x, y) for y in range(2, h - 1) for x in range(1, w - 1) if free(x, y) and free(x, y - 1)]
    stand = [c for c in air if rock(c[0], c[1] + 1) or (c[0], c[1] + 1) in plat]
    near = lambda cells, cx, cy: min(cells, key=lambda c: (c[0] - cx) ** 2 + (c[1] - cy) ** 2)
    ground = [c for c in stand if rock(c[0], c[1] + 1)]
    left_right = lambda e, cx: e["x"] <= cx * T and cx * T + T <= e["x"] + e["w"]
    notes, count = [], {}
    for e in sorted(old["entities"], key=lambda e: "respawn_at" in e):  # respawns last: they must avoid kept spikes
        e, kind = dict(e), e["t"]
        cx, cy = int(e["x"]) // T, (int(e["y"]) + int(e.get("h", T)) - 1) // T
        if kind == "jumpthru":
            continue
        if kind.startswith("spikes_"):
            dx, dy = {"spikes_up": (0, 1), "spikes_down": (0, -1), "spikes_left": (1, 0), "spikes_right": (-1, 0)}[kind]
            if not free(cx, cy) or not rock(cx + dx, cy + dy):
                count["dropped: " + kind] = count.get("dropped: " + kind, 0) + 1
                continue
        elif e.get("respawn_at") and ground:  # the zone follows its landing point onto real ground
            px, py = (int(e["respawn_at"][0]) - 4) // T, (int(e["respawn_at"][1]) - 8) // T
            nx, ny = near(ground, px, py)
            if not left_right(e, nx):
                e["x"] = max(0, min(w * T - e["w"], e["x"] + (nx - px) * T))
            foot = ny * T + T
            if not e["y"] + 10 < foot <= e["y"] + e["h"]:
                e["y"] = min(e["y"], max(0, foot - e["h"]))
                e["h"] = foot - e["y"]
            at = resolve(room, [e["x"], e["y"], e["w"], e["h"]])
            if at is None:
                count["by hand: respawn"] = count.get("by hand: respawn", 0) + 1
            elif at != list(e["respawn_at"]):
                e["respawn_at"] = at
                notes.append("moved: respawn landing to %d,%d" % tuple(at))
        elif e.get("w", T) > 2 * T or e.get("h", T) > 2 * T:
            count["by hand: " + kind] = count.get("by hand: " + kind, 0) + 1
        else:
            cells = air if e.get("move") == "hover" else stand
            if cells and (cx, cy) not in cells:
                nx, ny = near(cells, cx, cy)
                e["x"], e["y"] = e["x"] + (nx - cx) * T, e["y"] + (ny - cy) * T
                notes.append("moved: %s to %d,%d" % (kind, e["x"], e["y"]))
        room["entities"].append(e)
    return notes + ["%s x%d" % kv for kv in sorted(count.items())]


def page(out, cards):
    os.makedirs(out, exist_ok=True)
    body = "".join("<article><h2>%s</h2><p>%s</p><div class='pair'>%s</div></article>" % (
        html.escape(title), "<br>".join(html.escape(n) for n in notes), "".join("<figure>%s</figure>" % svg(r) for r in rooms))
        for title, notes, rooms in cards)
    open(os.path.join(out, "index.html"), "w").write(
        "<!doctype html><meta charset='utf-8'><title>Room shapes</title><style>body{background:#182332;color:#eee;font:15px system-ui;"
        "max-width:1400px;margin:24px auto;padding:16px}svg{width:100%;image-rendering:pixelated}.pair{display:flex;gap:16px}"
        "figure{margin:0;flex:1}article{border-top:1px solid #526673;margin:28px 0}</style><h1>Room shapes: preview only</h1>" + body)


def show(room):
    plat = {(e["x"] // T + i, e["y"] // T) for e in room["entities"] if e["t"] == "jumpthru" for i in range(e["w"] // T)}
    for y, row in enumerate(room["tiles"]):
        print("".join("=" if (x, y) in plat else "#" if c == "1" else "." for x, c in enumerate(row)))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("command", choices=["list", "demo", "new", "reshape"])
    ap.add_argument("args", nargs="*")
    ap.add_argument("--w", type=int, default=60)
    ap.add_argument("--h", type=int, default=24)
    ap.add_argument("--door", action="append", default=[])
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--world", default="worlds/story")
    ap.add_argument("--out", default="reports/room-shapes")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    if a.command == "list":
        print("\n".join(TYPES))
        return 0
    jobs = []  # (name, kind, w, h, doors, env, old room or None)
    if a.command == "demo":
        jobs = [(k, k, w, h, [parse_door(d, w, h) for d in doors], ENV[k], None) for k, (w, h, doors) in DEMO.items()]
    elif a.command == "new":
        kind = a.args[0]
        jobs = [("%s_%d" % (kind, a.seed), kind, a.w, a.h, [parse_door(d, a.w, a.h) for d in a.door], ENV[kind], None)]
    else:
        name, kind = a.args
        old = json.load(open(os.path.join(a.world, name + ".json")))
        jobs = [(name, kind, old["w"], old["h"], find_doors(old), old["environment"], old)]
    cards, failed = [], 0
    for name, kind, w, h, doors, env, old in jobs:
        room, seed = build(kind, w, h, doors, a.seed, old["name"] if old else name, env, old and old["tiles"])
        if room is None:
            print("FAIL  %s: no %s shape in %d seeds lets the doors reach each other; nothing written" % (name, kind, TRIES))
            failed += 1
            continue
        notes = ["%s, seed %d, %d doors" % (kind, seed, len(doors))]
        if old:
            room = {**{k: v for k, v in old.items() if k not in ("tiles", "entities")}, "tiles": room["tiles"], "entities": room["entities"]}
            notes += carry_objects(old, room)
            if old.get("layers"):
                notes.append("by hand: layers were left untouched")
        os.makedirs(a.out, exist_ok=True)
        json.dump(room, open(os.path.join(a.out, name + ".json"), "w"), indent="\t")
        cards.append((name, notes, [old, room] if old else [room]))
        print("ok    %s  (%s)" % (name, "; ".join(notes[:1])))
        for n in notes[1:]:
            print("      " + n)
        if not a.quiet:
            show(room)
    if cards:
        page(a.out, cards)
        print("preview: %s/index.html" % a.out)
    return failed


if __name__ == "__main__":
    sys.exit(main())
