extends "res://tests/nonmap_entities.gd"
const Catalog := preload("res://scripts/attack_catalog.gd")
func _ready() -> void:
	var run := Adventure.new_run({"start":"test"})
	check(run.stamina is int and run.stress is int,"Fresh resources are integers")
	var restored := Adventure.restore_run({"start":"test","rooms":{"test":{}}},{"room":"test","stamina":19.9,"stress":51.9})
	check(restored.stamina is int and restored.stamina==19 and restored.stress is int and restored.stress==51,"Legacy fractional resources truncate on load")
	var rules = load("res://scripts/progression/environment_rules.gd")
	check(rules.heat({"heat_drain":3.9}) is int and rules.heat({"heat_drain":3.9})==3,"Heat rates truncate to whole points")
	for completed in 5:
		run.stress_blocks=4;run.stress=completed*50
		check(is_equal_approx(Adventure.Stress.recovery_multiplier(run),[1.0,0.93,0.85,0.78,0.70][completed]),"Four-block penalty truncates cumulative percentage")
	var catalog := Catalog.new()
	var result := catalog.score_attack({"coverage_area_units2":"2.5","animation_s":"0.3","windup_s":"0","base_weight":"1"})
	check(result.valid and result.score is int and result.score==8,"Attack scores truncate without quantizing timing or geometry")
	check(catalog.enemy_score([],2.9).score is int and catalog.enemy_score([],2.9).score==2,"Enemy total score truncates")
	for row in [[0,4],[11,6],[22,8],[33,5],[44,3]]:
		check(Adventure.regen_rate({"stamina":row[0],"blocks":2,"stress":0,"stress_blocks":1})==row[1],"Integer interpolation at %d stamina"%row[0])
	var invalid := Game.new_level("fractional heat",40,30)
	invalid.heat_drain=3.25
	check(Game.validate_level(invalid).is_empty(),"Room validation rejects fractional resource rates")
	var cool := Game.new_level("cool retreat",40,30)
	cool.heat_drain=0
	check(not Game.validate_level(cool).is_empty(),"Zero whole heat drain remains a valid cool retreat")
	if ResourceLoader.exists("res://scripts/progression/game_tick.gd"):
		var tick_rules = load("res://scripts/progression/game_tick.gd")
		for rate in 61:
			var exact := true
			for start in 7:
				var total := 0
				for tick in range(start,start+5):total+=tick_rules.share(rate,tick)
				exact=exact and total==rate
			check(exact,"Five consecutive ticks preserve whole rate %d"%rate)
		fixture([])
		Game.adv.stamina=10
		p().pos=Vector2(80,120);p().speed=Vector2(90,0)
		w._physics_process(DT)
		check(w.frame==1 and p().pos!=Vector2(80,120) and Game.adv.stamina==10,"Physics advances on a frame without resource accounting")
		w.paused=true;w._physics_process(DT)
		check(w.frame==1,"Pause does not advance the resource clock")
		w.paused=false;w.freeze=1;w._physics_process(DT)
		check(w.frame==1,"Hit freeze does not advance the resource clock")
		w.freeze=0;w.layer_active=false;w._physics_process(DT)
		check(w.frame==1,"Inactive layer does not advance the resource clock")
		w.layer_active=true
		w.data.heat_drain=2
		for i in 11:
			w.frame=i+1;w.update_stamina(DT)
		check(Game.adv.stamina==10,"Continuous drains do not change between tick frames")
		w.data.heat_drain=0
		w.drain_stamina(5)
		check(Game.adv.stamina==5 and Game.adv.stamina is int,"Jump costs apply immediately between ticks")
		var steps:=[]
		for i in 60:
			var held:int=Game.adv.stamina
			w.frame=12+i;w.update_stamina(DT)
			steps.append(Game.adv.stamina-held)
		check(Game.adv.stamina>5 and Game.adv.stamina is int and steps.max()==1,"Regeneration adds single whole points frame by frame")
		Game.adv.stamina=27;w.data.heat_drain=2
		for tick in 5:
			w.frame=tick*12;w.update_stamina(DT)
		check(Game.adv.stamina==25,"Low heat rate loses exactly two points per second without regeneration")
		Game.adv.stamina=27;p().state=p().ST_CLIMB;p().climb_no_move_timer=0;p().last_climb_move=-1
		w.data.heat_drain=0
		for tick in 5:
			w.frame=tick*12;w.update_stamina(DT)
		check(Game.adv.stamina==16,"Climbing up loses eleven whole points per second")
		p().last_climb_move=0
		for tick in 5:
			w.frame=tick*12;w.update_stamina(DT)
		check(Game.adv.stamina==14,"Holding a wall loses two points per second")
		w.data.heat_drain=2
		for tick in 5:
			w.frame=tick*12;w.update_stamina(DT)
		check(Game.adv.stamina==10,"Heat adds to climbing drain")
		fixture([{"t":"water","x":0,"y":0,"w":320,"h":224}])
		Game.adv.blocks=10;Game.adv.stamina=100;w.data.heat_drain=2
		for tick in 5:
			w.frame=tick*12;w.update_stamina(DT)
		check(Game.adv.stamina==58,"Water and heat combine to forty-two points per second")
		fixture([])
		Game.adv.stamina=27;w.data.heat_drain=2;p().stun_t=1
		for tick in 5:
			w.frame=tick*12;w.update_stamina(DT)
		check(Game.adv.stamina==25,"Heat still drains during stun without regeneration")
		p().stun_t=0;w.data.heat_drain=0;w.frame=13
		Game.adv.stamina=20;p().on_ground=false
		p().climb_jump()
		check(Game.adv.stamina==9 and Game.adv.stamina is int,"Climb jump immediately pays six plus the ordinary five-point jump cost")
		Game.adv.stamina=20
		check(w.spend_melee_stamina(2) and Game.adv.stamina==18,"Attack cost is immediate between ticks")
		var panel=load("res://scripts/stamina_panel.gd").new()
		panel.world=w
		var rate:Array=panel.rate()
		check(rate[0] is int and not str(rate[1]).contains(".") and str(rate[1]).contains("%"),"F3 regeneration presents integer rates and percentages")
		panel.free()
		Game.adv.stamina=20;Game.adv.stress=0;Game.adv.stress_exhausted=false
		p()._hard_landing()
		check(Game.adv.stamina==0 and Game.adv.stress==5,"Hard landing records exhaustion immediately between resource ticks")
		w.free();w=null
	else:check(false,"Deterministic resource tick module exists")
	Game.adv={}
	print("INTEGER RESOURCES: %d failure(s)"%fails)
	Game.quit_game(fails)
