extends RefCounted
const MAX_POINTS := 64
const CARDINAL := [[1, 0], [-1, 0], [0, 1], [0, -1]]
# These are room/encounter anchors, not movable bodies. Do not silently move story gates.
const ANCHORS := ["dead_skeleton","layer_passage","boat","rock_giant","trigger_zone", "pressure_plate","spawn", "respawn", "door", "house_door", "auto_walk", "camera_zone", "boss_gate", "ape_chase", "vent_plug"]

static func supports(data: Dictionary) -> bool:
	return data.t not in ANCHORS and not str(data.t).begins_with("boss_")

static func number(value, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high

static func vector(value) -> bool:
	return value is Array and value.size() == 2 and number(value[0], -1048576, 1048576) and number(value[1], -1048576, 1048576) and float(value[0]) == floorf(value[0]) and float(value[1]) == floorf(value[1])

static func validate(config, bounds := Vector2i(-1, -1)) -> String:
	if not config is Dictionary: return "Movement must be an object"
	if config.get("mode", "") not in ["surface", "path"]: return "Choose surface or path movement"
	if config.has("enabled") and not config.enabled is bool: return "Start moving must be a checkbox value"
	if not number(config.get("speed", null), 0, 100): return "Speed must be between 0 and 100 tiles/second"
	if not number(config.get("pause", 0), 0, 60): return "Pause must be between 0 and 60 seconds"
	if config.mode == "surface":
		if not config.get("sticky", false) is bool: return "Sticky must be a checkbox value"
		var direction = config.get("direction", [1, 0])
		var support = config.get("support", [0, 1])
		if direction not in CARDINAL or support not in CARDINAL: return "Direction and support must be cardinal"
		if Vector2(direction[0], direction[1]).dot(Vector2(support[0], support[1])) != 0: return "Direction must follow the attached surface"
	else:
		if not config.get("closed", false) is bool: return "Closed path must be a checkbox value"
		var points = config.get("points", null)
		if not points is Array or points.size() < 2 or points.size() > MAX_POINTS: return "A path needs 2 to 64 points"
		for i in points.size():
			if not vector(points[i]): return "Path points must contain two whole pixel coordinates"
			if bounds.x > 0 and (points[i][0] < 0 or points[i][1] < 0 or points[i][0] >= bounds.x or points[i][1] >= bounds.y): return "Keep path points inside the room"
			if i > 0 and points[i] == points[i - 1]: return "Adjacent path points must differ"
		if config.get("closed", false) and points[-1] == points[0]: return "Closed paths close automatically; omit the repeated first point"
	return ""
