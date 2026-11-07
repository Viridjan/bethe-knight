extends Node
const Adventure := preload("res://scripts/adventure.gd")
func snap(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/nonmap-systems-2026-11-07/"+name+".png")
func _ready() -> void:
	Game.adv_temp=true
	Game.level=Game.new_level("Systems preview",80,30)
	Game.level.environment="rocky_plateau"
	Game.level.entities=[{"t":"spawn","x":80,"y":208},{"t":"rock_giant","x":160,"y":180},{"t":"lighthouse_keeper","x":96,"y":204},{"t":"quest_crystal","id":"preview","x":120,"y":204}]
	Game.adv_world={"start":"preview","abilities":[],"rooms":{"preview":{"pos":Vector2i.ZERO,"level":Game.level}}}
	Game.adv=Adventure.new_run(Game.adv_world)
	Game.adv.blocks=4;Game.adv.stamina=60;Game.adv.stress_blocks=4;Game.adv.stress=125
	Adventure.Story.lighthouse_talk(Game.adv)
	Adventure.Story.give_item(Game.adv,"crystal",2)
	var world=load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	await snap("hud-and-giant")
	var map=load("res://scripts/map_view.gd").new(world)
	world.ui.add_child(map)
	map._set_tab(2)
	await snap("items")
	map.free()
	world.talk_lighthouse("Lighthouse keeper")
	await snap("dialogue")
	world.dialogue.finish()
	var crossing=load("res://scripts/ui/boat_crossing.gd").new()
	crossing.world=world
	world.ui.add_child(crossing)
	crossing.set_physics_process(false)
	crossing.model.phase="evade";crossing.model.warning=0.5
	crossing.model.tentacles=[{"x":30.0,"y":122.0,"velocity":300.0}]
	await snap("crossing")
	Game.quit_game(0)
