"""Convert legacy checkpoint points into editable activation rectangles.

Anchors choose the lowest safe permanent floor in the area; ties favor its center.
Only checkpoint fields change. Nested room layers are migrated too. Reapplying
preserves authored rectangles. Usage: python3 tools/checkpoint_areas.py worlds/story
"""
import argparse
import json
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from checkpoint_ground import solid_ground

TYPES=('spawn','respawn')


def marker_origin(entity):
    at=entity.get('respawn_at')
    return (int(at[0])-4,int(at[1])-8) if at else (int(entity['x']),int(entity['y']))


def safe(level,x,y):
    if not solid_ground(level,x-4,y-8):return False
    for entity in level['entities']:
        if not entity['t'].startswith('spikes_') and entity['t']!='trap_spikes':continue
        ex,ey=entity['x'],entity['y']
        if max(x-5,ex)<min(x+5,ex+entity.get('w',8)) and max(y-12,ey)<min(y+1,ey+entity.get('h',8)):return False
    return True


def resolve(level,area):
    left,top,width,height=map(int,area)
    right=min(level['w']*8,left+width)
    bottom=min(level['h']*8-8,top+height)
    left=max(0,left);top=max(0,top)
    columns=[x for x in range(4,level['w']*8,8) if x-4>=left and x+4<=right]
    center=(left+right)//2
    columns.sort(key=lambda x:(abs(x-center),x))
    for y in range(bottom-bottom%8,top+10,-8):
        for x in columns:
            if safe(level,x,y):return [x,y]
    return None


def convert_level(level,width=56):
    count=0
    points=[e for e in level['entities'] if e['t'] in TYPES]
    for entity in points:
        if 'w' in entity and 'h' in entity:
            at=resolve(level,[entity[k] for k in ('x','y','w','h')])
            if at is None:raise ValueError(f"Authored checkpoint area has no safe ground: {level.get('name','')} {entity}")
            entity['respawn_at']=at
            continue
        old_x,old_y=marker_origin(entity)
        near=old_x+4
        # Find a safe landing below the old point first, retaining its floor where possible.
        columns=sorted(range(4,level['w']*8,8),key=lambda x:(abs(x-near),x))
        foot=None
        rows=list(range(max(16,old_y+8),level['h']*8-7,8))
        rows+=list(range(min(old_y,level['h']*8-16),15,-8))
        for y in rows:
            for x in columns:
                if safe(level,x,y):foot=[x,y];break
            if foot:break
        if foot is None:raise ValueError(f"No safe checkpoint landing: {level.get('name','')} {entity}")
        x,y=foot
        top=0
        for row in range(y//8-1,-1,-1):
            if level['tiles'][row][x//8]=='1':top=(row+1)*8;break
        left=max(0,(x-4-(width-8)//2)//8*8)
        right=min(level['w']*8,left+width)
        # Neighboring same-floor checkpoints divide their horizontal coverage at the midpoint.
        for other in points:
            if other is entity:continue
            ox,oy=marker_origin(other)
            if oy+8!=y or ox+4==x:continue
            middle=((ox+4+x)//2)//8*8
            if ox+4<x:left=max(left,middle)
            else:right=min(right,middle)
        if right-left<8:left=max(0,(x-4)//8*8);right=left+8
        entity.update(x=left,y=top,w=right-left,h=y-top)
        at=resolve(level,[entity[k] for k in ('x','y','w','h')])
        if at is None:raise ValueError(f"No safe ground within generated checkpoint area: {entity}")
        entity['respawn_at']=at
        count+=1
    for plane in level.get('layers',{}).values():count+=convert_level(plane,width)
    return count


def apply(root):
    changes={}
    total=0
    for path in sorted(Path(root).glob('*.json')):
        if path.name=='world.json':continue
        original=path.read_text()
        level=json.loads(original)
        total+=convert_level(level)
        text=json.dumps(level,indent='\t',ensure_ascii=False)+'\n'
        if json.loads(original)!=level:changes[path]=text
    # Resolve every room before writing any file, so invalid areas cannot partially migrate the map.
    for path,text in changes.items():path.write_text(text)
    return total,len(changes)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('world',type=Path)
    count,files=apply(parser.parse_args().world)
    print(f'Converted {count} checkpoints across {files} room files')
