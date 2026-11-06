extends Node
const Adventure := preload("res://scripts/adventure.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	var folder := "user://world_selection"
	DirAccess.make_dir_recursive_absolute(folder)
	var level := Game.new_level("Room", 12, 10)
	level.tiles = []
	for y in 10: level.tiles.append("0".repeat(12))
	for name in ["a", "b", "remote"]: Game.write_safe(folder + "/" + name + ".json", JSON.stringify(level))
	var old_path: String = Game.world_path
	Game.world_path = folder + "/world.json"
	var fixture := {"start": "a", "abilities": [], "rooms": {"a": {"pos": Vector2i(0, 0), "level": level}, "b": {"pos": Vector2i(12, 0), "level": level}, "remote": {"pos": Vector2i(60, 20), "level": level}}}
	Adventure.save_world(Game.world_path, fixture)
	var editor = load("res://scripts/world_editor.gd").new()
	add_child(editor)
	editor.set_process(false)
	if not editor.has_method("_box_select"):
		check(false, "World editor supports rectangular room selection")
	else:
		# Exercise press/release without motion events: fast drags must use the release position.
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = true
		mouse.position = editor.to_screen(Vector2(-1, -1))
		editor._gui_input(mouse)
		mouse.pressed = false
		mouse.position = editor.to_screen(Vector2(25, 11))
		editor._gui_input(mouse)
		check(editor.selected_rooms.size() == 2, "Mouse release completes a fast selection rectangle")
		mouse.pressed = true
		mouse.ctrl_pressed = true
		mouse.position = editor.to_screen(Vector2(1, 1))
		editor._gui_input(mouse)
		check(not editor.selected_rooms.has("a") and editor.selected_rooms.has("b"), "Control-click removes only the clicked room from the group")
		editor._box_select(Rect2(Vector2(-1, -1), Vector2(26, 12)), false)
		check(editor.selected_rooms.size() == 2, "Drag selection includes both rooms and excludes distant rooms")
		editor._begin_room_drag("a", Vector2.ZERO)
		editor._drag_rooms(Vector2(10, 8), true)
		check(editor.world.rooms.a.pos == Vector2i(10, 8) and editor.world.rooms.b.pos == Vector2i(22, 8), "Selected rooms move by the same delta")
		editor._end_room_drag(false)
		check(editor.world.rooms.remote.pos == Vector2i(60, 20), "Unselected rooms remain fixed")
		editor._select_only("a")
		editor._begin_room_drag("a", Vector2.ZERO)
		editor._drag_rooms(Vector2(-10, -8), true)
		editor._end_room_drag(false)
		editor._select_only("b")
		editor._begin_room_drag("b", Vector2.ZERO)
		editor._drag_rooms(Vector2(-8, -8), false)
		check(editor.world.rooms.b.pos == Vector2i(12, 0), "Nearby passage openings snap flush instead of leaving a gap")
		editor._cancel_room_drag()
		check(editor.world.rooms.b.pos == Vector2i(22, 8), "Escape cancellation restores every original room position")
		editor._select_only("remote")
		editor._begin_room_drag("remote", Vector2.ZERO)
		editor._drag_rooms(Vector2(2, 0), false)
		check(editor.world.rooms.remote.pos == Vector2i(62, 20), "Distant rooms are not pulled into a remote connection")
		editor._end_room_drag(true)
		var saved: Dictionary = Adventure.load_world(Game.world_path)
		check(saved.rooms.remote.pos == Vector2i(62, 20), "Group drag completion persists room positions")
		editor.world.rooms.a.pos = Vector2i.ZERO
		editor.world.rooms.b.pos = Vector2i(12, 0)
		editor.world.rooms.remote.pos = Vector2i(36, 0)
		editor._box_select(Rect2(-1, -1, 26, 12), false)
		editor._begin_room_drag("a", Vector2.ZERO)
		editor._drag_rooms(Vector2(10, 0), false)
		check(editor.world.rooms.a.pos == Vector2i(12, 0) and editor.world.rooms.b.pos == Vector2i(24, 0), "Snapping translates the entire group without changing its internal offsets")
		editor._cancel_room_drag()
		check(editor.world.rooms.a.pos == Vector2i.ZERO and editor.world.rooms.b.pos == Vector2i(12, 0), "Group cancellation restores all selected rooms")
		editor._box_select(Rect2(35, -1, 14, 12), true)
		check(editor.selected_rooms.size() == 3, "Additive box selection retains previously selected rooms")
		editor._select_only("a")
		editor._begin_room_drag("a", Vector2.ZERO)
		editor._drag_rooms(Vector2(20, 20), true)
		Game.world_path = folder + "/missing_folder/world.json"
		editor._end_room_drag(true)
		check(editor.world.rooms.a.pos == Vector2i.ZERO and editor.status.text.contains("restored"), "A failed group save restores the previous layout")
		var sealed: Dictionary = level.duplicate(true)
		sealed.tiles = []
		for y in 10: sealed.tiles.append("1".repeat(12))
		sealed.entities.append({"t": "house_door", "x": 16, "y": 16, "id": "in", "to": "a:out"})
		editor.world.rooms.remote.level = sealed
		editor.world.rooms.remote.pos = Vector2i(14, 0)
		editor.world.rooms.a.level.entities.append({"t": "house_door", "x": 16, "y": 16, "id": "out", "to": "remote:in"})
		editor._select_only("remote")
		editor._begin_room_drag("remote", Vector2.ZERO)
		editor._drag_rooms(Vector2.ZERO, false)
		check(editor.world.rooms.remote.pos == Vector2i(14, 0) and editor.snapped_pair.is_empty(), "A nearby door-only connection does not cause physical snapping")
		editor._end_room_drag(false)

	editor.queue_free()
	Game.world_path = old_path
	await get_tree().process_frame
	print("WORLD SELECTION: %d failure(s)" % failures)
	Game.quit_game(failures)
