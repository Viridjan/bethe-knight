extends Node
func _ready() -> void:
	Game.main = self
	get_viewport().gui_embed_subwindows = true
	Game.goto("menu")
	for frame in 3: await get_tree().process_frame
	var menu = get_child(get_child_count() - 1)
	menu._monster_editor()
	for frame in 3: await get_tree().process_frame
	var editor = menu.body.get_children().filter(func(node): return node.has_method("_show_enemies"))[0]
	editor._show_enemies()
	for frame in 3: await get_tree().process_frame
	var card: Control = null
	for button in editor.form.find_children("*", "Button", true, false):
		if button.text == "Edit" and button.get_parent().get_children().any(func(node): return node is LineEdit and node.text == "Ape stone throw"):
			button.pressed.emit()
			card = button.get_parent().get_parent().get_parent()
	for frame in 4: await get_tree().process_frame
	if card != null: editor.form_scroll.ensure_control_visible(card)
	for frame in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	screenshot.save_png("res://reports/monster-editor-grouped-2026-11-02/editor.png")
	Game.quit_game(0)
