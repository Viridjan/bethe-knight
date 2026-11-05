extends Node

func _ready() -> void:
	Game.main = self
	Game.start_adventure(true)
	Game.adv_temp = true
	var world = get_child(-1)
	for frame in 90: await get_tree().physics_frame
	world.set_physics_process(false)
	for stress in [0, 125, 250]:
		Game.adv.stress = stress
		world.hud.queue_redraw()
		for frame in 3: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://reports/stress-2026-11-05/stress-%d.png" % stress)
	Game.adv = {}
	Game.quit_game(0)
