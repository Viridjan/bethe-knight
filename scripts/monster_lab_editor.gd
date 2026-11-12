extends "res://scripts/attack_catalog_editor.gd"
# The Monster Lab's editor (world.gd _toggle_lab): the Monster Editor on the lab's own catalogue. Pick an enemy,
# give it attacks, press Test: the room restarts with that enemy using them. The catalogue starts empty and
# lives in user://monster_lab/, so the game's data is never touched.

const DIR := "user://monster_lab/"

# The lab's catalogue, read from disk (its empty files are created on first use).
static func lab_catalog():
	DirAccess.make_dir_recursive_absolute(DIR)
	var lab = Catalog.new()
	lab.standalone = true
	for file in ["attacks.csv", "enemy_attacks.csv"]:
		if not FileAccess.file_exists(DIR + file):  # an empty table: the game's column names, no rows
			Game.write_safe(DIR + file, FileAccess.get_file_as_string("res://data/" + file).get_slice("\n", 0) + "\n")
	lab.attack_path = DIR + "attacks.csv"
	lab.assignment_path = DIR + "enemy_attacks.csv"
	if not lab.reload(): push_error(lab.error)
	return lab

func _init() -> void:
	catalog = lab_catalog()

# Only the enemies whose attacks come from the catalogue: the others have theirs in code.
func _all_enemies() -> Array:
	return CSV_ENEMIES.duplicate()

# The game's built-in triggered effects are listed for the Ape even when the catalogue lacks them: not here.
func _enemy_rows(e: Array) -> Array:
	return super(e).filter(func(row): return not catalog.attack(row.attack_name).is_empty())

func _select_enemy(i: int) -> void:
	super(i)
	var test := Game.button("Save & test" if dirty else "Test", _test)
	test.name = "TestEnemy"
	test.add_theme_font_size_override("font_size", 12)
	test.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	test.tooltip_text = "Put this enemy in the room behind, with these attacks. Unsaved edits are saved first."
	form.get_child(0).add_child(test)  # the heading row, beside the enemy's name

func _update_feedback() -> void:
	super()
	var test: Node = form.find_child("TestEnemy", true, false)
	if test != null: test.text = "Save & test" if dirty else "Test"

# Save pending edits, then restart the room with the selected enemy. A failed save stays here.
func _test() -> void:
	if dirty: _save()
	if not dirty: Game.play_lab(str(ENEMIES[enemy_index][0]))
