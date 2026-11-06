extends Node
func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	Game.main = self
	Game.goto("menu")
	for frame in 5: await get_tree().process_frame
	var menu = get_child(-1)
	menu._monster_editor()
	for frame in 5: await get_tree().process_frame
	var editor = menu.body.get_children().filter(func(node): return node.has_method("_show_enemies"))[0]
	editor.expanded_attacks["boss_ape/normal/ape_retreat"] = true
	editor._select_enemy(0)
	for frame in 5: await get_tree().process_frame
	editor.form_scroll.scroll_vertical = 120
	for frame in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/ape-attack-triggers-2026-11-06/editor.png")
	Game.quit_game(0)
