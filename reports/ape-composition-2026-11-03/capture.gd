extends Node
# Disposable visual fixture. Does not save gameplay/editor state.
func _ready() -> void:
	Game.main = self
	get_viewport().gui_embed_subwindows = true
	Game.goto("menu")
	for frame in 3: await get_tree().process_frame
	var menu = get_child(-1)
	menu._monster_editor()
	for frame in 3: await get_tree().process_frame
	var editor = menu.body.get_children().filter(func(node): return node.has_method("_show_enemies"))[0]
	editor._show_enemies()
	for frame in 3: await get_tree().process_frame
	await _capture("editor")
	var effects_card: Control
	for button in editor.form.find_children("*", "Button", true, false):
		if button.text == "Edit" and button.get_parent().get_children().any(func(node): return node is LineEdit and node.text == "Ape log throw"):
			button.pressed.emit()
			effects_card = button.get_parent().get_parent().get_parent()
	for frame in 3: await get_tree().process_frame
	if effects_card != null: editor.form_scroll.ensure_control_visible(effects_card)
	for frame in 3: await get_tree().process_frame
	await _capture("attacks")
	editor.form_scroll.scroll_vertical = int(editor.form_scroll.get_v_scroll_bar().max_value)
	for frame in 3: await get_tree().process_frame
	await _capture("effects")
	var level: Dictionary = Game.load_level("a1_ape_arena", "res://worlds/story/")
	Game.play(level, true)
	for frame in 3: await get_tree().process_frame
	var world = get_child(-1)
	world.set_physics_process(false)
	var ape = world.ents.filter(func(e): return e.d.t == "boss_ape")[0]
	ape.hp = 2
	ape.phase = "idle"
	ape.clock = 0.125
	ape.effects.spawn(Vector2(100, 65), Vector2(50, -30), {})
	ape.effects.spawn(Vector2(150, 85), Vector2(-50, 50), {})
	for frame in 3: await get_tree().process_frame
	await _capture("arena")
	Game.quit_game(0)

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/ape-composition-2026-11-03/%s.png" % name)
