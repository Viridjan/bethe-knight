extends Node
func _ready() -> void:
	Game.editor_return = "menu"
	Game.editor_level = Game.new_level("Resize from any edge",40,24)
	var editor = load("res://scripts/editor.gd").new()
	add_child(editor)
	for button in editor.tool_group.get_buttons():
		if button.get_meta("tool_id","") == "room_size": button.button_pressed = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/room-resize-2026-11-05/handles.png")
	editor._begin_resize(Vector2i(-1,-1),Vector2.ZERO)
	editor._preview_resize(Vector2(-16,-16))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/room-resize-2026-11-05/preview.png")
	get_tree().quit()
