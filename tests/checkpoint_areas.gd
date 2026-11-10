extends Node
var fails:=0
func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ")+message)
	if not ok:fails+=1
func _ready() -> void:
	Game.adv={}
	Game.level=Game.new_level("Checkpoint areas",40,30)
	for y in range(24,28):
		Game.level.tiles[y]=Game.level.tiles[y].substr(0,8)+"1".repeat(7)+Game.level.tiles[y].substr(15)
	Game.level.entities=[{"t":"spawn","x":64,"y":64,"w":96,"h":160}]
	var world=load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	if not world.has_method("checkpoint_for_area"):
		check(false,"World resolves user-defined checkpoint areas")
	else:
		var entity=world.ents[0]
		check(entity.rect==Rect2i(64,64,96,160),"The selected rectangle remains the full activation area")
		check(entity.point()==Vector2(124,224) and world.spawn==entity.point(),"Anchor chooses lowest safe terrain and then the nearest central column")
		world.spawn=Vector2(20,224)
		world.player.pos=Vector2(100,100)
		world.player.on_ground=false
		entity.touch(world.player)
		check(world.spawn==Vector2(124,224),"Entering the selected area in midair activates its grounded anchor")
		check(world.checkpoint_for_area(Rect2i(64,64,32,24))==Vector2(-1,-1),"An area with no permanent ground has no valid anchor")
		world.ents.append(load("res://scripts/entities.gd").make(world,{"t":"water","x":120,"y":208,"w":16,"h":16}))
		var water=world.ents.pop_back()
		world._register(water)
		check(world.checkpoint_for_area(Rect2i(64,64,96,160)).x>=140,"Lowest anchors skip unsafe liquid-covered floor")
		var small=load("res://scripts/entities.gd").make(world,{"t":"spawn","x":120,"y":160,"w":32,"h":64})
		world._register(small)
		small.resolve_point()
		world.spawn=Vector2(20,224)
		world.player.pos=Vector2(132,200)
		world.player_touch(world.player)
		check(world.spawn==small.point(),"Overlapping regions select the more specific area once")
	world.queue_free()
	await get_tree().process_frame
	Game.editor_level=Game.level.duplicate(true)
	Game.editor_level.entities=[]
	var editor=load("res://scripts/editor.gd").new()
	add_child(editor)
	await get_tree().process_frame
	editor.tool="spawn"
	editor._push_undo()
	editor._place_rect(Vector2i(8,8),Vector2i(19,27))
	check(editor.level.entities.size()==1 and editor.level.entities[0].respawn_at==[124,224],"Respawn tool drags a rectangle and previews the grounded lowest anchor")
	editor._resize_bounds(Rect2i(-2,0,42,30))
	check(editor.level.entities[0].x==80 and editor.level.entities[0].respawn_at==[140,224],"Room resizing moves the checkpoint region and refreshes its anchor")
	editor._undo()
	check(editor.level.entities[0].respawn_at==[124,224],"Undo restores the authored area and grounded anchor")
	var count:int=editor.level.entities.size()
	editor._place_rect(Vector2i(8,8),Vector2i(10,9))
	check(editor.level.entities.size()==count,"An unsupported selection is rejected without adding a checkpoint")
	editor.queue_free()
	Game.editor_level={}
	await get_tree().process_frame
	var outside=Game.new_level("Exterior",40,30)
	outside.entities=[{"t":"spawn","x":16,"y":216}]
	var interior=Game.new_level("No checkpoint",40,30)
	interior.entities=[]
	outside.layers={"cave":interior}
	Game.level=outside
	Game.adv_world={"start":"test","abilities":[],"rooms":{"test":{"pos":Vector2i.ZERO,"level":outside}}}
	Game.adv=Game.Adventure.new_run(Game.adv_world)
	Game.adv.spawn=[20,224]
	Game.adv_temp=true
	world=load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	world.switch_layer("cave",Vector2(124,224))
	world.layer_manager.worlds.cave.set_physics_process(false)
	check(Game.adv.layer=="main" and Game.adv.spawn==[20,224],"A layer entrance outside authored regions keeps the previous checkpoint")
	world.queue_free()
	Game.adv={}
	await get_tree().process_frame
	print("CHECKPOINT AREAS: %d failure(s)"%fails)
	Game.quit_game(fails)
