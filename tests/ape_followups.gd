extends "res://tests/test_runner.gd"
# Behavioral regressions for docs/reviews/ape-composition/CODEX_PROMPT.md.
func _ready() -> void:
	await check_effect_listing()
	check_configurable_health()
	print("APE FOLLOWUPS: %d failure(s)" % fails)
	Game.quit_game(fails)

func check_effect_listing() -> void:
	var catalog = E.AttackCatalog.new()
	check(catalog.reload(), "Effect listing fixture loads")
	var ui = load("res://scripts/attack_catalog_editor.gd").new()
	ui.catalog = catalog
	add_child(ui)
	ui._show_enemies()
	check(_effect_ids(ui) == ["ape_log", "ape_slam", "ape_spikes"], "Normal page shows only effects used by normal attacks")
	ui._select_enemy(1)
	check(_effect_ids(ui) == ["ape_log", "ape_slam", "ape_spikes", "ape_split"], "Enraged page includes the splitting variant")
	catalog.enemy_profile("boss_ape").landing_effects = []
	ui._select_enemy(0)
	check(_effect_ids(ui) == ["ape_log", "ape_spikes"], "Disabling landing effects removes the wave but keeps thrown-log consequences")
	catalog.enemy_profile("boss_ape").phase2_throw_effect = "ape_log"
	ui._select_enemy(1)
	check(_effect_ids(ui) == ["ape_log", "ape_spikes"], "Replacing the phase-two projectile removes the unused splitting variant")
	# Old CSVs may still list effects; those rows must not override the runtime profile.
	catalog.assignments = catalog.assignments.filter(func(row): return not catalog.triggered(row))
	catalog.assignments.append({"enemy_id": "boss_ape", "phase": "normal", "attack_name": "ape_split", "min_range_units": "0", "max_range_units": "0", "priority": "999", "skip_chance": "0", "activation_mode": "triggered"})
	check(catalog.validate().is_empty(), "Legacy triggered bindings remain readable")
	ui._select_enemy(0)
	check(_effect_ids(ui) == ["ape_log", "ape_spikes"], "Legacy metadata cannot add effects absent from the runtime graph")
	var called := []
	catalog.select_attack("boss_ape", "normal", ["ape_split"], 1, func(id): called.append(id); return true)
	check(called.is_empty(), "Legacy triggered metadata never enters AI eligibility")
	var folder := "user://ape_followup_legacy"
	DirAccess.make_dir_recursive_absolute(folder)
	catalog.attack_path = folder + "/attacks.csv"
	catalog.assignment_path = folder + "/enemy_attacks.csv"
	check(catalog.save_all().is_empty() and catalog.reload(), "Legacy effect metadata can be saved and reloaded")
	check(catalog.assignments.all(func(row): return not catalog.triggered(row)), "Saving migrates redundant legacy effect rows out of the selection CSV")
	ui._select_enemy(0)
	check(_effect_ids(ui) == ["ape_log", "ape_spikes"], "Reload preserves the authoritative profile effect listing")
	ui.queue_free()
	await get_tree().process_frame

func _effect_ids(ui) -> Array:
	var names: Array = ui.form.find_children("*", "LineEdit", true, false).map(func(node): return node.text)
	var ids: Array = ui.catalog.RUNTIME_ONLY.filter(func(id): return ui.catalog.attack(id).codex_online_name in names)
	ids.sort()
	return ids

func check_configurable_health() -> void:
	var profile: Dictionary = E.AttackCatalog.shared().enemy_profile("boss_ape")
	var original := profile.duplicate(true)
	profile.merge({"max_hp": 5, "phase2_hp": 2, "phase2_wave_scales": [1.3, 1.7]}, true)
	Game.settings.invincible = false
	check_ape()  # Existing first-hit, spike removal, phase, gate and reward assertions.
	profile.clear()
	profile.merge(original, true)
