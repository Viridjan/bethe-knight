extends "res://tests/test_runner.gd"
# Integration contracts: an effect cannot enter AI selection; all ordinary logs share impacts;
# phase entry happens once and authored health is consumed by real arena objects.
func _ready() -> void:
	Game.settings.invincible = true
	var catalog = E.AttackCatalog.shared()
	var bindings: Array = catalog.enemy_entries("boss_ape", "normal")
	check(bindings.any(func(row): return row.attack_name == "ape_log" and row.get("activation_mode", "") == "triggered"), "Ape loadout includes its triggered log effect")
	var chosen: String = catalog.select_attack("boss_ape", "normal", ["ape_log", "ape_slam"], 1.0)
	check(chosen == "", "Triggered effects never enter attack selection")
	check(not catalog.score_attack(catalog.attack("ape_spikes")).valid, "Persistent spikes do not receive a made-up finite-duration score")
	# Even a valid high-priority trigger may never run its eligibility callback.
	var seen := []
	catalog.select_attack("boss_ape", "normal", [], 1.0, func(id): seen.append(id); return false)
	check(not seen.has("ape_log") and not seen.has("ape_slam"), "Trigger-only effects do not perform AI range/chance eligibility work")
	if not catalog.has_method("enemy_profile"):
		check(false, "Enemy catalogue exposes authored health and phase configuration")
		Game.quit_game(fails)
		return
	var profile: Dictionary = catalog.enemy_profile("boss_ape")
	var original_profile := profile.duplicate(true)
	profile.merge({"max_hp": 5, "phase2_hp": 2, "phase2_wave_scales": [1.3, 1.7]}, true)
	var saved := profile.duplicate(true)
	# Save to a disposable content set, exercising the same path used by the Enemy tab.
	var draft = E.AttackCatalog.new()
	draft.reload()
	var folder := "user://ape_composition"
	DirAccess.make_dir_recursive_absolute(folder)
	draft.attack_path = folder + "/attacks.csv"
	draft.assignment_path = folder + "/enemy_attacks.csv"
	draft.enemy_profile("boss_ape").phase2_wave_scales = [1.234, 1.789]
	var saved_result: String = draft.save_all()
	check(saved_result == "" and draft.reload() and draft.enemy_profile("boss_ape").phase2_wave_scales == [1.23, 1.79], "Saved phase settings round to two decimals and reload with the CSV content set")
	draft.enemy_profile("boss_ape").phase2_hp = draft.enemy_profile("boss_ape").max_hp
	check(not draft.validate().is_empty(), "Phase threshold equal to maximum HP is rejected")
	profile.max_hp = 7
	profile.phase2_hp = 3
	make_world([{"t": "boss_ape", "x": 200, "y": 200}])
	var ape = w.ents.filter(func(e): return e is E.Ape)[0]
	check(ape.hp == 7, "Arena Ape reads editable maximum health")
	ape.hp = 4
	check(not ape.enraged(), "Phase threshold uses authored HP")
	ape._hit()
	check(ape.enraged(), "Crossing authored threshold enters phase two")
	ape.timer = 0
	ape.update(0)
	check(ape.phase == "crouch" and ape.hops == 2, "Phase two starts the in-place leap sequence")
	ape.hops = 0
	ape._go("scream", -1)
	ape.update(0)
	check(ape.phase == "idle" and ape.hops == 0, "Phase-entry hops do not repeat after each scream")
	profile.clear()
	profile.merge(saved, true)
	var log_row: Dictionary = catalog.attack("ape_log")
	var old_area: String = log_row.coverage_area_units2
	log_row.coverage_area_units2 = "7.12"
	make_world([{"t": "boss_ape", "x": 200, "y": 192}])
	ape = w.ents.filter(func(e): return e is E.Ape)[0]
	p().pos.x = ape.center().x
	check(not ape._cornered(p()), "A player directly above the Ape cannot trap its wall-search loop")
	ape._throw(Vector2(320, 210))
	check(ape.logs[0].size == Vector2i(38, 12), "Shared log area changes both thrown and falling log dimensions")
	log_row.coverage_area_units2 = old_area
	ape.effects.clear()
	ape._land()
	var wave_at: Rect2i = ape.slam_box()
	ape.rect.position.x += 30
	check(ape.slam_box() == wave_at, "Spawned ground shockwave stays at the landing point when its owner moves")
	# Same launch point and floor, different launch source: both leave the same spike.
	var results := []
	for thrown in [false, true]:
		make_world([{"t": "boss_ape", "x": 200, "y": 200}])
		ape = w.ents.filter(func(e): return e is E.Ape)[0]
		ape.phase = "sleep"
		p().pos = Vector2(60, 200)
		if thrown:
			ape._throw(Vector2(320, 220))
			check(ape.logs.size() == 1, "Throw spawns a log rather than a stone")
			ape.logs[0].position = Vector2(300, 80)
			ape.logs[0].velocity = Vector2(0, 60)
		else:
			ape.effects.spawn(Vector2(300, 80), Vector2.ZERO, {})
		for tick in 180:
			ape._update_logs(DT)
			w.after_player_move()
		results.append(w.ents.filter(func(e): return e is E.Spikes and e.collidable).map(func(e): return [int(e.d.x), int(e.d.y)]))
	check(results[0] == [[304, 216]] and results[1] == results[0], "Falling and thrown logs use the same floor-spike consequence (%s)" % [results])
	make_world([{"t": "boss_ape", "x": 200, "y": 200}])
	ape = w.ents.filter(func(e): return e is E.Ape)[0]
	ape.hp = 2
	p().pos = Vector2(20, 40)
	ape._throw(Vector2(260, 220))  # children hop about 135 px each way: keep both clear of the room walls
	var children := 0
	for tick in 180:
		ape._update_logs(DT)
		children = maxi(children, ape.logs.size())
		w.after_player_move()
	check(children == 2, "Phase-two log splits once into exactly two ordinary logs")
	check(w.ents.filter(func(e): return e is E.Spikes and e.collidable).size() == 2, "Both split children create their own floor spikes (%s)" % [w.ents.filter(func(e): return e is E.Spikes and e.collidable).map(func(e): return [e.d.x,e.d.y])])
	ape.effects.spawn(Vector2(300, 80), Vector2.ZERO, {})
	ape.hp = 1
	ape._hit()
	check(ape.logs.is_empty() and ape.slam_t <= 0, "The lethal boss hit immediately cancels transient encounter hazards")
	ape._beaten()
	check(ape.logs.is_empty() and ape.damage_boxes().is_empty(), "Boss defeat cancels encounter-owned transient effects")
	# An actual editor input must alter the private draft, then survive Save/reload.
	draft.reload()
	var ui = load("res://scripts/attack_catalog_editor.gd").new()
	ui.catalog = draft
	add_child(ui)
	ui._show_enemies()
	var hp_edit: LineEdit = ui.find_child("max_hp", true, false)
	check(hp_edit != null, "Ape Enemy tab exposes a health input")
	if hp_edit != null:
		hp_edit.text = "9"
		hp_edit.text_changed.emit("9")
		check(ui.dirty and draft.enemy_profile("boss_ape").max_hp == 9, "Health edits change the private enemy draft")
		ui._save()
		check(not ui.dirty and draft.reload() and draft.enemy_profile("boss_ape").max_hp == 9, "Enemy-tab Save persists health with the attack catalogue")
	ui.queue_free()
	await get_tree().process_frame
	profile.clear()
	profile.merge(original_profile, true)
	print("APE COMPOSITION: %d failure(s)" % fails)
	Game.quit_game(fails)
