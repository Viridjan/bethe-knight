extends "res://scripts/attack_catalog_editor.gd"
# The Monster Lab's own editor (world.gd _toggle_lab). It starts as the Monster Editor plus a Test button;
# changes meant only for the lab go here, not in the Monster Editor.

var on_test: Callable  # called with the enemy id to fight

func _init() -> void:
	page_title = "Monster Lab"

func _select_enemy(i: int) -> void:
	super(i)
	var test := Game.button("Save & test" if dirty else "Test", _test)
	test.name = "TestEnemy"
	test.add_theme_font_size_override("font_size", 12)
	test.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	test.tooltip_text = "Fight this enemy alone in the room behind. Unsaved edits are saved first."
	form.get_child(0).add_child(test)  # the heading row, beside the enemy's name

func _update_feedback() -> void:
	super()
	var test: Node = form.find_child("TestEnemy", true, false)
	if test != null: test.text = "Save & test" if dirty else "Test"

# Save pending edits, then restart the room with the selected enemy. A failed save stays here.
func _test() -> void:
	if dirty: _save()
	if not dirty: on_test.call(str(ENEMIES[enemy_index][0]))
