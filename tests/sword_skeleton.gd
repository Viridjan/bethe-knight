extends "res://tests/nonmap_entities.gd"
func _ready() -> void:
	check(not E.TYPES.has("refill") and not E.TYPES.has("refill_two"),"Dash crystals are absent from the entity catalogue")
	var run:=Adventure.new_run({"start":"test"})
	Adventure.Story.lighthouse_talk(run)
	check(not run.abilities.has("attack") and run.quests.get("lighthouse_crystals")=="started","Keeper starts crystal quest without granting a sword")
	var old:=Game.new_level("legacy crystals",40,30)
	old.entities.append({"t":"refill","x":40,"y":40,"object_id":"old_crystal"})
	old.entities.append({"t":"trigger_zone","x":64,"y":40,"w":16,"h":16,"object_id":"old_trigger","trigger":{"on_enter":[{"target":"old_crystal","action":"stop_motion"}]}})
	old.layers={"interior":Game.new_level("old interior",40,30)}
	old.layers.interior.entities.append({"t":"refill_two","x":48,"y":40})
	var cleaned:=Game.validate_level(old)
	check(not cleaned.is_empty() and not cleaned.entities.any(func(e):return e.t=="refill") and not cleaned.layers.interior.entities.any(func(e):return e.t=="refill_two"),"Legacy crystal entities are removed without invalidating saved rooms or layers")
	check(E.TYPES.has("dead_skeleton"),"Dead skeleton is an authorable story entity")
	if E.TYPES.has("dead_skeleton"):
		fixture([{"t":"dead_skeleton","id":"fallen","x":96,"y":208}])
		var bones=w.ents.filter(func(e):return e.d.t=="dead_skeleton")[0]
		check(not p().has_method("use_refill"),"Dash-crystal consumption API is removed")
		bones.touch(p())
		check(not Game.has_ability("attack"),"Passing the skeleton does not automatically collect the sword")
		p().interact=true;bones.touch(p())
		check(Game.has_ability("attack") and not p().interact,"Interact takes the skeleton's sword")
		var stress:int=Game.adv.stress
		p().interact=true;bones.touch(p())
		check(Game.adv.abilities.count("attack")==1 and Game.adv.stress==stress and bones.collidable,"Repeated interaction leaves the skeleton without duplicate rewards")
		var saved:=Adventure.restore_run(Game.adv_world,JSON.parse_string(JSON.stringify(Game.adv)))
		check(saved.abilities.has("attack"),"Skeleton sword survives save and continue")
		w.free();w=null
	var coast:=Game.load_level("s2_shore","res://worlds/story/")
	check(coast.get("entities",[]).any(func(e):return e.t=="dead_skeleton"),"Sword skeleton is placed after the sand-cave exit")
	if E.TYPES.has("dead_skeleton"):
		Game.level=coast
		Game.adv_world={"start":"s2_shore","rooms":{"s2_shore":{"pos":Vector2i.ZERO,"level":coast}}}
		Game.adv=Adventure.new_run(Game.adv_world);Game.adv_temp=true
		w=load("res://scripts/world.gd").new();add_child(w);w.set_physics_process(false)
		w.player=Bot.new(w,Vector2(28,328))
		var corpse=w.ents.filter(func(e):return e.d.t=="dead_skeleton")[0]
		check(w.safe_spawn(Vector2(corpse.rect.get_center().x,corpse.rect.end.y)),"Authored skeleton rests on safe permanent ground beyond the cave exit")
		p().hold={"right":true};step(20)
		p().hold={};p().tap={"interact":true};step()
		check(Game.has_ability("attack") and p().on_ground,"The sword can be reached and taken from the actual Shore entrance without another ability")
		w.free();w=null
	var village:=Game.load_level("l3_treetop_village","res://worlds/story/")
	check(village.get("entities",[]).any(func(e):return e.t=="ability_climb"),"Opposite village branch contains climb reward")
	Game.level=village
	Game.adv_world={"start":"l3_treetop_village","rooms":{"l3_treetop_village":{"pos":Vector2i.ZERO,"level":village}}}
	Game.adv=Adventure.new_run(Game.adv_world);Game.adv_temp=true
	w=load("res://scripts/world.gd").new();add_child(w);w.set_physics_process(false)
	w.player=Bot.new(w,Vector2(56,120));p().hold={"right":true}
	for tick in 400:
		step()
		if Game.has_ability("climb"):break
	check(Game.has_ability("climb") and not Game.has_ability("attack"),"Village branch reward is reachable with no sword or climb prerequisite")
	w.free();w=null
	Game.adv={}
	print("SWORD SKELETON: %d failure(s)"%fails)
	Game.quit_game(fails)
