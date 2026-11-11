extends Node
var world
func snap(label: String) -> void:
	for frame in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/room-cosmetics-2026-11-10/"+label+".png")
func open(room: String, at: Vector2) -> void:
	if world:world.free()
	Game.adv=Game.Adventure.new_run(Game.adv_world)
	Game.adv.room=room;Game.adv_temp=true
	Game.level=Game.adv_world.rooms[room].level
	world=load("res://scripts/world.gd").new();add_child(world)
	world.set_physics_process(false);world.player.pos=at
	world.cam_pos=world.cam_goal();world.snap_interp()
func _ready() -> void:
	Game.adv_world=Game.Adventure.load_world(Game.STORY_WORLD)
	open("t1_cove_town",Vector2(88,96))
	world.switch_layer("h1_villager_house",Vector2(64,96))
	world.layer_manager.worlds.h1_villager_house.set_physics_process(false)
	await snap("house")
	open("s2_shore",Vector2(372,408))
	world.switch_layer("lh1_lighthouse_stairs",Vector2(372,408))
	world.layer_manager.worlds.lh1_lighthouse_stairs.set_physics_process(false)
	await snap("tower")
	open("c1_lake_cave",Vector2(80,80));await snap("cave")
	open("i11_flooded_hall",Vector2(100,80));await snap("flooded-hall")
	open("l1_jungle_depths",Vector2(200,120));await snap("root-interior")
	# A disposable deep pool displays the full underwater set without changing story liquid geometry.
	if world:world.free();world=null
	Game.adv={};Game.level=Game.new_level("Underwater cosmetics",48,24)
	Game.level.environment="sea";Game.level.backdrop="underwater"
	Game.level.tiles[0]="1".repeat(48)
	Game.level.entities=[{"t":"spawn","x":48,"y":64},{"t":"water","x":8,"y":16,"w":368,"h":160}]
	world=load("res://scripts/world.gd").new();add_child(world)
	world.set_physics_process(false);world.player.pos=Vector2(160,120)
	world.cam_pos=world.cam_goal();world.snap_interp()
	await snap("underwater")
	Game.quit_game(0)
