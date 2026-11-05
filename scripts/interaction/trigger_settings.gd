extends RefCounted
const SOURCES := ["trigger_zone", "pressure_plate"]
const TRAPS := ["trap_spikes"]
const MAX_LINKS := 32
const CYCLE := {"interval": 4.0, "active": 1.0, "extend": 0.25, "retract": 0.25, "offset": 0.0, "enabled": true, "direction": "up"}

static func number(value, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high

static func id_valid(value) -> bool:
	return value is String and value.length() <= 64 and value.is_valid_identifier()

static func cycle(config) -> Dictionary:
	var out := CYCLE.duplicate()
	if config is Dictionary: out.merge(config, true)
	return out

static func validate_cycle(config) -> String:
	if not config is Dictionary: return "Trap timing must be an object"
	for field in config:
		if field not in CYCLE: return "Unsupported trap setting: " + str(field)
	var timing := cycle(config)
	for field in ["interval", "offset"]:
		if not number(timing[field], 0, 3600): return field + " must be between 0 and 3600 seconds"
	for field in ["active", "extend", "retract"]:
		if not number(timing[field], 0, 60): return field + " must be between 0 and 60 seconds"
	if not timing.enabled is bool: return "Trap start enabled must be a checkbox value"
	if timing.direction not in ["up", "down", "left", "right"]: return "Choose a cardinal trap direction"
	if timing.interval > 0 and (timing.interval < 0.05 or timing.interval + 0.000001 < timing.active + timing.extend + timing.retract): return "Interval must cover deployment, active time and retraction (or be zero for trigger-only)"
	return ""

static func actions_for(data: Dictionary) -> Array:
	var result: Array = ["activate", "deactivate", "toggle"] if data.t in TRAPS else []
	if data.has("motion"): result.append_array(["start_motion", "stop_motion", "toggle_motion"])
	return result

static func validate_level(entities: Array) -> String:
	var by_id := {}
	for entity in entities:
		if entity.has("object_id"):
			if not id_valid(entity.object_id): return "Object IDs must be identifiers of at most 64 characters"
			if by_id.has(entity.object_id): return "Duplicate object ID: " + entity.object_id
			by_id[entity.object_id] = entity
		if entity.t in TRAPS:
			var error := validate_cycle(entity.get("trap", {}))
			if not error.is_empty(): return error
	for source in entities:
		if source.t not in SOURCES: continue
		var config = source.get("trigger", {})
		if not config is Dictionary: return "Trigger settings must be an object"
		for field in config:
			if field not in ["once", "cancel_on_exit", "cooldown", "ability", "on_enter", "on_exit"]: return "Unsupported trigger setting: " + str(field)
		for key in ["once", "cancel_on_exit"]:
			if config.has(key) and not config[key] is bool: return key + " must be a checkbox value"
		if not number(config.get("cooldown", 0), 0, 3600): return "Cooldown must be between 0 and 3600 seconds"
		var ability = config.get("ability", "")
		if not ability is String or (ability != "" and ability not in preload("res://scripts/adventure.gd").ABILITIES): return "Unknown required ability"
		for edge in ["on_enter", "on_exit"]:
			var links = config.get(edge, [])
			if not links is Array or links.size() > MAX_LINKS: return "A trigger supports at most 32 links per edge"
			if not links.is_empty() and not source.has("object_id"): return "Assign a stable object ID to the trigger"
			for link in links:
				if not link is Dictionary or not by_id.has(link.get("target", "")): return "Trigger target does not exist: " + str(link.get("target", "")) if link is Dictionary else "Trigger link must be an object"
				if link.get("action", "") not in actions_for(by_id[link.target]): return "Target does not support action: " + str(link.get("action", ""))
				if not number(link.get("delay", 0), 0, 60): return "Link delay must be between 0 and 60 seconds"
	return ""
