extends RefCounted
const Settings := preload("res://scripts/interaction/trigger_settings.gd")
var config: Dictionary
var stage := "waiting"
var remaining := 0.0
var enabled := true
var starts := 0
var active_time := 0.0
var standard_wait := false

func _init(timing: Dictionary) -> void:
	config = Settings.cycle(timing)
	enabled = config.enabled
	remaining = config.offset
	advance(0)

func active() -> bool:
	return stage == "active" and config.active > 0

func extension() -> float:
	match stage:
		"active": return 1.0
		"extending": return 1.0 - remaining / float(config.extend) if config.extend > 0 else 1.0
		"retracting": return remaining / float(config.retract) if config.retract > 0 else 0.0
	return 0.0

func fire() -> bool:
	if stage != "waiting": return false
	enabled = true
	_begin()
	advance(0)
	return true

func disable() -> void:
	enabled = false
	stage = "waiting"
	remaining = 0
	active_time = 0
	standard_wait = false

func _begin() -> void:
	stage = "extending"
	remaining = config.extend
	standard_wait = false
	starts += 1

func advance(dt: float) -> void:
	active_time = 0
	var elapsed := maxf(0, dt)
	for iteration in 64:
		if stage == "waiting" and standard_wait and enabled and config.interval > 0 and elapsed >= config.interval:
			var periods := floori(elapsed / config.interval)
			elapsed -= periods * config.interval
			starts += periods
			active_time += periods * float(config.active)
		if remaining > 0:
			if elapsed <= 0: break
			var used := minf(remaining, elapsed)
			if stage == "active": active_time += used
			remaining = maxf(0, remaining - used)
			elapsed = maxf(0, elapsed - used)
			if remaining > 0.00000001: break
		match stage:
			"waiting":
				if not enabled or config.interval == 0: break
				_begin()
			"extending":
				stage = "active"
				remaining = config.active
			"active":
				stage = "retracting"
				remaining = config.retract
			"retracting":
				stage = "waiting"
				remaining = maxf(0, config.interval - config.extend - config.active - config.retract)
				standard_wait = true
