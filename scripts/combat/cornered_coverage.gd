extends RefCounted
## Pure geometry: the caller supplies real attack damage and solid/support queries.
const TILE := 8
const WALL_HEIGHT := 3*TILE
const MAX_SCAN := 4096

static func floor_at(x: int, feet: int, support: Callable, allowance := TILE) -> int:
	for y in range(feet,feet+allowance+1):
		if support.call(Rect2i(x,y,1,1)): return y
	return -2147483648

static func no(reason: String) -> Dictionary:
	return {"cornered":false,"reason":reason}

# +2 tiles total means one tile of candidate-search padding on each edge.
# That padding never changes hits(), which must match the real attack geometry.
static func evaluate(enemy: Rect2i, player: Rect2i, damage: Rect2i, grounded: bool, footprint: Dictionary, solid: Callable, support: Callable = Callable()) -> Dictionary:
	if not grounded: return no("player airborne")
	var hits: Variant = footprint.get("hits",null)
	var bounds: Variant = footprint.get("bounds",null)
	if not hits is Callable or not hits.is_valid() or not bounds is Rect2 or not bounds.has_area(): return no("unsupported coverage")
	if not support.is_valid(): support = solid
	var enemy_floor := floor_at(enemy.get_center().x,enemy.end.y,support)
	var player_floor := floor_at(player.get_center().x,player.end.y,support)
	if enemy_floor == -2147483648 or player_floor == -2147483648 or absi(enemy_floor-player_floor) > TILE: return no("different floor levels")
	var side := signi(player.get_center().x-enemy.get_center().x)
	if side == 0: return no("no horizontal separation")
	if (side>0 and player.position.x<enemy.end.x) or (side<0 and player.end.x>enemy.position.x): return no("player overlaps enemy")
	var tracer_size: Vector2 = bounds.size+Vector2.ONE*(2*TILE)
	var tracer := Rect2(Vector2(player.get_center())-tracer_size/2,tracer_size)
	if not tracer.has_point(Vector2(enemy.get_center())): return no("enemy outside candidate tracer")
	var front := enemy.end.x if side>0 else enemy.position.x-1
	var edge := floori(tracer.end.x) if side>0 else ceili(tracer.position.x)
	var distance := absi(edge-front)
	if distance > MAX_SCAN: return no("coverage exceeds scan budget")
	var wall := Rect2i()
	for step in distance+1:
		var probe := Rect2i(front+side*step,player_floor-WALL_HEIGHT,1,WALL_HEIGHT)
		if solid.call(probe):
			wall = probe
			break
	if not wall.has_area(): return no("no wall in first three rows")
	var face := wall.position.x if side>0 else wall.end.x
	if (side>0 and player.end.x>face) or (side<0 and player.position.x<face): return no("wall is not beyond player")
	if not tracer.has_point(Vector2(wall.position.x,player_floor-1)): return no("wall outside candidate tracer")
	var first := enemy.end.x if side>0 else face
	var last := face-player.size.x if side>0 else enemy.position.x-player.size.x
	if first>last: return no("no standing room")
	var checked := 0
	for x in range(first,last+1):
		var floor_y := floor_at(x+player.size.x/2,player_floor-TILE,support,2*TILE)
		if floor_y == -2147483648: return no("gap in floor corridor")
		var body := Rect2i(x,floor_y-player.size.y,player.size.x,player.size.y)
		if solid.call(body): continue  # only positions where the player can actually stand
		var target := Rect2i(body.position+damage.position-player.position,damage.size)
		if not hits.call(target): return no("uncovered standing position")
		checked += 1
	if checked == 0: return no("no clear standing positions")
	return {"cornered":true,"reason":"floor corridor covered","wall":wall,"tracer":tracer}
