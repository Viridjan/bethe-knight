extends ColorRect
# Main menu and its subpages, built from Godot interface nodes in code.
# Game owns screen switching; this script prepares selections and asks Game to open a screen.
# Buttons connect their pressed signal to a function; that function runs only when activated.
# Reading help: docs/CODE_GUIDE.md.

# Title screen, level select, options, credits.

const OptionsPanel := preload("res://scripts/options.gd")

var body: VBoxContainer
var hint: Label

# Initialize the menu appearance and open its initial page.
func _ready() -> void:
	color = Color("141433")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Game.theme
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	body = VBoxContainer.new()
	body.custom_minimum_size = Vector2(520, 0)
	body.add_theme_constant_override("separation", 10)
	center.add_child(body)
	hint = Game.label("", 18)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -40
	hint.modulate = Color(1, 1, 1, 0.6)
	add_child(hint)
	_main()

# Remove the previous menu page controls before building another page.
func _clear() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()

# Create the main navigation buttons and world selection controls.
func _main() -> void:
	_clear()
	hint.text = "Arrows: move    %s / Enter: select    %s / Esc: back" % [Game.key_name("jump"), Game.key_name("dash")]
	body.add_child(Game.label("Bethe Knight", 56))
	body.add_child(Game.label("Be faces the world within", 20))
	body.add_child(HSeparator.new())
	var play := Game.button("Adventure", _adventure)
	body.add_child(play)
	if not _is_web():
		if OS.has_feature("editor"):  # world files are writable only from source
			body.add_child(Game.button("World Editor", func(): Game.goto("world_editor")))
		if OS.has_feature("editor"):
			body.add_child(Game.button("Monster Editor", _monster_editor))
		body.add_child(Game.button("Art", _art))
		body.add_child(Game.button("Music Studio", func(): Game.goto("music_studio")))
	body.add_child(Game.button("Options", _options))
	body.add_child(Game.button("Credits", _credits))
	body.add_child(Game.button("Quit", func(): Game.quit_game()))
	play.grab_focus()

func _is_web() -> bool:
	return OS.has_feature("web")

# Open the adventure start/continue choices.
func _adventure() -> void:
	_clear()
	body.add_child(Game.label("Adventure", 44))
	var first: Button = null
	if Game.has_adventure_save():
		first = Game.button("Continue", func(): Game.start_adventure(false))
		body.add_child(first)
	var fresh := Game.button("New Game", func(): Game.start_adventure(true))
	body.add_child(fresh)
	var back := Game.button("Back", _main)
	body.add_child(back)
	(first if first else fresh).grab_focus()

# Open settings and reconnect the close action to the menu.
func _options() -> void:
	var o := OptionsPanel.new()
	add_child(o)
	o.closed.connect(_main)

# The attack CSV editor (attacks, enemies) as a page of its own. (The monsters met in a run are in the map's tab.)
func _monster_editor() -> void:
	_clear()
	var editor = load("res://scripts/attack_catalog_editor.gd").new()
	editor.custom_minimum_size = Vector2(minf(1140, get_viewport_rect().size.x - 48), minf(760, get_viewport_rect().size.y - 130))
	editor.theme = Game.theme.duplicate()
	editor.theme.default_font_size = 15
	body.add_child(editor)
	var back := Game.button("Back", _leave)
	back.add_theme_font_size_override("font_size", 16)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 100
	body.add_child(back)

# Leave the current page; the Monster Editor asks first when it has unsaved edits (Back and Esc both come here).
func _leave() -> void:
	var editors := body.get_children().filter(func(n): return n.has_method("_show_enemies"))
	if editors.is_empty() or not editors[0].dirty:
		_main()
		return
	if get_children().any(func(n): return n is ConfirmationDialog and n.visible): return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Discard unsaved CSV edits?"
	confirm.confirmed.connect(_main)
	confirm.visibility_changed.connect(func():
		if not confirm.visible: confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()

# Every piece of game art, by folder (scripts/art_gallery.gd).
func _art() -> void:
	_clear()
	body.add_child(Game.label("Art", 44))
	body.add_child(load("res://scripts/art_gallery.gd").new())
	var back := Game.button("Back", _main)
	body.add_child(back)
	back.grab_focus()

# Display project credits and attribution information.
func _credits() -> void:
	_clear()
	body.add_child(Game.label("Credits", 44))
	body.add_child(Game.label("Player physics ported from Celeste's Player.cs\n(MIT, Maddy Makes Games - github.com/NoelFB/Celeste)\n\nArt: Paper Pixels by VEXED (v3x3d.itch.io), CC0.\nExtra effects and code: original.\nCeleste is a trademark of Maddy Makes Games.\nThis is an unaffiliated fan project.", 20))
	var back := Game.button("Back", _main)
	body.add_child(back)
	back.grab_focus()

# Return from a subpage on cancel after the active controls handled their own input.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_leave()
