extends "res://tests/test_runner.gd"
const Adventure := preload("res://scripts/adventure.gd")
func fixture(objects: Array) -> void:
	if w: w.free()
	Game.level=Game.new_level("nonmap",40,30)
	Game.level.entities=[{"t":"spawn","x":32,"y":208}]+objects
	Game.adv_world={"start":"test","abilities":[],"rooms":{"test":{"pos":Vector2i.ZERO,"level":Game.level}}}
	Game.adv=Adventure.new_run(Game.adv_world)
	Game.adv_temp=true
	w=load("res://scripts/world.gd").new()
	add_child(w)
	w.set_physics_process(false)
func _ready() -> void:
	if not E.TYPES.has("lighthouse_keeper"):
		check(false,"New quest entities are registered")
	else:
		fixture([{"t":"lighthouse_keeper","x":64,"y":196},{"t":"quest_crystal","id":"a","x":120,"y":200},{"t":"stress_block","id":"stress1","x":144,"y":200}])
		var npc=w.ents.filter(func(e):return e.d.t=="lighthouse_keeper")[0]
		var crystal=w.ents.filter(func(e):return e.d.t=="quest_crystal")[0]
		p().interact=true
		crystal.touch(p())
		check(Adventure.Story.count(Game.adv,"crystal")==0,"Quest crystals cannot be claimed before speaking to the keeper")
		p().interact=true
		npc.touch(p())
		check(not Game.has_ability("attack") and w.dialogue!=null,"Real keeper starts the quest without granting a sword")
		w.dialogue.finish()
		p().interact=true
		crystal.touch(p())
		check(not crystal.collidable and Adventure.Story.count(Game.adv,"crystal")==1,"Real crystal is an explicit interactable unique inventory pickup")
		var upgrade=w.ents.filter(func(e):return e.d.t=="stress_block")[0]
		p().interact=true
		upgrade.touch(p())
		check(Adventure.Stress.blocks(Game.adv)==2 and not upgrade.collidable,"Stress upgrade adds one persistent capacity block")
		w._build()
		check(not w.ents.filter(func(e):return e.d.t=="quest_crystal")[0].collidable and not w.ents.filter(func(e):return e.d.t=="stress_block")[0].collidable,"Room rebuild cannot duplicate quest or stress pickups")
		var map=load("res://scripts/map_view.gd").new(w)
		w.ui.add_child(map)
		map._set_tab(2)
		check(map.TABS==["Map","Monsters","Items","Abilities"] and map.progress.visible,"Map overlay exposes Items and Abilities tabs")
		w.grant_ability("attack")
		map._set_tab(3)
		check(map.progress_content.get_children().any(func(n):return n is Label and n.text=="Sword"),"Abilities page lists the acquired sword")
		map.free()
		var bars=load("res://scripts/ui/resource_bars.gd").layout(Game.adv)
		check(bars.stamina[0].rect.end.y==bars.stress[0].rect.position.y and bars.stress.size()==2,"Resource rows are attached and stress segmentation follows owned capacity")
		fixture([{"t":"thick_water","x":0,"y":80,"w":320,"h":160}])
		p().pos=Vector2(80,160)
		check(w.in_water() and w.liquid_at(p().hurt_rect(),"water"),"Thick water uses real water immersion rules")
		p().underwater=true;p().move_x=1
		for i in 120:p()._swim_update(DT)
		check(absf(p().speed.x)<=p().WATER_MAX_X*0.45+0.01,"Thick-water steering is slower than normal water")
		fixture([])
		w.data.heat_drain=2.0
		Game.adv.stamina=20
		for tick in 5:
			w.frame=tick*12;w.update_stamina(DT)
		check(is_equal_approx(Game.adv.stamina,18),"Heat causes net energy loss rather than being cancelled by regeneration")
		Game.adv.abilities.append("heat_resist")
		check(w.heat_drain()==0,"Heat-resistance ability disables the heat drain and tint")
		Game.adv.abilities.append("double_jump")
		p().pos=Vector2(80,160);p().on_ground=false;p().jump_grace_timer=0;p().jump_buf=0.1
		p()._normal_update(DT)
		check(p().air_jump_used and p().speed.y<0,"Acquired double jump grants one real airborne jump")
		p().speed.y=0;p().jump_buf=0.1
		p()._normal_update(DT)
		check(p().speed.y>=0,"The double jump cannot repeat infinitely in one airtime")
		fixture([{"t":"dialogue_npc","id":"trade","x":64,"y":196,"requires_items":{"key":1},"consume_items":true,"give_items":{"gem":1},"text":"Thank you."},{"t":"item_pickup","id":"key1","x":120,"y":200},{"t":"rock_giant","x":160,"y":180}])
		var trader=w.ents.filter(func(e):return e.d.t=="dialogue_npc")[0]
		p().interact=true;trader.touch(p())
		check(Adventure.Story.count(Game.adv,"gem")==0,"Real NPC denies rewards without required items")
		w.dialogue.finish()
		var key=w.ents.filter(func(e):return e.d.t=="item_pickup")[0]
		p().interact=true;key.touch(p())
		p().interact=true;key.touch(p())
		check(Adventure.Story.count(Game.adv,"key")==1,"Repeated direct item interaction cannot duplicate a key")
		p().interact=true;trader.touch(p())
		w.dialogue.finish()
		p().interact=true;trader.touch(p())
		check(Adventure.Story.count(Game.adv,"key")==0 and Adventure.Story.count(Game.adv,"gem")==1,"Real NPC consumes key and grants its reward only once")
		w.dialogue.finish()
		var giant=w.ents.filter(func(e):return e.d.t=="rock_giant")[0]
		p().pos=Vector2(40,208)
		check(giant.base.y+24==28*8 and giant.rect.end.y<=28*8-24,"Giant foot finds the floor and leaves a passable gap while raised")
		giant.timer=0;giant.update(DT)
		check(giant.phase=="warn" and giant.wave==0,"Giant warns before the damaging stomp")
		for i in 65:giant.update(DT)
		check(giant.phase=="recover" and giant.wave>0 and giant.rect.end.y==28*8,"Giant stomp lands on the floor and creates a short ground wave")
		var bad=Game.level.duplicate(true)
		bad.entities.append({"t":"dialogue_npc","x":64,"y":196,"give_items":{"gem":-1}})
		check(Game.validate_level(bad).is_empty(),"Room validation rejects malformed story transactions")
		fixture([{"t":"boat","id":"boat","to":"test:arrival","x":40,"y":184,"w":80,"h":32},{"t":"house_door","id":"arrival","x":200,"y":192,"w":16,"h":24}])
		var boat=w.ents.filter(func(e):return e.d.t=="boat")[0]
		w.start_sea_crossing(boat)
		check(w.dialogue!=null and w.crossing==null,"Real boat refuses travel until the quest is turned in")
		w.dialogue.finish()
		Adventure.Story.set_event(Game.adv,"boat_unlocked")
		w.start_sea_crossing(boat)
		check(w.crossing!=null,"Unlocked boat starts a playable crossing without editing a map")
		w.crossing.model.phase="done"
		w.crossing._physics_process(DT)
		check(Adventure.Story.has_event(Game.adv,"boat_lost") and p().pos.x>=200 and w.dialogue!=null,"Successful crossing transfers to configured dock and persistently loses the boat")
	if w:w.free()
	Game.adv={};Game.adv_temp=false
	Game.editor_level=Game.new_level("story authoring",40,30)
	var editor=load("res://scripts/editor.gd").new()
	add_child(editor)
	await get_tree().process_frame
	editor.environment_pick.select(editor.Art.EnvironmentArt.THEMES.find("volcano")+1)
	editor.environment_pick.item_selected.emit(editor.environment_pick.selected)
	check(editor.level.environment=="volcano" and editor.heat_spin.value==2,"Editor environment selection exposes the default volcanic heat")
	editor.heat_spin.value=3.25
	check(editor.level.heat_drain is int and editor.level.heat_drain==3,"Editor authors whole heat drain")
	editor._undo()
	check(not editor.level.has("heat_drain") and editor.heat_spin.value==2,"Heat-setting undo restores implicit room defaults")
	editor.clip={"w":2,"h":2,"tiles":["00","00"],"entities":[{"t":"quest_crystal","id":"original","x":0,"y":0}]}
	editor._paste(Vector2i(4,4))
	var placed:Dictionary=editor.level.entities[-1]
	check(placed.id!="original" and placed.t=="quest_crystal","Pasted quest pickups receive a new persistent ID")
	editor._ask_story(placed)
	var dialog=editor.get_child(-1)
	check(dialog is ConfirmationDialog and dialog.visible,"Story entity settings are reachable in the editor")
	dialog.hide()
	editor.queue_free()
	Game.editor_level={}

	await get_tree().process_frame
	print("NONMAP ENTITIES: %d failure(s)"%fails)
	Game.quit_game(fails)
