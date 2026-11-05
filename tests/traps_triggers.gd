extends "res://tests/test_runner.gd"

class Target extends RefCounted:
	var d: Dictionary
	var events := []
	func _init(data: Dictionary) -> void: d = data
	func apply_trigger(action: String) -> void: events.append(action)

func _ready() -> void:
	if not ResourceLoader.exists("res://scripts/interaction/trap_cycle.gd"):
		check(false, "Shared trap cycle exists")
		Game.quit_game(fails)
		return
	var cycle_script = load("res://scripts/interaction/trap_cycle.gd")
	var cycle = cycle_script.new({"interval": 2.0, "active": 0.5, "extend": 0.25, "retract": 0.25, "offset": 0.0})
	check(cycle.stage == "extending" and not cycle.active(), "Automatic trap begins with a safe deployment")
	cycle.advance(0.25)
	check(cycle.active(), "Trap becomes damaging only when fully deployed")
	cycle.advance(0.5)
	check(cycle.stage == "retracting" and not cycle.active(), "Active duration ends before safe retraction")
	cycle.advance(1.25)
	check(cycle.stage == "extending" and cycle.starts == 2, "Interval is measured start-to-start")
	var manual = cycle_script.new({"interval": 0.0, "active": 1.0, "extend": 0.0, "retract": 0.0})
	manual.advance(20)
	check(manual.stage == "waiting" and manual.fire(), "Zero interval waits for a trigger")
	check(manual.active() and not manual.fire(), "A running trap ignores retriggers")
	manual.disable()
	check(not manual.active() and not manual.enabled, "Deactivation cancels damage immediately")
	var router_script = load("res://scripts/interaction/trigger_router.gd")
	var mover := Target.new({"t": "jumpthru", "object_id": "mover", "motion": {"mode": "path", "speed": 2.0, "points": [[0, 0], [16, 0]]}})
	var source := Target.new({"t": "pressure_plate", "object_id": "plate", "trigger": {"once": true, "on_enter": [{"target": "mover", "action": "start_motion", "delay": 1.0}], "on_exit": [{"target": "mover", "action": "stop_motion", "delay": 0.0}]}})
	var router = router_script.new([source, mover], func(_ability): return true)
	router.enter("plate")
	router.advance(0.5)
	check(mover.events.is_empty(), "Delayed commands do not execute early")
	router.exit("plate")
	router.advance(1.0)
	check(mover.events == ["stop_motion"], "A released plate cancels its delayed start but still releases a once-only activation")
	router.enter("plate")
	router.advance(2.0)
	check(mover.events == ["stop_motion"], "Once-per-visit sources cannot reactivate")
	check_runtime()
	check_conditions_and_motion()
	await check_editor()
	Game.adv = {}
	if w: w.queue_free()
	await get_tree().process_frame
	print("TRAPS TRIGGERS: %d failure(s)" % fails)
	Game.quit_game(fails)

func check_runtime() -> void:
	Game.adv = {}
	var trap_config := {"interval": 0.0, "active": 0.5, "extend": 0.1, "retract": 0.1}
	make_world([{"t": "trap_spikes", "x": 200, "y": 208, "w": 24, "h": 16, "object_id": "trap", "trap": trap_config}, {"t": "trigger_zone", "x": 80, "y": 192, "w": 24, "h": 32, "object_id": "zone", "trigger": {"on_enter": [{"target": "trap", "action": "activate", "delay": 0.0}]}}])
	var trap = w.ents.filter(func(e): return e.d.t == "trap_spikes")[0]
	p().pos = Vector2(90, 216)
	for i in 2:
		for entity in w.ents: w._tick_entity(entity, DT)
		w.trigger_router.advance(DT)
	check(trap.cycle.stage == "extending", "Actual zone queues activation of the linked trap")
	for i in 20:
		for entity in w.ents: w._tick_entity(entity, DT)
		w.trigger_router.advance(DT)
	check(trap.cycle.starts == 1, "Standing in a zone does not activate every frame")
	p().pos = Vector2(212, 216)
	trap.touch(p())
	check(p().dead, "A fully active trap uses the real damage contact")
	var valid := Game.new_level("Links", 60, 30)
	valid.entities.append({"t": "trap_spikes", "x": 200, "y": 208, "object_id": "trap", "trap": trap_config.duplicate()})
	valid.entities.append({"t": "trigger_zone", "x": 80, "y": 192, "object_id": "zone", "trigger": {"on_enter": [{"target": "missing", "action": "activate"}]}})
	check(Game.validate_level(valid).is_empty(), "Dangling target links are rejected")
	valid.entities[-1].trigger.on_enter[0].target = "trap"
	check(not Game.validate_level(valid.duplicate(true)).is_empty(), "Valid typed target links load")
	valid.entities[-1].trigger.on_enter[0].action = "start_motion"
	check(Game.validate_level(valid).is_empty(), "Actions unsupported by the target are rejected")
	Game.adv = {}

func check_conditions_and_motion() -> void:
	var cycle_script = load("res://scripts/interaction/trap_cycle.gd")
	var fast = cycle_script.new({"interval": 2.0, "active": 0.5, "extend": 0.25, "retract": 0.25})
	fast.advance(1000)
	check(fast.starts == 501 and fast.stage == "extending", "Large timing steps preserve periodic phase without an unbounded loop")
	var zero = cycle_script.new({"interval": 0.0, "active": 0.0, "extend": 0.0, "retract": 0.0})
	check(zero.fire() and zero.stage == "waiting" and not zero.active(), "All-zero trigger-only animation settles safely")
	var router_script = load("res://scripts/interaction/trigger_router.gd")
	var mover := Target.new({"t": "jumpthru", "object_id": "target", "motion": {"mode": "path"}})
	var source := Target.new({"t": "trigger_zone", "object_id": "source", "trigger": {"ability": "dash", "cooldown": 1.0, "on_enter": [{"target": "target", "action": "start_motion"}], "on_exit": [{"target": "target", "action": "stop_motion"}]}})
	var unlocked := [false]
	var router = router_script.new([source, mover], func(_ability): return unlocked[0])
	check(not router.enter("source"), "Missing required ability rejects entry without consuming activation")
	unlocked[0] = true
	check(router.enter("source"), "An eligible later entry can activate")
	router.advance(0)
	router.exit("source")
	check(not router.enter("source"), "Cooldown blocks a fresh entry")
	router.advance(0)
	check(mover.events == ["start_motion", "stop_motion"], "Cooldown never blocks the matching exit release")
	router.advance(1)
	check(router.enter("source"), "Cooldown expires in simulation time")
	make_world([{"t": "pressure_plate", "x": 80, "y": 216, "w": 24, "h": 8, "object_id": "plate", "trigger": {"on_enter": [{"target": "platform", "action": "start_motion"}], "on_exit": [{"target": "platform", "action": "stop_motion"}]}}, {"t": "jumpthru", "x": 200, "y": 160, "w": 24, "h": 8, "object_id": "platform", "motion": {"mode": "path", "enabled": false, "speed": 2.0, "points": [[200, 160], [240, 160]]}}, {"t": "trap_spikes", "x": 280, "y": 208}])
	var plate = w.ents.filter(func(e): return e.d.t == "pressure_plate")[0]
	var platform = w.ents.filter(func(e): return e.d.t == "jumpthru")[0]
	w._tick_entity(platform, 1.0)
	check(platform.rect.position.x == 200, "A disabled mover waits for a trigger")
	p().pos = Vector2(90, 224)
	p().on_ground = true
	w._tick_entity(plate, DT)
	w.trigger_router.advance(0)
	w._tick_entity(platform, 1.0)
	check(platform.rect.position.x == 216, "A real pressure plate starts authored movement")
	p().pos.x = 140
	w._tick_entity(plate, DT)
	w.trigger_router.advance(0)
	w._tick_entity(platform, 1.0)
	check(platform.rect.position.x == 216 and platform.lift == Vector2.ZERO, "Releasing a plate pauses the mover without teleporting")
	var trap = w.ents.filter(func(e): return e.d.t == "trap_spikes")[0]
	var remaining: float = trap.cycle.remaining
	var clock: float = w.trigger_router.clock
	w.paused = true
	for i in 120: w._physics_process(DT)
	check(trap.cycle.remaining == remaining and w.trigger_router.clock == clock, "Paused worlds freeze trap cycles and delayed command time")
	w.paused = false

func check_editor() -> void:
	Game.editor_level = Game.new_level("Trigger authoring", 60, 30)
	Game.editor_return = "menu"
	var editor = load("res://scripts/editor.gd").new()
	add_child(editor)
	editor.set_process(false)
	editor.tool = "trap_spikes"
	editor._place_rect(Vector2i(25, 26), Vector2i(27, 27))
	editor.tool = "trigger_zone"
	editor._place_rect(Vector2i(10, 24), Vector2i(12, 27))
	check(editor.level.entities[1].has("object_id") and editor.level.entities[2].has("object_id"), "Placed traps and triggers receive stable IDs")
	editor._select_trigger(2)
	editor.trigger_panel.link_edge = "on_enter"
	editor.trigger_panel.link_target(1)
	check(editor.level.entities[2].trigger.on_enter[0].target == editor.level.entities[1].object_id, "Editor creates a real stable-ID connection")
	var linked: Dictionary = editor.level.duplicate(true)
	editor._undo()
	check(not editor.level.entities[2].get("trigger", {}).has("on_enter"), "Link creation is undoable")
	editor._set_level(linked)
	editor.sel = Rect2i(0, 0, 40, 28)
	editor._copy(false)
	editor._paste(Vector2i.ZERO)
	var ids: Array = editor.level.entities.filter(func(e): return e.has("object_id")).map(func(e): return e.object_id)
	check(ids.size() == 4 and ids.size() == _unique(ids).size(), "Pasted linked objects receive fresh IDs")
	var pasted: Array = editor.level.entities.filter(func(e): return e.t == "trigger_zone")
	check(pasted[0].trigger.on_enter[0].target != pasted[1].trigger.on_enter[0].target, "Pasted links point to their copied target")
	editor.queue_free()
	Game.editor_level = {}
	await get_tree().process_frame

func _unique(values: Array) -> Array:
	var seen := {}
	for value in values: seen[value] = true
	return seen.keys()
