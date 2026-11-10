extends Node
var world
func snap(label: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/room-layers-2026-11-07/"+label+".png")
func open(room: String, at: Vector2) -> void:
	if world:world.free()
	Game.adv=Game.Adventure.new_run(Game.adv_world)
	Game.adv.room=room
	Game.adv_temp=true
	Game.level=Game.adv_world.rooms[room].level
	world=load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	world.player.pos=at
	world.cam_pos=world.cam_goal()
	world.snap_interp()
func _ready() -> void:
	Game.adv_world=Game.Adventure.load_world(Game.STORY_WORLD)
	open("t1_cove_town",Vector2(88,96))
	await snap("cove-exterior")
	world.switch_layer("h1_villager_house",Vector2(64,96))
	world.layer_manager.worlds.h1_villager_house.set_physics_process(false)
	await snap("villager-interior")
	open("s2_shore",Vector2(372,408))
	await snap("shore-base")
	world.switch_layer("lh1_lighthouse_stairs",Vector2(372,408))
	var inner=world.layer_manager.worlds.lh1_lighthouse_stairs
	inner.set_physics_process(false)
	inner.set_process(false)
	inner.cam.zoom=Vector2(2,2)
	inner.cam.position=Vector2(388,224)
	await snap("lighthouse-interior")
	inner.switch_layer("main",Vector2(372,40))
	world.set_physics_process(false)
	await snap("lighthouse-rooftop")
	Game.quit_game(0)
