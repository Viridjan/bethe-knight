extends Node
# Read-only visual fixtures: the real phase pages, including their derived effects.
func _ready() -> void:
	Game.main = self
	get_viewport().gui_embed_subwindows = true
	Game.goto("menu")
	for frame in 3: await get_tree().process_frame
	var menu = get_child(-1)
	menu._monster_editor()
	for frame in 3: await get_tree().process_frame
	var ui = menu.body.get_children().filter(func(node): return node.has_method("_show_enemies"))[0]
	ui._show_enemies()
	ui.expanded_attacks["boss_ape/normal/ape_throw"] = true
	ui._select_enemy(0)
	for frame in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/ape-unified-editor/attacks.png")
	ui.form_scroll.scroll_vertical = 240
	for frame in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/ape-unified-editor/compact-details.png")
	ui.form_scroll.scroll_vertical = int(ui.form_scroll.get_v_scroll_bar().max_value)
	for frame in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/ape-unified-editor/effects.png")
	Game.quit_game(0)
