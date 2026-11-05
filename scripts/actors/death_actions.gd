extends RefCounted
# Pure death-spawn definitions. The actor owns the once-only death transition;
# World owns queued spawning, so children never enter the live entity iteration.
static func brood(data: Dictionary, center: Vector2, family: String, has_type: Callable, blocked: Callable) -> Array:
	var children: Array = []
	for side in [-1, 1]:
		var child: Dictionary
		if data.t == "enemy_monster":
			child = data.duplicate(true)
			child.erase("object_id")
			child.traits = data.traits.filter(func(t): return t != "brood")
		else:
			var kind := family + "_swift" if has_type.call(family + "_swift") else family
			child = {"t": kind}
		var box := Rect2i(Vector2i(center) + Vector2i(side * 4 - 2, -2), Vector2i(4, 4))
		# Keep the library monster's previous authored offsets; ordinary families
		# retain their existing obstacle fallback until shared placement is designed.
		var at := box.position
		if data.t != "enemy_monster" and blocked.call(box.grow(2)):
			at = Vector2i(center) - Vector2i(2, 2)
		child.merge({"x": at.x, "y": at.y, "facing": side, "brood_child": true}, true)
		children.append(child)
	return children
