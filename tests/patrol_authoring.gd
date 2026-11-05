extends "res://tests/test_runner.gd"

func _ready() -> void:
	if not ResourceLoader.exists("res://scripts/motion/patrol_runtime.gd"):
		check(false, "Authorable patrol runtime exists")
		Game.quit_game(fails)
		return
	Game.adv = {}
	var path_script = load("res://scripts/motion/path_patrol.gd")
	var path = path_script.new([Vector2(0, 0), Vector2(10, 0)], false, 10.0, 0.0, Vector2.ZERO)
	check(path.advance(1.5).is_equal_approx(Vector2(5, 0)), "Open paths reverse and consume remaining travel time")
	path = path_script.new([Vector2.ZERO, Vector2(10, 0), Vector2(10, 10)], true, 10.0, 0.0, Vector2.ZERO)
	check(path.advance(2).is_equal_approx(Vector2(10, 10)) and path.advance(0.5).x < 10, "Closed paths traverse the closing segment")
	path = path_script.new([Vector2.ZERO, Vector2(10, 0)], false, 10.0, 0.5, Vector2.ZERO)
	check(path.advance(1.25).is_equal_approx(Vector2(10, 0)) and path.advance(0.5).is_equal_approx(Vector2(7.5, 0)), "Waypoint pauses account for elapsed time exactly")
	var d := Game.new_level("Patrol", 60, 30)
	var motion := {"mode": "path", "speed": 3.0, "closed": false, "pause": 0.0, "points": [[80, 160], [160, 160]]}
	d.entities.append({"t": "jumpthru", "x": 80, "y": 160, "w": 24, "h": 8, "motion": motion})
	check(not Game.validate_level(d.duplicate(true)).is_empty(), "Valid motion survives room validation")
	var broken := d.duplicate(true)
	broken.entities[-1].motion.points[1] = [80, 160]
	check(Game.validate_level(broken).is_empty(), "Duplicate path points are rejected")
	broken = d.duplicate(true)
	broken.entities[-1].motion.speed = NAN
	check(Game.validate_level(broken).is_empty(), "Invalid motion speed is rejected")
	broken = d.duplicate(true)
	broken.entities[0].motion = motion.duplicate(true)
	check(Game.validate_level(broken).is_empty(), "Room spawn anchors reject unsupported motion instead of silently ignoring it")

	check_runtime(motion)
	check_surface_and_solid()
	await check_editor(d)
	Game.adv = {}
	if w: w.queue_free()
	await get_tree().process_frame
	print("PATROL AUTHORING: %d failure(s)" % fails)
	Game.quit_game(fails)

func check_runtime(motion: Dictionary) -> void:
	make_world([{"t": "jumpthru", "x": 80, "y": 160, "w": 24, "h": 8, "motion": motion.duplicate(true)}, {"t": "enemy_mosstrot", "x": 240, "y": 216, "motion": {"mode": "surface", "speed": 2.0, "sticky": false, "direction": [1, 0], "support": [0, 1]}}])
	var platform = w.ents.filter(func(e): return e.d.t == "jumpthru")[0]
	p().pos = Vector2(90, platform.rect.position.y)
	p().on_ground = true
	var before: Vector2 = p().pos
	for i in 120: w._tick_entity(platform, DT)
	check(platform.rect.position.x == 128 and is_equal_approx(p().pos.x, before.x + 48), "A moving one-way platform carries its rider")
	check(w.collide_jumpthru(platform.rect) == platform and w.collide_jumpthru(Rect2i(80, 160, 8, 8)) == null, "Moving platforms update their collision index")
	var enemy = w.ents.filter(func(e): return e.d.t == "enemy_mosstrot")[0]
	for i in 60: w._tick_entity(enemy, DT)
	check(enemy.rect.position.x == 256, "Authored enemy patrol replaces native speed without double movement")
	var attacker = E.make(w, {"t": "enemy_hornback", "x": 320, "y": 214, "motion": {"mode": "path", "speed": 3.0, "closed": false, "points": [[320, 214], [360, 214]]}})
	w._register(attacker)
	attacker.phase = "windup"
	attacker.timer = 10
	w._tick_entity(attacker, DT)
	check(attacker.rect.position.x == 320, "An attack wind-up pauses its authored route")
	attacker.phase = "idle"
	attacker.rect.position.x += 12
	w._tick_entity(attacker, DT)
	check(absi(attacker.rect.position.x - 332) <= 1, "A route resumes after external displacement without teleporting")
	var pickup = E.make(w, {"t": "refill", "x": 200, "y": 176, "motion": {"mode": "path", "speed": 2.0, "points": [[200, 176], [240, 176]]}})
	w._register(pickup)
	var pickup_start: Vector2i = pickup.rect.position
	for i in 60: w._tick_entity(pickup, DT)
	check(pickup.rect.position == pickup_start + Vector2i(16, 0), "Pickup patrol preserves its collider-to-anchor offset")
	var prop = E.make(w, {"t": "island_prop", "x": 80, "y": 96, "motion": {"mode": "path", "speed": 2.0, "points": [[80, 96], [120, 96]]}})
	w._register(prop)
	for i in 60: w._tick_entity(prop, DT)
	check(prop.rect.position.x == 96, "Non-colliding decorations can use the same route controller")
	var moving_spikes = E.make(w, {"t": "spikes_up", "x": 200, "y": 210, "motion": {"mode": "path", "speed": 10.0, "points": [[200, 210], [240, 210]]}})
	w._register(moving_spikes)
	p().pos = Vector2(220, 218)
	p().speed = Vector2.ZERO
	for i in 30: w._tick_entity(moving_spikes, DT)
	check(p().dead and w.deaths == 1, "Moving hazards detect player contact during their travel")
	var wall_path := {"mode": "path", "speed": 20.0, "closed": false, "pause": 0.0, "points": [[448, 160], [479, 160]]}
	var hazard = E.make(w, {"t": "spikes_up", "x": 448, "y": 160, "motion": wall_path})
	w._register(hazard)
	for i in 60: w._tick_entity(hazard, DT)
	check(hazard.rect.end.x <= 472, "Path bodies stop at room walls without tunnelling")

func check_surface_and_solid() -> void:
	var tiles := []
	for y in range(18, 28): tiles.append([30, y])
	make_world([{"t": "enemy_mosstrot", "x": 228, "y": 190, "motion": {"mode": "surface", "speed": 2.0, "sticky": false, "direction": [0, -1], "support": [1, 0]}}], tiles)
	var vertical = w.ents.filter(func(e): return e.d.t == "enemy_mosstrot")[0]
	for i in 60: w._tick_entity(vertical, DT)
	check(vertical.rect.position == Vector2i(228, 174), "A placed wall patrol follows its vertical support")
	var solid = E.make(w, {"t": "breakwall", "x": 100, "y": 128, "w": 16, "h": 16, "motion": {"mode": "path", "speed": 5.0, "points": [[100, 128], [180, 128]]}})
	w._register(solid)
	for i in 60: w._tick_entity(solid, DT)
	check(not solid.fixed and solid.rect.position.x == 140 and w.collide_solid(solid.rect) == solid, "Originally fixed solids use dynamic collision while patrolling")
	check(w.collide_solid(Rect2i(100, 128, 8, 8)) == null, "A moving solid leaves no collision at its old position")
	make_world([{"t": "jumpthru", "x": 200, "y": 160, "w": 64, "h": 8}, {"t": "enemy_mosstrot", "x": 216, "y": 152, "motion": {"mode": "surface", "speed": 2.0, "direction": [1, 0], "support": [0, 1]}}])
	var walker = w.ents.filter(func(e): return e.d.t == "enemy_mosstrot")[0]
	for i in 60: w._tick_entity(walker, DT)
	check(walker.rect.position == Vector2i(232, 152), "Surface patrol treats one-way platform tops as support")
	make_world([{"t": "enemy_thornmite", "x": 200, "y": 216, "motion": {"mode": "surface", "speed": 2.5, "sticky": true, "direction": [1, 0], "support": [0, 1]}}], [[30, 26], [31, 26], [30, 27], [31, 27]])
	var crawler = w.ents.filter(func(e): return e.d.t == "enemy_thornmite")[0]
	var climbed := false
	for i in 480:
		w._tick_entity(crawler, DT)
		climbed = climbed or crawler.rect.position.y < 210
	check(climbed and crawler.rect.position.x >= 256 and crawler.rect.position.y == 216, "Authored sticky patrol traverses connected corners and returns to the floor")

func check_editor(d: Dictionary) -> void:
	Game.editor_level = d.duplicate(true)
	Game.editor_return = "menu"
	var editor = load("res://scripts/editor.gd").new()
	add_child(editor)
	editor.set_process(false)
	check(editor.has_method("_select_motion"), "Room editor exposes an object-motion inspector")
	editor._select_motion(1)
	check(editor.motion_panel.visible and editor.motion_mode.selected == 2, "Selecting a patrolling object shows its saved mode")
	var original: Dictionary = editor.level.duplicate(true)
	editor._motion_add_point(Vector2i(200, 160))
	check(editor.level.entities[1].motion.points.size() == 3, "Canvas point insertion updates the actual room definition")
	editor._undo()
	check(editor.level == original, "Motion edits participate in normal room undo")
	editor._select_motion(1)
	editor.motion_panel.canvas_left(Vector2i(80, 160), true)
	editor.motion_panel.drag_to(Vector2i(96, 144))
	editor.motion_panel.canvas_left(Vector2i(96, 144), false)
	check(editor.level.entities[1].motion.points[0] == [96, 144], "Canvas dragging moves a selected numbered point")
	editor._undo()
	check(editor.level == original, "A point drag is one undoable edit")
	editor._select_motion(1)
	editor.motion_mode.select(1)
	editor.motion_panel.direction.select(3)
	editor.motion_panel.support.select(0)
	editor.motion_panel.sticky.set_pressed_no_signal(true)
	editor.motion_panel.change_settings()
	check(editor.level.entities[1].motion.sticky and editor.level.entities[1].motion.direction == [0, -1], "Inspector authors sticky and vertical starting-direction settings")
	editor._undo()
	editor._select_motion(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var zoom: Vector2 = editor.cam.zoom
	var at: Vector2 = editor.motion_panel.get_global_rect().position + Vector2(40, 60)
	var mouse := InputEventMouseMotion.new()
	mouse.position = at
	get_viewport().push_input(mouse, true)
	var wheel := InputEventMouseButton.new()
	wheel.position = at
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	get_viewport().push_input(wheel, true)
	await get_tree().process_frame
	check(editor.cam.zoom == zoom, "Inspector scrolling never zooms the room")

	editor._shift(editor.level.entities[1], Vector2i(16, 8))
	check(editor.level.entities[1].motion.points[0] == [96, 168], "Copy/paste offsets path points with the object")
	var path := "user://patrol_roundtrip.json"
	check(Game.write_safe(path, JSON.stringify(editor.level)) and not Game.load_level("patrol_roundtrip", "user://").is_empty(), "Authored motion saves and reloads through the room loader")
	var valid: Dictionary = editor.level.duplicate(true)
	editor.level.entities[1].motion.points[1] = [9999, 9999]
	check(not editor._save(), "Invalid patrols cannot be written as unloadable room files")
	editor._process(0)
	check(editor.status.text.contains("Keep path points"), "Movement-tool help never hides a save validation error")
	editor.level = valid.duplicate(true)
	editor.clip = {"w": 1, "h": 1, "tiles": ["0"], "entities": [{"t": "jumpthru", "x": 0, "y": 0, "w": 24, "h": 8, "motion": {"mode": "path", "speed": 2.0, "points": [[0, 0], [400, 0]]}}]}
	editor._paste(Vector2i(20, 2))
	check(editor.level == valid, "Pasting a path outside the room is rejected before changing tiles or objects")
	editor.clip = {}
	editor.queue_free()
	Game.editor_level = {}
	await get_tree().process_frame
