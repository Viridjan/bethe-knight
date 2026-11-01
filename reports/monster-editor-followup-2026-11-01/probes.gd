extends Node
const Catalog := preload("res://scripts/attack_catalog.gd")
const Editor := preload("res://scripts/attack_catalog_editor.gd")
const Entities := preload("res://scripts/entities.gd")
var observations := {}
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
	editor._show_enemies()
	await get_tree().process_frame
	var timings: Array = []
	for n in 8:
		var start := Time.get_ticks_usec()
		editor._select_enemy(0)
		timings.append((Time.get_ticks_usec() - start) / 1000.0)
		await get_tree().process_frame
		await get_tree().process_frame
	timings.sort()
	observations.ape_warm_selection_median_ms = timings[4]
	observations.ape_overview_nodes = collect(editor.form, func(_node): return true).size()
	var parent := catalog.attack("ape_retreat")
	var before := "%.2f" % catalog.score_attack(parent).score
	var parent_labels := collect(editor.form, func(node): return node is Label and node.text == before)
	var throws: Array = collect(editor.form, func(node): return node is Button and node.text == "Edit")
	for button in throws: button.pressed.emit()
	var child := catalog.attack("ape_throw")
	var windups := collect(editor.form, func(node): return node is LineEdit and node.text.is_valid_float() and is_equal_approx(float(node.text), float(child.windup_s)) and node.tooltip_text.replace("\n", " ").contains("Warning before execution"))
	windups[0].text_changed.emit("1.90")
	observations.parent_score_display_before = before
	observations.parent_score_display_after_child_edit = parent_labels[0].text
	observations.parent_score_recomputed_after_child_edit = "%.2f" % catalog.score_attack(parent).score
	windups[0].text = "1.234"
	windups[0].text_changed.emit("1.234")
	windups[0].focus_exited.emit()
	observations.compact_number_after_focus_exit = windups[0].text
	windups[0].text = "invalid"
	windups[0].text_changed.emit("invalid")
	observations.invalid_compact_field_marked = windups[0].has_theme_color_override("font_color")
	observations.invalid_compact_error_location = catalog.error_at.duplicate()
	catalog.reload()
	editor._show_enemies()
	var hornback: int = editor.ENEMIES.map(func(entry): return entry[0]).find("enemy_hornback")
	editor._select_enemy(hornback)
	observations.hornback_score_before_planned_binding = editor._score_text(editor.ENEMIES[hornback])
	var planned: String = editor._new_attack()
	editor._add_binding(editor.ENEMIES[hornback], planned)
	observations.planned_attack_runs = catalog.performs("enemy_hornback", planned)
	observations.hornback_score_after_planned_binding = editor._score_text(editor.ENEMIES[hornback])
	# Valid empty assignments revive fixed families through the load-failure fallback.
	catalog.reload()
	catalog.assignments = []
	observations.empty_assignments_validate = catalog.validate().is_empty()
	editor.queue_free()
	await get_tree().process_frame
	Game.level = Game.new_level("Review", 60, 30)
	Game.adv = {}
	Game.playtest = true
	var world = load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	world.player.pos = Vector2(100, 27 * 8)
	var live = Catalog.shared()
	var old_bindings: Array = live.assignments.duplicate(true)
	live.assignments = []
	var enemy = Entities.make(world, {"t": "enemy_skeleton", "x": 140, "y": 27 * 8 - 12})
	enemy.timer = 0
	enemy.update(0)
	observations.empty_catalog_skeleton_phase = enemy.phase
	live.assignments = old_bindings
	var old_shots: String = live.attack("ossling_bone_throw").multishot
	live.attack("ossling_bone_throw").multishot = "5"
	enemy = Entities.make(world, {"t": "enemy_skeleton", "x": 140, "y": 27 * 8 - 12})
	enemy.phase = "windup"
	enemy.timer = 0
	enemy.update(0)
	observations.ossling_configured_shots = 5
	observations.ossling_emitted_shots = enemy.bones.size()
	live.attack("ossling_bone_throw").multishot = old_shots
	world.queue_free()
	await get_tree().process_frame
	# Simulate interruption after the first CSV rename; an intact previous pair exists as .bak.
	var disk := Catalog.new()
	disk.reload()
	var folder := "user://monster-review-followup"
	DirAccess.make_dir_recursive_absolute(folder)
	disk.attack_path = folder + "/attacks.csv"
	disk.assignment_path = folder + "/enemy_attacks.csv"
	var draft: Dictionary = disk.attack("ape_scream").duplicate(true)
	draft.name = "draft_old"
	draft.status = "planned"
	disk.attacks.append(draft)
	disk.assignments.append({"enemy_id":"enemy_hornback","phase":"default","attack_name":"draft_old","min_range_units":"0","max_range_units":"10","priority":"1","skip_chance":"0"})
	disk.save_all()
	for path in [disk.attack_path, disk.assignment_path]: DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
	draft.name = "draft_new"
	for binding in disk.assignments:
		if binding.attack_name == "draft_old": binding.attack_name = "draft_new"
	disk._stage_table(false)
	disk._stage_table(true)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(disk.attack_path + ".tmp"), ProjectSettings.globalize_path(disk.attack_path))
	var recovered := Catalog.new()
	recovered.attack_path = disk.attack_path
	recovered.assignment_path = disk.assignment_path
	observations.interrupted_pair_auto_recovered = recovered.reload()
	observations.interrupted_pair_error = recovered.error
	observations.backup_pair_exists = FileAccess.file_exists(disk.attack_path + ".bak") and FileAccess.file_exists(disk.assignment_path + ".bak")
	var backup := Catalog.new()
	backup.attack_path = disk.attack_path + ".bak"
	backup.assignment_path = disk.assignment_path + ".bak"
	observations.backup_pair_validates = backup.reload()
	# A pending ID edit must not bypass the exit guard before focus-out commits it.
	var menu = load("res://scripts/menu.gd").new()
	add_child(menu)
	menu._monster_editor()
	await get_tree().process_frame
	var page = menu.body.get_children().filter(func(node): return node.has_method("_show_enemies"))[0]
	var draft_catalog := Catalog.new()
	draft_catalog.reload()
	var draft_row: Dictionary = draft_catalog.attack("ape_scream").duplicate(true)
	draft_row.name = "draft_focus"
	draft_row.status = "planned"
	draft_catalog.attacks.append(draft_row)
	page.catalog = draft_catalog
	page._show_table(false)
	page._select_row(draft_catalog.attacks.size() - 1)
	page.dirty = false
	for button in collect(page.form, func(node): return node is Button and node.text == "+ Advanced"): button.pressed.emit()
	await get_tree().process_frame
	page.fields.name.grab_focus()
	page.fields.name.text = "draft_focus_new"
	page.fields.name.text_changed.emit("draft_focus_new")
	observations.pending_id_field_has_focus = page.fields.name.has_focus()
	observations.pending_id_marks_dirty = page.dirty
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	get_viewport().push_input(escape, true)
	for frame in 3: await get_tree().process_frame
	observations.pending_id_escape_left_editor = page.get_parent() == null
	observations.pending_id_escape_confirmations = collect(menu, func(node): return node is ConfirmationDialog and node.visible).size()
	menu.queue_free()
	await get_tree().process_frame
	# Screenshot/geometry are captured separately in the real menu.
	var output := FileAccess.open("res://reports/monster-editor-followup-2026-11-01/observations.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(observations, "\t"))
	output.close()
	print(JSON.stringify(observations))
	Game.quit_game(0)
