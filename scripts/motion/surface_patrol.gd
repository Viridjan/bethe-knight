extends RefCounted
# Collision adapters retain ownership of their body, contact rules and support queries.
# Each controller belongs to one mover; fractional displacement is never shared.
class Floor extends RefCounted:
	var remainder := 0.0
	func advance(body: Rect2i, distance: float, facing: int, supported: Callable, blocked: Callable, moved: Callable) -> bool:
		remainder += distance
		var count := int(remainder)
		remainder -= count
		for i in count:
			var next := Rect2i(body.position + Vector2i(facing, 0), body.size)
			if not supported.call() or blocked.call(next):
				remainder = 0
				return true
			body = next
			moved.call(body)
		return false

class Crawler extends RefCounted:
	var remainder := 0.0
	var direction := Vector2i.RIGHT
	var support := Vector2i.DOWN
	func advance(body: Rect2i, distance: float, blocked: Callable, moved: Callable, support_query: Callable = Callable()) -> void:
		if not support_query.is_valid(): support_query = blocked
		remainder += distance
		while remainder >= 1:
			remainder -= 1
			var next := Rect2i(body.position + direction, body.size)
			if blocked.call(next):
				var turn := -support
				support = direction
				direction = turn
				continue
			body = next
			moved.call(body)
			if not support_query.call(Rect2i(body.position + support, body.size)):
				var turn := support
				support = -direction
				direction = turn
				var around := Rect2i(body.position + direction, body.size)
				if not blocked.call(around):
					body = around
					moved.call(body)
