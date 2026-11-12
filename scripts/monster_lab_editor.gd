extends "res://scripts/attack_catalog_editor.gd"
# The Monster Lab's editor (world.gd _toggle_lab): the Monster Editor on the lab's own catalogue. Pick an enemy,
# give it attacks, press Test: the room restarts with that enemy using them. The catalogue starts as a copy of
# the game's attacks with no enemy using them, and lives in user://monster_lab/: the game's data is never touched.

const DIR := "user://monster_lab/"

# The lab's catalogue, read from disk (its empty files are created on first use).
static func lab_catalog():
	DirAccess.make_dir_recursive_absolute(DIR)
	var lab = Catalog.new()
	lab.standalone = true
	# Starts with the game's attacks to choose from, and no enemy using any of them.
	if FileAccess.get_file_as_string(DIR + "attacks.csv").strip_edges().count("\n") == 0:
		Game.write_safe(DIR + "attacks.csv", FileAccess.get_file_as_string("res://data/attacks.csv"))
	if not FileAccess.file_exists(DIR + "enemy_attacks.csv"):
		Game.write_safe(DIR + "enemy_attacks.csv", FileAccess.get_file_as_string("res://data/enemy_attacks.csv").get_slice("\n", 0) + "\n")
	lab.attack_path = DIR + "attacks.csv"
	lab.assignment_path = DIR + "enemy_attacks.csv"
	if not lab.reload(): push_error(lab.error)
	return lab

func _init() -> void:
	catalog = lab_catalog()

# Only the enemies whose attacks come from the catalogue: the others have theirs in code.
func _all_enemies() -> Array:
	return CSV_ENEMIES.duplicate()

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
	if not dirty: Game.play_lab(str(ENEMIES[enemy_index][0]), Game.lab_at)
