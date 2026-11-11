#!/usr/bin/env python3
"""Assign cosmetic backdrops only. Preserve all terrain, entities and gameplay fields."""
import argparse
import hashlib
import json
from pathlib import Path

ROOMS = {
    's1_sand_cave': 'sand_cave',
    'l1_jungle_depths': 'canopy', 'l2_net_trap': 'canopy',
    'w2_wilds_hollow': 'canopy', 'w3_wilds_roots': 'canopy', 'w4_wilds_den': 'canopy',
    'i11_flooded_hall': 'flooded_ruins', 'i12_echo_gallery': 'ruins',
    'i15_quiet_refuge': 'ruins', 'i16_guardian_chamber': 'ruins',
    'i16_guardian_chamber_after': 'ruins', 'i17_crystal_pocket': 'deep_cave',
}
LAYERS = {'lh1_lighthouse_stairs': 'tower', 'h1_villager_house': 'house', 'h2_quest_house': 'house'}


def without_backdrops(value):
    if isinstance(value, dict):
        return {k: without_backdrops(v) for k, v in value.items() if k != 'backdrop'}
    if isinstance(value, list):
        return [without_backdrops(v) for v in value]
    return value


def fingerprint(value):
    return hashlib.sha256(json.dumps(without_backdrops(value), sort_keys=True).encode()).hexdigest()


def dress(document, room):
    before = fingerprint(document)
    changed = 0
    for plane_id, plane in [(room, document), *document.get('layers', {}).items()]:
        style = LAYERS.get(plane_id, ROOMS.get(plane_id))
        if style and plane.get('backdrop', 'auto') == 'auto':
            plane['backdrop'] = style
            changed += 1
    assert fingerprint(document) == before, 'Cosmetic dressing changed gameplay data'
    return changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', nargs='?', default='worlds/story')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    records = []
    total = 0
    for path in sorted(Path(args.directory).glob('*.json')):
        source = path.read_text()
        document = json.loads(source)
        if 'tiles' not in document:
            continue
        before = fingerprint(document)
        count = dress(document, path.stem)
        if count:
            indent = '\t' if '\n\t' in source else 2
            path.write_text(json.dumps(document, indent=indent, ensure_ascii=False) + '\n')
            records.append({'file': str(path), 'planes': count, 'gameplay_before': before, 'gameplay_after': fingerprint(document)})
            total += count
    if args.report:
        args.report.write_text(json.dumps({'changed_planes': total, 'files': records}, indent=2) + '\n')
    print(f'{total} cosmetic backdrop assignments in {len(records)} files; gameplay fingerprints unchanged')


if __name__ == '__main__':
    main()
