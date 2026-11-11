extends "res://tests/test_runner.gd"
func fixture(kind := "enemy_hornback", build: Dictionary = {}, wall_x := 19, gap_x := -1) -> void:
	if w:w.free()
	Game.adv={};Game.level=Game.new_level("ordinary corner",40,20)
	Game.level.tiles=[]
	for y in 20:Game.level.tiles.append("1".repeat(40) if y>=16 else "0".repeat(40))
	if wall_x>=0:Game.level.tiles[15]="0".repeat(wall_x)+"1"+"0".repeat(39-wall_x)
	if gap_x>=0:Game.level.tiles[16]="1".repeat(gap_x)+"0"+"1".repeat(39-gap_x)
	var enemy:Dictionary={"t":kind,"x":96,"y":118}
	enemy.merge(build,true)
	Game.level.entities=[{"t":"spawn","x":140,"y":120},enemy]
	w=load("res://scripts/world.gd").new();add_child(w);w.set_physics_process(false)
	w.player=Bot.new(w,Vector2(140,128));p().on_ground=true
func _ready() -> void:
	var catalog=E.AttackCatalog.shared()
	var profiles:Dictionary=catalog.enemy_profiles.duplicate(true)
	var assignments:Array=catalog.assignments.duplicate(true)
	var charge:Dictionary=catalog.attack("charge")
	var original:Dictionary=charge.duplicate(true)
	catalog.enemy_profiles.enemy_hornback={"cornered_coverage_attack":"charge"}
	var binding:Dictionary=catalog.ordered_attacks("enemy_hornback","default")[0]
	binding.trigger_condition="player_cornered";binding.skip_chance="0"
	check(catalog.validate().is_empty(),"Ordinary charge coverage and cornered condition are valid authoring")
	fixture()
	var enemy=w.ents.filter(func(e):return e.d.t=="enemy_hornback")[0]
	if not enemy.has_method("_cornered"):
		check(false,"Ordinary enemies expose a real coverage/context adapter")
	else:
		check(enemy._cornered(p()) and enemy.atk_ready(),"Ground charge covers every standing escape position and enables its binding")
		var before:Rect2i=enemy.rect
		var meter:float=enemy.floor_patrol.remainder
		enemy._cornered(p())
		check(enemy.rect==before and enemy.floor_patrol.remainder==meter and not p().dead,"Prediction does not move the enemy, alter motion remainder or damage the player")
		charge.max_distance_units="1"
		check(not enemy._cornered(p()) and not enemy.atk_ready(),"A short real charge cannot use the search envelope as damage reach")
		charge.max_distance_units=original.max_distance_units
		p().on_ground=false
		check(not enemy._cornered(p()) and not enemy.atk_ready(),"Ordinary corner condition rejects an airborne player")
		p().on_ground=true
		fixture("enemy_hornback",{},-1)
		enemy=w.ents.filter(func(e):return e.d.t=="enemy_hornback")[0]
		check(not enemy._cornered(p()),"An open floor corridor does not qualify")
		fixture();enemy=w.ents.filter(func(e):return e.d.t=="enemy_hornback")[0]
		var hazard=E.make(w,{"t":"spikes_up","x":120,"y":120});w._register(hazard)
		check(not enemy._cornered(p()),"Real charge safety stops before intervening spikes")
		fixture();enemy=w.ents.filter(func(e):return e.d.t=="enemy_hornback")[0]
		enemy.phase="idle";enemy.timer=0;enemy.update(0)
		check(enemy.phase=="windup","A cornered binding starts the ordinary charge through its actual AI decision")
		catalog.enemy_profiles.enemy_hornback.cornered_coverage_attack=""
		check(not enemy._cornered(p()),"Coverage can be disabled explicitly")
		catalog.enemy_profiles.enemy_monster={"cornered_coverage_attack":"charge"}
		fixture("enemy_monster",{"move":"patrol","attacks":["charge"],"traits":[],"tier":0,"look":"enemy_hornback"})
		enemy=w.ents.filter(func(e):return e.d.t=="enemy_monster")[0]
		check(enemy._cornered(p()),"Grounded library charge uses the same coverage adapter")
		var library_binding:Dictionary=catalog.ordered_attacks("enemy_monster","default",["charge"])[0]
		library_binding.trigger_condition="player_cornered"
		enemy.update(0)
		check(enemy.phase=="windup" and enemy.attack=="charge","Library selection receives the real cornered context")
		fixture("enemy_monster",{"move":"patrol","attacks":["charge"],"traits":[],"tier":0,"look":"enemy_hornback"},-1)
		enemy=w.ents.filter(func(e):return e.d.t=="enemy_monster")[0]
		p().pos=Vector2(140,128);p().on_ground=true
		enemy.update(0)
		check(enemy.phase!="windup","Library cornered binding is ineligible in an open corridor")
		fixture("enemy_monster",{"move":"hover","attacks":["charge"],"traits":[],"tier":0,"look":"enemy_bat"})
		enemy=w.ents.filter(func(e):return e.d.t=="enemy_monster")[0]
		check(not enemy._cornered(p()),"Unsupported flying trajectories cannot pretend to use a floor-charge footprint")
	catalog.enemy_profiles.enemy_hornback={"cornered_coverage_attack":"charge"}
	fixture();enemy_trace_parity()
	fixture("enemy_hornback",{},6)
	var left_enemy=w.ents.filter(func(e):return e.d.t=="enemy_hornback")[0]
	p().pos=Vector2(64,128);p().on_ground=true
	check(left_enemy._cornered(p()),"Ordinary charge coverage works toward the left wall")
	fixture("enemy_hornback",{},19,16)
	var pit_enemy=w.ents.filter(func(e):return e.d.t=="enemy_hornback")[0]
	p().pos=Vector2(140,128);p().on_ground=true
	check(not pit_enemy._cornered(p()),"The ground-charge forecast stops at a real ledge")
	catalog.enemy_profiles.erase("enemy_hornback")
	var ui=load("res://scripts/attack_catalog_editor.gd").new()
	ui.catalog=catalog;add_child(ui)
	var index:int=ui.ENEMIES.map(func(e):return e[0]).find("enemy_hornback")
	ui._select_enemy(index)
	var health:Array=ui.form.find_children("FamilyHealth","LineEdit",true,false)
	var picker:OptionButton=ui.form.find_children("*","OptionButton",true,false).filter(func(n):return n.get_item_text(0)=="Disabled")[0]
	health[0].text_changed.emit("7")
	picker.select(1);picker.item_selected.emit(1)
	check(catalog.enemy_profile("enemy_hornback").get("max_hp")==7 and catalog.enemy_profile("enemy_hornback").get("cornered_coverage_attack")=="charge","Editing health then coverage persists both fields on a newly created family profile")
	ui.free()
	await get_tree().process_frame
	var draft=E.AttackCatalog.new();draft.reload()
	draft.enemy_profiles=catalog.enemy_profiles.duplicate(true)
	draft.assignments=catalog.assignments.duplicate(true)
	var folder:="user://ordinary_cornered"
	DirAccess.make_dir_recursive_absolute(folder)
	draft.attack_path=folder+"/attacks.csv";draft.assignment_path=folder+"/enemy_attacks.csv"
	check(draft.save_all().is_empty() and draft.reload() and draft.enemy_profile("enemy_hornback").get("max_hp")==7 and draft.enemy_profile("enemy_hornback").get("cornered_coverage_attack")=="charge" and draft.ordered_attacks("enemy_hornback","default")[0].trigger_condition=="player_cornered","Coverage, health and cornered reaction survive the real catalogue save/reload")
	catalog.enemy_profiles.enemy_hornback={"cornered_coverage_attack":"shoot"}
	check(not catalog.validate().is_empty(),"Unsupported footprint references are rejected")
	catalog.enemy_profiles=profiles;catalog.assignments=assignments
	charge.clear();charge.merge(original,true)
	if w:w.free();w=null
	await get_tree().process_frame
	print("ORDINARY CORNERED: %d failure(s)"%fails)
	Game.quit_game(fails)

func enemy_trace_parity() -> void:
	var enemy=w.ents.filter(func(e):return e.d.t=="enemy_hornback")[0]
	p().pos=Vector2(300,128)
	enemy.floor_patrol.remainder=0.4
	var forecast:Dictionary=enemy._cornered_coverage(p())
	var initial:Rect2i=enemy.rect
	enemy.phase="charge";enemy.charged=0;enemy.facing=1
	for tick in 120:
		enemy.update(DT)
		if enemy.phase=="rest":break
	check(forecast.has("sweep") and forecast.sweep==initial.merge(enemy.rect) and enemy.phase=="rest","Predicted swept charge equals the real runner's terrain-stopped movement including fractional remainder")
