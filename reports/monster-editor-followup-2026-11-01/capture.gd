extends Node
func _ready() -> void:
	Game.main = self
	get_viewport().gui_embed_subwindows = true
	Game.goto("menu")
	for i in 3: await get_tree().process_frame
	var menu = get_child(get_child_count() - 1)
	menu._monster_editor()
	for i in 5: await get_tree().process_frame
	var editor = menu.body.get_children().filter(func(node): return node.has_method("_show_enemies"))[0]
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/monster-editor-followup-2026-11-01/attacks.png")
	editor._show_enemies()
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/monster-editor-followup-2026-11-01/enemies.png")
	Game.quit_game(0)
