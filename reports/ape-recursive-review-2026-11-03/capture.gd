extends Node
# Visual review only: no Save invocation; all invalid input stays in the editor's private draft.
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
	await _shot("normal")
	editor._select_enemy(1)
	for frame in 3: await get_tree().process_frame
	await _shot("enraged")
	var health: LineEdit = editor.find_child("max_hp", true, false)
	health.text = ""
	health.text_changed.emit("")
	editor._select_enemy(0)
	for frame in 3: await get_tree().process_frame
	await _shot("invalid-health")
	editor.dirty = false  # discard this disposable draft; no disk writes
	Game.quit_game(0)

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/ape-recursive-review-2026-11-03/%s.png" % name)
