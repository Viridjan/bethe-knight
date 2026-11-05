extends Node
func _ready() -> void:
	Game.main = self
	Game.goto("menu")
	for frame in 3: await get_tree().process_frame
	var menu = get_child(-1)
	menu._monster_editor()
	var ui = menu.body.get_children().filter(func(n): return n.has_method("_show_enemies"))[0]
	var index: int = ui.ENEMIES.map(func(e): return e[0]).find("enemy_hornback")
	ui._select_enemy(index)
	var field: LineEdit = ui.form.find_children("FamilyHealth", "LineEdit", true, false)[0]
	field.text = "7"
	field.text_changed.emit("7")
	for frame in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/partial-foundations-2026-11-05/family-health.png")
	Game.quit_game(0)
