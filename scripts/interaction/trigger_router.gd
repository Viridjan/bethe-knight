extends RefCounted
# Room-owned typed command queue. Sources emit edges; no graph recursion or polling rolls.
const Settings := preload("res://scripts/interaction/trigger_settings.gd")
const MAX_PENDING := 512
var objects := {}
var states := {}
var pending: Array = []
var serial := 0
var clock := 0.0
var ability_query: Callable
var last_error := ""

func _init(entities: Array, abilities: Callable) -> void:
	ability_query = abilities
	for entity in entities: register_entity(entity)

func register_entity(entity) -> void:
	var id: String = entity.d.get("object_id", "")
	if id.is_empty(): return
	if objects.has(id) and objects[id] != entity:
		last_error = "Duplicate runtime object ID: " + id
		return
	objects[id] = entity
	if entity.d.t in Settings.SOURCES and not states.has(id):
		states[id] = {"latched": false, "used": false, "ready": 0.0, "epoch": 0}

func enter(id: String) -> bool:
	if not states.has(id): return false
	var config: Dictionary = objects[id].d.get("trigger", {})
	var state: Dictionary = states[id]
	if state.latched or (config.get("once", false) and state.used) or clock < state.ready: return false
	var ability: String = config.get("ability", "")
	if ability != "" and not ability_query.call(ability): return false
	state.epoch += 1
	state.latched = true
	state.used = true
	state.ready = clock + float(config.get("cooldown", 0))
	_schedule(id, "on_enter", config)
	return true

func exit(id: String) -> void:
	if not states.has(id) or not states[id].latched: return
	states[id].latched = false
	_schedule(id, "on_exit", objects[id].d.get("trigger", {}))

func _schedule(id: String, edge: String, config: Dictionary) -> void:
	for link in config.get(edge, []):
		if pending.size() >= MAX_PENDING:
			last_error = "Trigger command limit reached"
			return
		serial += 1
		pending.append({"serial": serial, "source": id, "edge": edge, "epoch": states[id].epoch, "target": link.target, "action": link.action, "due": clock + float(link.get("delay", 0))})

func advance(dt: float) -> void:
	clock += maxf(0, dt)
	var due := []
	var future := []
	for command in pending:
		if command.due <= clock + 0.00000001: due.append(command)
		else: future.append(command)
	pending = future
	due.sort_custom(func(a, b): return a.due < b.due or (a.due == b.due and a.serial < b.serial))
	for command in due:
		if not states.has(command.source) or command.epoch != states[command.source].epoch: continue
		var source = objects[command.source]
		var config: Dictionary = source.d.get("trigger", {})
		if command.edge == "on_enter" and config.get("cancel_on_exit", source.d.t == "pressure_plate") and not states[command.source].latched: continue
		if objects.has(command.target): objects[command.target].apply_trigger(command.action)
