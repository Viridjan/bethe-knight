extends Node
# Integration smoke run: opens real screens and exercises UI/editor workflows for a few frames each. Optional screenshots require a rendered display; headless mode still checks behavior.
# Reading help: docs/CODE_GUIDE.md.

# Smoke test: open each screen for a few frames, all entity types placed.
# Run: godot --headless --path . res://tests/smoke.tscn

const E := preload("res://scripts/entities.gd")

# Scripted player input for repeatable tests; it uses the real movement implementation.
class Bot extends "res://scripts/player.gd":  # scripted input, for the character close-ups
	var hold := {}
	# Initialize this test helper with the same production dependencies as its parent.
	func _init(world, spawn: Vector2) -> void:
		super(world, spawn)
	# Supply scripted actions instead of physical keyboard/gamepad events for deterministic movement.
	func _read_input(dt: float) -> void:
		in_x = int(hold.has("right")) - int(hold.has("left"))
		in_y = int(hold.has("down")) - int(hold.has("up"))
		aim_raw = Vector2(in_x, in_y).normalized()
		jump_buf -= dt
		dash_buf -= dt
		jump_check = false
		grab_check = hold.has("grab")

# Start the test/benchmark scene, configure its disposable fixtures and run the checks.
func _ready() -> void:
	Game.main = self
	var d := Game.new_level("smoke", 60, 30)
	for pl in [[3, 22, 10, 26], [14, 18, 20, 20], [24, 24, 30, 27], [33, 12, 34, 27]]:  # platforms x0,y0,x1,y1
		for y in range(pl[1], pl[3] + 1):
			var row: String = d.tiles[y]
			d.tiles[y] = row.substr(0, pl[0]) + "1".repeat(pl[2] - pl[0] + 1) + row.substr(pl[2] + 1)
	var x := 24
	for t in E.TYPES:
		d.entities.append({"t": t, "x": x, "y": 120, "w": 16, "h": 16, "tx": x, "ty": 60})
		x += 24
	# Put every new combat behaviour on screen as well as in the generic registry row.
	for enemy in [["enemy_thornmite", 56, 160], ["enemy_skree", 168, 72], ["enemy_bat", 200, 96], ["enemy_skeleton", 264, 180], ["enemy_hornback", 120, 180], ["enemy_fuzzbob", 320, 120], ["enemy_cragjaw", 200, 150], ["enemy_murkspore", 280, 60]]:
		for t in E.TYPES:  # the family and every variant it comes in
			if t == enemy[0] or t.begins_with(enemy[0] + "_"):
				d.entities.append({"t": t, "x": enemy[1], "y": enemy[2]})
	# Connected surfaces: wide, tall and shallow pieces, including the 5px one-way rail.
	for block in [["breakwall", 336, 32, 40, 24], ["crumble", 392, 32, 40, 8], ["falling", 336, 72, 16, 32], ["zip", 392, 72, 32, 16], ["dream", 336, 120, 40, 24], ["jumpthru", 392, 120, 40, 8]]:
		d.entities.append({"t": block[0], "x": block[1], "y": block[2], "w": block[3], "h": block[4], "tx": block[1], "ty": block[2] + 24})
	var previous_invincible: bool = Game.settings.invincible
	Game.settings.invincible = true
	Game.editor_level = d
	Game.play(d, true)
	await _frames(90)
	await _shot("world")
	Game.settings.invincible = previous_invincible
	var world = get_child(0)
	var tc = world.TouchControls.new()  # desktop has no touchscreen: force the phone controls on
	world.touch = tc
	world.ui.add_child(tc)
	var tap := InputEventScreenTouch.new()
	await _frames(1)  # laid out to the screen size
	tap.position = tc.at(Vector2(1150, 600))  # Jump
	tap.pressed = true
	tc._input(tap)
	Input.flush_buffered_events()  # parse_input_event is buffered until the next process frame
	await _frames(2)
	await _shot("touch")
	if not Input.is_action_pressed("jump"):
		_fail("touch Jump did not press jump")
	tap.pressed = false
	tc._input(tap)
	Input.flush_buffered_events()  # parse_input_event is buffered until the next process frame
	await _frames(2)
	if Input.is_action_pressed("jump"):
		_fail("touch Jump stayed held")
	# character close-ups: standing, running, climbing the platform wall at x=264 (tiles 33-34)
	var real_player = world.player
	world.player = Bot.new(world, Vector2(200, 27 * 8))
	for pose in [["idle", {}, Vector2(110, 224)], ["run", {"right": true}, Vector2(100, 224)], ["climb", {"right": true, "grab": true}, Vector2(255, 180)]]:
		world.player.pos = pose[2]
		world.player.hold = pose[1]
		await _frames(25)
		await _shot_player("char_" + pose[0], world)
	world.player = real_player
	Game.settings.hitboxes = true
	var keep_pos: Vector2 = world.player.pos
	world.player.pos = Vector2(330, 150)  # floating below the objects, in view
	world.player.attack_timer = world.player.ATTACK_TIME
	world.queue_redraw()
	await _frames(1)
	await _shot("hitboxes")
	Game.settings.hitboxes = false
	world.player.attack_timer = 0
	world.player.pos = keep_pos
	world.player.transitions[Vector2i(0, 2)] = 3  # draw-only bookkeeping: exercise edge drawing
	world.player.transitions[Vector2i(2, 0)] = 3
	world.player.transitions[Vector2i(0, 1)] = 1
	world.player.transitions[Vector2i(4, 0)] = 2
	world.player.transitions[Vector2i(0, 8)] = 1
	for i in 10:
		world.player.transition_log.append([16.75 + i, i % 2 * 7, (i + 1) % 2 * 7])
	world._toggle_debug()
	await _frames(10)
	await _shot("debug")
	var t0: float = world.time
	world.debug_panel.pause_box.button_pressed = true
	await _frames(5)
	var frozen: bool = world.time == t0
	world.debug_panel.step_frames = 1
	await _frames(5)
	if not frozen or world.time <= t0:
		_fail("debug panel pause/step did not hold the simulation")
	await _press("pause")  # Esc closes the panel instead of pausing
	if world.debug_panel != null or world.paused:
		_fail("Esc did not close the debug panel")
	await _press("map")
	await _frames(5)
	await _shot("map")
	await _press("pause")
	await _press("debug")
	await _press("debug")
	if world.map_view != null or world.debug_panel != null or world.paused or not world.hud.visible:
		_fail("map/debug keys did not open and close cleanly")
	var hb0: bool = Game.settings.hitboxes
	await _press("hitboxes")
	var hb1: bool = Game.settings.hitboxes
	await _press("hitboxes")
	if hb1 == hb0 or Game.settings.hitboxes != hb0:
		_fail("hitboxes key did not toggle the overlay")
	await _press("assist")
	await _frames(5)
	await _shot("assist")
	if not world.paused or world.overlay == null or not world.overlay.assist_page:
		_fail("assist key did not open the paused Assist Mode page")
	await _press("assist")
	await _frames(2)
	if world.paused or world.overlay != null:
		_fail("assist key did not close Assist Mode and resume")
	world._set_paused(true)
	await _frames(5)
	await _shot("pause")
	if is_instance_valid(Game.music_engine) and not Game.music_engine.muffled:
		_fail("music not muffled in the pause menu")
	world._open_options()
	await _frames(5)
	await _shot("options")
	var saved_pad: Dictionary = Game.settings.pad.duplicate()
	var back_to := Button.new()
	world.overlay.add_child(back_to)
	world.overlay._open_pad(back_to)
	await _frames(5)
	await _shot("options_pad")
	var pad = world.overlay.get_child(world.overlay.get_child_count() - 1)
	pad._rebind("jump")
	var trig := InputEventJoypadMotion.new()
	trig.axis = JOY_AXIS_TRIGGER_LEFT
	trig.axis_value = 1.0
	pad._input(trig)
	if Game.settings.pad.jump != Game.PAD_AXIS + JOY_AXIS_TRIGGER_LEFT or pad.key_buttons.jump.text != "LT / L2":
		_fail("controller page did not rebind jump to L2")
	pad._reset_keys()
	if Game.settings.pad != Game.DEFAULT_PAD:
		_fail("controller page reset failed")
	Game.settings.pad = saved_pad
	Game.apply_settings()
	Game.save_settings()
	pad._close()
	world._show_complete()
	await _frames(5)
	Game.goto("editor")
	await _frames(30)
	var ed = get_child(get_child_count() - 1)
	ed.tool = "zip"
	ed._place_rect(Vector2i(3, 3), Vector2i(5, 4))
	ed._left(true)
	ed._resize()
	ed._undo()
	await _frames(10)
	await _shot("editor")
	Game.goto("menu")
	await _frames(10)
	await _frames(1)
	await _shot("menu")
	Game.goto("music_studio")
	await _frames(3)
	var studio = get_child(get_child_count() - 1)
	studio._toggle_play()
	await _frames(5)
	await _shot("music_studio")
	studio._back()
	await _frames(3)
	if Game.get_music_engine().playing:
		_fail("leaving music studio did not stop playback")
	# adventure: menu -> new game -> walk into room 2 -> map -> exit; world editor
	Game.save_path = "user://smoke_save.cfg"
	DirAccess.remove_absolute(Game.save_path)
	Game.world_path = "res://tests/fixtures/adventure/world.json"  # the 3 known test rooms
	var menu = get_child(get_child_count() - 1)
	menu._adventure()
	await _frames(5)
	Game.start_adventure(true)
	await _frames(10)
	var adv = get_child(get_child_count() - 1)
	if adv.room != "a1_first_steps":
		_fail("new adventure did not start in the start room")
	adv.player.pos = Vector2(adv.bounds.end.x - 2, 160)  # half out of the doorway
	adv.player.speed.x = 90
	await _frames(10)
	if adv.room != "a2_little_gap":
		_fail("walking off the right edge did not enter room 2 (in %s)" % adv.room)
	await _press("map")
	await _frames(5)
	await _shot("adventure_map")
	await _press("map")
	adv._exit()
	await _frames(5)
	if not Game.has_adventure_save():
		_fail("adventure run was not saved")
	Game.world_path = Game.STORY_WORLD  # the shipped world from here on
	Game.goto("world_editor")
	await _frames(10)
	await _shot("world_editor")
	DirAccess.remove_absolute(Game.save_path)
	Game.save_path = Game.SAVE_PATH
	# Real story rooms: the themed renderers, neighbour caches and room swaps.
	var hk := Game.Adventure.load_world("res://worlds/story/world.json")
	var examples := {}
	for room_name in hk.rooms:
		var environment: String = hk.rooms[room_name].level.get("environment", "")
		if not examples.has(environment): examples[environment] = room_name
	Game.settings.invincible = true
	Game.playtest_adventure(hk, hk.start)
	await _frames(8)
	var themed_world = get_child(get_child_count()-1)
	for environment in examples:
		var room_name: String = examples[environment]
		var at := Vector2(16,16)
		for entity in hk.rooms[room_name].level.entities:
			if entity.t == "spawn":
				at = Vector2(entity.x+4,entity.y+8)
				break
		themed_world.enter_room(room_name, at)
		await _frames(3)
		if Game.get_music_engine().environment != environment or not Game.get_music_engine().playing:
			_fail("room music did not follow background: " + environment)
		if themed_world.tile_layer.chunks[0].environment != environment:
			_fail("room terrain did not switch to " + environment)
		for neighbour in themed_world.near_layers:
			var expected: String = hk.rooms[neighbour].level.get("environment", "")
			if themed_world.near_layers[neighbour].chunks[0].environment != expected:
				_fail("neighbour terrain lost its own environment")
		await _shot("environment_"+environment)
	# Monster Editor "Test": every listed enemy loads alone in the empty room.
	var monster_editor = load("res://scripts/attack_catalog_editor.gd").new()
	Game.settings.invincible = true
	for listed in monster_editor._all_enemies():
		Game.play(monster_editor.test_room(str(listed[0])), false)
		await _frames(30)
		var room = get_child(-1)
		if not room.ents.any(func(ent): return ent.d.get("t", "") == listed[0]):
			_fail("test room has no %s" % listed[0])
	var monster_editor_room: Dictionary = monster_editor.test_room("enemy_hornback")
	monster_editor.free()
	# Ground distance: read from the family profile, whole numbers only, and it moves the image, not the body.
	var profiles = load("res://scripts/attack_catalog.gd").shared()
	profiles.enemy_profiles["enemy_hornback"] = {"ground_distance": 6}
	Game.play(monster_editor_room, false)
	await _frames(20)
	var lifted = get_child(-1).ents.filter(func(ent): return ent.d.get("t", "") == "enemy_hornback")[0]
	if lifted.ground_distance() != 6 or not profiles.validate().is_empty():
		_fail("ground distance is not read from the family profile")
	profiles.enemy_profiles["enemy_hornback"] = {"ground_distance": 1.5}
	if profiles.validate().is_empty(): _fail("a fractional ground distance is accepted")
	profiles.enemy_profiles.erase("enemy_hornback")
	# Monster Lab: an empty room; Tab opens its editor (own catalogue) and freezes the room; picking an enemy
	# and pressing Test restarts the room with it. Every enemy it lists runs on the lab catalogue.
	Game.play_lab()
	await _frames(5)
	var lab = get_child(-1)
	var tab_key := InputEventKey.new()
	tab_key.keycode = KEY_TAB
	tab_key.pressed = true
	Input.parse_input_event(tab_key)
	await _frames(3)
	if not lab.lab_open(): _fail("Tab does not open the Monster Lab editor")
	var clock: float = lab.time
	await _frames(5)
	if lab.time != clock: _fail("Monster Lab room keeps running under its editor")
	var lab_editor = lab.lab_panel.find_children("", "VBoxContainer", true, false).filter(func(n): return n.has_method("_test"))[0]
	lab_editor._show_table(false)
	lab_editor._show_enemies()
	if not lab_editor.catalog.attack_path.begins_with("user://monster_lab/") or not lab_editor.catalog.validate().is_empty():
		_fail("Monster Lab editor is not on its own valid catalogue")
	if lab_editor.catalog.attacks.is_empty() or not lab_editor.catalog.assignments.all(func(row): return row.enemy_id in lab_editor.ENEMIES.map(func(listed): return listed[0])):
		_fail("Monster Lab editor has no attacks to choose from")
	var lab_ids: Array = lab_editor.ENEMIES.map(func(listed): return listed[0])
	lab_editor._select_enemy(lab_ids.find("enemy_hornback"))
	lab_editor._test()
	await _frames(5)
	if load("res://scripts/attack_catalog.gd").shared().attack_path != "user://monster_lab/attacks.csv":
		_fail("Monster Lab room does not run on the lab catalogue")
	for lab_id in lab_ids:
		Game.play_lab(lab_id)
		await _frames(90)
		if not get_child(-1).ents.any(func(ent): return ent.d.get("t", "") == lab_id):
			_fail("Monster Lab room has no %s" % lab_id)
	Game.play_lab("enemy_hornback", Vector2(100, 120))  # dropped by hand: it starts there
	await _frames(1)
	if not get_child(-1).ents.any(func(ent): return ent.d.get("t", "") == "enemy_hornback" and ent.d.x == 100 and ent.d.y == 120):
		_fail("Monster Lab enemy is not placed where it was dropped")
	if get_child(-1)._lab_drop().size != Vector2(12, 10): _fail("Monster Lab carry outline is not the enemy's size")
	for held in [true, false]:  # a real click in the room: press carries, release drops
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = held
		click.position = Vector2(640, 360)
		Input.parse_input_event(click)
		await _frames(2)
		if held and not get_child(-1).lab_carry: _fail("Monster Lab: pressing in the room does not pick the enemy up")
	if Game.lab_at == Vector2(100, 120) or Game.lab_at == Vector2.INF: _fail("Monster Lab: releasing in the room does not drop the enemy there")
	Game.goto("menu")
	await _frames(2)
	if Game.lab or load("res://scripts/attack_catalog.gd").shared().attack_path != "res://data/attacks.csv":
		_fail("leaving the Monster Lab does not restore the game's attacks")
	Game.settings.invincible = previous_invincible
	Game.adv = {}
	Game.adv_world = {}
	for oid in Node.get_orphan_node_ids():  # a node built but never added to the tree leaks (with its text and art)
		var o = instance_from_id(oid)
		_fail("orphan node left behind: %s %s" % [o, o.text if o is Button else ""])
	print("SMOKE OK" if failures == 0 else "SMOKE FAILED: %d" % failures)
	Game.quit_game(failures)

var failures := 0

# Count and report an integration failure rather than silently continuing as if it passed.
func _fail(msg: String) -> void:
	failures += 1
	push_error(msg)

# Inject a press/release pair and wait for the scene to process it, like a real button action.

func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await _frames(2)

# Wait for a known number of physics frames so real scene callbacks can run before the next assertion.
func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

# Save a close-up around the player for visual review, clipping the image region to viewport bounds.
func _shot_player(name: String, world) -> void:
	var dir := OS.get_environment("SHOT_DIR")
	if dir != "" and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var c := Vector2i((world.player.pos - world.cam.position) * world.ZOOM + Vector2(img.get_size()) / 2)
		img.get_region(Rect2i(c - Vector2i(100, 110), Vector2i(200, 140)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))).save_png(dir.path_join(name + ".png"))

# Optionally save a viewport screenshot when a rendered display and screenshot output directory are available.
func _shot(name: String) -> void:
	var dir := OS.get_environment("SHOT_DIR")
	if dir != "" and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(name + ".png"))
