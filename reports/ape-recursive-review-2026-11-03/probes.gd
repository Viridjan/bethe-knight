extends "res://tests/test_runner.gd"
# Evidence only. All catalogue mutations stay in memory; disk fixtures use disposable user:// data.
# Select one probe using SUMMIT_REVIEW_CASE. Expected engine errors are isolated to their case log.
var observation := {}
class TimedCatalog extends "res://scripts/attack_catalog.gd":
	var validation_calls := 0
	var validation_us := 0
	func validate() -> String:
		validation_calls += 1
		var started := Time.get_ticks_usec()
		var result := super.validate()
		validation_us += Time.get_ticks_usec() - started
		return result
func _ready() -> void:
	Game.settings.invincible = true
	var which := OS.get_environment("SUMMIT_REVIEW_CASE")
	var catalog = E.AttackCatalog.shared()
	catalog.reload()
	observation["case"] = which
	match which:
		"retreat_gravity":
			catalog.attack("ape_retreat").gravity_units_s2 = "25.00"
			observation.validation = catalog.validate_for_save()
			var ape = _ape()
			ape.retreat = true
			ape._go("crouch", 0)
			ape.update(0)
			var initial: float = ape.vel.y
			ape.update(DT)
			observation.merge({"launch_vy": initial, "actual_vy": ape.vel.y, "expected_vy": initial + 200.0 / 60.0, "snapshot": ape.attack_snapshot.name})
		"zero_leap":
			catalog.attack("ape_leap").gravity_units_s2 = "0.00"
			observation.validation = catalog.validate_for_save()
			var ape = _ape()
			ape._go("crouch", 0)
			for tick in 180: ape.update(DT)
			observation.merge({"state_after_3_seconds": ape.phase, "vertical_speed": ape.vel.y, "health": ape.hp})
		"zero_wave":
			catalog.attack("ape_slam").coverage_area_units2 = "0.00"
			observation.validation = catalog.validate_for_save()
			var ape = _ape()
			ape._land()
			observation.width = ape.slam_box().size.x
			# Same texture helper invoked by Ape.draw while the zero-width wave is active.
			var texture = load("res://scripts/ape_art.gd").impact_texture(ape.slam_box().size.x, 8, 0)
			observation.null_texture = texture == null
		"apex_collision":
			_ape()
			var effects = E.AttackEffects.new()
			effects.spawn(Vector2(100, 100), Vector2(0, -1), {"split": true})
			var hits: Array = effects.update(DT, w.collide_solid, Rect2i(105, 100, 8, 6), Rect2i(0, 0, 480, 240))
			var next_hits: Array = effects.update(DT, w.collide_solid, Rect2i(105, 100, 8, 6), Rect2i(0, 0, 480, 240))
			observation.merge({"events": hits.map(func(event): return event.event), "next_tick_events": next_hits.map(func(event): return event.event), "children": effects.projectiles.size(), "overlaps_at_start": Rect2i(100, 100, 19, 6).intersects(Rect2i(105, 100, 8, 6))})
		"split_near_wall":
			_ape()
			var effects = E.AttackEffects.new()
			effects.spawn(Vector2(25, 100), Vector2(0, -1), {"split": true})
			effects.update(DT, w.collide_solid, Rect2i(), Rect2i(0, 0, 480, 240))
			var after_split: int = effects.projectiles.size()
			var events: Array = effects.update(DT, w.collide_solid, Rect2i(), Rect2i(0, 0, 480, 240))
			observation.merge({"children_after_split": after_split, "children_next_tick": effects.projectiles.size(), "events": events})
		"ignored_values":
			catalog.attack("ape_throw").coverage_area_units2 = "40.00"
			catalog.attack("ape_split").gravity_units_s2 = "100.00"
			observation.validation = catalog.validate_for_save()
			var ape = _ape()
			ape.hp = 2
			ape._throw(Vector2(320, 215))
			observation.merge({"throw_area_setting": "40.00", "actual_log_size": [ape.logs[0].size.x, ape.logs[0].size.y], "split_gravity_setting_px": 800, "actual_child_gravity": ape.logs[0].child_gravity})
		"invalid_health_ui":
			var ui = _editor()
			var hp: LineEdit = ui.find_child("max_hp", true, false)
			hp.text = ""
			hp.text_changed.emit("")
			observation.validation = ui.catalog.validate_for_save()
			ui._select_enemy(1)
			observation.merge({"health_input_after_switch": ui.find_child("max_hp", true, false) != null, "dirty": ui.dirty})
			ui.queue_free()
		"empty_loadout":
			catalog.assignments = []
			observation.validation = catalog.validate_for_save()
			make_world([{"t": "enemy_hornback", "x": 160, "y": 210}])
			var enemy = w.ents.filter(func(e): return e.d.t == "enemy_hornback")[0]
			observation.merge({"ready": enemy.atk_ready(), "range": enemy.atk_range(160)})
		"runtime_bounds":
			catalog.attack("ape_scream").coverage_area_units2 = "100000000.00"
			catalog.attack("ape_split").horizontal_speed_units_s = "10000000.00"
			observation.validation = catalog.validate_for_save()
			# Measure normal vertical travel: every zero horizontal step repeats a solid query.
			var ape = _ape()
			var calls := [0]
			var effects = E.AttackEffects.new()
			effects.spawn(Vector2(300, 40), Vector2(0, 120), {"gravity": 0})
			var start := Time.get_ticks_usec()
			for tick in 30:
				effects.update(DT, func(r): calls[0] += 1; return w.collide_solid(r), Rect2i(), Rect2i(0, 0, 480, 240))
			observation.merge({"vertical_distance": 60, "solid_queries": calls[0], "elapsed_us": Time.get_ticks_usec() - start})
		"effect_bindings":
			catalog.assignments = catalog.assignments.filter(func(row): return not catalog.triggered(row))
			observation.validation = catalog.validate_for_save()
			var ape = _ape()
			ape._land()
			observation.merge({"trigger_bindings": 0, "logs": ape.logs.size(), "wave_active": ape.slam_t > 0})
		"phase_draft_precision":
			var ui = _editor()
			var scales: LineEdit = ui.find_child("phase2_wave_scales", true, false)
			scales.text = "1.234, 1.789"
			scales.text_changed.emit(scales.text)
			scales.focus_exited.emit()
			observation.merge({"shown_after_blur": scales.text, "draft": ui.catalog.enemy_profile("boss_ape").phase2_wave_scales, "validation": ui.catalog.validate_for_save()})
			ui.queue_free()
		"ui_cost":
			var ui = _editor()
			var started := Time.get_ticks_usec()
			for n in 100: ui._update_feedback()
			observation.feedback_us_per_call = (Time.get_ticks_usec() - started) / 100.0
			started = Time.get_ticks_usec()
			for n in 20: ui._select_enemy(0)
			observation.page_us_per_build = (Time.get_ticks_usec() - started) / 20.0
			ui.queue_free()
		"backup_recovery":
			var dir := "user://recursive_review"
			DirAccess.make_dir_recursive_absolute(dir)
			var draft = E.AttackCatalog.new()
			draft.reload()
			draft.attack_path = dir + "/attacks.csv"
			draft.assignment_path = dir + "/enemy_attacks.csv"
			observation.first_save = draft.save_all()
			observation.second_save = draft.save_all()
			var corrupt := FileAccess.open(draft.attack_path, FileAccess.WRITE)
			corrupt.store_string("partial")
			corrupt.close()
			observation.merge({"backup_exists": FileAccess.file_exists(draft.attack_path + ".bak"), "reload": draft.reload(), "error": draft.error})
		"new_file_rollback":
			var dir := "user://recursive_first_save"
			DirAccess.make_dir_recursive_absolute(dir + "/enemy_attacks.csv")
			var draft = E.AttackCatalog.new()
			draft.reload()
			draft.attack_path = dir + "/attacks.csv"
			draft.assignment_path = dir + "/enemy_attacks.csv"
			var result: String = draft.save_all()
			observation.merge({"save_error": result, "new_attack_file_left": FileAccess.file_exists(draft.attack_path), "new_profile_file_left": FileAccess.file_exists(draft.profile_path())})
		"blank_wave_time":
			catalog.attack("ape_slam").shockwave_s = ""
			observation.validation = catalog.validate_for_save()
			var ape = _ape()
			ape._land()
			observation.merge({"actual_lifetime": ape.slam_t, "fallback_lifetime": 0.2})
		"projectile_cost":
			_ape()
			var effects = E.AttackEffects.new()
			var query := func(r): return w.collide_solid(r)
			var samples := []
			for n in 30:
				effects.clear()
				effects.spawn(Vector2(300, 40), Vector2(0, 120), {"gravity": 0})
				var started := Time.get_ticks_usec()
				for tick in 60: effects.update(DT, query, Rect2i(), Rect2i(0, 0, 480, 240))
				samples.append(Time.get_ticks_usec() - started)
			samples.sort()
			observation.median_us_per_tick = samples[15] / 60.0
		"zero_hp_input_rebuild":
			var ui = _editor()
			var hp: LineEdit = ui.find_child("max_hp", true, false)
			hp.text_changed.emit("")
			observation.live_health_still_valid = catalog.enemy_profile("boss_ape").max_hp == 4
			ui._select_enemy(1)
			observation.health_input_after_switch = ui.find_child("max_hp", true, false) != null
			ui.queue_free()
		"outside_sweep_cost":
			catalog.attack("ape_split").horizontal_speed_units_s = "122880.00"
			observation.validation = catalog.validate_for_save()
			_ape()
			var effects = E.AttackEffects.new()
			var velocity: float = catalog.value("ape_split", "horizontal_speed_units_s", 0) * 8.0
			effects.spawn(Vector2(600, 40), Vector2(velocity, 0), {"gravity": 0})
			var calls := [0]
			var started := Time.get_ticks_usec()
			effects.update(DT, func(r): calls[0] += 1; return w.collide_solid(r), Rect2i(), Rect2i(0, 0, 480, 240))
			observation.merge({"solid_queries": calls[0], "elapsed_us": Time.get_ticks_usec() - started, "remaining": effects.projectiles.size(), "started_outside_bounds": true})
		"ui_validation_cost":
			var ui = load("res://scripts/attack_catalog_editor.gd").new()
			ui.catalog = TimedCatalog.new()
			ui.catalog.reload()
			ui.size = Vector2(1280, 720)
			add_child(ui)
			ui._show_enemies()
			await get_tree().process_frame
			var samples := []
			var counts := []
			var validation_times := []
			for n in 20:
				ui.catalog.validation_calls = 0
				ui.catalog.validation_us = 0
				var started := Time.get_ticks_usec()
				ui._select_enemy(0)
				samples.append(Time.get_ticks_usec() - started)
				counts.append(ui.catalog.validation_calls)
				validation_times.append(ui.catalog.validation_us)
				await get_tree().process_frame
			samples.sort()
			validation_times.sort()
			observation.merge({"median_page_us": samples[10], "validation_calls_per_build": counts, "median_validation_us": validation_times[10]})
			ui.queue_free()
		"configured_health_tests":
			Game.settings.invincible = false  # match the production suite's entry conditions
			catalog.enemy_profile("boss_ape").max_hp = 5
			observation.validation = catalog.validate_for_save()
			check_ape()
			observation.failing_assertions = fails
		_:
			observation.error = "Unknown probe"
	catalog.reload()
	await get_tree().process_frame
	var output := "res://reports/ape-recursive-review-2026-11-03/%s.json" % which
	var f := FileAccess.open(output, FileAccess.WRITE)
	f.store_string(JSON.stringify(observation, "\t") + "\n")
	f.close()
	print(JSON.stringify(observation))
	Game.quit_game(0)

func _ape():
	make_world([{"t": "boss_ape", "x": 200, "y": 192}])
	p().pos = Vector2(60, 224)
	return w.ents.filter(func(e): return e is E.Ape)[0]

func _editor():
	var ui = load("res://scripts/attack_catalog_editor.gd").new()
	ui.catalog = E.AttackCatalog.new()
	ui.catalog.reload()
	ui.size = Vector2(1280, 720)
	add_child(ui)
	ui._show_enemies()
	return ui
