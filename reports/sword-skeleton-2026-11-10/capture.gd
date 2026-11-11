extends Node
var world
func snap(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/sword-skeleton-2026-11-10/"+name+".png")
func _ready() -> void:
	Game.adv_world=Game.Adventure.load_world(Game.STORY_WORLD)
	Game.adv=Game.Adventure.new_run(Game.adv_world)
	Game.adv.room="s2_shore";Game.adv_temp=true
	Game.level=Game.adv_world.rooms.s2_shore.level
	world=load("res://scripts/world.gd").new();add_child(world)
	world.set_physics_process(false)
	world.player.pos=Vector2(54,328)
	world.cam_pos=world.cam_goal();world.snap_interp()
	var bones=world.ents.filter(func(e):return e.d.t=="dead_skeleton")[0]
	bones.near=1
	await snap("sword-present")
	world.player.interact=true;bones.touch(world.player)
	await snap("sword-taken")
	Game.adv.room="l3_treetop_village"
	Game.level=Game.adv_world.rooms.l3_treetop_village.level
	world.free();world=load("res://scripts/world.gd").new();add_child(world)
	world.set_physics_process(false);world.player.pos=Vector2(512,120)
	world.cam_pos=world.cam_goal();world.snap_interp()
	await snap("village-climb")
	Game.quit_game(0)
