extends RefCounted
# Pure layout helpers: whole groups keep their offsets; only compatible physical openings snap.
const Adventure := preload("res://scripts/adventure.gd")

static func openings(level: Dictionary) -> Dictionary:
	var result := {}
	for side in ["left", "right", "top", "bottom"]:
		var vertical: bool = side in ["left", "right"]
		var length: int = level.h if vertical else level.w
		var runs := []
		var start := -1
		for i in length + 1:
			var open := false
			if i < length:
				var x: int = (0 if side == "left" else int(level.w) - 1) if vertical else i
				var y: int = i if vertical else (0 if side == "top" else int(level.h) - 1)
				open = level.tiles[y].unicode_at(x) != 49
			if open and start < 0: start = i
			if not open and start >= 0:
				if i - start >= (2 if vertical else 1): runs.append(Vector2i(start, i))
				start = -1
		result[side] = runs
	return result

static func sockets(world: Dictionary) -> Dictionary:
	var result := {}
	for name in world.rooms: result[name] = openings(world.rooms[name].level)
	return result

static func _overlap(start_a: int, end_a: int, start_b: int, end_b: int) -> int:
	return maxi(0, mini(end_a, end_b) - maxi(start_a, start_b))

static func _clear(world: Dictionary, origins: Dictionary, delta: Vector2i) -> bool:
	for moving in origins:
		var candidate: Dictionary = world.rooms[moving].duplicate()
		candidate.pos = origins[moving] + delta
		for fixed in world.rooms:
			if origins.has(fixed): continue
			var fixed_room: Dictionary = world.rooms[fixed]
			var candidate_rect := Rect2i(candidate.pos, Vector2i(candidate.level.w, candidate.level.h))
			var fixed_rect := Rect2i(fixed_room.pos, Vector2i(fixed_room.level.w, fixed_room.level.h))
			if candidate_rect.intersects(fixed_rect) and not Adventure.overlaps({"rooms": {"moving": candidate, "fixed": fixed_room}}).is_empty(): return false
	return true

static func snap(world: Dictionary, origins: Dictionary, requested: Vector2i, threshold: float, ports: Dictionary) -> Dictionary:
	var best := {"delta": requested, "pair": []}
	var best_distance := threshold * threshold + 0.0001
	for moving in origins:
		var room: Dictionary = world.rooms[moving]
		var position: Vector2i = origins[moving] + requested
		for fixed in world.rooms:
			if origins.has(fixed): continue
			var other: Dictionary = world.rooms[fixed]
			for pair in [["left", "right"], ["right", "left"], ["top", "bottom"], ["bottom", "top"]]:
				var vertical: bool = pair[0] in ["left", "right"]
				var axis := 0 if vertical else 1
				var tangent := 1 - axis
				var clearance := 2 if vertical else 1
				var size := Vector2i(room.level.w, room.level.h)
				var other_size := Vector2i(other.level.w, other.level.h)
				var desired: int = other.pos[axis] + (other_size[axis] if pair[0] in ["left", "top"] else -size[axis])
				var normal_shift := desired - position[axis]
				if absf(normal_shift) > threshold: continue
				for run in ports[moving][pair[0]]:
					for other_run in ports[fixed][pair[1]]:
						var start: int = position[tangent] + run.x
						var end: int = position[tangent] + run.y
						var fixed_start: int = other.pos[tangent] + other_run.x
						var fixed_end: int = other.pos[tangent] + other_run.y
						var shifts: Array = []
						for offset in [fixed_start - start, fixed_end - end]:
							if absf(offset) <= threshold and _overlap(start + offset, end + offset, fixed_start, fixed_end) >= clearance and offset not in shifts: shifts.append(offset)
						if shifts.is_empty() and _overlap(start, end, fixed_start, fixed_end) >= clearance: shifts.append(0)
						for offset in shifts:
							var correction := Vector2i.ZERO
							correction[axis] = normal_shift
							correction[tangent] = offset
							var distance := Vector2(correction).length_squared()
							if distance > threshold * threshold or distance >= best_distance: continue
							var delta := requested + correction
							if not _clear(world, origins, delta): continue
							best_distance = distance
							best = {"delta": delta, "pair": [moving, fixed]}
	return best
