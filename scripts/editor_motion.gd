extends PanelContainer
# Object selection, motion authoring and previews. Room data/undo remain Editor's.
const Runtime := preload("res://scripts/motion/patrol_runtime.gd")
var editor
var selected_index := -1
var selected_point := -1
var dragging_point := false
var adding_points := false
var syncing := false
var mode: OptionButton
var speed: SpinBox
var pause: SpinBox
var sticky: CheckBox
var closed: CheckBox
var direction: OptionButton
var support: OptionButton
var preview_button: CheckBox
var start_enabled: CheckBox
var remove_button: Button
var add_button: CheckBox
var title: Label
var help: Label
var grid: GridContainer
var preview_motion = null
var preview_body := Rect2i()

func setup(owner_editor) -> void:
	editor = owner_editor
	theme = Game.theme.duplicate()
	theme.default_font_size = 14
	mouse_force_pass_scroll_events = false
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -324
	offset_right = -12
	offset_top = 64
	offset_bottom = -48
	add_theme_font_size_override("font_size", 14)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_force_pass_scroll_events = false
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	title = Game.label("Select an object", 17)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	grid = GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	mode = _choice(grid, "Movement", ["Original behaviour", "Surface patrol", "Path patrol"])
	speed = _number(grid, "Speed (tiles/second)", 0, 100, 0.1)
	pause = _number(grid, "Pause (seconds)", 0, 60, 0.1)
	direction = _choice(grid, "Starting direction", ["Right", "Left", "Down", "Up"])
	support = _choice(grid, "Attached surface", ["Wall on right", "Wall on left", "Floor below", "Ceiling above"])
	sticky = CheckBox.new()
	sticky.text = "Sticky (follow corners)"
	sticky.tooltip_text = "Follow connected floors, walls and ceilings around corners; otherwise reverse at a surface end."
	box.add_child(sticky)
	closed = CheckBox.new()
	closed.text = "Closed path (loop)"
	closed.tooltip_text = "Loop from the last point to the first. Open paths reverse at either end."
	box.add_child(closed)
	add_button = CheckBox.new()
	add_button.text = "Add path points"
	add_button.tooltip_text = "Enable, then click the room canvas to append snapped path points."
	add_button.toggled.connect(func(on): adding_points = on)
	box.add_child(add_button)
	remove_button = Game.button("Delete selected point", remove_point)
	remove_button.tooltip_text = "Select a numbered point; a path must keep at least two points."
	box.add_child(remove_button)
	start_enabled = CheckBox.new()
	start_enabled.text = "Start moving"
	start_enabled.tooltip_text = "Uncheck to wait for a trigger Start movement command. Stop movement pauses only authored patrol, not enemy combat."
	start_enabled.toggled.connect(func(_on): change_settings())
	box.add_child(start_enabled)
	preview_button = CheckBox.new()
	preview_button.text = "Preview movement"
	preview_button.tooltip_text = "Animate an outlined body using the saved movement settings and room collision, without modifying the room. A red preview is blocked by terrain."
	preview_button.toggled.connect(func(_on): reset_preview())
	box.add_child(preview_button)
	help = Game.label("", 13)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help)
	for option in [mode, direction, support]: option.item_selected.connect(func(_index): change_settings())
	for field in [speed, pause]: field.value_changed.connect(func(_value): change_settings())
	for field in [sticky, closed]: field.toggled.connect(func(_on): change_settings())
	clear_selection()
	visible = false

func _choice(parent: Control, label: String, choices: Array) -> OptionButton:
	parent.add_child(Game.label(label, 13))
	var option := OptionButton.new()
	option.tooltip_text = "Choose " + label.to_lower() + "."
	for choice in choices: option.add_item(choice)
	parent.add_child(option)
	return option

func _number(parent: Control, label: String, low: float, high: float, step: float) -> SpinBox:
	parent.add_child(Game.label(label, 13))
	var field := SpinBox.new()
	field.min_value = low
	field.max_value = high
	field.step = step
	field.tooltip_text = "Movement speed in tiles per second; zero holds position." if label.begins_with("Speed") else "Wait at path points or surface ends, in seconds."
	field.custom_minimum_size.x = 72
	parent.add_child(field)
	return field

func data() -> Dictionary:
	return editor.level.entities[selected_index] if selected_index >= 0 and selected_index < editor.level.entities.size() else {}

func clear_selection() -> void:
	selected_index = -1
	selected_point = -1
	dragging_point = false
	preview_motion = null
	if is_instance_valid(grid):
		grid.visible = false
		for control in [sticky, closed, add_button, preview_button, remove_button, start_enabled]:
			control.disabled = true
			control.visible = false
		title.text = "Select an object"
		help.text = "Click an existing object. Choose a movement mode, then edit its path or attached surface."

func select_object(index: int) -> void:
	selected_index = index
	selected_point = -1
	dragging_point = false
	visible = true
	sync()

func sync() -> void:
	var d := data()
	if d.is_empty():
		clear_selection()
		return
	syncing = true
	title.text = str(editor.E.TYPES[d.t][0])
	var supported := Runtime.Settings.supports(d)
	grid.visible = supported
	for control in [sticky, closed, add_button, preview_button, remove_button, start_enabled]:
		control.disabled = not supported
		control.visible = supported
	if not supported:
		help.text = "Room and boss encounter anchors keep their authored position. Select a movable enemy, platform, pickup, hazard or decoration."
		syncing = false
		return
	var config: Dictionary = d.get("motion", {})
	mode.select({"surface": 1, "path": 2}.get(config.get("mode", ""), 0))
	speed.set_value_no_signal(config.get("speed", 2.0))
	pause.set_value_no_signal(config.get("pause", 0.0))
	start_enabled.set_pressed_no_signal(config.get("enabled", true))
	sticky.set_pressed_no_signal(config.get("sticky", false))
	closed.set_pressed_no_signal(config.get("closed", false))
	direction.select(Runtime.Settings.CARDINAL.find(config.get("direction", [1, 0])))
	support.select(Runtime.Settings.CARDINAL.find(config.get("support", [0, 1])))
	for control in [speed, pause]: _row_visible(control, mode.selected != 0)
	for control in [direction, support]: _row_visible(control, mode.selected == 1)
	sticky.visible = mode.selected == 1
	closed.visible = mode.selected == 2
	add_button.visible = mode.selected == 2
	remove_button.visible = mode.selected == 2
	preview_button.visible = mode.selected != 0
	start_enabled.visible = mode.selected != 0
	direction.disabled = mode.selected != 1
	support.disabled = mode.selected != 1
	sticky.disabled = mode.selected != 1
	closed.disabled = mode.selected != 2
	add_button.disabled = mode.selected != 2
	remove_button.disabled = mode.selected != 2
	preview_button.disabled = mode.selected == 0
	speed.editable = mode.selected != 0
	pause.editable = mode.selected != 0
	if mode.selected != 2:
		dragging_point = false
		selected_point = -1
		adding_points = false
		add_button.set_pressed_no_signal(false)
	help.text = "Drag numbered points. Enable Add path points to extend the route; right-click a point to delete." if mode.selected == 2 else ("Place beside the chosen surface. Sticky follows connected corners." if mode.selected == 1 else "Choose a patrol mode to override this object's original movement.")
	help.tooltip_text = "Open paths reverse; closed paths loop. The placed object travels to point 1 first. Arrows show direction; the outlined box previews motion against static room geometry. Speed zero holds position. Enemy patrol pauses during attacks and resumes without teleporting."
	syncing = false
	reset_preview()

func _row_visible(control: Control, show_row: bool) -> void:
	control.visible = show_row
	grid.get_child(control.get_index() - 1).visible = show_row

func _default_points(d: Dictionary) -> Array:
	var end_x := int(d.x) + 24 if int(d.x) + 24 < int(editor.level.w) * 8 else int(d.x) - 24
	return [[int(d.x), int(d.y)], [maxi(0, end_x), int(d.y)]]

func change_settings() -> void:
	if syncing or data().is_empty(): return
	var d := data()
	if mode.selected == 0:
		if d.has("motion"):
			editor._push_undo()
			d.erase("motion")
			editor._refresh_one(selected_index)
		sync()
		return
	var config := {"mode": "surface" if mode.selected == 1 else "path", "speed": speed.value, "pause": pause.value, "enabled": start_enabled.button_pressed}
	if mode.selected == 1:
		config.sticky = sticky.button_pressed
		config.direction = Runtime.Settings.CARDINAL[direction.selected].duplicate()
		config.support = Runtime.Settings.CARDINAL[support.selected].duplicate()
		if Vector2(config.direction[0], config.direction[1]).dot(Vector2(config.support[0], config.support[1])) != 0:
			# An attached-surface change chooses a valid tangent instead of saving an invalid pair.
			config.direction = [config.support[1], -config.support[0]]
	else:
		config.closed = closed.button_pressed
		config.points = d.get("motion", {}).get("points", _default_points(d)).duplicate(true)
	apply_config(config)

func apply_config(config: Dictionary, undo := true) -> bool:
	var error: String = Runtime.Settings.validate(config, Vector2i(editor.level.w * 8, editor.level.h * 8))
	if not error.is_empty():
		editor._status(error)
		return false
	if config == data().get("motion", {}): return true
	if undo: editor._push_undo()
	data().motion = config.duplicate(true)
	editor._refresh_one(selected_index)
	sync()
	editor._redraw()
	return true

func add_point(point: Vector2i) -> void:
	if data().get("motion", {}).get("mode", "") != "path": return
	var config: Dictionary = data().motion.duplicate(true)
	config.points.append([point.x, point.y])
	apply_config(config)

func point_at(point: Vector2) -> int:
	if data().get("motion", {}).get("mode", "") != "path": return -1
	var points: Array = data().motion.points
	for i in range(points.size() - 1, -1, -1):
		if point.distance_to(Vector2(points[i][0], points[i][1])) <= 9 / editor.cam.zoom.x: return i
	return -1

func canvas_left(point: Vector2i, pressed: bool) -> void:
	if not pressed:
		dragging_point = false
		return
	var hit := point_at(Vector2(point))
	if hit >= 0:
		selected_point = hit
		dragging_point = true
		editor._push_undo()
	elif adding_points:
		add_point(Vector2i(roundi(point.x / 8.0) * 8, roundi(point.y / 8.0) * 8))
	else:
		select_object(editor._motion_entity_at(Vector2(point)))
	editor._redraw()

func drag_to(point: Vector2i) -> void:
	if not dragging_point or selected_point < 0 or data().is_empty(): return
	var config: Dictionary = data().motion.duplicate(true)
	config.points[selected_point] = [point.x, point.y]
	apply_config(config, false)

func remove_point() -> void:
	if selected_point < 0 or data().get("motion", {}).get("mode", "") != "path": return
	var config: Dictionary = data().motion.duplicate(true)
	if config.points.size() <= 2:
		editor._status("A path must keep at least two points")
		return
	config.points.remove_at(selected_point)
	selected_point = -1
	apply_config(config)

func reset_preview() -> void:
	preview_motion = null
	if selected_index < 0 or selected_index >= editor.preview.size() or not data().has("motion"): return
	preview_body = editor.preview[selected_index].rect
	preview_motion = Runtime.new(data().motion, preview_body, Vector2(data().x, data().y))

func advance_preview(dt: float) -> void:
	if dragging_point and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): dragging_point = false
	if not visible or not preview_button.button_pressed or preview_motion == null: return
	preview_motion.advance(preview_body, minf(dt, 0.05), _preview_blocked, func(body): preview_body = body, _preview_support)
	editor._redraw()

func _preview_blocked(body: Rect2i) -> bool:
	if not Rect2i(0, 0, editor.level.w * 8, editor.level.h * 8).encloses(body): return true
	if data().t in ["building", "island_prop", "village_elf", "village_mage"]: return false
	for y in range(floori(body.position.y / 8.0), floori((body.end.y - 1) / 8.0) + 1):
		for x in range(floori(body.position.x / 8.0), floori((body.end.x - 1) / 8.0) + 1):
			if editor.level.tiles[y].unicode_at(x) == 49: return true
	for i in editor.preview.size():
		var other = editor.preview[i]
		if i != selected_index and other != null and other.collidable:
			if other.solid and other.rect.intersects(body): return true
			if str(data().t).begins_with("enemy_") and (other.d.t == "acid" or str(other.d.t).begins_with("spikes_")) and other.rect.intersects(body): return true
	return false

func _preview_support(probe: Rect2i) -> bool:
	if _preview_blocked(probe): return true
	if preview_motion.crawler.support == Vector2i.DOWN:
		for i in editor.preview.size():
			var other = editor.preview[i]
			if i != selected_index and other != null and other.collidable and other.jumpthru and other.rect.intersects(probe) and preview_body.end.y <= other.rect.position.y: return true
	return false

func draw_guides(canvas: Node2D) -> void:
	if not visible or data().is_empty(): return
	var scale: float = editor.cam.zoom.x
	var color := Color("65deec")
	canvas.draw_rect(Rect2(editor.preview[selected_index].rect).grow(1), color, false, 2 / scale)
	var config: Dictionary = data().get("motion", {})
	if config.get("mode", "") == "path":
		var points: Array = config.points
		var anchor := Vector2(data().x, data().y)
		var first := Vector2(points[0][0], points[0][1])
		if not anchor.is_equal_approx(first): canvas.draw_line(anchor, first, Color(color, 0.45), 1.0 / scale)
		var count := points.size() if config.get("closed", false) else points.size() - 1
		for i in count:
			var a := Vector2(points[i][0], points[i][1])
			var b := Vector2(points[(i + 1) % points.size()][0], points[(i + 1) % points.size()][1])
			canvas.draw_line(a, b, color, 1.5 / scale)
			var forward := (b - a).normalized()
			var middle := (a + b) / 2
			canvas.draw_line(middle, middle - forward.rotated(0.6) * 5 / scale, color, 1.5 / scale)
			canvas.draw_line(middle, middle - forward.rotated(-0.6) * 5 / scale, color, 1.5 / scale)
		for i in points.size():
			var at := Vector2(points[i][0], points[i][1])
			canvas.draw_circle(at, 4 / scale, Color("ffd270") if i == selected_point else color)
			canvas.draw_string(ThemeDB.fallback_font, at + Vector2(5, -5) / scale, str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(4, roundi(14 / scale)), Color.WHITE)
	elif config.get("mode", "") == "surface":
		var at := Vector2(editor.preview[selected_index].rect.get_center())
		var normal: Array = config.get("support", [0, 1])
		canvas.draw_line(at, at + Vector2(normal[0], normal[1]) * 16 / scale, Color("ffd270"), 2 / scale)
	if preview_button.button_pressed and preview_motion != null:
		var preview_color := Color("ff7777") if preview_motion.config.mode == "path" and preview_motion.blocked_last_tick else color
		canvas.draw_rect(Rect2(preview_body), Color(preview_color, 0.15))
		canvas.draw_rect(Rect2(preview_body), preview_color, false, 1.5 / scale)
