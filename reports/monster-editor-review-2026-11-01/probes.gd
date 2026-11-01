extends Node
const Catalog := preload("res://scripts/attack_catalog.gd")
const Editor := preload("res://scripts/attack_catalog_editor.gd")
const Entities := preload("res://scripts/entities.gd")
var observations := {}
class CountingCatalog extends "res://scripts/attack_catalog.gd":
	var validation_calls := 0
	var validation_us := 0
	func validate() -> String:
		validation_calls += 1
		var start := Time.get_ticks_usec()
		var result := super.validate()
		validation_us += Time.get_ticks_usec() - start
		return result
class ProfileEditor extends "res://scripts/attack_catalog_editor.gd":
	var measured := {"score_text_us": 0, "frame_lookup_us": 0, "tooltip_us": 0}
	var tip_depth := 0
	func _score_text(e: Array) -> String:
		var start := Time.get_ticks_usec()
		var result := super._score_text(e)
		measured.score_text_us += Time.get_ticks_usec() - start
		return result
	func _attack_frames(e: Array, attack: Dictionary) -> Array:
		var start := Time.get_ticks_usec()
		var result := super._attack_frames(e, attack)
		measured.frame_lookup_us += Time.get_ticks_usec() - start
		return result
	func _wrap_tips(node: Node) -> void:
		var start := Time.get_ticks_usec()
		tip_depth += 1
		super._wrap_tips(node)
		tip_depth -= 1
		if tip_depth == 0: measured.tooltip_us += Time.get_ticks_usec() - start
func collect(node: Node, predicate: Callable) -> Array:
	var found: Array = []
	if predicate.call(node): found.append(node)
	for child in node.get_children(): found.append_array(collect(child, predicate))
	return found
func _ready() -> void:
	Game.main = self
	var catalog := Catalog.new()
	catalog.reload()
	var editor := Editor.new()
	editor.catalog = catalog
	editor.custom_minimum_size = Vector2(1000, 600)
	add_child(editor)
	await get_tree().process_frame
	# Runtime-only IDs are missing from the UI's protected-ID list.
	editor._select_row(catalog.attacks.find(catalog.attack("ape_slam")))
	observations.rename_runtime_component_enabled = editor.fields.name.editable
	observations.delete_runtime_component_enabled = editor.form.get_children().any(func(node): return node is Button and node.text == "Delete attack" and not node.disabled)
	var slam := catalog.attack("ape_slam")
	catalog.attacks.erase(slam)
	observations.deleted_runtime_component_passes_validation = catalog.validate().is_empty()
	catalog.reload()
	# A duplicate ID during typing can hijack unrelated bindings before the final ID is unique again.
	catalog.reload()
	var original_shoot_bindings: int = catalog.assignments.filter(func(row): return row.attack_name == "shoot").size()
	var new_id: String = editor._new_attack()
	editor._show_table(false)
	editor._select_row(catalog.attacks.find(catalog.attack(new_id)))
	editor._change("name", "shoot")
	editor._change("name", "shoot_variant")
	observations.rename_hijacked_existing_shoot_bindings = catalog.assignments.filter(func(row): return row.attack_name == "shoot_variant").size()
	observations.original_shoot_bindings_before_rename = original_shoot_bindings
	observations.rename_hijack_final_state_validates = catalog.validate().is_empty()
	catalog.reload()
	# Invalid follow-ups are silently omitted from otherwise valid scores.
	var retreat := catalog.attack("ape_retreat").duplicate(true)
	retreat.follow_up = "ape_log"
	var parent_score := catalog.score_attack(retreat)
	observations.unscored_followup_claims_complete_score = parent_score.valid
	observations.unscored_followup_score = parent_score.get("score")
	catalog.attack("ape_scream").follow_up = "ape_throw"
	catalog.attack("ape_scream").follow_up_count = "1"
	catalog.attack("ape_scream").follow_up_gap_s = "0.5"
	catalog.attack("ape_throw").follow_up = "ape_scream"
	catalog.attack("ape_throw").follow_up_count = "1"
	catalog.attack("ape_throw").follow_up_gap_s = "0.5"
	observations.followup_cycle_validates = catalog.validate().is_empty()
	catalog.reload()
	catalog.attack("shoot").multishot = "100000000"
	observations.hundred_million_shots_validate = catalog.validate().is_empty()
	catalog.reload()
	# All writes below target disposable user data, never project CSV files.
	var folder := "user://monster-editor-review"
	DirAccess.make_dir_recursive_absolute(folder)
	catalog.attack_path = folder + "/attacks.csv"
	catalog.assignment_path = folder + "/enemy_attacks.csv"
	catalog.attack("ape_throw").base_weight = "1.0049"
	catalog.save_all()
	var disk := Catalog.new()
	disk.attack_path = catalog.attack_path
	disk.assignment_path = catalog.assignment_path
	disk.reload()
	var saved_parent: String = disk.attack("ape_retreat").score
	var actual_parent := "%.2f" % disk.score_attack(disk.attack("ape_retreat")).score
	observations.persisted_followup_score = saved_parent
	observations.recomputed_followup_score = actual_parent
	observations.saved_score_mismatches_rounded_data = saved_parent != actual_parent
	# Edits update a row score but leave the enemy's displayed total unchanged.
	catalog = Catalog.new()
	catalog.reload()
	editor.catalog = catalog
	editor._show_enemies()
	var hornback_index: int = editor.ENEMIES.map(func(entry): return entry[0]).find("enemy_hornback")
	editor._select_enemy(hornback_index)
	for b in collect(editor.form, func(node): return node is Button and node.text == "Edit"): b.pressed.emit()  # details build on open
	var before := editor.summary.text
	var windups := collect(editor.form, func(node): return node is LineEdit and node.tooltip_text.replace("\n", " ").contains("Warning before execution"))
	windups[0].text_changed.emit("1.80")
	observations.enemy_total_stays_stale_after_edit = editor.summary.text == before
	observations.enemy_total_displayed = editor.summary.text
	observations.enemy_total_recomputed = editor._score_text(editor.ENEMIES[hornback_index])
	editor.queue_free()
	await get_tree().process_frame
	# Escape bypasses the guarded Back action.
	var menu = load("res://scripts/menu.gd").new()
	add_child(menu)
	menu._monster_editor()
	await get_tree().process_frame
	var page = menu.body.get_children().filter(func(node): return node.has_method("_show_enemies"))[0]
	page._change("windup_s", "0.61")
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	menu._unhandled_input(event)
	observations.escape_discards_dirty_editor = page.get_parent() == null
	observations.escape_confirmation_count = collect(menu, func(node): return node is ConfirmationDialog).size()
	menu.queue_free()
	await get_tree().process_frame
	# Geometry and retained-scroll inspection at a fixed logical editor size.
	var layout := Editor.new()
	layout.custom_minimum_size = Vector2(1000, 600)
	layout.size = Vector2(1000, 600)
	add_child(layout)
	layout._show_enemies()
	for frame in 3: await get_tree().process_frame
	var scroll: ScrollContainer = layout.form.get_parent()
	var room_rules: Array = layout.catalog.ordered_attacks("boss_ape", "normal")
	for binding in room_rules: layout.expanded_attacks["boss_ape/normal/" + binding.attack_name] = true
	layout._select_enemy(0)
	for frame in 3: await get_tree().process_frame
	scroll.scroll_vertical = 180
	await get_tree().process_frame
	var old_scroll := scroll.scroll_vertical
	layout._select_enemy(1)
	for frame in 3: await get_tree().process_frame
	observations.scroll_before_enemy_change = old_scroll
	observations.scroll_after_enemy_change = scroll.scroll_vertical
	observations.enemy_overview_min_width = layout.form.get_combined_minimum_size().x
	observations.enemy_overview_viewport_width = scroll.size.x
	observations.layout_requested_width = 1000
	observations.layout_actual_width = layout.size.x
	observations.layout_minimum_width = layout.get_combined_minimum_size().x
	var wide: Array = []
	for node in collect(layout.form, func(node): return node is Control and node.get_combined_minimum_size().x > 700):
		wide.append({"kind": node.get_class(), "minimum_width": node.get_combined_minimum_size().x})
	observations.wide_controls = wide
	observations.readonly_enemy_rows = layout.ENEMIES.filter(func(entry): return entry[1] == "").size()
	layout.queue_free()
	await get_tree().process_frame
	# Navigation CPU timings (warm, headless/debug). Not release-frame or GPU measurements.
	var counted := CountingCatalog.new()
	counted.reload()
	var bench := ProfileEditor.new()
	bench.catalog = counted
	bench.custom_minimum_size = Vector2(1000, 600)
	add_child(bench)
	bench._show_enemies()
	await get_tree().process_frame
	var timings := {}
	for index in [0, hornback_index, bench.ENEMIES.size() - 1]:
		var samples: Array = []
		counted.validation_calls = 0
		counted.validation_us = 0
		bench.measured = {"score_text_us": 0, "frame_lookup_us": 0, "tooltip_us": 0}
		for n in 8:
			var start := Time.get_ticks_usec()
			bench._select_enemy(index)
			samples.append((Time.get_ticks_usec() - start) / 1000.0)
			await get_tree().process_frame
			await get_tree().process_frame
		samples.sort()
		timings[str(bench.ENEMIES[index][2])] = {"median_ms": samples[4], "max_ms": samples[-1], "validation_calls_per_selection": counted.validation_calls / 8.0, "validation_ms_per_selection": counted.validation_us / 8000.0, "score_text_ms_per_selection": bench.measured.score_text_us / 8000.0, "frame_lookup_ms_per_selection": bench.measured.frame_lookup_us / 8000.0, "tooltip_ms_per_selection": bench.measured.tooltip_us / 8000.0, "node_count": collect(bench.form, func(_node): return true).size(), "process_monitor_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000}
	observations.navigation = timings
	var large_row := counted.attack("shoot").duplicate(true)
	large_row.multishot = "10000"
	var start := Time.get_ticks_usec()
	counted.score_attack(large_row)
	observations.score_10000_shots_ms = (Time.get_ticks_usec() - start) / 1000.0
	bench.queue_free()
	await get_tree().process_frame
	# Fixed enemy families do not consult their binding's minimum, and deleting the binding falls back to code defaults.
	Game.level = Game.new_level("Review", 60, 30)
	Game.adv = {}
	Game.playtest = true
	var world = load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	world.player.pos = Vector2(100, 27 * 8)
	var live = Catalog.shared()
	var old_bindings: Array = live.assignments.duplicate(true)
	var rule: Dictionary = live.ordered_attacks("enemy_skeleton", "default")[0]
	rule.min_range_units = "10"
	var enemy = Entities.make(world, {"t": "enemy_skeleton", "x": 140, "y": 27 * 8 - 12})
	enemy.timer = 0
	enemy.update(0)
	observations.skeleton_attacks_below_minimum = enemy.phase == "windup"
	observations.skeleton_distance_units = enemy.center().distance_to(world.player.center()) / 8.0
	live.assignments.erase(rule)
	enemy = Entities.make(world, {"t": "enemy_skeleton", "x": 140, "y": 27 * 8 - 12})
	enemy.timer = 0
	enemy.update(0)
	observations.skeleton_attacks_without_binding = enemy.phase == "windup"
	live.assignments = old_bindings
	# The retreat's follow-up ID is ignored by the boss's hard-coded transition.
	var old_retreat: Dictionary = live.attack("ape_retreat").duplicate(true)
	live.attack("ape_retreat").follow_up = "ape_scream"
	live.attack("ape_retreat").follow_up_count = "1"
	var ape = Entities.make(world, {"t": "boss_ape", "x": 180, "y": 27 * 8 - 32})
	ape.retreat = true
	ape._land()
	observations.retreat_with_scream_followup_enters = ape.phase
	for key in old_retreat: live.attack("ape_retreat")[key] = old_retreat[key]
	var output := FileAccess.open("res://reports/monster-editor-review-2026-11-01/observations.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(observations, "\t"))
	output.close()
	print(JSON.stringify(observations))
	world.queue_free()
	Game.quit_game(0)
