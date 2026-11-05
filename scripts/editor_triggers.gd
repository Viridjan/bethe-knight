extends PanelContainer
const Settings := preload("res://scripts/interaction/trigger_settings.gd")
var editor
var selected_index := -1
var link_edge := ""
var syncing := false
var title: Label
var identity: Label
var assign_button: Button
var help: Label
var trap_grid: GridContainer
var trap_fields := {}
var trap_enabled: CheckBox
var trap_direction: OptionButton
var preview_button: CheckBox
var source_box: VBoxContainer
var cooldown: SpinBox
var ability: OptionButton
var once: CheckBox
var cancel: CheckBox
var links_box: VBoxContainer
const ACTIONS := {"activate": "Activate trap", "deactivate": "Deactivate trap", "toggle": "Toggle trap", "start_motion": "Start movement", "stop_motion": "Stop movement", "toggle_motion": "Toggle movement"}

func setup(owner_editor) -> void:
	editor = owner_editor
	theme = Game.theme.duplicate()
	theme.default_font_size = 14
	mouse_force_pass_scroll_events = false
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -344
	offset_right = -12
	offset_top = 64
	offset_bottom = -48
	var scroll := ScrollContainer.new()
	scroll.mouse_force_pass_scroll_events = false
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	title = Game.label("Select a trap or trigger", 16)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	identity = Game.label("", 13)
	box.add_child(identity)
	assign_button = Game.button("Assign object ID", assign_id)
	assign_button.tooltip_text = "Assign a stable identifier without changing this object's position or existing door/story IDs."
	box.add_child(assign_button)
	trap_grid = GridContainer.new()
	trap_grid.columns = 2
	box.add_child(trap_grid)
	for row in [["interval", "Activation interval (seconds)"], ["active", "Stay active (seconds)"], ["extend", "Deployment timing (seconds)"], ["retract", "Retraction timing (seconds)"], ["offset", "Initial delay (seconds)"]]:
		trap_grid.add_child(Game.label(row[1], 13))
		var field := _number(3600 if row[0] in ["interval", "offset"] else 60)
		field.tooltip_text = "Start-to-start interval. Zero waits for a trigger." if row[0] == "interval" else str(row[1]) + ". Damage occurs only while fully active."
		trap_fields[row[0]] = field
		trap_grid.add_child(field)
		field.value_changed.connect(func(_value): change_trap())
	trap_grid.add_child(Game.label("Direction", 13))
	trap_direction = OptionButton.new()
	for text in ["Up", "Down", "Left", "Right"]: trap_direction.add_item(text)
	trap_direction.tooltip_text = "The direction in which the spikes deploy from their base."
	trap_direction.item_selected.connect(func(_index): change_trap())
	trap_grid.add_child(trap_direction)
	trap_enabled = _check(box, "Start enabled", "Start the automatic cycle on room entry. Activate links can enable and fire it.", change_trap)
	preview_button = _check(box, "Preview cycle", "Preview timing without damage or changes to saved data. For trigger-only traps, toggle on to fire once.", reset_preview)
	source_box = VBoxContainer.new()
	box.add_child(source_box)
	var grid := GridContainer.new()
	grid.columns = 2
	source_box.add_child(grid)
	grid.add_child(Game.label("Cooldown (seconds)", 13))
	cooldown = _number(3600)
	cooldown.tooltip_text = "Minimum time before a new entry activation. Exit/release commands are never suppressed."
	cooldown.value_changed.connect(func(_value): change_source())
	grid.add_child(cooldown)
	grid.add_child(Game.label("Required ability", 13))
	ability = OptionButton.new()
	ability.add_item("None")
	for name in Game.Adventure.ABILITIES: ability.add_item(str(name).capitalize())
	ability.tooltip_text = "Check this ability on entry. Release still executes if the ability later changes."
	ability.item_selected.connect(func(_index): change_source())
	grid.add_child(ability)
	once = _check(source_box, "Once per room visit", "Allow one entry activation; its matching exit/release still runs. Resets when the room is rebuilt.", change_source)
	cancel = _check(source_box, "Cancel pending entry on exit", "Cancel delayed entry actions if the player leaves before they execute. Enabled by default for pressure plates.", change_source)
	for edge in ["on_enter", "on_exit"]:
		var button := Game.button("Link on enter" if edge == "on_enter" else "Link on exit", func():
			link_edge = edge
			editor._status("Click a trap or object with authored movement to link"))
		button.tooltip_text = "Click a target on the canvas. The link receives a stable target ID, typed action and optional delay."
		source_box.add_child(button)
	links_box = VBoxContainer.new()
	source_box.add_child(links_box)
	help = Game.label("", 13)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help)
	visibility_changed.connect(func():
		if not visible:
			link_edge = ""
			preview_button.set_pressed_no_signal(false)
			reset_preview())
	clear_selection()
	visible = false

func _number(maximum: float) -> SpinBox:
	var field := SpinBox.new()
	field.min_value = 0
	field.max_value = maximum
	field.step = 0.05
	field.custom_minimum_size.x = 76
	return field

func _check(parent: Control, text: String, tip: String, callback: Callable) -> CheckBox:
	var control := CheckBox.new()
	control.text = text
	control.tooltip_text = tip
	control.toggled.connect(func(_on): callback.call())
	parent.add_child(control)
	return control

func data() -> Dictionary:
	return editor.level.entities[selected_index] if selected_index >= 0 and selected_index < editor.level.entities.size() else {}

func clear_selection() -> void:
	selected_index = -1
	link_edge = ""
	if is_instance_valid(title): sync()

func select_object(index: int) -> void:
	selected_index = index
	link_edge = ""
	visible = true
	preview_button.set_pressed_no_signal(false)
	sync()

func sync() -> void:
	syncing = true
	var d := data()
	var trap: bool = not d.is_empty() and d.t in Settings.TRAPS
	var source: bool = not d.is_empty() and d.t in Settings.SOURCES
	title.text = str(editor.E.TYPES[d.t][0]) if not d.is_empty() else "Select a trap or trigger"
	identity.text = "Object ID: " + str(d.get("object_id", "not assigned"))
	assign_button.visible = not d.is_empty() and not d.has("object_id")
	trap_grid.visible = trap
	trap_enabled.visible = trap
	preview_button.visible = trap
	source_box.visible = source
	if trap:
		var timing := Settings.cycle(d.get("trap", {}))
		for key in trap_fields: trap_fields[key].set_value_no_signal(timing[key])
		trap_enabled.set_pressed_no_signal(timing.enabled)
		trap_direction.select(["up", "down", "left", "right"].find(timing.direction))
	if source:
		var config: Dictionary = d.get("trigger", {})
		cooldown.set_value_no_signal(config.get("cooldown", 0))
		once.set_pressed_no_signal(config.get("once", false))
		cancel.set_pressed_no_signal(config.get("cancel_on_exit", d.t == "pressure_plate"))
		ability.select(Game.Adventure.ABILITIES.find(config.get("ability", "")) + 1)
		_rebuild_links()
	help.text = "Zero interval waits for a trigger. Interval must cover both animations plus active time." if trap else ("Link a trap or moving object. Enter and exit are edge events, not continuous activation." if source else "Select a trap/trigger to configure it, or a movable target to inspect its object ID.")
	syncing = false
	reset_preview()

func assign_id() -> void:
	if data().is_empty() or data().has("object_id"): return
	editor._push_undo()
	data().object_id = editor._new_object_id()
	sync()

func change_trap() -> void:
	if syncing or data().is_empty(): return
	var config := {}
	for field in trap_fields: config[field] = trap_fields[field].value
	config.enabled = trap_enabled.button_pressed
	config.direction = ["up", "down", "left", "right"][trap_direction.selected]
	var error := Settings.validate_cycle(config)
	if not error.is_empty():
		editor._status(error)
		sync()
		return
	editor._push_undo()
	data().trap = config
	editor._refresh_one(selected_index)
	sync()

func change_source() -> void:
	if syncing or data().is_empty(): return
	var config: Dictionary = data().get("trigger", {}).duplicate(true)
	config.merge({"once": once.button_pressed, "cancel_on_exit": cancel.button_pressed, "cooldown": cooldown.value, "ability": "" if ability.selected == 0 else Game.Adventure.ABILITIES[ability.selected - 1]}, true)
	editor._push_undo()
	data().trigger = config
	sync()

func link_target(index: int) -> void:
	if link_edge == "" or data().is_empty() or index < 0 or index >= editor.level.entities.size(): return
	var target: Dictionary = editor.level.entities[index]
	var actions := Settings.actions_for(target)
	if actions.is_empty():
		editor._status("Target a trap or configure Object movement on this target first")
		return
	var config: Dictionary = data().get("trigger", {}).duplicate(true)
	var links: Array = config.get(link_edge, []).duplicate(true)
	if links.size() >= Settings.MAX_LINKS:
		editor._status("A trigger supports at most 32 links per edge")
		return
	editor._push_undo()
	if not data().has("object_id"): data().object_id = editor._new_object_id()
	if not target.has("object_id"): target.object_id = editor._new_object_id()
	var action: String = actions[0]
	if link_edge == "on_exit": action = "deactivate" if target.t in Settings.TRAPS else "stop_motion"
	links.append({"target": target.object_id, "action": action, "delay": 0.0})
	config[link_edge] = links
	data().trigger = config
	link_edge = ""
	sync()
	editor._redraw()

func _edit_link(edge: String, index: int, field: String, value) -> void:
	if data().is_empty(): return
	editor._push_undo()
	if field == "remove": data().trigger[edge].remove_at(index)
	else: data().trigger[edge][index][field] = value
	_rebuild_links.call_deferred()
	editor._redraw()

func _rebuild_links() -> void:
	for node in links_box.get_children():
		links_box.remove_child(node)
		node.queue_free()
	var d := data()
	if d.is_empty(): return
	for edge in ["on_enter", "on_exit"]:
		var links: Array = d.get("trigger", {}).get(edge, [])
		for i in links.size():
			var link: Dictionary = links[i]
			var label := Game.label(("Enter: " if edge == "on_enter" else "Exit: ") + link.target, 13)
			links_box.add_child(label)
			var row := HBoxContainer.new()
			links_box.add_child(row)
			var targets: Array = editor.level.entities.filter(func(entity): return entity.get("object_id", "") == link.target)
			var choices: Array = Settings.actions_for(targets[0]) if not targets.is_empty() else [link.action]
			var pick := OptionButton.new()
			pick.tooltip_text = "Action sent to this target. Trigger zones cannot be targets, preventing recursive activation cycles."
			for action in choices: pick.add_item(ACTIONS.get(action, action))
			pick.select(choices.find(link.action))
			pick.item_selected.connect(func(which): _edit_link(edge, i, "action", choices[which]))
			row.add_child(pick)
			var remove := Game.button("Remove", func(): _edit_link(edge, i, "remove", null))
			remove.tooltip_text = "Remove this link; the target object is kept."
			row.add_child(remove)
			var delay := _number(60)
			delay.value = link.get("delay", 0)
			delay.prefix = "Delay "
			delay.suffix = " seconds"
			delay.tooltip_text = "Delay this command in simulation seconds. Pausing the game also pauses the delay."
			delay.value_changed.connect(func(value): _edit_link(edge, i, "delay", value))
			links_box.add_child(delay)

func canvas_click(point: Vector2) -> void:
	var index: int = editor._motion_entity_at(point)
	if link_edge != "": link_target(index)
	else: select_object(index)

func reset_preview() -> void:
	for i in editor.preview.size():
		var entity = editor.preview[i]
		if entity != null and entity.d.t in Settings.TRAPS:
			entity.preview_animated = i == selected_index and preview_button.button_pressed
			if entity.preview_animated:
				entity.cycle = load("res://scripts/interaction/trap_cycle.gd").new(data().get("trap", {}))
				if entity.cycle.config.interval == 0: entity.cycle.fire()
	editor._redraw()

func advance_preview(dt: float) -> void:
	if not visible or not preview_button.button_pressed or data().is_empty() or data().t not in Settings.TRAPS: return
	editor.preview[selected_index].cycle.advance(minf(dt, 0.05))
	editor._redraw()

func draw_guides(canvas: Node2D) -> void:
	if not visible or data().is_empty(): return
	var from := Vector2(editor.preview[selected_index].rect.get_center())
	var scale: float = editor.cam.zoom.x
	canvas.draw_rect(Rect2(editor.preview[selected_index].rect), Color("65dec6"), false, 2 / scale)
	for edge in ["on_enter", "on_exit"]:
		for link in data().get("trigger", {}).get(edge, []):
			for i in editor.level.entities.size():
				if editor.level.entities[i].get("object_id", "") != link.target: continue
				var at := Vector2(editor.preview[i].rect.get_center())
				var color := Color("65dec6") if edge == "on_enter" else Color("edc16c")
				canvas.draw_line(from, at, color, 1.5 / scale)
				var direction := (at - from).normalized()
				canvas.draw_line(at, at - direction.rotated(0.5) * 8 / scale, color, 1.5 / scale)
				canvas.draw_line(at, at - direction.rotated(-0.5) * 8 / scale, color, 1.5 / scale)
	if link_edge != "": canvas.draw_line(from, editor.get_global_mouse_position(), Color("f4e6a5"), 1.5 / scale)
