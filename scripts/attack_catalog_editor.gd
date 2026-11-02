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
var view := "attacks"  # "attacks" (attack definitions) or "enemies" (each enemy's attacks, ranges and scores)
var enemy_index := 0
var form_scroll: ScrollContainer
var world_cache := {}
# The enemies whose attacks come from the CSV: [enemy id, phase, name in the list]
const CSV_ENEMIES := [["boss_ape", "normal", "Ape"], ["boss_ape", "enraged", "Ape · enraged"],
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
	loaded_texts = [FileAccess.get_file_as_string(catalog.attack_path), FileAccess.get_file_as_string(catalog.assignment_path)]
	writable = OS.has_feature("editor") and not OS.has_feature("web")
	ENEMIES = _all_enemies()
	theme = _soft_theme(theme)
	add_theme_constant_override("separation", 12)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	add_child(heading)
	var title := Game.label("Monster Editor", 25)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	reload_button = Game.button("Reload", _reload_requested)
	reload_button.tooltip_text = "Reload the CSV files from disk."
	heading.add_child(reload_button)
	save_button = Game.button("Save changes", _save)
	save_button.disabled = not writable
	save_button.tooltip_text = "Validate and save both CSVs. New attack selections use the saved changes."
	save_button.add_theme_stylebox_override("normal", _surface("294862", "476b88", 10))
	heading.add_child(save_button)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	add_child(tabs)
	attack_tab = Game.button("Attack library", func(): _show_table(false))
	enemy_tab = Game.button("Enemy loadouts", _show_enemies)
	for tab in [attack_tab, enemy_tab]:
		tab.toggle_mode = true
		tab.add_theme_stylebox_override("pressed", _surface("26364b", "44638b", 10))
		tabs.add_child(tab)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	var location := Game.label("Tiles · seconds" if writable else "Read only · tiles · seconds", 12)
	location.tooltip_text = "Source: data/attacks.csv and data/enemy_attacks.csv. One tile = 8 pixels."
	tabs.add_child(location)
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
	table.item_selected.connect(func(i): _select_enemy(list_indices[i]) if view == "enemies" else _select_row(list_indices[i]))
	var scroll := ScrollContainer.new()
	form_scroll = scroll
	scroll.mouse_force_pass_scroll_events = false
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panes.add_child(scroll)
	form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 12)
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form)
	summary = Game.label("", 12)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	feedback = Game.label("", 12)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(feedback)
	_show_table(false)

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

func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _surface("1c2330", "303c4c"))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
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
			table.add_item("— Read only —", null, false)  # divider
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
	t.set_stylebox("normal", "Button", _surface("242e3e", "35445a", 8))
	t.set_stylebox("hover", "Button", _surface("304159", "5b779b", 8))
	t.set_stylebox("pressed", "Button", _surface("304a65", "6d92ba", 8))
	t.set_stylebox("disabled", "Button", _surface("1b2230", "2c3543", 8))
	t.set_stylebox("panel", "ItemList", _surface("171e2a", "2c3747", 8))
	t.set_stylebox("selected", "ItemList", _surface("2b425c", "476b8c", 6))
	t.set_stylebox("selected_focus", "ItemList", _surface("2b425c", "638bb3", 6))

	t.set_color("font_color", "Label", Color("b9bdca"))
	t.set_color("font_color", "Button", text)
	t.set_color("font_color", "ItemList", Color("b9bdca"))
	t.set_color("font_selected_color", "ItemList", Color("eef0f5"))
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_uneditable_color", "LineEdit", Color("7c8193"))
	t.set_color("font_placeholder_color", "LineEdit", Color("6c7183"))
	t.set_color("font_color", "TextEdit", text)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1f2230")
	box.border_color = Color("343849")
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
		["Definition", ["codex_online_name", "type"], false],
		["Timing", ["windup_s", "animation_s", "recovery_s"], false],
		["Attack shape", ["coverage_area_units2", "initial_speed_units_s", "multishot", "aimed_shot", "spread_deg", "max_distance_units", "shockwave_s"], false],
		["Trajectory", ["flight_time_s", "horizontal_speed_units_s", "vertical_speed_units_s", "gravity_units_s2"], true],
		["Advanced", ["name", "base_weight"], true]
	]
	if ranges: groups = [["Assignment", ["enemy_id", "phase", "attack_name"], false], ["Distance", ["min_range_units", "max_range_units", "priority"], false]]
	var keep: Array = _applicable(row) + ["codex_online_name", "name", "type", "base_weight"] if not ranges else []
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
	var labels := {"codex_online_name": "Name", "name": "ID", "windup_s": "Wind-up", "animation_s": "Execution", "recovery_s": "Recovery", "flight_time_s": "Flight time", "coverage_area_units2": "Area (u²)", "initial_speed_units_s": "Initial speed", "horizontal_speed_units_s": "Horizontal speed", "vertical_speed_units_s": "Vertical speed", "gravity_units_s2": "Gravity", "multishot": "Multishot", "aimed_shot": "Aimed shot #", "spread_deg": "Spread (°)", "max_distance_units": "Max distance", "shockwave_s": "Shockwave time", "min_range_units": "Minimum", "max_range_units": "Maximum", "base_weight": "Weight", "follow_up": "Then", "follow_up_count": "Times", "follow_up_gap_s": "Every (s)"}
	var label := Game.label(labels.get(column, column.replace("_", " ").capitalize()), 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.tooltip_text = _help(column)
	cell.add_child(label)
	if column == "type" and not ranges:  # a choice, not free text
		var pick := OptionButton.new()
		for t in catalog.TYPES:
			pick.add_item(t)
		pick.select(catalog.TYPES.find(str(_rows()[index].get("type", ""))))
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.custom_minimum_size.y = ROW_H
		pick.add_theme_constant_override("arrow_margin", 6)
		var flat := (pick.get_theme_stylebox("normal") as StyleBox).duplicate()  # its padding made it 5 px taller than the boxes
		flat.content_margin_top = 2
		flat.content_margin_bottom = 2
		for state in ["normal", "hover", "pressed", "focus", "disabled"]: pick.add_theme_stylebox_override(state, flat)
		pick.disabled = not writable
		pick.tooltip_text = _help("type")
		pick.item_selected.connect(func(i):
			_change("type", catalog.TYPES[i])
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
			score_value.text = "Score  %.2f" % result.score if result.valid else "Score  —"
			score_value.tooltip_text = "Raw %.2f / warning factor %.2f" % [result.raw, result.penalty] if result.valid else result.reason

func _update_feedback() -> void:
	if feedback == null: return
	var invalid: String = catalog.validate_for_save()
	feedback.text = invalid if not invalid.is_empty() else ("Unsaved draft" if dirty else "CSV loaded")
	feedback.tooltip_text = catalog.range_warnings()
	if invalid.is_empty() and not feedback.tooltip_text.is_empty(): feedback.text += " · Overlapping ranges (hover for details)"
	save_button.disabled = not writable or not dirty or not invalid.is_empty()

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
	if not catalog.reload():
		feedback.text = "Saved, but reloading failed: " + catalog.error
		return
	if view == "enemies": _select_enemy(enemy_index)
	else: _select_row(clampi(selected, 0, _rows().size() - 1))
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
	if view == "enemies": _show_enemies()
	else: _show_table(ranges)
	return true

# ---- Enemies tab: pick an enemy; its sprite, its attacks in priority order (move up / down, skip chance), scores ----
func _show_enemies() -> void:
	view = "enemies"
	ranges = true
	_tabs()
	_filter_list()
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
		var k := minf(3.0, (size.y - 12.0) / maxf(ent.rect.size.x, ent.rect.size.y))
		canvas.ent = ent
		canvas.scale = Vector2(k, k)
		canvas.position = size / 2.0 - Vector2(ent.rect.get_center()) * k
		canvas.queue_redraw()
	class Sprite extends Node2D:
		var ent = null
		func _draw() -> void:
			if ent != null: ent.draw(self)

func _select_enemy(i: int) -> void:
	if i != enemy_index and is_instance_valid(form_scroll): form_scroll.scroll_vertical = 0  # a new enemy starts at its top
	enemy_index = i
	selected = i
	var visible_index := list_indices.find(i)
	if visible_index >= 0: table.select(visible_index)
	fields.clear()
	for node in form.get_children():
		form.remove_child(node)
		node.queue_free()
	score_value = null
	var enemy_title := Game.label(str(ENEMIES[i][2]), 24)
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	form.add_child(enemy_title)
	var e: Array = ENEMIES[i]
	var preview := SpritePreview.new()
	preview.custom_minimum_size = Vector2(0, 70)
	preview.clip_contents = true
	var data: Dictionary = {"t": e[0]}
	if e[0] == "boss_guardian":
		data.merge({"w": 96, "h": 64})
	data.x = 0
	data.y = 0
	preview.ent = load("res://scripts/entities.gd").make(null, data)
	form.add_child(preview)
	var own: Array = (_look_frames(e[0]) if e[0].begins_with("enemy_") else (_ape_frames(["idle", "run", "crouch", "air"]) if e[0] in ["boss_ape", "ape_chase"] else []))
	if not own.is_empty():
		var own_row := HBoxContainer.new()
		own_row.alignment = BoxContainer.ALIGNMENT_CENTER
		own_row.visible = false
		var gallery := Game.button("+ Animation reference", func(): pass)
		gallery.pressed.connect(func():
			if own_row.get_child_count() == 0: own_row.add_child(_frame_strip(own, 2.0))  # built when first opened
			own_row.visible = not own_row.visible
			gallery.text = ("− " if own_row.visible else "+ ") + "Animation reference")
		gallery.flat = true
		gallery.add_theme_font_size_override("font_size", 14)
		gallery.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		gallery.alignment = HORIZONTAL_ALIGNMENT_LEFT
		form.add_child(gallery)
		form.add_child(own_row)
	if e[1] == "":  # attacks in the game code: what it is and does, read-only
		_code_enemy_info(e, preview.ent)
		return
	# one block per attack: its binding line (rank, name, ranges, skip, order, score), its mechanics, its notes
	var widths := [22, 190, 62, 62, 62, 30, 30, 30, 56]
	var caption := Game.label("ATTACK ORDER", 12)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caption.modulate = Color("91b2d3")
	caption.tooltip_text = "The first eligible attack executes. Use the arrows to change priority."
	form.add_child(caption)
	var rows: Array = catalog.ordered_attacks(e[0], e[1])
	for k in rows.size():
		var row: Dictionary = rows[k]
		var attack: Dictionary = catalog.attack(row.attack_name)
		var block := _card(form)
		var line := HBoxContainer.new()
		block.add_child(line)
		var rank := Game.label(str(k + 1), 13)
		rank.custom_minimum_size.x = widths[0]
		line.add_child(rank)
		var score := Game.label("", 13)
		var title := _compact_field(line, attack, "codex_online_name", score)  # the research name, editable here
		var tagged: bool = attack.get("status", "") != "implemented" or not catalog.performs(e[0], row.attack_name)
		title.custom_minimum_size.x = 150
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.tooltip_text = "%s (%s, %s)\n%s" % [row.attack_name, attack.get("type", ""), attack.get("status", ""), attack.get("notes", "")]
		var info := Game.button("i", func(): _edit_notes(attack, title))  # notes: in the tooltip; click to edit
		info.add_theme_font_size_override("font_size", 12)
		info.custom_minimum_size.x = 22
		info.tooltip_text = str(attack.get("notes", "")) if str(attack.get("notes", "")) != "" else "No notes yet: click to add"
		info.disabled = not writable and str(attack.get("notes", "")) == ""
		line.add_child(info)
		if attack.get("status", "") != "implemented" or not catalog.performs(e[0], row.attack_name):
			var tag := Game.label("not in game yet" if not catalog.performs(e[0], row.attack_name) else str(attack.get("status", "")), 11)
			tag.custom_minimum_size.x = 46
			tag.modulate = Color(1, 1, 1, 0.5)
			line.add_child(tag)
		var binding_line := HBoxContainer.new()
		binding_line.add_theme_constant_override("separation", 8)
		block.add_child(binding_line)
		for column in ["min_range_units", "max_range_units", "skip_chance"]:
			var edit := _small_edit(writable)
			edit.text = _shown(column, str(row.get(column, "0")))
			if column == "max_range_units" and float(str(row.get(column, "0"))) == 0:
				edit.text = ""  # 0 = no maximum
			if column == "max_range_units":
				edit.placeholder_text = "no max"
			edit.custom_minimum_size.x = widths[2]
			edit.tooltip_text = _help(column)
			if catalog.error_at.table == "ranges" and catalog.assignments.find(row) == catalog.error_at.index and catalog.error_at.field == column:
				edit.add_theme_color_override("font_color", Color("ff7070"))
			edit.text_changed.connect(func(v): _binding_change(row, column, v))
			var label := Game.label({"min_range_units": "Min", "max_range_units": "Max", "skip_chance": "Skip %"}[column], 12)
			binding_line.add_child(label)
			binding_line.add_child(edit)
		for b in [["up", -1, k == 0], ["down", 1, k == rows.size() - 1], ["cross", 0, false]]:
			var btn := Game.button("", (func(): _move(row, b[1])) if b[1] != 0 else (func(): _remove_binding(row)))
			btn.icon = _glyph(b[0])
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.add_theme_font_size_override("font_size", 12)
			btn.custom_minimum_size = Vector2(widths[5], 0)
			btn.disabled = not writable or b[2]
			btn.tooltip_text = {-1: "Raise priority", 1: "Lower priority", 0: "Remove this attack from the enemy"}[b[1]]
			line.add_child(btn)
		score.custom_minimum_size.x = widths[8]
		line.add_child(score)
		_show_score(score, attack)
		if "follow_up" in _applicable(attack):  # its follow-up stays visible without opening Edit
			var follow := HBoxContainer.new()
			follow.add_theme_constant_override("separation", 8)
			block.add_child(follow)
			for column in ["follow_up", "follow_up_count", "follow_up_gap_s"]:  # same look as Min / Max / Skip above
				var tag := Game.label(TAGS.get(column, column), 12)
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
		expand.tooltip_text = "Show or hide this attack's mechanics, animation frames, and follow-up settings."
		expand.add_theme_font_size_override("font_size", 12)
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
			var shown: Array = _attack_frames(e, attack)
			if not shown[0].is_empty():
				var anim := HBoxContainer.new()
				anim.add_child(_frame_strip(shown[0], 1.5))
				if shown[1] != "":
					var cap := Game.label(shown[1], 11)
					cap.modulate = Color(1, 1, 1, 0.5)
					anim.add_child(cap)
				inner.add_child(anim)
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
		var free: Array = catalog.attacks.map(func(a): return str(a.name)).filter(func(a): return not rows.any(func(r): return r.attack_name == a))
		free.sort_custom(func(a, b): return int(catalog.performs(e[0], a)) > int(catalog.performs(e[0], b)) or (catalog.performs(e[0], a) == catalog.performs(e[0], b) and a < b))
		var add_row := HBoxContainer.new()
		var pick := OptionButton.new()
		pick.fit_to_longest_item = false  # long attack names must not widen the page
		pick.clip_text = true
		pick.custom_minimum_size = Vector2(260, ROW_H)
		pick.add_theme_font_size_override("font_size", 12)
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for a in free:
			pick.add_item("%s · %s%s" % [a, catalog.attack(a).get("codex_online_name", ""), "" if catalog.performs(e[0], a) else "  (not in game yet)"])
			pick.set_item_metadata(pick.item_count - 1, a)
		pick.add_item("+ New attack…")
		pick.set_item_metadata(pick.item_count - 1, "")
		add_row.add_child(pick)
		var add := Game.button("+ Add attack", func():
			var chosen: String = pick.get_item_metadata(pick.selected)
			_add_binding(e, chosen if chosen != "" else _new_attack()))
		add.add_theme_font_size_override("font_size", 12)
		add.custom_minimum_size.y = ROW_H
		add_row.add_child(add)
		form.add_child(add_row)
	_enemy_total(e)
	_wrap_tips(form)

# Use the card's width: two groups side by side, with aligned, stretching numeric fields.
func _build_grouped_values(parent: Control, attack: Dictionary, score: Label) -> void:
	var groups := GridContainer.new()
	groups.columns = 2
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	groups.add_theme_constant_override("h_separation", 12)
	groups.add_theme_constant_override("v_separation", 10)
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
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _surface("18202b", "2c3b4e", 10))
		groups.add_child(panel)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 8)
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
			edit.custom_minimum_size.x = 64
			edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if columns.size() % 2 == 1:
			grid.add_child(Control.new())
			var filler := Control.new()
			filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(filler)

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
	summary.text = score_details.get_slice(" (", 0).get_slice(";", 0) + (" · incomplete" if score_details.contains("unavailable") else "")
	summary.tooltip_text = squarish(score_details)

# Short tags for the compact view, in display order; the fields an attack's type always needs.
const TAGS := {"windup_s": "Wind-up", "animation_s": "Execution", "recovery_s": "Recovery", "flight_time_s": "Flight time", "coverage_area_units2": "Area",
	"initial_speed_units_s": "Speed", "multishot": "Multishot", "aimed_shot": "Aimed shot", "spread_deg": "Spread °", "horizontal_speed_units_s": "Horizontal speed",
	"vertical_speed_units_s": "Vertical speed", "gravity_units_s2": "Gravity", "max_distance_units": "Max distance", "shockwave_s": "Shockwave", "base_weight": "Weight", "follow_up": "Then", "follow_up_count": "Times", "follow_up_gap_s": "Every (s)"}


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

const ROW_H := 33  # every box and button in the Enemy loadout cards: one height (the buttons' natural one)

func _small_edit(editable: bool) -> LineEdit:
	var edit := LineEdit.new()
	edit.add_theme_font_size_override("font_size", 12)
	edit.custom_minimum_size = Vector2(56, ROW_H)
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
		if view == "enemies": _enemy_total(ENEMIES[enemy_index])
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

# ---- sprite frames: the enemy's own, and each attack's animation ----
const APE_POSES := {"ape_throw": ["crouch", "throw"], "ape_leap": ["crouch", "launch", "rise", "apex", "fall", "land"],
	"ape_retreat": ["crouch", "launch", "rise", "apex", "fall", "land"],
	"ape_scream": ["crouch", "scream"]}

func _frame_strip(textures: Array, k: float) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	for t in textures:
		var pic := TextureRect.new()
		pic.texture = t
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(t.get_width(), t.get_height()) * k
		strip.add_child(pic)
	return strip

func _look_frames(kind: String) -> Array:  # an enemy family's 4 walk frames (EnemyArt atlas row)
	var art = load("res://scripts/enemy_art.gd")
	var row: int = art.KINDS.find(kind)
	if row < 0: return []
	var out: Array = []
	for f in 4:
		var at := AtlasTexture.new()
		at.atlas = art.texture()
		at.region = Rect2(f * art.SIZE, row * art.SIZE, art.SIZE, art.SIZE)
		out.append(at)
	return out

func _ape_frames(poses: Array) -> Array:
	var art = load("res://scripts/ape_art.gd")
	return poses.map(func(p): return art.texture(p, 0))

# What an attack looks like: the Ape's poses / shockwave, a projectile, or (library monsters, which have only walk
# frames) the walk frames. Returns [textures, caption].
func _attack_frames(e: Array, attack: Dictionary) -> Array:
	var id: String = attack.get("name", "")
	if APE_POSES.has(id): return [_ape_frames(APE_POSES[id]), ""]
	if id == "ape_slam":
		var art = load("res://scripts/ape_art.gd")
		return [[0, 1, 2, 3].map(func(f): return art.impact_texture(24, 8, f)), "shockwave"]
	if attack.get("type", "") == "ranged":
		var img := Image.create(5, 5, false, Image.FORMAT_RGBA8)  # (a placeholder dot: projectiles are drawn in code)
		img.fill_rect(Rect2i(1, 1, 3, 3), Color("8a7a6a"))
		return [[ImageTexture.create_from_image(img)], "projectile"]
	if e[0].begins_with("enemy_"):
		return [_look_frames(e[0]), "walk frames (no attack art yet)"]
	return [[], ""]

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
		"spread_deg": "0.00", "notes": "Added in the Monster Editor: needs its gameplay written before enemies can use it."}, true)
	catalog.attacks.append(row)
	return row.name

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
		lines.append("Score %s (body %.2f once, then each attack; its variants change speed, warning and recovery)" % ["%.2f" % result.score if result.valid else "unavailable: " + result.reason, area])
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
		"type": return "What kind of attack it is: it decides which values it has and how it's scored (body movement, melee, ranged, area, movement). What the game does is still up to the enemy's code."
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
		"max_range_units": return "Center-to-center radial distance in tiles, exclusive. Empty (0) = no maximum."
		"follow_up": return "Another attack done right after this one (e.g. ape_throw). Empty = none."
		"follow_up_count": return "How many times the follow-up comes."
		"follow_up_gap_s": return "Seconds between one follow-up and the next."
		"base_weight": return "Score multiplier for this kind of attack (1 = as the formula says, 2 = counts double). Only affects the score."
		"min_range_units": return "Center-to-center radial distance in tiles. Minimum inclusive; maximum exclusive."
		"notes": return str(_rows()[selected].get("notes", ""))
	return field.replace("_", " ") + ". Blank means unspecified, not zero. See docs/ATTACK_SCORING_PLAN.md."
