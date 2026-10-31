extends VBoxContainer
# The Monsters catalogue edits a private draft; only validated, explicitly saved CSV affects gameplay.
const Catalog := preload("res://scripts/attack_catalog.gd")
var catalog = null
var table: ItemList
var form: VBoxContainer
var feedback: Label
var summary: Label
var save_button: Button
var reload_button: Button
var ranges := false
var selected := 0
var dirty := false
var fields := {}
var writable := false
var loaded_texts: Array = []
var view := "attacks"  # "attacks" (attack definitions) or "enemies" (each enemy's attacks, ranges and scores)
var enemy_index := 0
# The enemies whose attacks come from the CSV: [enemy id, phase, name in the list]
const ENEMIES := [["enemy_monster", "default", "Library monster"], ["boss_ape", "normal", "Ape"], ["boss_ape", "enraged", "Ape · enraged"]]
signal dirty_changed

func _ready() -> void:
	if catalog == null:
		catalog = Catalog.new()
		catalog.reload()
	loaded_texts = [FileAccess.get_file_as_string(catalog.attack_path), FileAccess.get_file_as_string(catalog.assignment_path)]
	writable = OS.has_feature("editor") and not OS.has_feature("web")
	add_theme_constant_override("separation", 8)
	var bar := HBoxContainer.new()
	add_child(bar)
	bar.add_child(Game.button("Attacks", func(): _show_table(false)))
	bar.add_child(Game.button("Enemies", _show_enemies))
	save_button = Game.button("Save CSV", _save)
	save_button.disabled = not writable
	save_button.tooltip_text = "Validate and save this CSV. Changes apply to the next attack selection. Current attacks finish normally."
	bar.add_child(save_button)
	reload_button = Game.button("Reload CSV", _reload_requested)
	bar.add_child(reload_button)
	var location := Game.label("Source CSVs · tiles (8 px), seconds · saved with 2 decimals" if writable else "Read-only catalogue · tiles (8 px), seconds", 14)
	location.tooltip_text = "res://data/attacks.csv and res://data/enemy_attacks.csv. Editing is available in the desktop source version."
	bar.add_child(location)
	var panes := HSplitContainer.new()
	panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panes.split_offset = 240
	add_child(panes)
	table = ItemList.new()
	table.custom_minimum_size.x = 235
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panes.add_child(table)
	table.item_selected.connect(func(i): _select_enemy(i) if view == "enemies" else _select_row(i))
	var scroll := ScrollContainer.new()
	scroll.mouse_force_pass_scroll_events = false
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panes.add_child(scroll)
	form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 8)
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form)
	summary = Game.label("", 14)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	feedback = Game.label("", 14)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(feedback)
	_show_table(false)

func _rows() -> Array:
	return catalog.assignments if ranges else catalog.attacks

func _show_table(show_ranges: bool) -> void:
	view = "ranges" if show_ranges else "attacks"
	ranges = show_ranges
	table.clear()
	for row in _rows():
		table.add_item("%s · %s · %s" % [row.enemy_id, row.phase, row.attack_name] if ranges else "%s · %s" % [row.name, row.type])
	if table.item_count > 0:
		table.select(0)
		_select_row(0)
	_update_feedback()

func _select_row(index: int) -> void:
	selected = index
	fields.clear()
	for node in form.get_children():
		form.remove_child(node)
		node.queue_free()
	var groups: Array = [
		["Identity", ["name", "codex_online_name", "type", "status"]],
		["Timing · seconds", ["windup_s", "animation_s", "recovery_s", "flight_time_s"]],
		["Scoring · tile units", ["score", "base_weight", "coverage_area_units2", "initial_speed_units_s", "projectiles_toward", "projectiles_other", "omnidirectional"]],
		["Movement · tile units / seconds", ["horizontal_speed_units_s", "vertical_speed_units_s", "gravity_units_s2"]],
		["Reference", ["source_url", "notes"]]
	]
	if ranges:
		groups = [["Assignment", ["enemy_id", "phase", "attack_name"]], ["Distance · tiles", ["min_range_units", "max_range_units", "priority"]]]
	for group in groups:
		var heading := Game.label(group[0], 15)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		heading.modulate = Color("a8c6e6")
		form.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 2 if group[0] == "Reference" else 4
		grid.add_theme_constant_override("h_separation", 12)
		form.add_child(grid)
		for column in group[1]:
			if _rows()[index].has(column): _add_field(grid, column, index)
		# Fill an incomplete pair so both field columns retain consistent widths.
		if grid.columns == 4 and grid.get_child_count() % 4 != 0:
			grid.add_child(Control.new())
			var filler := Control.new()
			filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(filler)
	_update_summary()

func _add_field(grid: GridContainer, column: String, index: int) -> void:
	var labels := {"codex_online_name": "Research name", "windup_s": "Wind-up", "animation_s": "Execution", "recovery_s": "Recovery", "flight_time_s": "Flight time", "coverage_area_units2": "Area (u²)", "initial_speed_units_s": "Initial speed", "horizontal_speed_units_s": "Horizontal speed", "vertical_speed_units_s": "Vertical speed", "gravity_units_s2": "Gravity", "projectiles_toward": "Shots toward", "projectiles_other": "Other shots", "min_range_units": "Minimum", "max_range_units": "Maximum"}
	var label := Game.label(labels.get(column, column.replace("_", " ").capitalize()), 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.tooltip_text = _help(column)
	grid.add_child(label)
	var edit := LineEdit.new()
	edit.text = catalog.format_cell(column, str(_rows()[index].get(column, "")))
	edit.custom_minimum_size.x = 125
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.editable = writable and column not in ["score", "name", "type", "status"]
	edit.tooltip_text = _help(column)
	if catalog.error_at.table == ("ranges" if ranges else "attacks") and catalog.error_at.index == index and catalog.error_at.field == column:
		edit.add_theme_color_override("font_color", Color("ff7070"))  # the value the validation stopped at
	grid.add_child(edit)
	fields[column] = edit
	edit.text_changed.connect(func(value): _change(column, value))
	edit.focus_exited.connect(func():
		if selected != index or fields.get(column) != edit: return
		var formatted: String = catalog.format_cell(column, edit.text)
		if formatted != edit.text:
			edit.text = formatted
			_change(column, formatted))

func _change(column: String, value: String) -> void:
	_rows()[selected][column] = value
	dirty = true
	dirty_changed.emit()
	_update_summary()
	_update_feedback()

func _update_summary() -> void:
	if _rows().is_empty(): return
	var invalid: String = catalog.validate()
	if not invalid.is_empty():
		summary.text = invalid
		return
	var row: Dictionary = _rows()[selected]
	if ranges:
		summary.text = "Check maximum range descending, then priority descending. Use [minimum, maximum); execute only the first eligible attack."
	else:
		var result: Dictionary = catalog.score_attack(row)
		summary.text = "Score unavailable: " + result.reason if not result.valid else "Score %.2f = raw %.2f / warning penalty %.2f · area %.2f units² · measured time %.2f s · weighted count %.2f" % [result.score, result.raw, result.penalty, result.area, result.time, result.count]
		if fields.has("score"): fields.score.text = "%.2f" % result.score if result.valid else ""

func _update_feedback() -> void:
	if feedback == null: return
	var invalid: String = catalog.validate_for_save()
	feedback.text = invalid if not invalid.is_empty() else ("Unsaved draft" if dirty else "CSV loaded")
	feedback.tooltip_text = catalog.range_warnings()
	if invalid.is_empty() and not feedback.tooltip_text.is_empty(): feedback.text += " · Overlapping ranges (hover for details)"
	save_button.disabled = not writable or not invalid.is_empty()

func _save() -> void:
	if not writable: return
	# Save both drafts after joint validation so switching tables cannot lose edits.
	var invalid: String = catalog.validate_for_save()
	if not invalid.is_empty():
		feedback.text = invalid
		return
	if not dirty:
		feedback.text = "No unsaved changes"
		return
	if loaded_texts != [FileAccess.get_file_as_string(catalog.attack_path), FileAccess.get_file_as_string(catalog.assignment_path)]:
		feedback.text = "CSV changed on disk. Reload before saving to avoid overwriting external edits."
		return
	var saved: String = catalog.save_all()
	if not saved.is_empty():
		feedback.text = saved
		return
	catalog.reload()
	_select_row(selected)
	loaded_texts = [FileAccess.get_file_as_string(catalog.attack_path), FileAccess.get_file_as_string(catalog.assignment_path)]
	if catalog.attack_path == "res://data/attacks.csv": Catalog.shared().reload()
	dirty = false
	dirty_changed.emit()
	feedback.text = "Saved CSVs · new selections use the updated catalogue"

func _reload_requested() -> void:
	if not dirty:
		_reload()
		return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Discard unsaved CSV edits and reload?"
	confirm.confirmed.connect(_reload)
	confirm.visibility_changed.connect(func():
		if not confirm.visible: confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()

func _reload() -> bool:
	if not catalog.reload():
		feedback.text = catalog.error
		return false
	loaded_texts = [FileAccess.get_file_as_string(catalog.attack_path), FileAccess.get_file_as_string(catalog.assignment_path)]
	dirty = false
	dirty_changed.emit()
	if catalog.attack_path == "res://data/attacks.csv": Catalog.shared().reload()
	_show_table(ranges)
	return true

# ---- Enemies tab: pick an enemy; its sprite, its attacks in priority order (move up / down, skip chance), scores ----
func _show_enemies() -> void:
	view = "enemies"
	ranges = true
	table.clear()
	for e in ENEMIES:
		table.add_item(e[2])
	table.select(enemy_index)
	_select_enemy(enemy_index)
	_update_feedback()

class SpritePreview extends Control:  # the enemy drawn 3x, animated
	var ent = null
	func _process(dt: float) -> void:
		if ent != null and "clock" in ent:
			ent.clock += dt
		queue_redraw()
	func _draw() -> void:
		if ent == null: return
		var k := 5.0
		draw_set_transform(size / 2.0 - Vector2(ent.rect.get_center()) * k, 0, Vector2(k, k))
		ent.draw(self)
		draw_set_transform(Vector2.ZERO)

func _sample_monster() -> Dictionary:  # the first saved library-monster build in the world, else a plain one
	var world: Dictionary = Game.Adventure.load_world(Game.world_path)
	for room in world.get("rooms", {}).values():
		for d in room.level.entities:
			if d.t == "enemy_monster": return d.duplicate(true)
	return {"t": "enemy_monster", "move": "patrol", "attacks": ["charge"], "traits": [], "tier": 0, "look": "enemy_hornback"}

func _select_enemy(i: int) -> void:
	enemy_index = i
	selected = i
	fields.clear()
	for node in form.get_children():
		form.remove_child(node)
		node.queue_free()
	var e: Array = ENEMIES[i]
	var preview := SpritePreview.new()
	preview.custom_minimum_size = Vector2(0, 170)
	var data: Dictionary = _sample_monster() if e[0] == "enemy_monster" else {"t": e[0]}
	data.x = 0
	data.y = 0
	preview.ent = load("res://scripts/entities.gd").make(null, data)
	form.add_child(preview)
	var head := Game.label("Attacks in priority order: the first one in range, eligible and not skipped is used", 14)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.modulate = Color("a8c6e6")
	form.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 10)
	form.add_child(grid)
	for title in ["#", "Attack", "Min (tiles)", "Max (tiles)", "Skip %", "", "", "", "Score"]:
		var l := Game.label(title, 13)
		l.modulate = Color(1, 1, 1, 0.6)
		grid.add_child(l)
	var rows: Array = catalog.ordered_attacks(e[0], e[1])
	for k in rows.size():
		var row: Dictionary = rows[k]
		grid.add_child(Game.label(str(k + 1), 14))
		var name := Game.label(str(catalog.attack(row.attack_name).get("codex_online_name", row.attack_name)), 14)
		name.tooltip_text = row.attack_name
		grid.add_child(name)
		for column in ["min_range_units", "max_range_units", "skip_chance"]:
			var edit := LineEdit.new()
			edit.text = catalog.format_cell(column, str(row.get(column, "0")))
			edit.custom_minimum_size.x = 80
			edit.editable = writable
			edit.tooltip_text = _help(column)
			var bad: bool = catalog.error_at.table == "ranges" and catalog.assignments.find(row) == catalog.error_at.index and catalog.error_at.field == column
			if bad: edit.add_theme_color_override("font_color", Color("ff7070"))
			edit.text_changed.connect(func(v): _binding_change(row, column, v))
			grid.add_child(edit)
		for b in [["▲", -1, k == 0], ["▼", 1, k == rows.size() - 1]]:
			var btn := Game.button(b[0], func(): _move(row, b[1]))
			btn.disabled = not writable or b[2]
			btn.tooltip_text = "Raise priority" if b[1] < 0 else "Lower priority"
			grid.add_child(btn)
		var del := Game.button("✕", func(): _remove_binding(row))
		del.disabled = not writable
		del.tooltip_text = "Remove this attack from the enemy"
		grid.add_child(del)
		var sc: Dictionary = catalog.score_attack(catalog.attack(row.attack_name))
		grid.add_child(Game.label("%.2f" % sc.score if sc.valid else "-", 14))
	var free: Array = catalog.EXECUTABLE.get(e[0], []).filter(func(a): return not rows.any(func(r): return r.attack_name == a))
	if writable and not free.is_empty():
		var add_row := HBoxContainer.new()
		var pick := OptionButton.new()
		for a in free:
			pick.add_item(a)
		add_row.add_child(pick)
		add_row.add_child(Game.button("+ Add attack", func(): _add_binding(e, pick.get_item_text(pick.selected))))
		form.add_child(add_row)
	var scores := Game.label(_score_text(e), 13)
	scores.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	form.add_child(scores)
	summary.text = "Skip %: the chance an attack in range passes its turn, so the next one in the list is tried."

func _binding_change(row: Dictionary, column: String, value: String) -> void:
	row[column] = value
	dirty = true
	dirty_changed.emit()
	_update_feedback()

func _move(row: Dictionary, step: int) -> void:
	catalog.move_binding(row, step)
	dirty = true
	dirty_changed.emit()
	_select_enemy(enemy_index)
	_update_feedback()

func _remove_binding(row: Dictionary) -> void:
	catalog.assignments.erase(row)
	dirty = true
	dirty_changed.emit()
	_select_enemy(enemy_index)
	_update_feedback()

func _add_binding(e: Array, attack_name: String) -> void:  # added last (lowest priority)
	for row in catalog.ordered_attacks(e[0], e[1]):
		row.priority = str(int(row.priority) + 1)
	var row := {}
	for column in catalog.assignment_columns:
		row[column] = ""
	row.merge({"enemy_id": e[0], "phase": e[1], "attack_name": attack_name, "min_range_units": "0.00", "max_range_units": "10.00", "priority": "0", "skip_chance": "0.00"}, true)
	catalog.assignments.append(row)
	dirty = true
	dirty_changed.emit()
	_select_enemy(enemy_index)
	_update_feedback()

# Scores for the selected enemy: each saved library-monster build, or the Ape phase's repertoire.
func _score_text(e: Array) -> String:
	if not catalog.validate().is_empty(): return "Scores: fix the invalid value first."
	var lines := PackedStringArray()
	if e[0] == "enemy_monster":
		lines.append("Scores of the saved builds (body area once, then each of its attacks):")
		var world: Dictionary = Game.Adventure.load_world(Game.world_path)
		var entities = load("res://scripts/entities.gd")
		var library = load("res://scripts/monster_library.gd")
		var seen := {}
		for room_id in world.get("rooms", {}):
			for data in world.rooms[room_id].level.entities:
				if data.t != "enemy_monster": continue
				var enemy = entities.make(null, data.duplicate(true))
				var key: String = library.key(enemy.d)
				if seen.has(key): continue
				seen[key] = true
				var area := float(enemy.rect.size.x * enemy.rect.size.y) / 64.0
				var result: Dictionary = catalog.enemy_score(enemy.d.attacks, area, enemy.speed_multiplier, enemy.warning_multiplier)
				lines.append("  %s · %s" % [library.describe(enemy.d), "%.2f" % result.score if result.valid else "unavailable: " + result.reason])
	else:
		var ids: Array = []
		for binding in catalog.ordered_attacks(e[0], e[1]): ids.append(binding.attack_name)
		ids.append_array(["ape_slam", "ape_log"])
		if e[1] == "enraged": ids.append("ape_split")
		var result: Dictionary = catalog.enemy_score(ids, 9.0)
		lines.append("Repertoire score %.2f (body 9 once, each distinct attack once)%s" % [result.score, "" if result.valid else "; unavailable: " + result.reason])
	return "\n".join(lines)

func _help(field: String) -> String:
	match field:
		"type": return "Implemented attack classification; changing it requires matching gameplay behavior."
		"name": return "Stable runtime ID. Renaming requires implementing and migrating the attack."
		"score": return "Derived reference score; recalculated when saved. Not editable."
		"windup_s": return "Warning before execution, in seconds. Longer warning reduces score."
		"animation_s": return "Execution duration; area/melee scoring uses this. Projectiles use 20-unit reference travel time."
		"coverage_area_units2": return "Reference damage area in square tiles, not sprite size. Body scores use actual enemy size in encounter inspection."
		"initial_speed_units_s": return "Initial speed for reference scoring; charge, dive, and straight shots also use this at runtime. Aimed ballistic attacks use their component parameters."
		"priority": return "Higher values are checked first when maximum ranges match."
		"skip_chance": return "Percent chance this attack passes its turn when it could be used; the next one in the list is tried."
		"min_range_units", "max_range_units": return "Center-to-center radial distance in tiles. Minimum inclusive; maximum exclusive. Large maximum ranges are checked first."
		"notes": return str(_rows()[selected].get("notes", ""))
	return field.replace("_", " ") + ". Blank means unspecified, not zero. See docs/ATTACK_SCORING_PLAN.md."
