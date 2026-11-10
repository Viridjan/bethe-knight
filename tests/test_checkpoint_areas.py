import importlib.util
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

class CheckpointAreas(unittest.TestCase):
    def module(self):
        path=ROOT/'tools/checkpoint_areas.py'
        self.assertTrue(path.exists(), 'Checkpoint area migration exists')
        spec=importlib.util.spec_from_file_location('checkpoint_areas',path)
        module=importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_lowest_floor_with_safe_headroom(self):
        module=self.module()
        level={'w':8,'h':8,'tiles':['10000001']*6+['11111111']*2,'entities':[]}
        self.assertEqual(module.resolve(level, [8,8,48,40]), [28,48])
        level['entities'].append({'t':'thick_water','x':16,'y':32,'w':24,'h':16})
        self.assertIn(module.resolve(level,[8,8,48,40])[0], (12,44))

    def test_conversion_preserves_grounded_anchor_and_other_content(self):
        module=self.module()
        level={'w':8,'h':8,'tiles':['11111111']+['10000001']*5+['11111111']*2,
               'entities':[{'t':'spawn','x':24,'y':40},{'t':'note','x':40,'y':32,'text':'keep'}]}
        tiles=level['tiles'][:]
        module.convert_level(level)
        point=level['entities'][0]
        self.assertEqual(point['respawn_at'],[28,48])
        self.assertEqual(point['y'],8)
        self.assertGreater(point['w'],8)
        self.assertEqual(level['tiles'],tiles)
        self.assertEqual(level['entities'][1]['text'],'keep')
        before=json.dumps(level,sort_keys=True)
        module.convert_level(level)
        self.assertEqual(json.dumps(level,sort_keys=True),before)

    def test_shipped_maps_and_layers_use_valid_explicit_areas(self):
        module=self.module()
        seen=0
        for path in (ROOT/'worlds/story').glob('*.json'):
            if path.name=='world.json':continue
            data=json.loads(path.read_text())
            for level in [data,*data.get('layers',{}).values()]:
                for entity in level['entities']:
                    if entity['t'] not in ('spawn','respawn'):continue
                    self.assertIn('respawn_at',entity,(path,entity))
                    self.assertEqual(entity['respawn_at'],module.resolve(level,[entity[k] for k in ('x','y','w','h')]))
                    seen+=1
        self.assertGreater(seen,50)
