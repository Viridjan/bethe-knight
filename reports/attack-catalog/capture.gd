extends Node
func _ready() -> void:
	Game.main = self
	get_viewport().gui_embed_subwindows = true
	Game.goto("menu")
	for i in 3: await get_tree().process_frame
	var menu = get_child(get_child_count() - 1)
	menu._monsters()
	for i in 3: await get_tree().process_frame
	var bestiary = menu.body.get_children().filter(func(n): return n is Control and n.has_method("_open_catalog"))[0]
	bestiary._open_catalog()
	for i in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/attack-catalog/attacks.png")
	bestiary.catalog_editor._show_table(true)
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/attack-catalog/ranges.png")
	bestiary.catalog_editor._show_enemy_scores()
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/attack-catalog/scores.png")
	Game.quit_game(0)
