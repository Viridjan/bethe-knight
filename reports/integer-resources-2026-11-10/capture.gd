extends Node
func _ready() -> void:
	Game.level=Game.new_level("Integer resources",80,30)
	Game.level.entities=[{"t":"spawn","x":80,"y":208}]
	Game.adv_world={"start":"test","rooms":{"test":{"pos":Vector2i.ZERO,"level":Game.level}}}
	Game.adv=Game.Adventure.new_run(Game.adv_world)
	Game.adv_temp=true
	Game.adv.blocks=4;Game.adv.stress_blocks=4;Game.adv.stress=100;Game.adv.stamina=40
	var world=load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	world._toggle_stamina_panel()
	for frame in 120:
		world._physics_process(1.0/60.0)
		world.stamina_panel._process(1.0/60.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/integer-resources-2026-11-10/hud-f3.png")
	Game.quit_game(0)
