extends RefCounted
## Shared stamina policy and the deliberately tiny, horizontal unarmed hitbox.
const ATTEMPT_COST := 2
const ENEMY_HIT_COST := 4  # once on the first accepted enemy hit, never on walls/shields
const PUNCH_TIME := 0.12
const PUNCH_ACTIVE_FROM := 0.08
const PUNCH_ACTIVE_TO := 0.02
const PUNCH_REACH := 3
const PUNCH_HEIGHT := 3

static func fist(body: Rect2i, facing: int) -> Rect2i:
	return Rect2i(body.end.x if facing>0 else body.position.x-PUNCH_REACH,
		body.get_center().y-PUNCH_HEIGHT/2,PUNCH_REACH,PUNCH_HEIGHT)

static func clear_contact(world, origin: Vector2, target: Rect2i, object = null) -> bool:
	var point := Vector2(clampf(origin.x,target.position.x,target.end.x),clampf(origin.y,target.position.y,target.end.y))
	var steps := maxi(1,ceili(origin.distance_to(point)))
	for i in range(1,steps):
		if world.collide_solid(Rect2i(Vector2i(origin.lerp(point,float(i)/steps)),Vector2i.ONE),object) != null:
			return false
	return true
