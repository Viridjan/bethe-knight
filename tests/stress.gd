extends "res://tests/test_runner.gd"
const Adventure := preload("res://scripts/adventure.gd")

func _ready() -> void:
	if not ResourceLoader.exists("res://scripts/progression/stress.gd"):
		check(false, "Persistent stress service exists")
		Game.quit_game(fails)
		return
	var stress = load("res://scripts/progression/stress.gd")
	var world := {"start": "test", "rooms": {"test": {}}, "abilities": []}
	var run: Dictionary = Adventure.new_run(world)
	check(run.stress == 0 and run.stress_blocks == 1, "New runs start with one empty stress block")
	run.stress_blocks = 5  # Exercise legacy capacity and event amounts.
	for i in 6:
		check(is_equal_approx(stress.recovery_multiplier(i * 50), [1.0, 0.94, 0.88, 0.82, 0.76, 0.70][i]), "Stress recovery target %d" % (i * 50))
	check(is_equal_approx(stress.recovery_multiplier(125), 0.88), "Partial blocks do not add another penalty")
	stress.change(run, 900)
	check(run.stress == 250, "Stress caps at five full bars")
	stress.change(run, -999)
	check(run.stress == 0, "Stress cannot go negative")
	run.stamina = 10.0
	stress.observe_exhaustion(run, Adventure.stamina_max(run))
	run.stamina = 4
	for i in 60: stress.observe_exhaustion(run, Adventure.stamina_max(run))
	check(run.stress == 5, "Exhaustion adds five once, not per frame")
	run.stamina = 10.0
	stress.observe_exhaustion(run, Adventure.stamina_max(run))
	Adventure.drain_stamina(run, 6)
	check(run.stress == 10, "Recovery rearms exhaustion and action costs detect it immediately")
	var old: Dictionary = Adventure.restore_run(world, {"room": "test", "stamina": 1.0})
	stress.observe_exhaustion(old, Adventure.stamina_max(old))
	check(old.stress == 0 and old.last_saved_at == 0, "Old saves migrate without an exhaustion charge or rest bonus")
	var clean := Adventure.new_run(world)
	clean.stamina = 16.0
	var stressed: Dictionary = clean.duplicate(true)
	stressed.stress = 250
	check(Adventure.regen_rate(clean)==7 and Adventure.regen_rate(stressed)==4,"Stress truncates the integer regeneration rate")
	await check_world_events(stress, world)
	check_rest(stress, world)
	await check_continue_flow()
	Game.adv = {}
	if w: w.queue_free()
	await get_tree().process_frame
	print("STRESS: %d failure(s)" % fails)
	Game.quit_game(fails)

func check_world_events(stress, world: Dictionary) -> void:
	Game.adv = {}
	make_world([{"t": "enemy_hornback", "x": 200, "y": 200}, {"t": "boss_ape", "x": 300, "y": 190}])
	Game.adv_world = {"rooms": {"test": {"pos": Vector2i.ZERO, "level": Game.level}}}
	Game.adv = Adventure.new_run(world)
	Game.adv.stress_blocks = 5
	Game.adv_temp = true
	w.room = "test"
	w.spawn_room = "test"
	Game.adv.stress = 250
	var enemy = w.ents.filter(func(e): return e.d.t == "enemy_hornback")[0]
	enemy.hp = 1
	enemy.hit(p())
	enemy.hit(p())
	check(Game.adv.stress == 200, "A real monster death reduces stress once")
	var ape = w.ents.filter(func(e): return e.d.t == "boss_ape")[0]
	ape._beaten()
	ape._beaten()
	check(Game.adv.stress == 100, "Boss victory reduces stress by 100, not 150 or twice")
	Game.adv.stress = 250
	w.collect_energy_fragment("stress-fragment")
	w.collect_energy_fragment("stress-fragment")
	check(Game.adv.stress == 150, "A persistent collectible reduces stress once")
	Game.adv.stress = 250
	w.add_stamina_block("stress-capacity")
	w.add_stamina_block("stress-capacity")
	check(Game.adv.stress == 150, "Capacity collectibles reduce stress once")
	Game.adv.stress = 250
	w.grant_ability("dash")
	w.grant_ability("dash")
	check(Game.adv.stress == 150, "Ability collectibles reduce stress once")
	Game.adv.stress = 250
	var berry := {"id": "stress-star", "pos": Vector2.ZERO}
	w.collect_berry(berry)
	w.collect_berry(berry)
	check(Game.adv.stress == 150, "Legacy stars also reduce stress only once")
	Game.adv.stress = 0
	w.on_player_death(p(), Vector2.ZERO)
	w.respawn()
	check(Game.adv.stress == 20, "Death adds twenty and respawn does not reset it")
	p().dashes = 0
	Game.adv.stamina = Adventure.BASE_STAMINA
	var before: float = Game.adv.stress
	p().hair_color()
	w.update_stamina(0)
	check(Game.adv.stress == before, "Dash-only grey hair does not add exhaustion stress")
	Game.adv = {}
	w.queue_free()
	w = null
	await get_tree().process_frame

func check_rest(stress, world: Dictionary) -> void:
	var run := Adventure.new_run(world)
	run.stress_blocks = 5
	run.stress = 200
	run.last_saved_at = 100000
	var now := 100000 + 12 * 60 * 60
	check(not stress.rest_due(run, now - 1) and stress.rest_due(run, now), "Rest qualifies at exactly twelve hours")
	check(not stress.rest_due(run, 99999), "A backwards clock grants nothing")
	Game.save_path = "user://stress_save.cfg"
	Game.adv_temp = false
	Game.adv = run
	check(Game.call("save_adventure", 100000), "Real save records its timestamp")
	check(Game.call("claim_stress_rest", now), "Eligible load commits its rest recovery")
	check(Game.adv.stress == 100 and not Game.call("claim_stress_rest", now), "A second claim cannot repeat the reduction")
	var saved: Dictionary = Game.read_config(Game.save_path).get_value("adventure", Game._run_key())
	check(saved.stress == 100 and saved.last_saved_at == now, "Reduced stress and rest timestamp persist together")
	Game.adv = saved.duplicate(true)
	check(not Game.call("claim_stress_rest", now), "Reloading the saved file cannot repeat rest")
	Game.adv.last_saved_at = now - 86400
	Game.adv.stress = 250
	check(Game.call("claim_stress_rest", now) and Game.adv.stress == 150, "Twenty-four hours still grants only two bars")
	Game.adv.last_saved_at = 100000
	Game.save_path = "user://missing_stress_folder/save.cfg"
	var before: Dictionary = Game.adv.duplicate(true)
	check(not Game.call("claim_stress_rest", now) and Game.adv == before, "Failed saves cannot grant or consume rest")
	check(not Game.save_adventure(now) and Game.adv == before, "Failed ordinary saves also leave the successful-save timestamp unchanged")
	Game.save_path = Game.SAVE_PATH
	Game.adv_temp = true

func check_continue_flow() -> void:
	var actual_world: Dictionary = Adventure.load_world(Game.world_path)
	Game.adv = Adventure.new_run(actual_world)
	Game.adv.stress_blocks = 5
	Game.adv.stress = 200
	Game.adv_temp = false
	Game.save_path = "user://stress_continue.cfg"
	Game.save_adventure(int(Time.get_unix_time_from_system()) - 43210)
	Game.main = self
	w = null
	Game.start_adventure(false)
	var scene = get_child(-1)
	scene.set_physics_process(false)
	check(Game.adv.stress == 100 and scene.note_label.text.contains("Rested"), "Actual Continue flow claims rest and explains the reduction")
	await get_tree().process_frame
	Game.start_adventure(false)
	scene = get_child(-1)
	scene.set_physics_process(false)
	check(Game.adv.stress == 100 and not scene.note_label.text.contains("Rested"), "A second Continue does not repeat the rest reward or message")
	Game.adv = {}
	scene.queue_free()
	Game.save_path = Game.SAVE_PATH
	Game.adv_temp = true
	await get_tree().process_frame
