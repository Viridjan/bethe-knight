extends Node
var fails := 0
func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ")+message)
	if not ok: fails+=1
func fixture() -> Dictionary:
	var base := Game.new_level("Layer fixture",40,30)
	base.entities=[{"t":"spawn","x":32,"y":208},{"t":"stamina_orb","x":80,"y":200},{"t":"layer_passage","id":"entrance","to_layer":"cave","to":"exit","x":80,"y":184,"w":16,"h":40}]
	var cave := Game.new_level("Cavern",40,30)
	cave.entities=[{"t":"spawn","x":112,"y":192,"w":32,"h":32},{"t":"stamina_orb","x":80,"y":200},{"t":"layer_passage","id":"exit","to_layer":"main","to":"entrance","x":120,"y":184,"w":16,"h":40}]
	base.layers={"cave":cave}
	return base
func _ready() -> void:
	Game.adv={};Game.adv_temp=true
	Game.level=fixture()
	var world=load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	if not world.has_method("switch_layer"):
		check(false,"World supports retained room layers")
	else:
		var manager=world.layer_manager
		check(manager.worlds.size()==2,"All layer worlds are instantiated on room load")
		var cave=manager.worlds.cave
		check(not cave.visible,"Unvisited preloaded layers remain concealed")
		var orb=world.ents.filter(func(e):return e.d.t=="stamina_orb")[0]
		orb.respawn=1.25
		var player=world.player
		check(world.switch_layer("cave",Vector2(124,216)),"Switch to a valid cavern layer")
		cave.set_physics_process(false)
		check(manager.active=="cave" and cave.player==player and player.w==cave,"One controllable player transfers to the active layer")
		check(not world.layer_active and not world.is_physics_processing() and not world.ui.visible,"Inactive layer simulation and UI stop")
		check(world.layer_shade.visible and not cave.layer_shade.visible,"A thick black overlay covers only inactive layers")
		check(orb.respawn==1.25 and world.ents.has(orb),"Inactive entity objects and their state stay loaded")
		var before=manager.active
		check(not cave.switch_layer("missing",Vector2.ZERO) and manager.active==before,"Invalid layer target changes nothing")
		check(world.star_key("same")!=cave.star_key("same"),"Equal pickup IDs in different layers do not collide")
		check(not cave.switch_layer("main",Vector2(4,236)),"Blocked layer arrivals are rejected atomically")
		check(cave.switch_layer("main",Vector2(84,216)) and world.ents.has(orb) and orb.respawn==1.25,"Returning resumes the same retained objects")
		world.set_physics_process(false)
		var passage=world.ents.filter(func(e):return e.d.t=="layer_passage")[0]
		world.player.on_ground=true;world.player.interact=true
		passage.touch(world.player);world.after_player_move()
		check(manager.active=="cave" and cave.player.pos.x>=120,"Interact passage reaches the configured layer doorway")
		cave.set_physics_process(false)
		Game.get_sfx().cooldowns.clear()
		Game.play_sfx("cave_roar")
		manager.activate("main",Vector2(84,216))
		check(Game.get_sfx().voices.all(func(v):return not v.playing),"Switching stops all old-layer SFX voices")
		world.set_physics_process(false)
		check(not Game.validate_level(fixture()).is_empty(),"Valid layered rooms pass level validation")
		var bad=fixture();bad.layers.cave.w=39
		check(Game.validate_level(bad).is_empty(),"Mismatched layer dimensions are rejected")
		bad=fixture();bad.layers.cave.entities[2].to="missing"
		check(Game.validate_level(bad).is_empty(),"Dangling cross-layer passage links are rejected")
	world.queue_free()
	await get_tree().process_frame
	Game.level=fixture()
	Game.adv_world={"start":"test","abilities":[],"rooms":{"test":{"pos":Vector2i.ZERO,"level":Game.level}}}
	Game.adv=Game.Adventure.new_run(Game.adv_world)
	world=load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	check(world.switch_layer("cave",Vector2(124,224)),"Adventure enters a safe layered checkpoint")
	var nested=world.layer_manager.worlds.cave
	nested.set_physics_process(false)
	check(Game.adv.layer=="cave" and Game.adv.room=="test" and Game.adv.spawn==[124.0,224.0],"Safe arrival persists room, checkpoint and layer together")
	var restored:Dictionary=Game.Adventure.restore_run(Game.adv_world,JSON.parse_string(JSON.stringify(Game.adv)))
	world.free()
	Game.adv=restored
	world=load("res://scripts/world.gd").new()
	add_child(world)
	check(world.layer_manager.active=="cave" and world.layer_manager.worlds.cave.player.pos==Vector2(124,224),"Continue restores the saved plane and safe checkpoint")
	world.layer_manager.worlds.cave.set_physics_process(false)
	var other=Game.new_level("Other",40,30)
	Game.adv_world.rooms.other={"pos":Vector2i(40,0),"level":other}
	world.layer_manager.worlds.cave.enter_room("other",Vector2(32,208))
	check(world.room=="other" and world.layer_manager==null and world.layer_active,"A doorway to another room releases all old planes and restores root ownership")
	world.set_physics_process(false)
	world.respawn()
	check(world.room=="test" and world.layer_manager.active=="cave","Respawn from another room returns to the saved interior plane")
	world.layer_manager.worlds.cave.set_physics_process(false)
	world.queue_free()
	Game.adv={}
	await get_tree().process_frame
	Game.editor_level=fixture()
	var editor=load("res://scripts/editor.gd").new()
	add_child(editor)
	await get_tree().process_frame
	check(editor.select_room_layer("cave"),"Editor selects a nested room layer for normal terrain tools")
	editor.level.entities.append({"t":"note","x":64,"y":200,"text":"Cave only"})
	check(editor.select_room_layer("main") and not editor.level.entities.any(func(e):return e.get("text")=="Cave only"),"Layer authoring keeps terrain and entities independent")
	var packed:Dictionary=editor.room_layers.pack()
	check(packed.layers.cave.entities.any(func(e):return e.get("text")=="Cave only") and not Game.validate_level(packed.duplicate(true)).is_empty(),"Editor packs every plane into one valid room file")
	check(editor._resize_bounds(Rect2i(-2,0,42,30)),"Room edge resizing applies to all planes")
	packed=editor.room_layers.pack()
	check(packed.w==42 and packed.layers.cave.w==42 and packed.layers.cave.entities[2].x==136,"Other planes resize and translate passage objects together")
	editor._undo()
	check(editor.level.w==40 and editor.room_layers.pack().layers.cave.w==40,"Undo restores all room layers atomically")
	check(editor.room_layers.add("secret") and editor.room_layers.documents.size()==3,"Editor adds a new empty plane")
	editor._undo()
	check(not editor.room_layers.documents.has("secret"),"Undo removes the newly added plane")
	Game.editor_dir="user://layer_checks/"
	Game.editor_file="layered_room"
	DirAccess.make_dir_recursive_absolute(Game.editor_dir)
	check(editor._save(),"Editor saves the full layered room through the normal save workflow")
	var disk:Dictionary=Game.load_level("layered_room",Game.editor_dir)
	check(disk.has("layers") and disk.layers.cave.entities.any(func(e):return e.get("text")=="Cave only"),"Saved room reload retains the inactive plane edits")
	editor.queue_free()
	Game.editor_level={}
	await get_tree().process_frame
	await check_lighthouse_climb()
	print("ROOM LAYERS: %d failure(s)"%fails)
	Game.quit_game(fails)

func check_lighthouse_climb() -> void:
	Game.adv_world=Game.Adventure.load_world(Game.STORY_WORLD)
	var legacy:Dictionary=Game.Adventure.restore_run(Game.adv_world,{"room":"h1_villager_house","spawn":[24,96],"stamina":12.0})
	check(legacy.room=="t1_cove_town" and legacy.layer=="h1_villager_house" and legacy.spawn==[64.0,96.0],"Legacy detached-house saves migrate to the parent plane and translated checkpoint")
	var roof:Dictionary=Game.Adventure.restore_run(Game.adv_world,{"room":"s3_lighthouse_top","spawn":[64,88]})
	check(roof.room=="s2_shore" and roof.layer=="main" and Vector2(roof.spawn[0],roof.spawn[1])==Vector2(372,40),"Legacy lighthouse-top saves migrate onto the real Shore roof (%s / %s / %s)"%[roof.room,roof.layer,roof.spawn])
	Game.level=Game.adv_world.rooms.s2_shore.level
	Game.adv=Game.Adventure.new_run(Game.adv_world)
	Game.adv.room="s2_shore"
	Game.adv_temp=true
	var root=load("res://scripts/world.gd").new()
	add_child(root)
	root.set_physics_process(false)
	check(root.switch_layer("lh1_lighthouse_stairs",Vector2(372,408)),"Shore entrance reaches the actual narrow lighthouse interior")
	var inside=root.layer_manager.worlds.lh1_lighthouse_stairs
	inside.set_physics_process(false)
	var bot=load("res://tests/test_runner.gd").Bot.new(inside,Vector2(372,408))
	inside.player=bot
	var climbed:=true
	var failed_at:=-1
	for index in 15:
		var floor_y:=384-index*24
		var goal:=372 if index%2==0 else 404
		# A long climb includes safe recovery landings; it does not require capacity upgrades.
		for rest in 180:
			if Game.adv.stamina>=10:break
			bot.hold={}
			bot.update(1.0/60.0)
			inside.after_player_move()
			inside.update_stamina(1.0/60.0)
		bot.tap={"jump":true}
		var landed:=false
		for tick in 150:
			bot.hold={"jump":true}
			if bot.pos.x<goal-2:bot.hold.right=true
			elif bot.pos.x>goal+2:bot.hold.left=true
			bot.update(1.0/60.0)
			inside.after_player_move()
			inside.update_stamina(1.0/60.0)
			if bot.on_ground and absf(bot.pos.y-floor_y)<1:
				landed=true
				break
		if not landed:
			climbed=false
			failed_at=index
			break
	check(climbed and not bot.dead,"Every lighthouse stair is reachable with real jump-only physics and starting stamina (step %d, at %s, energy %s)"%[failed_at,bot.pos,Game.adv.stamina])
	if climbed:
		var exit=inside.ents.filter(func(e):return e.d.t=="layer_passage" and e.d.id=="top")[0]
		inside._go_door(exit)
		check(root.layer_manager.active=="main" and root.player.pos.y==40,"Actual top passage exits onto the lamp roof in the same Shore room")
	root.queue_free()
	Game.adv={}
	await get_tree().process_frame
