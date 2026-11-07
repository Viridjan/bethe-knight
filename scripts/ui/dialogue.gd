extends Control
signal closed
var speaker := "Traveller"
var message := "..."
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.03,0.07,0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",16)
	margin.add_child(box)
	box.add_child(Game.label(speaker,24))
	var text := Label.new()
	text.text = message
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(minf(620,get_viewport_rect().size.x-80),100)
	box.add_child(text)
	var button := Game.button("Continue",finish)
	box.add_child(button)
	button.grab_focus.call_deferred()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		finish()
func finish() -> void:
	closed.emit()
	queue_free()
