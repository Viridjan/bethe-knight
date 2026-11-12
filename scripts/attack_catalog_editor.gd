extends VBoxContainer
# The Monsters catalogue edits a private draft; only validated, explicitly saved CSV affects gameplay.
const Catalog := preload("res://scripts/attack_catalog.gd")
var catalog = null
var search: LineEdit
var list_indices: Array = []
var list_count: Label
var attack_tab: Button
var enemy_tab: Button
var score_value: Label
var detail_title: Label
var expanded_attacks := {}
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
var view := "enemies"  # "attacks" (attack definitions) or "enemies" (each enemy's attacks, ranges and scores)
var enemy_index := 0
var form_scroll: ScrollContainer
var world_cache := {}
var stats: HFlowContainer  # the selected enemy's health and coverage fields
var page_title := "Monster Editor"
var effect_hints: Array = []  # visible effect controls and the profile effect IDs they describe
# The enemies whose attacks come from the CSV: [enemy id, phase, name in the list]
const CSV_ENEMIES := [["boss_ape", "normal", "Ape"], ["enemy_monster", "default", "Library monster"],
	["enemy_skree", "default", "Dropwing · ceiling dive"], ["enemy_bat", "default", "Duskflit · swoop"], ["enemy_skeleton", "default", "Ossling · bone throw"],
	["enemy_hornback", "default", "Hornback · charge"], ["enemy_cragjaw", "default", "Cragjaw · leaping brute"], ["enemy_murkspore", "default", "Murkspore · spore spitter"]]
# Every enemy in the game: the CSV-driven ones first (their attacks are edited here), then all the others, whose
# attacks live in scripts/entities.gd ([type id, "" , name]).
var ENEMIES: Array = []

func _all_enemies() -> Array:
	var out: Array = CSV_ENEMIES.duplicate()
	var types: Dictionary = load("res://scripts/entities.gd").TYPES
	for t in types:
		if t.begins_with("enemy_") and t != "enemy_monster" and not CSV_ENEMIES.any(func(c): return c[0] == t):
			out.append([t, "", str(types[t][0])])
	out.append(["ape_chase", "", "Ape (Sand Cave chase)"])
	out.append(["boss_guardian", "", "Guardian (boss)"])
	return out
signal dirty_changed

func _ready() -> void:
	if catalog == null:
		catalog = Catalog.new()
		catalog.reload()
	loaded_texts = catalog.source_texts()
	writable = OS.has_feature("editor") and not OS.has_feature("web")
	ENEMIES = _all_enemies()
	theme = _soft_theme(theme)
	add_theme_constant_override("separation", 12)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	add_child(heading)
	var title := Game.label(page_title, 25)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	reload_button = Game.button("Reload", _reload_requested)
	reload_button.tooltip_text = "Reload the CSV files from disk."
	heading.add_child(reload_button)
	save_button = Game.button("Save changes", _save)
	save_button.disabled = not writable
	save_button.tooltip_text = "Validate and save both CSVs. New attack selections use the saved changes."
	save_button.add_theme_stylebox_override("normal", _surface("2d5273", "2d5273", 10))
	heading.add_child(save_button)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	add_child(tabs)
	attack_tab = Game.button("Attack library", func(): _show_table(false))
	enemy_tab = Game.button("Enemy loadouts", _show_enemies)
	for tab in [attack_tab, enemy_tab]:
		tab.toggle_mode = true
		var plain := StyleBoxFlat.new()
		plain.bg_color = Color(0, 0, 0, 0)
		plain.content_margin_left = 4
		plain.content_margin_right = 4
		plain.content_margin_top = 6
		plain.content_margin_bottom = 6
		plain.border_color = Color("6f8fc4")
		var chosen: StyleBoxFlat = plain.duplicate()
		chosen.border_width_bottom = 2
		for state in ["normal", "hover", "focus"]: tab.add_theme_stylebox_override(state, plain)
		for state in ["pressed", "hover_pressed"]: tab.add_theme_stylebox_override(state, chosen)
		tab.add_theme_color_override("font_color", Color("8a93a6"))
		tab.add_theme_color_override("font_pressed_color", Color("eef0f5"))
		tabs.add_child(tab)
	tabs.add_theme_constant_override("separation", 18)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	var panes := HSplitContainer.new()
	panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panes.split_offset = 230
	add_child(panes)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 220
	panes.add_child(sidebar)
	search = LineEdit.new()
	search.placeholder_text = "Search attacks…"
	search.clear_button_enabled = true
	search.text_changed.connect(func(_value): _filter_list())
	sidebar.add_child(search)
	list_count = Game.label("", 12)
	list_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	list_count.modulate = Color("8496ad")
	sidebar.add_child(list_count)
	table = ItemList.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.add_theme_constant_override("v_separation", 8)
	sidebar.add_child(table)
	table.item_selected.connect(func(i):
		if view == "enemies": _select_enemy(list_indices[i])
		else: _select_row(list_indices[i]))
	var scroll := ScrollContainer.new()
	form_scroll = scroll
	scroll.mouse_force_pass_scroll_events = false
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panes.add_child(scroll)
	form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 8)
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form)
	summary = Game.label("", 12)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary.modulate = Color(1, 1, 1, 0.7)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	feedback = Game.label("", 12)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(feedback)
	_show_enemies()

static func _surface(background: String, border: String, padding: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

# Section heading: small, quiet, left-aligned. The same everywhere on the page.
func _caption(text: String) -> Label:
	var caption := Game.label(text, 11)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caption.modulate = Color("7f96b3")
	return caption

# A value's name beside its box: quieter than the value.
func _tag(text: String) -> Label:
	var tag := Game.label(text, 12)
	tag.modulate = Color(1, 1, 1, 0.62)
	return tag

# One label + control pair that wraps as a unit in the stats row.
func _stat(parent: Control, text: String, control: Control) -> void:
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 6)
	pair.add_child(_tag(text))
	pair.add_child(control)
	parent.add_child(pair)

func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _surface("1a202c", "1a202c", 10))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	return content

func _filter_list() -> void:
	table.clear()
	list_indices.clear()
	var entries: Array = ENEMIES if view == "enemies" else _rows()
	for i in entries.size():
		var label: String
		var detail: String
		if view == "enemies":
			label = str(entries[i][2])
			detail = str(entries[i][0])
		elif ranges:
			label = "%s · %s" % [entries[i].enemy_id, entries[i].attack_name]
			detail = entries[i].phase
		else:
			label = str(entries[i].get("codex_online_name", entries[i].name))
			detail = "%s · %s" % [entries[i].name, entries[i].type]
		if not search.text.is_empty() and not (label + " " + detail).to_lower().contains(search.text.to_lower()): continue
		if view == "enemies" and entries[i][1] == "" and (i == 0 or entries[i - 1][1] != "") and not list_indices.is_empty():
			table.add_item("— Code-driven attacks —", null, false)  # divider
			table.set_item_custom_fg_color(table.item_count - 1, Color("6f7fa8"))
			list_indices.append(-1)
		list_indices.append(i)
		table.add_item(label)
		table.set_item_tooltip(table.item_count - 1, label + "\n" + detail)
		if view == "enemies" and entries[i][1] == "": table.set_item_custom_fg_color(table.item_count - 1, Color("8d92a3"))
	list_count.text = "%d %s" % [list_indices.filter(func(k): return k >= 0).size(), "enemies" if view == "enemies" else "attacks"] if not list_indices.is_empty() else "No matches"
	var active := enemy_index if view == "enemies" else selected
	var visible_index := list_indices.find(active)
	if visible_index >= 0: table.select(visible_index)

func _tabs() -> void:
	attack_tab.set_pressed_no_signal(view != "enemies")
	enemy_tab.set_pressed_no_signal(view == "enemies")
	search.text = ""
	search.placeholder_text = "Search enemies…" if view == "enemies" else "Search attacks…"

# Softer contrast than the game's pure white on dark: off-white text, dimmer labels, darker boxes with a thin border.
static func _soft_theme(base: Theme) -> Theme:
	var t: Theme = base.duplicate() if base != null else Game.theme.duplicate()
	var text := Color("d4d7e0")
	# Flat surfaces: an outline appears only on hover and focus.
	t.set_stylebox("normal", "Button", _surface("222b3a", "222b3a", 8))
	t.set_stylebox("hover", "Button", _surface("2b3a50", "4d6788", 8))
	t.set_stylebox("pressed", "Button", _surface("2b425c", "2b425c", 8))
	t.set_stylebox("disabled", "Button", _surface("1a202c", "1a202c", 8))
	t.set_stylebox("panel", "ItemList", _surface("171c27", "171c27", 6))
	t.set_stylebox("selected", "ItemList", _surface("26384f", "26384f", 6))
	t.set_stylebox("selected_focus", "ItemList", _surface("26384f", "4d6788", 6))

	t.set_color("font_color", "Label", Color("b9bdca"))
	t.set_color("font_color", "Button", text)
	t.set_color("font_color", "ItemList", Color("b9bdca"))
	t.set_color("font_selected_color", "ItemList", Color("eef0f5"))
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_uneditable_color", "LineEdit", Color("7c8193"))
	t.set_color("font_placeholder_color", "LineEdit", Color("6c7183"))
	t.set_color("font_color", "TextEdit", text)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("131822")
	box.border_color = Color("2a3140")
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 6
	box.content_margin_right = 6
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	t.set_stylebox("normal", "LineEdit", box)
	var focus: StyleBoxFlat = box.duplicate()
	focus.border_color = Color("6f8fc4")
	t.set_stylebox("focus", "LineEdit", focus)
	var locked: StyleBoxFlat = box.duplicate()
	locked.bg_color = Color("191b25")
	locked.border_color = Color("262938")
	t.set_stylebox("read_only", "LineEdit", locked)
	return t

func _rows() -> Array:
	return catalog.assignments if ranges else catalog.attacks

func _show_table(show_ranges: bool) -> void:
	view = "ranges" if show_ranges else "attacks"
	ranges = show_ranges
	_tabs()
	_filter_list()
	if not _rows().is_empty(): _select_row(clampi(selected, 0, _rows().size() - 1))
	_update_feedback()

func _select_row(index: int) -> void:
	selected = index
	var visible_index := list_indices.find(index)
	if visible_index >= 0: table.select(visible_index)
	fields.clear()
	for node in form.get_children():
		form.remove_child(node)
		node.queue_free()
	score_value = null
	var row: Dictionary = _rows()[index]
	var hero := HBoxContainer.new()
	form.add_child(hero)
	var name_label := Game.label(str(row.get("codex_online_name", row.get("attack_name", "Attack"))), 23)
	detail_title = name_label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.tooltip_text = str(row.get("notes", ""))
	hero.add_child(name_label)
	if not ranges:
		score_value = Game.label("", 20)
		score_value.modulate = Color("a4d4df")
		hero.add_child(score_value)
	var groups: Array = [
		["Definition", ["codex_online_name", "type", "behavior"], false],
		["Timing", ["windup_s", "animation_s", "recovery_s"], false],
		["Attack shape", ["coverage_area_units2", "initial_speed_units_s", "multishot", "aimed_shot", "spread_deg", "max_distance_units", "shockwave_s"], false],
		["Trajectory", ["flight_time_s", "horizontal_speed_units_s", "vertical_speed_units_s", "gravity_units_s2"], true],
		["Advanced", ["name", "base_weight"], true]
	]
	if ranges: groups = [["Assignment", ["enemy_id", "phase", "attack_name"], false], ["Distance", ["max_range_units", "priority"], false]]
	var keep: Array = _applicable(row) + ["codex_online_name", "name", "type", "behavior", "base_weight"] if not ranges else []
	for group in groups:
		var columns: Array = group[1].filter(func(column): return row.has(column) and (ranges or column in keep))
		if columns.is_empty(): continue
		var section := _card(form)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 18)
		grid.add_theme_constant_override("v_separation", 10)
		if group[2]:
			var toggle := Game.button("+ " + group[0], func(): pass)
			toggle.flat = true
			toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
			toggle.pressed.connect(func():
				grid.visible = not grid.visible
				toggle.text = ("− " if grid.visible else "+ ") + group[0])
			section.add_child(toggle)
			grid.visible = false
		else:
			var heading := Game.label(group[0], 14)
			heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			heading.modulate = Color("91b2d3")
			section.add_child(heading)
		section.add_child(grid)
		for column in columns: _add_field(grid, column, index)
	if not ranges and writable:
		var name: String = str(_rows()[index].get("name", ""))
		var used: bool = catalog.runtime_used(name)
		var del := Game.button("Delete attack", func(): _delete_attack(name))
		del.disabled = used
		del.visible = not used
		del.tooltip_text = "The game code uses this attack: it can't be deleted." if used else "Remove this attack from the catalogue and from every enemy that has it."
		form.add_child(del)
	_update_summary()
	_wrap_tips(form)

func _add_field(grid: GridContainer, column: String, index: int) -> void:
	var cell := VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", 4)
	grid.add_child(cell)
	var labels := {"codex_online_name": "Name", "name": "ID", "windup_s": "Wind-up", "animation_s": "Execution", "recovery_s": "Recovery", "flight_time_s": "Flight time", "coverage_area_units2": "Area (u²)", "initial_speed_units_s": "Initial speed", "horizontal_speed_units_s": "Horizontal speed", "vertical_speed_units_s": "Vertical speed", "gravity_units_s2": "Gravity", "multishot": "Multishot", "aimed_shot": "Aimed shot #", "spread_deg": "Spread (°)", "max_distance_units": "Max distance", "shockwave_s": "Shockwave time", "min_range_units": "Minimum", "max_range_units": "Range", "base_weight": "Weight", "follow_up": "Then", "follow_up_count": "Times", "follow_up_gap_s": "Every (s)"}
	var label := Game.label(labels.get(column, column.replace("_", " ").capitalize()), 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.tooltip_text = _help(column)
	cell.add_child(label)
	if column in ["type", "behavior"] and not ranges:  # a choice, not free text
		var pick := OptionButton.new()
		var choices: Array = catalog.TYPES if column == "type" else catalog.BEHAVIORS.keys()
		for t in choices:
			pick.add_item(t if column == "type" else catalog.BEHAVIORS[t])
		pick.select(choices.find(str(_rows()[index].get(column, ""))))
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.custom_minimum_size.y = ROW_H
		pick.add_theme_constant_override("arrow_margin", 6)
		var flat := (pick.get_theme_stylebox("normal") as StyleBox).duplicate()  # its padding made it 5 px taller than the boxes
		flat.content_margin_top = 2
		flat.content_margin_bottom = 2
		for state in ["normal", "hover", "pressed", "focus", "disabled"]: pick.add_theme_stylebox_override(state, flat)
		# built-in rows keep their behavior: code, levels and tests name them
		pick.disabled = not writable or (column == "behavior" and catalog.runtime_used(str(_rows()[index].get("name", ""))))
		pick.tooltip_text = _help(column)
		pick.item_selected.connect(func(i):
			if column == "behavior": _rows()[index].status = "implemented" if choices[i] != "" else "planned"
			_change(column, choices[i])
			_select_row(index))  # its type's boxes
		cell.add_child(pick)
		return
	var edit := LineEdit.new()
	edit.text = _shown(column, str(_rows()[index].get(column, "")))
	edit.custom_minimum_size = Vector2(110, ROW_H)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var in_code: bool = catalog.runtime_used(str(_rows()[index].get("name", "")))
	edit.editable = writable and column not in ["score", "type", "status"] and not (column == "name" and (in_code or ranges))
	if column == "animation_s" and _rows()[index].get("type", "") in ["ranged", "movement"]:  # a projectile / the move sets the time
		edit.editable = false
	if column == "coverage_area_units2" and catalog.uses_body(_rows()[index]):  # empty = the enemy's own body
		edit.placeholder_text = "body"
	edit.tooltip_text = _help(column)
	if column == "animation_s" and _rows()[index].get("type", "") == "ranged":
		edit.tooltip_text = "Ranged attacks spawn a projectile that then flies by itself: there's no execution animation to time."
	elif column == "animation_s" and _rows()[index].get("type", "") == "movement":
		edit.tooltip_text = "Movement attacks last as long as the move (a charge until a wall or ledge, a leap until it lands): the value here is only a time limit / reference."
	if catalog.error_at.table == ("ranges" if ranges else "attacks") and catalog.error_at.index == index and catalog.error_at.field == column:
		edit.add_theme_color_override("font_color", Color("ff7070"))  # the value the validation stopped at
	cell.add_child(edit)
	fields[column] = edit
	if column == "name":  # an ID is renamed once, on Enter / leaving the box, never per keystroke
		var commit := func(_v = ""):
			if selected == index and fields.get(column) == edit: _rename(index, edit)
		edit.text_submitted.connect(commit)
		edit.focus_exited.connect(commit)
		return
	edit.text_changed.connect(func(value): _change(column, value))
	edit.focus_exited.connect(func():
		if selected != index or fields.get(column) != edit: return
		var formatted: String = _shown(column, edit.text)
		if formatted != edit.text:
			edit.text = formatted
			_change(column, formatted))

# Rename an attack: every enemy and follow-up that uses it follows. Refused (box reset) when empty, taken, or used by code.
func _rename(index: int, edit: LineEdit) -> void:
	var old: String = str(_rows()[index].get("name", ""))
	var value := edit.text.strip_edges()
	if value == old: return
	var problem := ""
	if value.is_empty(): problem = "An attack ID can't be empty"
	elif catalog.attacks.any(func(a): return a.name == value): problem = "Another attack already has the ID " + value
	elif catalog.runtime_used(old): problem = "The game code uses %s: it can't be renamed" % old
	if problem != "":
		edit.text = old
		feedback.text = problem
		return
	for b in catalog.assignments:
		if b.attack_name == old: b.attack_name = value
	for a in catalog.attacks:
		if str(a.get("follow_up", "")) == old: a.follow_up = value
	_change("name", value)

func _change(column: String, value: String) -> void:
	_rows()[selected][column] = value
	if column in ["name", "codex_online_name", "type"]: _filter_list()
	if column == "codex_online_name" and view == "attacks" and is_instance_valid(detail_title): detail_title.text = value
	dirty = true
	dirty_changed.emit()
	_update_summary()
	_update_feedback()

func _update_summary() -> void:
	if _rows().is_empty(): return
	var invalid: String = catalog.validate()
	if not invalid.is_empty():
		summary.text = ""
		if is_instance_valid(score_value):
			score_value.text = "Score  —"
			score_value.tooltip_text = invalid
		return
	var row: Dictionary = _rows()[selected]
	if ranges:
		summary.text = "Highest priority first; an attack starts when the distance is in [minimum, maximum) and it isn't skipped."
	else:
		summary.text = ""
		if is_instance_valid(score_value):
			var result: Dictionary = catalog.score_attack(row)
			score_value.text = "Score  %d" % result.score if result.valid else "Score  —"
			score_value.tooltip_text = "Raw %.2f / warning factor %.2f" % [result.raw, result.penalty] if result.valid else result.reason

func _update_feedback() -> void:
	if feedback == null: return
	var invalid: String = catalog.validate_for_save()
	feedback.text = invalid if not invalid.is_empty() else ("Unsaved draft" if dirty else "CSV loaded")
	feedback.tooltip_text = catalog.range_warnings()
	if invalid.is_empty() and not feedback.tooltip_text.is_empty(): feedback.text += " · Overlapping ranges (hover for details)"
	feedback.visible = feedback.text != "CSV loaded"  # nothing to report: no line
	save_button.disabled = not writable or not dirty or not invalid.is_empty()

func _save() -> void:
	if not writable: return
	# Save all drafts after joint validation so switching tables cannot lose edits.
	var invalid: String = catalog.validate_for_save()
	if not invalid.is_empty():
		feedback.text = invalid
		return
	if not dirty:
		feedback.text = "No unsaved changes"
		return
	if loaded_texts != catalog.source_texts():
		feedback.text = "Catalogue changed on disk. Reload before saving to avoid overwriting external edits."
		return
	var saved: String = catalog.save_all()
	if not saved.is_empty():
		feedback.text = saved
		return
	if not catalog.reload():
		feedback.text = "Saved, but reloading failed: " + catalog.error
		return
	if view == "enemies": _select_enemy(enemy_index)
	else: _select_row(clampi(selected, 0, _rows().size() - 1))
	loaded_texts = catalog.source_texts()
	if catalog.attack_path == "res://data/attacks.csv": Catalog.shared().reload()
	dirty = false
	dirty_changed.emit()
	feedback.text = "Saved catalogue · new selections use the updated catalogue"

func _reload_requested() -> void:
	if not dirty:
		_reload()
		return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Discard unsaved catalogue edits and reload?"
	confirm.confirmed.connect(_reload)
	confirm.visibility_changed.connect(func():
		if not confirm.visible: confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()

func _reload() -> bool:
	if not catalog.reload():
		feedback.text = catalog.error
		return false
	loaded_texts = catalog.source_texts()
	dirty = false
	dirty_changed.emit()
	if catalog.attack_path == "res://data/attacks.csv": Catalog.shared().reload()
	if view == "enemies": _show_enemies()
	else: _show_table(ranges)
	return true

# ---- Enemies tab: pick an enemy; its attacks in priority order (move up / down, skip chance), scores ----
func _show_enemies() -> void:
	view = "enemies"
	ranges = true
	_tabs()
	_filter_list()
	_select_enemy(enemy_index)
	_update_feedback()

# Projection only: shared mechanics appear once; phase bindings remain independent CSV rows.
func _enemy_rows(e: Array) -> Array:
	if e[0] != "boss_ape": return catalog.enemy_entries(e[0], e[1])
	var rows: Array = []
	for phase in ["normal", "enraged"]:
		for binding in catalog.enemy_entries(e[0], phase):
			var matches := rows.filter(func(r): return r.attack_name == binding.attack_name)
			var row: Dictionary
			if matches.is_empty():
				row = binding.duplicate()
				row._phases = []
				row._bindings = []
				rows.append(row)
			else: row = matches[0]
			row._phases.append(phase)
			if not catalog.triggered(binding): row._bindings.append(binding)
	rows.sort_custom(func(a, b): return not catalog.triggered(a) and catalog.triggered(b))
	return rows

func _effect_help(e: Array, effect: String = "") -> String:
	if e[0] != "boss_ape": return catalog.effect_trigger_text(e[0], e[1], effect)
	var lines := PackedStringArray()
	for phase in ["normal", "enraged"]:
		var hint: String = catalog.effect_trigger_text(e[0], phase, effect)
		if not hint.is_empty(): lines.append("Phase %s: %s" % ["1" if phase == "normal" else "2", hint])
	return "\n".join(lines)


func _attack_trigger_picker(row: Dictionary) -> OptionButton:
	var pick := OptionButton.new()
	var conditions: Array = Catalog.condition_choices(row.enemy_id)
	for condition in conditions: pick.add_item(Catalog.ATTACK_CONDITIONS[condition])
	pick.select(conditions.find(Catalog.attack_condition(row)))
	pick.custom_minimum_size = Vector2(140,ROW_H)
	pick.add_theme_font_size_override("font_size",12)
	pick.disabled = not writable
	pick.tooltip_text = "Condition that enables this attack. Range, priority and Skip % still apply. Player cornered: the player is grounded between the enemy and a wall, and the chosen coverage attack hits every standing position between them. A solid block in any of the first three rows above the floor counts as a wall. Normal rules keeps this attack's built-in selection rules."
	pick.set_meta("attack_trigger",row.attack_name)
	pick.set_meta("phase",row.phase)
	pick.item_selected.connect(func(index): _binding_change(row,"trigger_condition",conditions[index]))
	return pick

func _binding_controls(block: VBoxContainer, row: Dictionary, phased: bool) -> void:
	var widths := [22, 190, 48, 48, 48, 26, 26, 26, 56]
	var binding_line := HBoxContainer.new()
	binding_line.add_theme_constant_override("separation", 6)
	block.add_child(binding_line)
	var ordered: Array = catalog.ordered_attacks(row.enemy_id, row.phase).filter(func(r): return not catalog.triggered(r))
	var k := ordered.find(row)
	var selected_count := ordered.size()
	if phased:
		var phase_tag := _tag("Phase %s · #%d" % ["1" if row.phase == "normal" else "2", k + 1])
		phase_tag.custom_minimum_size.x = 84  # one column, so both phases' boxes line up
		phase_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		binding_line.add_child(phase_tag)
	for column in ["max_range_units", "skip_chance"]:
		var edit := _small_edit(writable)
		edit.text = _shown(column, str(row.get(column, "0")))
		if column == "max_range_units": edit.placeholder_text = "0"
		edit.custom_minimum_size.x = widths[2]
		edit.tooltip_text = _help(column)
		if catalog.error_at.table == "ranges" and catalog.assignments.find(row) == catalog.error_at.index and catalog.error_at.field == column:
			edit.add_theme_color_override("font_color", Color("ff7070"))
		edit.text_changed.connect(func(v): _binding_change(row, column, v))
		var label := _tag({"max_range_units": "Range", "skip_chance": "Skip %"}[column])
		binding_line.add_child(label)
		binding_line.add_child(edit)
	if Catalog.condition_choices(row.enemy_id).size()>1:
		binding_line.add_child(_tag("Trigger"))
		binding_line.add_child(_attack_trigger_picker(row))
	for b in [["up", -1, k == 0], ["down", 1, k == selected_count - 1], ["cross", 0, false]]:
		var btn := Game.button("", (func(): _move(row, b[1])) if b[1] != 0 else (func(): _remove_binding(row)))
		btn.icon = _glyph(b[0])
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_theme_font_size_override("font_size", 12)
		btn.custom_minimum_size = Vector2(widths[5], 0)
		btn.flat = true
		btn.disabled = not writable or b[2]
		btn.tooltip_text = {-1: "Raise priority", 1: "Lower priority", 0: "Remove this attack from the enemy"}[b[1]]
		binding_line.add_child(btn)

# An empty walled room holding the player and one enemy, for trying its attacks.
static func test_room(enemy_id: String) -> Dictionary:
	var room: Dictionary = Game.new_level("Test: " + enemy_id)
	room.tiles[0] = "1".repeat(room.w)
	var enemy := {"t": enemy_id, "x": (room.w - 12) * 8, "y": (room.h - 3) * 8}
	if enemy_id == "boss_guardian": enemy.merge({"w": 96, "h": 64, "y": (room.h - 10) * 8})
	room.entities.append(enemy)
	return room

func _select_enemy(i: int) -> void:
	if i != enemy_index and is_instance_valid(form_scroll): form_scroll.scroll_vertical = 0  # a new enemy starts at its top
	enemy_index = i
	selected = i
	var visible_index := list_indices.find(i)
	if visible_index >= 0: table.select(visible_index)
	fields.clear()
	effect_hints.clear()
	for node in form.get_children():
		form.remove_child(node)
		node.queue_free()
	score_value = null
	var enemy_title := Game.label(str(ENEMIES[i][2]), 24)
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	enemy_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var e: Array = ENEMIES[i]
	var heading := HBoxContainer.new()
	form.add_child(heading)
	heading.add_child(enemy_title)
	var data: Dictionary = {"t": e[0]}
	if e[0] == "boss_guardian":
		data.merge({"w": 96, "h": 64})
	data.x = 0
	data.y = 0
	var ent = load("res://scripts/entities.gd").make(null, data)  # for its family's health and coverage fields
	stats = HFlowContainer.new()
	stats.add_theme_constant_override("h_separation", 18)
	stats.add_theme_constant_override("v_separation", 6)
	if e[0] == "boss_ape": _ape_profile_fields()
	elif ent != null and ent.has_method("variant_hp"):
		_family_health_fields(ent.family())
		if not Catalog.coverage_attacks(ent.family()).is_empty():
			_stat(stats, "Cornered coverage", _cornered_coverage_picker(ent.family()))
	if stats.get_child_count() > 0:
		form.add_child(_caption("STATS"))
		form.add_child(stats)
	else: stats.free()
	if e[1] == "":  # attacks in the game code: what it is and does, read-only
		_code_enemy_info(e, ent)
		return
	# one block per attack: its binding line (rank, name, ranges, skip, order, score), its mechanics, its notes
	var widths := [22, 190, 48, 48, 48, 26, 26, 26, 56]
	var caption := _caption("ATTACK ORDER")
	caption.tooltip_text = "The first eligible attack executes. Use the arrows to change priority."
	form.add_child(caption)
	var rows: Array = _enemy_rows(e)
	var effects_heading := false
	for k in rows.size():
		var row: Dictionary = rows[k]
		if catalog.triggered(row) and not effects_heading:
			effects_heading = true
			var label := _caption("TRIGGERED EFFECTS")
			label.tooltip_text = _effect_help(e)
			effect_hints.append({"control": label, "effect": ""})
			form.add_child(label)
		var attack: Dictionary = catalog.attack(row.attack_name)
		var block := _card(form)
		var line := HBoxContainer.new()
		block.add_child(line)
		var rank := _tag(str(k + 1))
		rank.text = "FX" if catalog.triggered(row) else str(k + 1)
		rank.custom_minimum_size.x = widths[0]
		line.add_child(rank)
		var score := Game.label("", 13)
		var title := _compact_field(line, attack, "codex_online_name", score)  # the research name, editable here
		var is_effect: bool = catalog.triggered(row)
		title.custom_minimum_size.x = 150
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_theme_font_size_override("font_size", 15)  # reads as the block's title; a box appears on focus
		for state in ["normal", "read_only"]: title.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		title.tooltip_text = "%s (%s, %s)\n%s" % [row.attack_name, attack.get("type", ""), attack.get("status", ""), attack.get("notes", "")]
		if is_effect:
			title.tooltip_text = _effect_help(e, row.attack_name) + "\n\n" + squarish(title.tooltip_text)
			effect_hints.append({"control": title, "effect": row.attack_name})
		var info := Game.button("i", func(): _edit_notes(attack, title))  # notes: in the tooltip; click to edit
		info.add_theme_font_size_override("font_size", 12)
		info.custom_minimum_size.x = 22
		info.flat = true
		info.tooltip_text = str(attack.get("notes", "")) if str(attack.get("notes", "")) != "" else "No notes yet: click to add"
		info.disabled = not writable and str(attack.get("notes", "")) == ""
		line.add_child(info)
		if is_effect or attack.get("status", "") != "implemented" or not catalog.performs(e[0], row.attack_name):
			var tag := Game.label("triggered effect" if is_effect else ("not in game yet" if not catalog.performs(e[0], row.attack_name) else str(attack.get("status", ""))), 11)
			tag.custom_minimum_size.x = 46
			tag.modulate = Color(1, 1, 1, 0.5)
			line.add_child(tag)
		if not is_effect:
			for binding in row.get("_bindings", [row]):
				_binding_controls(block, binding, e[0] == "boss_ape")
		score.custom_minimum_size.x = widths[8]
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score.tooltip_text = "Score"
		line.add_child(score)
		_show_score(score, attack)
		if "follow_up" in _applicable(attack):  # its follow-up stays visible without opening Edit
			var follow := HBoxContainer.new()
			follow.add_theme_constant_override("separation", 6)
			block.add_child(follow)
			for column in ["follow_up", "follow_up_count", "follow_up_gap_s"]:  # same look as Min / Max / Skip above
				var tag := _tag(TAGS.get(column, column))
				tag.tooltip_text = _help(column)
				follow.add_child(tag)
				if column == "follow_up":
					var picker := _follow_up_picker(attack)
					picker.custom_minimum_size.x = 160
					follow.add_child(picker)
				else:
					_compact_field(follow, attack, column, score).custom_minimum_size.x = widths[2]
		var detail_key := "%s/%s/%s" % [e[0], e[1], row.attack_name]
		var details := VBoxContainer.new()
		details.visible = expanded_attacks.get(detail_key, false)
		var expand := Game.button("Close" if details.visible else "Edit", func(): pass)
		expand.tooltip_text = "Show or hide this attack's mechanics and follow-up settings."
		expand.add_theme_font_size_override("font_size", 12)
		expand.flat = true
		expand.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		expand.alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.add_child(expand)
		block.add_child(details)
		var build := func():  # its values, frames and follow-up: built when first opened (most enemies stay closed)
			var margin := MarginContainer.new()  # the attack's values: only those that apply, a short tag before each box
			margin.add_theme_constant_override("margin_left", widths[0])
			details.add_child(margin)
			var inner := VBoxContainer.new()
			inner.add_theme_constant_override("separation", 3)
			margin.add_child(inner)
			_build_grouped_values(inner, attack, score)
			if writable and not "follow_up" in _applicable(attack):  # no follow-up yet: one click adds one (in Edit)
				var add_then := Game.button("+ Then…", func():
					attack.merge({"follow_up_count": "1", "follow_up_gap_s": "0.50"}, true)
					dirty = true
					dirty_changed.emit()
					_select_enemy(enemy_index)
					_update_feedback())
				add_then.add_theme_font_size_override("font_size", 12)
				add_then.custom_minimum_size.y = ROW_H
				add_then.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				inner.add_child(add_then)
		if details.visible: build.call()
		expand.pressed.connect(func():
			if details.get_child_count() == 0: build.call()
			details.visible = not details.visible
			expanded_attacks[detail_key] = details.visible
			expand.text = "Close" if details.visible else "Edit")
	if writable:  # any attack from the catalogue, or a brand-new one
		var free: Array = catalog.attacks.map(func(a): return str(a.name)).filter(func(a): return a not in Catalog.RUNTIME_ONLY and not rows.any(func(r): return r.attack_name == a and (e[0] != "boss_ape" or r._bindings.size() == 2)))
		free.sort_custom(func(a, b): return int(catalog.performs(e[0], a)) > int(catalog.performs(e[0], b)) or (catalog.performs(e[0], a) == catalog.performs(e[0], b) and a < b))
		var add_row := HBoxContainer.new()
		var pick := OptionButton.new()
		pick.fit_to_longest_item = false  # long attack names must not widen the page
		pick.clip_text = true
		pick.custom_minimum_size = Vector2(320, ROW_H)
		pick.add_theme_font_size_override("font_size", 12)
		for a in free:
			pick.add_item("%s · %s%s" % [a, catalog.attack(a).get("codex_online_name", ""), "" if catalog.performs(e[0], a) else "  (not in game yet)"])
			pick.set_item_metadata(pick.item_count - 1, a)
		pick.add_item("+ New attack…")
		pick.set_item_metadata(pick.item_count - 1, "")
		add_row.add_child(pick)
		var phase_pick: OptionButton = OptionButton.new() if e[0] == "boss_ape" else null  # unparented nodes leak
		if e[0] == "boss_ape":
			for phase_name in ["Both phases", "Phase 1", "Phase 2"]: phase_pick.add_item(phase_name)
			add_row.add_child(phase_pick)
		var add := Game.button("+ Add attack", func():
			var chosen: String = pick.get_item_metadata(pick.selected)
			var attack_id := chosen if chosen != "" else _new_attack()
			var phases: Array = (["normal", "enraged"] if phase_pick.selected == 0 else ["normal" if phase_pick.selected == 1 else "enraged"]) if e[0] == "boss_ape" else [e[1]]
			for phase in phases: _add_binding([e[0], phase, e[2]], attack_id))
		add.add_theme_font_size_override("font_size", 12)
		add.custom_minimum_size.y = ROW_H
		add_row.add_child(add)
		form.add_child(add_row)
	_enemy_total(e)
	_wrap_tips(form)

# Enemy stats and phase entry are a separate authored definition, shared by both phases.
func _family_health_fields(family: String) -> void:
	var edit := _small_edit(writable)
	edit.name = "FamilyHealth"
	edit.placeholder_text = "default"
	var profile: Dictionary = catalog.enemy_profile(family)
	edit.text = str(int(profile.max_hp)) if Catalog.EnemyHealth.valid(profile.get("max_hp")) else ""
	edit.tooltip_text = "Shared by this family. Variants apply their health modifiers afterwards. Clear to restore the original family or movement default. New enemies use saved changes."
	edit.custom_minimum_size.x = 64
	_stat(stats, "Base health", edit)
	edit.text_changed.connect(func(value):
		if not catalog.enemy_profiles.has(family): catalog.enemy_profiles[family] = {}
		var target: Dictionary = catalog.enemy_profiles[family]
		if value.strip_edges().is_empty(): target.erase("max_hp")
		else: target.max_hp = int(value) if value.is_valid_int() else null
		dirty = true
		dirty_changed.emit()
		_update_feedback())

func _ape_profile_fields() -> void:
	var profile: Dictionary = catalog.enemy_profile("boss_ape")
	if profile.is_empty(): return
	for field in ["max_hp", "phase2_hp", "phase2_wave_scales"]:
		var edit := _small_edit(writable)
		edit.name = field
		edit.text = ", ".join(profile[field].map(func(v): return str(v))) if field == "phase2_wave_scales" else str(int(profile[field]))
		edit.tooltip_text = "Once at phase-two entry; one in-place leap per scale (comma separated)." if field == "phase2_wave_scales" else "Shared by both Ape phases. New encounters use the saved values."
		edit.custom_minimum_size.x = 115 if field == "phase2_wave_scales" else 56
		_stat(stats, {"max_hp": "Health", "phase2_hp": "Phase 2 at HP", "phase2_wave_scales": "Hop wave scales"}[field], edit)
		edit.text_changed.connect(func(v):
			if field == "phase2_wave_scales":
				var values: Array = []
				for cell in v.split(","):
					values.append(float(cell.strip_edges()) if cell.strip_edges().is_valid_float() else null)
				profile[field] = values
			else:
				profile[field] = int(v) if v.is_valid_int() else null
			dirty = true
			dirty_changed.emit()
			_update_feedback())
	_stat(stats, "Cornered coverage", _cornered_coverage_picker("boss_ape"))

func _cornered_coverage_picker(enemy_id: String) -> OptionButton:
	var profile: Dictionary = catalog.enemy_profile(enemy_id)
	var choices: Array = [""]+Catalog.coverage_attacks(enemy_id)
	var pick := OptionButton.new()
	pick.add_item("Disabled")
	for id in choices.slice(1): pick.add_item(str(catalog.attack(id).get("codex_online_name",id)))
	pick.select(choices.find(profile.get("cornered_coverage_attack","ape_scream" if enemy_id=="boss_ape" else "")))
	pick.custom_minimum_size.y = ROW_H
	pick.add_theme_font_size_override("font_size",12)
	pick.disabled = not writable
	pick.tooltip_text = "Attack whose actual damage footprint must cover the ground corridor for Player cornered. Separate from the reaction chosen on each attack row. Only supported coverage adapters are listed. Ground charges use collision-clipped swept body coverage; flying and projectile trajectories are unsupported."
	pick.item_selected.connect(func(index):
		if not catalog.enemy_profiles.has(enemy_id): catalog.enemy_profiles[enemy_id] = profile
		catalog.enemy_profiles[enemy_id].cornered_coverage_attack = choices[index]
		dirty = true
		dirty_changed.emit()
		_update_feedback())
	return pick

# Cards use their natural width and wrap together as the details pane narrows.
func _build_grouped_values(parent: Control, attack: Dictionary, score: Label) -> void:
	var groups := HFlowContainer.new()
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	groups.add_theme_constant_override("h_separation", 8)
	groups.add_theme_constant_override("v_separation", 6)
	parent.add_child(groups)
	var applicable := _applicable(attack)
	var definitions := [
		["Timing", ["windup_s", "animation_s", "recovery_s"]],
		["Damage & speed", ["coverage_area_units2", "initial_speed_units_s", "max_distance_units", "shockwave_s"]],
		["Projectile pattern", ["multishot", "aimed_shot", "spread_deg"]],
		["Trajectory", ["flight_time_s", "horizontal_speed_units_s", "vertical_speed_units_s", "gravity_units_s2"]]
	]
	for definition in definitions:
		var columns: Array = definition[1].filter(func(column): return column in applicable)
		if columns.is_empty(): continue
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		panel.add_theme_stylebox_override("panel", _surface("151a24", "151a24", 8))
		groups.add_child(panel)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 3)
		panel.add_child(content)
		var heading := Game.label(definition[0], 12)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		heading.modulate = Color("91b2d3")
		content.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 4)
		content.add_child(grid)
		for column in columns:
			var tag := _value_tag(column)
			tag.custom_minimum_size.x = 0
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			grid.add_child(tag)
			var edit := _compact_field(grid, attack, column, score)
			edit.custom_minimum_size.x = 52
			edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

# A value as shown in a box: the CSV's rounding, without trailing zeros (40, 0.5; the CSV keeps 40.00).
func _shown(column: String, cell: String) -> String:
	var v: String = catalog.format_cell(column, cell)
	return v.rstrip("0").trim_suffix(".") if v.contains(".") and v.is_valid_float() else v

# Up / down arrows and a cross drawn as 7x7 pixel icons: the UI font lacks ▲ ▼ ✕, and the system-font fallback cost
# ~2 ms per button (most of the Ape page's build time).
static var _glyphs := {}
static func _glyph(kind: String) -> Texture2D:
	if not _glyphs.has(kind):
		var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
		for y in 7:
			for x in 7:
				var on: bool
				match kind:
					"up": on = y >= 1 and y <= 4 and absi(x - 3) <= y - 1
					"down": on = y >= 2 and y <= 5 and absi(x - 3) <= 5 - y
					_: on = x == y or x == 6 - y
				if on: img.set_pixel(x, y, Color.WHITE)
		img.resize(14, 14, Image.INTERPOLATE_NEAREST)  # 2x, crisp
		_glyphs[kind] = ImageTexture.create_from_image(img)
	return _glyphs[kind]

# The enemy's total score line under its attacks (refreshed on every value edit).
func _enemy_total(e: Array) -> void:
	var score_details := _score_text(e)
	summary.text = " · ".join(Array(score_details.split("\n")).map(func(line): return line.get_slice(" (", 0).get_slice(";", 0))) + (" · incomplete" if score_details.contains("unavailable") else "")
	summary.tooltip_text = squarish(score_details)

func _refresh_effect_help() -> void:
	var enemy: Array = ENEMIES[enemy_index]
	for hint in effect_hints:
		if not is_instance_valid(hint.control): continue
		var text: String = _effect_help(enemy, hint.effect)
		if hint.effect != "":
			var attack: Dictionary = catalog.attack(hint.effect)
			text += "\n\n" + squarish("%s (%s, %s)\n%s" % [hint.effect, attack.get("type", ""), attack.get("status", ""), attack.get("notes", "")])
		hint.control.tooltip_text = text

# Short tags for the compact view, in display order; the fields an attack's type always needs.
const TAGS := {"windup_s": "Wind-up", "animation_s": "Execution", "recovery_s": "Recovery", "flight_time_s": "Flight time", "coverage_area_units2": "Area",
	"initial_speed_units_s": "Speed", "multishot": "Multishot", "aimed_shot": "Aimed shot", "spread_deg": "Spread °", "horizontal_speed_units_s": "Horizontal",
	"vertical_speed_units_s": "Vertical", "gravity_units_s2": "Gravity", "max_distance_units": "Max distance", "shockwave_s": "Shockwave", "base_weight": "Weight", "follow_up": "Then", "follow_up_count": "Times", "follow_up_gap_s": "Every (s)"}


# The boxes each attack type shows (the same for every attack of that type).
const TYPE_FIELDS := {
	"body movement": ["windup_s", "animation_s", "recovery_s", "coverage_area_units2", "initial_speed_units_s"],
	"melee": ["windup_s", "animation_s", "recovery_s", "coverage_area_units2"],
	"area": ["windup_s", "animation_s", "recovery_s", "coverage_area_units2"],
	"ranged": ["windup_s", "recovery_s", "coverage_area_units2", "initial_speed_units_s", "multishot", "aimed_shot", "spread_deg",
		"flight_time_s", "horizontal_speed_units_s", "vertical_speed_units_s", "gravity_units_s2"],
	"movement": ["windup_s", "recovery_s", "coverage_area_units2", "initial_speed_units_s", "flight_time_s", "horizontal_speed_units_s",
		"vertical_speed_units_s", "gravity_units_s2", "max_distance_units", "shockwave_s"]}

func _applicable(attack: Dictionary) -> Array:  # its type's boxes (Enemies tab: plus its follow-up, once it has one)
	var mine: Array = TYPE_FIELDS.get(attack.get("type", ""), [])
	return TAGS.keys().filter(func(c):
		if c in ["follow_up", "follow_up_count", "follow_up_gap_s"]:
			return str(attack.get("follow_up", "")) != "" or str(attack.get("follow_up_count", "")) != ""
		return c in mine)

const TAG_W := 96  # value labels and boxes in the Enemies tab: one size, so they line up across attacks
const BOX_W := 72

func _value_tag(column: String) -> Label:
	var tag := Game.label(TAGS.get(column, column), 12)
	tag.modulate = Color(1, 1, 1, 0.6)
	tag.tooltip_text = _help(column)
	tag.mouse_filter = Control.MOUSE_FILTER_PASS
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.custom_minimum_size.x = TAG_W
	return tag

const ROW_H := 27  # every box and button in the Enemy loadout cards: one height (the buttons' natural one)

func _small_edit(editable: bool) -> LineEdit:
	var edit := LineEdit.new()
	edit.add_theme_font_size_override("font_size", 12)
	edit.custom_minimum_size = Vector2(48, ROW_H)
	edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	edit.editable = editable
	return edit

# One small edit box for an attack value (shared by every enemy with that attack); greying as in the Attacks tab.
func _compact_field(parent: Control, attack: Dictionary, column: String, score: Label) -> LineEdit:
	var edit := _small_edit(writable)
	edit.text = _shown(column, str(attack.get(column, "")))
	if column == "follow_up":
		edit.custom_minimum_size.x = 110  # an attack name
	edit.tooltip_text = _help(column) + " · shared by every enemy with this attack"
	if column == "animation_s" and attack.get("type", "") in ["ranged", "movement"]:
		edit.editable = false
	if column == "coverage_area_units2" and catalog.uses_body(attack):  # empty = the enemy's own body
		edit.placeholder_text = "body"
	if catalog.error_at.table == "attacks" and catalog.attacks.find(attack) == catalog.error_at.index and catalog.error_at.field == column:
		edit.add_theme_color_override("font_color", Color("ff7070"))
	edit.text_changed.connect(func(v):
		attack[column] = v
		dirty = true
		dirty_changed.emit()
		_show_score(score, attack)
		if view == "enemies":
			_enemy_total(ENEMIES[enemy_index])
			if column == "codex_online_name": _refresh_effect_help()
		_update_feedback())
	parent.add_child(edit)
	return edit

# A small window to read / edit an attack's notes (shared by every enemy with the attack).
func _edit_notes(attack: Dictionary, title: Control) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Notes · " + str(attack.get("codex_online_name", attack.get("name", "")))
	var text := TextEdit.new()
	text.text = str(attack.get("notes", ""))
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.custom_minimum_size = Vector2(520, 140)
	text.editable = writable
	dlg.add_child(text)
	dlg.confirmed.connect(func():
		if writable and text.text != str(attack.get("notes", "")):
			attack.notes = text.text
			dirty = true
			dirty_changed.emit()
			_update_feedback()
			_select_enemy(enemy_index))
	dlg.visibility_changed.connect(func():
		if not dlg.visible: dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()

# Tooltips wrapped into a squarish block (a bit taller than wide) instead of one long line.
static func squarish(text: String) -> String:
	if text.length() <= 40 or text.contains("\n\n"): return text
	var width := maxi(28, int(sqrt(text.length() * 2.2)))
	var out := PackedStringArray()
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			if not line.is_empty() and line.length() + 1 + word.length() > width:
				out.append(line)
				line = word
			else:
				line = word if line.is_empty() else line + " " + word
		out.append(line)
	return "\n".join(out)

func _wrap_tips(node: Node) -> void:
	if node is Control and node.tooltip_text != "":
		node.tooltip_text = squarish(node.tooltip_text)
	for child in node.get_children():
		_wrap_tips(child)

func _show_score(label: Label, attack: Dictionary) -> void:
	var sc: Dictionary = catalog.score_attack(attack) if catalog.validate().is_empty() else {"valid": false}
	label.text = "%d" % sc.score if sc.valid else "-"

func _binding_change(row: Dictionary, column: String, value: String) -> void:
	if column == "max_range_units": row.min_range_units = "0"  # Range is a maximum-only editor control.
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

func _delete_attack(name: String) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Delete the attack %s from the catalogue and from every enemy?" % name
	confirm.confirmed.connect(func():
		catalog.attacks = catalog.attacks.filter(func(a): return a.name != name)
		catalog.assignments = catalog.assignments.filter(func(b): return b.attack_name != name)
		for a in catalog.attacks:
			if str(a.get("follow_up", "")) == name: a.follow_up = ""
		dirty = true
		dirty_changed.emit()
		_show_table(false)
		_update_feedback())
	confirm.visibility_changed.connect(func():
		if not confirm.visible: confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()

# "Then": which attack follows this one (none = no follow-up, clears its times and gap).
func _follow_up_picker(attack: Dictionary) -> OptionButton:
	var pick := OptionButton.new()
	pick.add_theme_font_size_override("font_size", 12)
	pick.add_item("none")
	var names: Array = catalog.attacks.map(func(a): return str(a.name)).filter(func(n): return n != attack.name)
	for n in names:
		pick.add_item(n if catalog.follow_up_runs(str(attack.name), n) else n + "  (not in game yet)")
	pick.select(names.find(str(attack.get("follow_up", ""))) + 1)
	pick.fit_to_longest_item = false
	pick.clip_text = true
	pick.disabled = not writable
	pick.tooltip_text = _help("follow_up")
	pick.item_selected.connect(func(i):
		if i == 0:
			attack.merge({"follow_up": "", "follow_up_count": "", "follow_up_gap_s": ""}, true)
		else:
			attack.follow_up = names[i - 1]
		dirty = true
		dirty_changed.emit()
		_select_enemy(enemy_index)
		_update_feedback())
	return pick

# A new attack row (status planned: no gameplay yet), named new_attack_N; returns its name.
func _new_attack() -> String:
	var n := 1
	while not catalog.attack("new_attack_%d" % n).is_empty():
		n += 1
	var row := {}
	for column in catalog.attack_columns:
		row[column] = ""
	row.merge({"name": "new_attack_%d" % n, "codex_online_name": "New attack %d" % n, "type": "melee", "status": "planned", "windup_s": "0.50",
		"animation_s": "0.30", "recovery_s": "0.50", "coverage_area_units2": "1.00", "base_weight": "1.00", "multishot": "1", "aimed_shot": "0",
		"spread_deg": "0.00", "notes": "Added in the Monster Editor: pick a Behavior so enemies can use it."}, true)
	catalog.attacks.append(row)
	return row.name

func _add_binding(e: Array, attack_name: String) -> void:  # added last (lowest priority)
	if catalog.ordered_attacks(e[0], e[1]).any(func(row): return row.attack_name == attack_name): return
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

func _code_enemy_info(e: Array, ent) -> void:
	var lines := PackedStringArray()
	var label: String = e[2]
	lines.append(label.get_slice(" · ", 0) + ("  ·  " + label.get_slice(" · ", 1) if label.contains(" · ") else ""))
	if ent != null and "hp" in ent:
		lines.append("Hit points: %d" % ent.hp)
	if ent != null and "variant" in ent and str(ent.variant) != "":
		lines.append("Variant: " + str(ent.variant))
	if world_cache.is_empty(): world_cache = Game.Adventure.load_world(Game.world_path)  # once per editor session
	var world: Dictionary = world_cache
	var rooms := PackedStringArray()
	var count := 0
	for room in world.get("rooms", {}):
		var n: int = world.rooms[room].level.entities.filter(func(d): return d.t == e[0]).size()
		if n > 0:
			count += n
			rooms.append(room)
	lines.append("In the story: %d%s" % [count, " (" + ", ".join(rooms) + ")" if count > 0 else ""])
	lines.append("")
	var fam: String = "enemy_" + str(e[0]).get_slice("_", 1)
	var csv_family: Array = CSV_ENEMIES.filter(func(c): return c[0] == fam)
	if not csv_family.is_empty() and fam != e[0]:
		lines.append("A variant: it uses the attacks of %s (editable there), with its own speed, warning and recovery." % csv_family[0][2])
	elif e[0] in ["enemy_thornmite", "enemy_fuzzbob", "enemy_mosstrot"] or fam in ["enemy_thornmite", "enemy_fuzzbob", "enemy_mosstrot"]:
		lines.append("No attack of its own: it hurts on touch while it moves.")
	else:
		lines.append("Its attacks are written in the game code (scripts/entities.gd), not in the attack CSV, so they can't be edited here.")
	var info := Game.label("\n".join(lines), 14)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	form.add_child(info)
	summary.text = ""

# Scores for the selected enemy: a family's body and attacks, or the Ape phase's repertoire.
func _score_text(e: Array) -> String:
	if not catalog.validate().is_empty(): return "Scores: fix the invalid value first."
	var lines := PackedStringArray()
	if e[0] != "boss_ape":  # an enemy family: its body once, then its attacks
		var enemy = load("res://scripts/entities.gd").make(null, {"t": e[0], "x": 0, "y": 0})
		var area := float(enemy.rect.size.x * enemy.rect.size.y) / 64.0
		var result: Dictionary = catalog.enemy_score(catalog.ordered_attacks(e[0], e[1]).map(func(b): return b.attack_name), area)
		lines.append("Score %s (body %.2f once, then each attack; its variants change speed, warning and recovery)" % ["%d" % result.score if result.valid else "unavailable: " + result.reason, area])
	else:
		for phase in ["normal", "enraged"]:
			var ids: Array = catalog.ordered_attacks(e[0], phase).filter(func(b): return not catalog.triggered(b)).map(func(b): return b.attack_name)
			var result: Dictionary = catalog.enemy_score(ids, 9.0)
			lines.append("Selected attacks · Phase %s: %d (body 9 once; triggered consequence totals pending)%s" % ["1" if phase == "normal" else "2", result.score, "" if result.valid else "; unavailable: " + result.reason])
	return "\n".join(lines)

func _help(field: String) -> String:
	match field:
		"type": return "What kind of attack it is: it decides which values it has and how it's scored (body movement, melee, ranged, area, movement). What the game does is set by Behavior."
		"behavior": return "What the attack does in game: charge, leap, straight shot, lobbed shot, ceiling dive. An enemy can use any attack whose behavior it supports, with that attack's own numbers. None: data only, no enemy performs it."
		"name": return "The attack's ID. The game code refers to some attacks by ID: those can't be renamed. Renaming another one updates every enemy and follow-up that uses it."
		"codex_online_name": return "The attack's name, as shown in the Enemies tab."
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
		"priority": return "Higher values are checked first, whatever their ranges."
		"skip_chance": return "Percent chance this attack passes its turn when it could be used; the next one in the list is tried."
		"max_range_units": return "Maximum center-to-center distance in tiles (exclusive). 0 = any range; an empty field also means 0."
		"follow_up": return "Another attack done right after this one (e.g. ape_throw). Empty = none."
		"follow_up_count": return "How many times the follow-up comes."
		"follow_up_gap_s": return "Seconds between one follow-up and the next."
		"base_weight": return "Score multiplier for this kind of attack (1 = as the formula says, 2 = counts double). Only affects the score."
		"min_range_units": return "Center-to-center radial distance in tiles. Minimum inclusive; maximum exclusive."
		"notes": return str(_rows()[selected].get("notes", ""))
	return field.replace("_", " ") + ". Blank means unspecified, not zero. See docs/ATTACK_SCORING_PLAN.md."
