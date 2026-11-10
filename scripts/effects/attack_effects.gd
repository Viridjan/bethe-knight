extends RefCounted
## Detached combat effects. The encounter supplies collision queries and consumes one-shot events.
## No boss decisions, save flags, or player state live here. Positions/sizes are pixels.

class Projectile extends RefCounted:
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var size := Vector2i(19, 6)
	var wait := 0.0
	var gravity := 200.0
	var terminal_speed := INF
	var split := false
	var child_velocity := Vector2(90, -150)
	var child_gravity := 200.0
	var child_terminal_speed := 140.0
	var impact_effect := "ape_spikes"
	func box() -> Rect2i:
		return Rect2i(Vector2i(position), size)

class Area extends RefCounted:
	var rect := Rect2i()
	var remaining := 0.0
	func active() -> bool:
		return remaining > 0.0
	func advance(dt: float) -> void:
		remaining = maxf(0.0, remaining - dt)
	func hits(box: Rect2i) -> bool:
		return active() and rect.intersects(box)

static func circle_hits(center: Vector2, radius: float, box: Rect2i) -> bool:
	var nearest := center.clamp(Vector2(box.position), Vector2(box.end))
	return box.has_area() and center.distance_squared_to(nearest) < radius * radius

var projectiles: Array = []

func spawn(at: Vector2, velocity: Vector2, settings: Dictionary) -> Projectile:
	var p := Projectile.new()
	p.position = at
	p.velocity = velocity
	p.size = settings.get("size", Vector2i(19, 6))
	p.wait = float(settings.get("wait", 0.0))
	p.gravity = float(settings.get("gravity", 200.0))
	p.terminal_speed = float(settings.get("terminal_speed", INF))
	p.split = bool(settings.get("split", false))
	p.child_velocity = settings.get("child_velocity", Vector2(90, -150))
	p.child_gravity = float(settings.get("child_gravity", 200.0))
	p.child_terminal_speed = float(settings.get("child_terminal_speed", 140.0))
	p.impact_effect = str(settings.get("impact_effect", "ape_spikes"))
	projectiles.append(p)
	return p

func clear() -> void:
	projectiles.clear()

# A splitting log lands: two ordinary logs hop outwards from its last free position; the parent leaves no spikes.
func _split(p: Projectile, solid: Callable, bounds: Rect2i, events: Array) -> void:
	events.append({"event": "split", "box": p.box()})
	for side in [-1.0, 1.0]:
		var child_position := p.position + Vector2(side * p.size.x, 0)
		var child_box := Rect2i(Vector2i(child_position), p.size)
		if not bounds.grow(64).intersects(child_box) or solid.call(child_box) != null:
			events.append({"event": "split_blocked", "box": child_box, "effect": p.impact_effect})
			continue
		spawn(child_position, Vector2(side * p.child_velocity.x, p.child_velocity.y), {
			"gravity": p.child_gravity, "size": p.size, "terminal_speed": p.child_terminal_speed, "impact_effect": p.impact_effect})

# Return events after iteration. New children start moving on the following tick.
# Sweeping each axis in <=1px steps prevents fast logs tunnelling through floors/player boxes.
func update(dt: float, solid: Callable, player_box: Rect2i, bounds: Rect2i, trunk_box: Rect2i = Rect2i()) -> Array:
	var events: Array = []
	for i in range(projectiles.size() - 1, -1, -1):
		var p: Projectile = projectiles[i]
		var elapsed := dt
		if p.wait > 0:
			elapsed = maxf(0.0, dt - p.wait)
			p.wait = maxf(0.0, p.wait - dt)
			if elapsed <= 0: continue
		p.velocity.y = minf(p.velocity.y + p.gravity * elapsed, p.terminal_speed)
		var displacement := p.velocity * elapsed
		var steps := maxi(1, ceili(maxf(absf(displacement.x), absf(displacement.y))))
		var increment := displacement / steps
		var gone := false
		for step in steps:
			for axis in [0, 1]:
				var next := p.position
				next[axis] += increment[axis]
				var box := Rect2i(Vector2i(next), p.size)
				if player_box.has_area() and box.intersects(player_box):
					events.append({"event": "player_hit", "box": box, "direction": p.velocity.normalized()})
					gone = true
				elif trunk_box.has_area() and box.intersects(trunk_box):
					events.append({"event": "trunk_hit", "box": box})
					gone = true
				elif solid.call(box) != null:
					if axis == 1 and increment.y > 0:
						if p.split: _split(p, solid, bounds, events)
						else: events.append({"event": "floor_impact", "box": box, "effect": p.impact_effect})
					gone = true
				else:
					p.position = next
				if gone: break
			if gone: break
		if not bounds.grow(64).intersects(p.box()): gone = true
		if gone: projectiles.remove_at(i)
	return events
