extends RefCounted
## Checkpoint rectangles activate broadly; their anchors require permanent safe terrain.
const INVALID := Vector2(-1,-1)
const TYPES := ["spawn","respawn"]
static func is_area(data: Dictionary) -> bool:
	return data.t in TYPES and data.has("w") and data.has("h")

static func resolve(level: Dictionary, area: Rect2i, safe: Callable = Callable()) -> Vector2:
	area=area.intersection(Rect2i(0,0,int(level.w)*8,int(level.h)*8))
	if area.size.x<8 or area.size.y<11:return INVALID
	var columns:=[]
	for column in int(level.w):
		var x:=column*8+4
		if x-4>=area.position.x and x+4<=area.end.x:columns.append(x)
	var middle:=area.get_center().x
	columns.sort_custom(func(a,b):return absi(a-middle)<absi(b-middle) if absi(a-middle)!=absi(b-middle) else a<b)
	var bottom:=mini(area.end.y,int(level.h)*8-8)
	bottom-=posmod(bottom,8)
	for y in range(bottom,area.position.y+10,-8):
		for x in columns:
			var at:=Vector2(x,y)
			if safe.call(at) if safe.is_valid() else safe_in_level(level,at):return at
	return INVALID

static func safe_in_level(level: Dictionary, point: Vector2) -> bool:
	var body:=Rect2i(int(point.x)-4,int(point.y)-11,8,11)
	if not Rect2i(0,0,int(level.w)*8,int(level.h)*8).encloses(body):return false
	var row:=int(point.y)/8
	if row<0 or row>=int(level.h):return false
	for y in range(body.position.y/8,(body.end.y-1)/8+1):
		for x in range(body.position.x/8,(body.end.x-1)/8+1):
			if level.tiles[y][x]!="0":return false
	for x in range(int(point.x)-3,int(point.x)+3):
		if level.tiles[row][x/8]!="1":return false
	for entity in level.entities:
		var kind:String=entity.t
		if kind not in ["water","thick_water","acid","trap_spikes","breakwall","hidden_wall","crumble","falling","zip","dream","boss_gate","ape_trunk"] and not kind.begins_with("spikes_"):continue
		var rect:=Rect2i(int(entity.x),int(entity.y),int(entity.get("w",8)),int(entity.get("h",8)))
		if rect.intersects(body.grow(1) if kind.begins_with("spikes_") or kind=="trap_spikes" else body):return false
	return true

static func prepare(level: Dictionary) -> bool:
	var valid:=true
	for entity in level.entities:
		if not is_area(entity):continue
		var point:=resolve(level,Rect2i(int(entity.x),int(entity.y),int(entity.w),int(entity.h)))
		if point==INVALID:
			entity.erase("respawn_at")
			valid=false
		else:
			var previous=entity.get("respawn_at")
			if not previous is Array or previous.size()!=2 or previous[0]!=point.x or previous[1]!=point.y:
				entity.respawn_at=[int(point.x),int(point.y)]
	for plane in level.get("layers",{}).values():
		if not prepare(plane):valid=false
	return valid
