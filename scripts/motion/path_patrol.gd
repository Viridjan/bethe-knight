extends RefCounted
# A distance/time based route cursor. Collision adapters commit or restore its state.
var points: Array
var closed: bool
var speed: float
var pause: float
var position: Vector2
var target := 0
var direction := 1
var waiting := 0.0

func _init(route: Array, loop: bool, pixels_per_second: float, pause_seconds: float, start: Vector2) -> void:
	points = route.duplicate()
	closed = loop
	speed = pixels_per_second
	pause = pause_seconds
	position = start
	if position.is_equal_approx(points[0]): target = 1

func state() -> Array:
	return [position, target, direction, waiting]

func restore(saved: Array) -> void:
	position = saved[0]
	target = saved[1]
	direction = saved[2]
	waiting = saved[3]

func advance(dt: float) -> Vector2:
	var remaining := maxf(0, dt)
	if speed <= 0: return position
	for iteration in 256:  # bounded even for deliberately enormous preview steps
		if remaining <= 0: break
		if waiting > 0:
			var elapsed := minf(waiting, remaining)
			waiting -= elapsed
			remaining -= elapsed
			if remaining <= 0: break
		var offset: Vector2 = points[target] - position
		var travel := offset.length() / speed
		if travel > remaining:
			position += offset.normalized() * speed * remaining
			break
		position = points[target]
		remaining = maxf(0, remaining - travel)
		waiting = pause
		if closed:
			target = (target + 1) % points.size()
		else:
			if target == points.size() - 1: direction = -1
			elif target == 0: direction = 1
			target += direction
	return position
