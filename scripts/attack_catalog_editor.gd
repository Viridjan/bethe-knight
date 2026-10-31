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
		["Identity", ["name", "type"]],
		["Timing · seconds", ["windup_s", "animation_s", "recovery_s", "flight_time_s"]],
		["Shape · tile units", ["coverage_area_units2", "initial_speed_units_s", "multishot", "aimed_shot", "spread_deg"]],
		["Movement · tile units / seconds", ["horizontal_speed_units_s", "vertical_speed_units_s", "gravity_units_s2", "max_distance_units", "shockwave_s"]]
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
	var labels := {"codex_online_name": "Research name", "windup_s": "Wind-up", "animation_s": "Execution", "recovery_s": "Recovery", "flight_time_s": "Flight time", "coverage_area_units2": "Area (u²)", "initial_speed_units_s": "Initial speed", "horizontal_speed_units_s": "Horizontal speed", "vertical_speed_units_s": "Vertical speed", "gravity_units_s2": "Gravity", "multishot": "Multishot", "aimed_shot": "Aimed shot #", "spread_deg": "Spread (°)", "max_distance_units": "Max distance", "shockwave_s": "Shockwave time", "min_range_units": "Minimum", "max_range_units": "Maximum"}
	var label := Game.label(labels.get(column, column.replace("_", " ").capitalize()), 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size.x = 150  # the same in every section, so the boxes line up
	label.tooltip_text = _help(column)
	grid.add_child(label)
	var edit := LineEdit.new()
	edit.text = catalog.format_cell(column, str(_rows()[index].get(column, "")))
	edit.custom_minimum_size.x = 125
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.editable = writable and column not in ["score", "name", "type", "status"]
	if column == "animation_s" and _rows()[index].get("type", "") in ["ranged", "movement"]:  # a projectile / the move sets the time
		edit.editable = false
	if column == "coverage_area_units2" and catalog.uses_body(_rows()[index]):  # body / movement attacks: the enemy's own body
		edit.text = "body"
		edit.editable = false
	edit.tooltip_text = _help(column)
	if column == "animation_s" and _rows()[index].get("type", "") == "ranged":
		edit.tooltip_text = "Ranged attacks spawn a projectile that then flies by itself: there's no execution animation to time."
	elif column == "animation_s" and _rows()[index].get("type", "") == "movement":
		edit.tooltip_text = "Movement attacks last as long as the move (a charge until a wall or ledge, a leap until it lands): the value here is only a time limit / reference."
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
		summary.text = "What makes the attack work. Scores, weights, names and notes are in Enemies, under each attack."

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

class SpritePreview extends Control:  # the enemy drawn 5x, animated (through a scaled node: some draws set their own transform)
	var ent = null
	var canvas := Sprite.new()
	func _ready() -> void:
		add_child(canvas)
	func _process(dt: float) -> void:
		if ent == null: return
		if "clock" in ent:
			ent.clock += dt
		var k := 5.0
		canvas.ent = ent
		canvas.scale = Vector2(k, k)
		canvas.position = size / 2.0 - Vector2(ent.rect.get_center()) * k
		canvas.queue_redraw()
	class Sprite extends Node2D:
		var ent = null
		func _draw() -> void:
			if ent != null: ent.draw(self)

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
	# one block per attack: its binding line (rank, name, ranges, skip, order, score), its mechanics, its notes
	var widths := [22, 190, 62, 62, 62, 30, 30, 30, 56]
	var header := HBoxContainer.new()
	for k in widths.size():
		var l := Game.label(["#", "Attack", "Min", "Max", "Skip %", "", "", "", "Score"][k], 12)
		l.custom_minimum_size.x = widths[k]
		l.modulate = Color(1, 1, 1, 0.6)
		header.add_child(l)
	form.add_child(header)
	var rows: Array = catalog.ordered_attacks(e[0], e[1])
	for k in rows.size():
		var row: Dictionary = rows[k]
		var attack: Dictionary = catalog.attack(row.attack_name)
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 2)
		form.add_child(block)
		var line := HBoxContainer.new()
		block.add_child(line)
		var rank := Game.label(str(k + 1), 13)
		rank.custom_minimum_size.x = widths[0]
		line.add_child(rank)
		var score := Game.label("", 13)
		var title := _compact_field(line, attack, "codex_online_name", score)  # the research name, editable here
		title.custom_minimum_size.x = widths[1] - (46 if attack.get("status", "") != "implemented" else 0)
		title.tooltip_text = "%s (%s, %s) · shared by every enemy with this attack" % [row.attack_name, attack.get("type", ""), attack.get("status", "")]
		if attack.get("status", "") != "implemented":
			var tag := Game.label(str(attack.get("status", "")), 11)
			tag.custom_minimum_size.x = 46
			tag.modulate = Color(1, 1, 1, 0.5)
			line.add_child(tag)
		for column in ["min_range_units", "max_range_units", "skip_chance"]:
			var edit := _small_edit(writable)
			edit.text = catalog.format_cell(column, str(row.get(column, "0")))
			if column == "max_range_units" and float(str(row.get(column, "0"))) == 0:
				edit.text = ""  # 0 = no maximum
			if column == "max_range_units":
				edit.placeholder_text = "no max"
			edit.custom_minimum_size.x = widths[2]
			edit.tooltip_text = _help(column)
			if catalog.error_at.table == "ranges" and catalog.assignments.find(row) == catalog.error_at.index and catalog.error_at.field == column:
				edit.add_theme_color_override("font_color", Color("ff7070"))
			edit.text_changed.connect(func(v): _binding_change(row, column, v))
			line.add_child(edit)
		for b in [["▲", -1, k == 0], ["▼", 1, k == rows.size() - 1], ["✕", 0, false]]:
			var btn := Game.button(b[0], (func(): _move(row, b[1])) if b[1] != 0 else (func(): _remove_binding(row)))
			btn.add_theme_font_size_override("font_size", 12)
			btn.custom_minimum_size = Vector2(widths[5], 0)
			btn.disabled = not writable or b[2]
			btn.tooltip_text = {-1: "Raise priority", 1: "Lower priority", 0: "Remove this attack from the enemy"}[b[1]]
			line.add_child(btn)
		score.custom_minimum_size.x = widths[8]
		line.add_child(score)
		_show_score(score, attack)
		var margin := MarginContainer.new()  # the attack's values: only those that apply, a short tag before each box
		margin.add_theme_constant_override("margin_left", widths[0])
		block.add_child(margin)
		var mech := HFlowContainer.new()
		mech.add_theme_constant_override("h_separation", 10)
		margin.add_child(mech)
		for column in _applicable(attack):
			var pair := HBoxContainer.new()  # tag and box wrap together
			pair.add_theme_constant_override("separation", 3)
			var tag := Game.label(TAGS.get(column, column), 11)
			tag.modulate = Color(1, 1, 1, 0.55)
			tag.tooltip_text = _help(column)
			pair.add_child(tag)
			_compact_field(pair, attack, column, score)
			mech.add_child(pair)
		var notes_line := HBoxContainer.new()
		block.add_child(notes_line)
		var pad := Control.new()
		pad.custom_minimum_size.x = widths[0]
		notes_line.add_child(pad)
		var notes := _compact_field(notes_line, attack, "notes", score)
		notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		notes.placeholder_text = "notes"
		block.add_child(HSeparator.new())
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

# Short tags for the compact view, in display order; the fields an attack's type always needs.
const TAGS := {"windup_s": "wind", "animation_s": "exec", "recovery_s": "rec", "flight_time_s": "flight", "coverage_area_units2": "area",
	"initial_speed_units_s": "spd", "multishot": "×", "aimed_shot": "aim", "spread_deg": "spr", "horizontal_speed_units_s": "h-spd",
	"vertical_speed_units_s": "v-spd", "gravity_units_s2": "grav", "max_distance_units": "dist", "shockwave_s": "wave", "base_weight": "wgt"}
const NEEDS := {"body": ["windup_s", "animation_s", "recovery_s", "initial_speed_units_s"], "melee": ["windup_s", "animation_s", "recovery_s", "coverage_area_units2"],
	"area": ["windup_s", "animation_s", "recovery_s", "coverage_area_units2"], "movement": ["windup_s", "recovery_s"],
	"ranged": ["windup_s", "recovery_s", "coverage_area_units2", "initial_speed_units_s", "multishot", "aimed_shot", "spread_deg"]}

func _applicable(attack: Dictionary) -> Array:  # the values that mean something for this attack
	var type: String = attack.get("type", "")
	var need: Array = NEEDS.get(type, []) + ["base_weight"]
	var shots := type == "ranged" or int(str(attack.get("multishot", "1")) if str(attack.get("multishot", "")) != "" else "1") > 1
	return TAGS.keys().filter(func(c):
		if c == "animation_s" and type in ["ranged", "movement"]: return false  # not used: the shot / the move sets the time
		if c in ["multishot", "aimed_shot", "spread_deg"] and not shots: return false
		return c in need or str(attack.get(c, "")) != "")

func _small_edit(editable: bool) -> LineEdit:
	var edit := LineEdit.new()
	edit.add_theme_font_size_override("font_size", 12)
	edit.custom_minimum_size.x = 56
	edit.editable = editable
	return edit

# One small edit box for an attack value (shared by every enemy with that attack); greying as in the Attacks tab.
func _compact_field(parent: Control, attack: Dictionary, column: String, score: Label) -> LineEdit:
	var edit := _small_edit(writable)
	edit.text = catalog.format_cell(column, str(attack.get(column, "")))
	edit.tooltip_text = _help(column) + " · shared by every enemy with this attack"
	if column == "animation_s" and attack.get("type", "") in ["ranged", "movement"]:
		edit.editable = false
	if column == "coverage_area_units2" and catalog.uses_body(attack):
		edit.text = "body"
		edit.editable = false
	if catalog.error_at.table == "attacks" and catalog.attacks.find(attack) == catalog.error_at.index and catalog.error_at.field == column:
		edit.add_theme_color_override("font_color", Color("ff7070"))
	edit.text_changed.connect(func(v):
		attack[column] = v
		dirty = true
		dirty_changed.emit()
		_show_score(score, attack)
		_update_feedback())
	parent.add_child(edit)
	return edit

func _show_score(label: Label, attack: Dictionary) -> void:
	var sc: Dictionary = catalog.score_attack(attack) if catalog.validate().is_empty() else {"valid": false}
	label.text = "%.2f" % sc.score if sc.valid else "-"

func _binding_change(row: Dictionary, column: String, value: String) -> void:
	row[column] = "0" if column == "max_range_units" and value.strip_edges().is_empty() else value  # empty = no maximum
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
		"coverage_area_units2": return "Damage area in square tiles, not sprite size. Body attacks hit with the enemy's own body: its size is used (10x10 px reference here; each enemy's real size in Enemies)."
		"initial_speed_units_s": return "Initial speed for reference scoring; charge, dive, and straight shots also use this at runtime. Aimed ballistic attacks use their component parameters."
		"max_distance_units": return "Charge / dive: the farthest it goes, in tiles (it stops sooner at a wall, a ledge or anything it hits)."
		"shockwave_s": return "Landing slam: how long the shockwave hits, in seconds."
		"multishot": return "How many projectiles the attack fires at once (library monsters' shoot and lob fire them all)."
		"aimed_shot": return "Which shot points at the player: 0 is the lowest one, numbers go upward."
		"spread_deg": return "Degrees between neighbouring shots. 0 spaces them evenly around the full circle."
		"priority": return "Higher values are checked first when maximum ranges match."
		"skip_chance": return "Percent chance this attack passes its turn when it could be used; the next one in the list is tried."
		"max_range_units": return "Center-to-center radial distance in tiles, exclusive. Empty (0) = no maximum."
		"min_range_units": return "Center-to-center radial distance in tiles. Minimum inclusive; maximum exclusive. Large maximum ranges are checked first."
		"notes": return str(_rows()[selected].get("notes", ""))
	return field.replace("_", " ") + ". Blank means unspecified, not zero. See docs/ATTACK_SCORING_PLAN.md."
