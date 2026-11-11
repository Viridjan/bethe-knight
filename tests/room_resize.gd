extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	Game.editor_return = "menu"
	var fixture := Game.new_level("Resize",20,16)
	fixture.tiles[5] = fixture.tiles[5].substr(0,5)+"1"+fixture.tiles[5].substr(6)
	fixture.entities = [{"t":"zip","x":40,"y":40,"w":8,"h":8,"tx":80,"ty":56}, {"t":"stamina_orb","x":48,"y":48,"motion":{"mode":"path","speed":2,"points":[[48,48],[64,48]]}}]
	Game.editor_level = fixture
	var editor = load("res://scripts/editor.gd").new()
	add_child(editor)
	editor.set_process(false)
	if not editor.has_method("_resize_bounds"):
		check(false,"Room can resize from arbitrary boundaries")
	else:
		for bounds in [Rect2i(-3,0,23,16),Rect2i(0,-2,20,18),Rect2i(0,0,24,16),Rect2i(0,0,20,19),Rect2i(-2,-3,22,19),Rect2i(2,2,18,14)]:
			editor._set_level(fixture.duplicate(true))
			check(editor._resize_bounds(bounds),"Each edge and corner can resize")
			var off: Vector2i = -bounds.position*8
			check(editor.level.tiles[5-bounds.position.y][5-bounds.position.x] == "1","Resizing preserves tiles at the expected offset")
			check(Vector2i(editor.level.entities[0].x,editor.level.entities[0].y) == Vector2i(40,40)+off and editor.level.entities[0].tx == 80+off.x,"Objects and zip endpoints follow left/top changes")
			check(editor.level.entities[1].motion.points[0] == [48+off.x,48+off.y],"Patrol points follow the same translation")
			editor._undo()
			check(editor.level == fixture and editor.origin_shift == Vector2i.ZERO,"Undo restores size, content and room origin together")
		var before: Dictionary = editor.level.duplicate(true)
		var undo_count: int = editor.undo_stack.size()
		check(not editor._resize_bounds(Rect2i(0,0,7,8)) and editor.level == before and editor.undo_stack.size() == undo_count,"Invalid dimensions make no changes and consume no undo")
		check(not editor._resize_bounds(Rect2i(0,0,8,8)),"Minimum width is enforced")
		check(not editor._resize_bounds(Rect2i(0,0,10,6)),"Shrinking cannot silently cut a retained patrol path")
		editor.tool = "room_size"
		check(editor._resize_handle(Vector2(0,64)) == Vector2i.LEFT and editor._resize_handle(Vector2(160,64)) == Vector2i.RIGHT,"Left and right edges have resize handles")
		check(editor._resize_handle(Vector2(80,0)) == Vector2i.UP and editor._resize_handle(Vector2(80,128)) == Vector2i.DOWN,"Top and bottom edges have resize handles")
		editor._begin_resize(Vector2i(-1,-1),Vector2.ZERO)
		editor._preview_resize(Vector2(-16,-24))
		check(editor.resize_preview == Rect2i(-2,-3,22,19) and editor.level == before,"Dragging previews a snapped boundary without editing data")
		editor._cancel_resize()
		check(editor.resize_side == Vector2i.ZERO and editor.level == before,"Escape-style cancellation preserves the room")
		await check_world_save(editor,fixture)
		Game.editor_level = editor.level.duplicate(true)
		Game.editor_resize_resume = {"file":Game.editor_file,"dir":Game.editor_dir,"origin":Vector2i(-2,-3),"saved_origin":Vector2i.ZERO,"saved_level":fixture.duplicate(true),"undo_stack":[],"origin_history":[]}
		var resumed = load("res://scripts/editor.gd").new()
		add_child(resumed)
		resumed.set_process(false)
		check(resumed.origin_shift == Vector2i(-2,-3) and resumed.saved_origin_shift == Vector2i.ZERO and Game.editor_resize_resume.is_empty(),"Playtest return restores pending room origin without marking it saved")
		resumed.queue_free()
	editor.queue_free()
	await get_tree().process_frame
	print("ROOM RESIZE: %d failure(s)" % failures)
	Game.quit_game(failures)
func check_world_save(editor, fixture: Dictionary) -> void:
	var folder := "user://room-resize/"
	DirAccess.make_dir_recursive_absolute(folder)
	Game.editor_return = "world_editor"
	Game.editor_dir = folder
	Game.editor_file = "a"
	Game.world_path = folder+"world.json"
	Game.save_level(fixture,folder,"a")
	var alternate := fixture.duplicate(true)
	alternate.entities.append({"t":"house_door","id":"reward","x":88,"y":64,"w":8,"h":16})
	Game.save_level(alternate,folder,"a_after")
	Game.write_safe(Game.world_path,JSON.stringify({"start":"a","rooms":{"a":[10,20]},"variants":{"a":[{"room":"a_after","when":"boss"}]}}))
	editor._set_level(fixture.duplicate(true))
	editor.saved_origin_shift = Vector2i.ZERO
	editor._resize_bounds(Rect2i(-2,-3,22,19))
	check(editor._save(),"Resized room saves")
	var after := Game.load_level("a_after",folder)
	check(after.w == 22 and after.h == 19 and after.entities[-1].x == 104 and after.entities[-1].y == 88,"Resizing also aligns conditional variants and their unique objects")
	var world: Dictionary = Game.Adventure.load_world(Game.world_path)
	check(world.rooms.a.pos == Vector2i(8,17),"Saving a left/top resize moves world origin, keeping the opposite edges fixed")
	editor._undo()
	check(editor._save(),"Undo after saving can be saved again")
	after = Game.load_level("a_after",folder)
	check(after.w == 20 and after.h == 16 and after.entities[-1].x == 88,"Undo also restores variant size and object coordinates")
	world = Game.Adventure.load_world(Game.world_path)
	check(world.rooms.a.pos == Vector2i(10,20) and world.rooms.a.level.w == 20,"Saving undo restores world placement and dimensions")
	var manifest_before := FileAccess.get_file_as_string(Game.world_path)
	after.entities[-1].motion = {"mode":"path","speed":2,"points":[[88,64],[144,64]]}
	# Use a movable object for this variant-only path.
	after.entities[-1].t = "stamina_orb"
	Game.save_level(after,folder,"a_after")
	editor._resize_bounds(Rect2i(0,0,14,16))
	check(not editor._save() and Game.load_level("a",folder).w == 20 and Game.load_level("a_after",folder).w == 20 and FileAccess.get_file_as_string(Game.world_path) == manifest_before,"A variant-only path cut refuses saving without partially changing saved files")
	editor._undo()
	editor._new()
	editor._resize_bounds(Rect2i(-2,0,int(editor.level.w)+2,int(editor.level.h)))
	check(editor._save() and FileAccess.get_file_as_string(Game.world_path) == manifest_before,"A new custom room resized from the left saves without changing the world manifest")
