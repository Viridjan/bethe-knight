extends Node
func _ready() -> void:
	Game.main = self
	var level := Game.new_level("Patrol authoring", 64, 32)
	level.entities.append({"t": "jumpthru", "x": 144, "y": 176, "w": 32, "h": 8, "motion": {"mode": "path", "speed": 3.0, "pause": 0.4, "closed": true, "points": [[144, 176], [240, 176], [240, 128]]}})
	level.entities.append({"t": "enemy_mosstrot", "x": 280, "y": 232, "motion": {"mode": "surface", "speed": 2.0, "sticky": true, "direction": [1, 0], "support": [0, 1]}})
	Game.editor_level = level
	Game.editor_return = "menu"
	Game.goto("editor")
	var editor = get_child(-1)
	editor.cam.position = Vector2(210, 150)
	editor.cam.zoom = Vector2(2.5, 2.5)
	for index in [1, 2]:
		editor._select_motion(index)
		editor.motion_panel.preview_button.button_pressed = true
		for frame in 6: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/patrol-authoring-2026-11-05/%s.png" % ("path" if index == 1 else "surface"))
	Game.quit_game(0)
