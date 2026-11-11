"""Original 32x16 fallen sword-bearer. Run from any directory to rebuild the runtime sheet."""
from pathlib import Path
import sys
sys.path.insert(0, '/home/viridjan/.codex/skills/pixel-art-studio/scripts')
from pixelstudio import Sprite
HERE = Path(__file__).resolve().parent
OUT = HERE.parents[1] / 'assets' / 'props'
OUT.mkdir(parents=True, exist_ok=True)
DARK, SHADE, BONE, LIGHT = '#252b37', '#8c8b7a', '#cdc8ab', '#eee2bc'
CLOTH, STEEL, EDGE, GOLD = '#69525d', '#96bdc7', '#daf2e7', '#bf9460'
s = Sprite(32, 16, palette=[DARK, SHADE, BONE, LIGHT, CLOTH, STEEL, EDGE, GOLD])
def body():
    # Torn cloak and the far arm: deliberately behind the rib cage.
    s.polygon([(9,9),(14,6),(19,8),(22,12),(18,14),(11,14)], DARK)
    s.polygon([(10,10),(14,7),(18,9),(20,12),(15,13),(11,12)], CLOTH)
    s.line(12,7,17,4,DARK); s.line(17,4,22,6,DARK)
    s.line(13,7,17,5,SHADE); s.line(17,5,21,6,BONE)
    # Pelvis and two bent legs; far leg darker, near leg warm and lit.
    s.line(19,10,23,7,DARK);s.line(23,7,27,9,DARK)
    s.line(20,10,23,8,SHADE);s.line(23,8,26,9,BONE)
    s.line(20,12,23,14,DARK);s.line(23,14,28,13,DARK)
    s.line(20,11,23,13,BONE);s.line(23,13,27,12,BONE)
    s.line(23,12,26,11,LIGHT)
    s.rect(26,9,28,10,DARK);s.line(27,9,28,9,SHADE)
    s.rect(27,12,29,13,DARK);s.line(27,12,29,12,BONE)
    s.ellipse(18,8,21,12,DARK);s.line(19,9,21,10,BONE);s.line(19,11,20,11,SHADE)
    # Rib arcs surround dark gaps, joined by a low spine.
    s.line(10,12,18,12,DARK);s.line(11,11,18,11,BONE)
    for x in [12,15,18]:
        s.line(x,7,x+1,8,DARK);s.line(x+1,8,x+1,10,DARK)
        s.px(x,7,LIGHT);s.line(x,8,x,10,BONE)
    # Near arm rests across the floor in front of the cloak.
    s.line(11,10,13,14,DARK);s.line(13,14,18,14,DARK)
    s.line(11,10,14,13,BONE);s.line(14,13,18,13,LIGHT)
    # Large skull, downturned jaw and paired dark sockets read at native scale.
    s.polygon([(3,5),(7,4),(10,6),(10,10),(8,13),(4,13),(2,10),(2,7)],DARK)
    s.polygon([(3,6),(7,5),(9,6),(9,10),(7,12),(4,12),(3,10)],BONE)
    s.rect(4,5,7,6,LIGHT);s.line(3,7,3,9,LIGHT)
    s.rect(4,8,5,9,DARK);s.rect(7,8,8,9,DARK)
    s.px(6,10,SHADE);s.line(4,11,7,11,SHADE)
    s.line(4,12,7,12,BONE)
def sword():
    s.polygon([(22,11),(29,3),(31,3),(30,6),(24,12)],DARK)
    s.polygon([(24,9),(29,4),(30,4),(29,6),(24,11)],STEEL)
    s.line(24,9,29,4,EDGE)
    s.line(21,10,24,13,DARK);s.line(21,10,23,12,GOLD)
    s.line(20,13,22,11,DARK);s.line(20,13,21,12,GOLD)
body();sword()
s.add_frame(copy=False);body()
s.save_png(HERE / 'with_sword.png', frame=1)
s.save_png(HERE / 'taken.png', frame=2)
s.save_spritesheet(OUT / 'dead_skeleton.png', layout='horizontal')
s.preview(HERE / 'preview.png', scale=8)
s.save_silhouette(HERE / 'silhouette.png', frame=1)
s.stats()
