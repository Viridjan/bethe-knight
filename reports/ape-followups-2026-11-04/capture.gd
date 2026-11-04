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
	for phase in [0, 1]:
		ui._select_enemy(phase)
		for frame in 3: await get_tree().process_frame
		ui.form_scroll.scroll_vertical = int(ui.form_scroll.get_v_scroll_bar().max_value)
		for frame in 3: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/ape-followups-2026-11-04/%s.png" % ("normal" if phase == 0 else "enraged"))
		var log_name: String = ui.catalog.attack("ape_log").codex_online_name
		var title: LineEdit = ui.form.find_children("*", "LineEdit", true, false).filter(func(node): return node.text == log_name)[0]
		get_viewport().warp_mouse(title.get_global_rect().get_center())
		await get_tree().create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/ape-followups-2026-11-04/%s-tooltip.png" % ("normal" if phase == 0 else "enraged"))
	Game.quit_game(0)
