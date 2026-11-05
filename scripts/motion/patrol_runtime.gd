extends RefCounted
const Settings := preload("res://scripts/motion/patrol_settings.gd")
const Path := preload("res://scripts/motion/path_patrol.gd")
const Surface := preload("res://scripts/motion/surface_patrol.gd")
var config: Dictionary
var path = null
var crawler := Surface.Crawler.new()
var remainder := 0.0
var fall := 0.0
var waiting := 0.0
var last_body: Vector2i
var support_query: Callable
var blocked_last_tick := false
var body: Rect2i

func _init(definition: Dictionary, initial: Rect2i, anchor: Vector2) -> void:
	config = definition.duplicate(true)
	body = initial
	last_body = initial.position
	if config.mode == "path":
		var offset := Vector2(initial.position) - anchor
		var route: Array = config.points.map(func(p): return Vector2(p[0], p[1]) + offset)
		path = Path.new(route, config.get("closed", false), float(config.speed) * 8, config.get("pause", 0), Vector2(initial.position))
	else:
		var direction: Array = config.get("direction", [1, 0])
		var support: Array = config.get("support", [0, 1])
		crawler.direction = Vector2i(direction[0], direction[1])
		crawler.support = Vector2i(support[0], support[1])

func advance(current: Rect2i, dt: float, blocked: Callable, moved: Callable, support_test: Callable = Callable()) -> void:
	body = current
	blocked_last_tick = false
	support_query = support_test if support_test.is_valid() else blocked
	if dt <= 0 or config.speed <= 0: return
	if path != null:
		if body.position != last_body: path.position = Vector2(body.position)  # resume after an attack without teleporting
		var steps := maxi(1, mini(1024, ceili(path.speed * dt)))
		for i in steps:  # preserve intermediate vertices and contact even at high speed
			var before: Array = path.state()
			var destination := Vector2i(path.advance(dt / steps).round())
			if not _toward(destination, blocked, moved):
				path.restore(before)
				path.position = Vector2(body.position)
				break

	else:
		_surface(dt, blocked, moved)
	last_body = body.position

func _toward(destination: Vector2i, blocked: Callable, moved: Callable) -> bool:
	for axis in 2:
		var distance := destination[axis] - body.position[axis]
		var step := Vector2i(signi(distance), 0) if axis == 0 else Vector2i(0, signi(distance))
		for i in mini(absi(distance), 1024):
			var next := Rect2i(body.position + step, body.size)
			if blocked.call(next):
				blocked_last_tick = true
				return false
			body = next
			moved.call(body)
	return true

func _surface(dt: float, blocked: Callable, moved: Callable) -> void:
	if waiting > 0:
		waiting = maxf(0, waiting - dt)
		return
	if not support_query.call(Rect2i(body.position + crawler.support, body.size)):
		crawler.support = Vector2i.DOWN
		if not support_query.call(Rect2i(body.position + crawler.support, body.size)):
			fall = minf(160, fall + 400 * dt)
			remainder += fall * dt
			var distance := int(remainder)
			remainder -= distance
			_toward(body.position + Vector2i(0, distance), blocked, moved)
			return
		if crawler.direction.y != 0: crawler.direction = Vector2i.RIGHT
	fall = 0
	if config.get("sticky", false):
		crawler.advance(body, float(config.speed) * 8 * dt, blocked, func(next):
			body = next
			moved.call(next), support_query)
		return
	remainder += float(config.speed) * 8 * dt
	var count := int(remainder)
	remainder -= count
	for i in count:
		var next := Rect2i(body.position + crawler.direction, body.size)
		var foot := next.get_center()
		for axis in 2:
			if crawler.direction[axis] != 0: foot[axis] = next.end[axis] - 1 if crawler.direction[axis] > 0 else next.position[axis]
			if crawler.support[axis] != 0: foot[axis] = next.end[axis] if crawler.support[axis] > 0 else next.position[axis] - 1
		if blocked.call(next) or not support_query.call(Rect2i(foot, Vector2i.ONE)):
			crawler.direction = -crawler.direction
			waiting = config.get("pause", 0)
			remainder = 0
			break
		body = next
		moved.call(body)
