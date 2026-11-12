extends "res://scripts/attack_catalog_editor.gd"
# The Monster Lab's editor (world.gd _toggle_lab): the Monster Editor on its own catalogue, which starts with
# no attacks and no enemies. Its files live in user://monster_lab/, so the game's data is never touched.

const DIR := "user://monster_lab/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	catalog = Catalog.new()
	catalog.standalone = true
	for file in ["attacks.csv", "enemy_attacks.csv"]:
		if not FileAccess.file_exists(DIR + file):  # an empty table: the game's column names, no rows
			Game.write_safe(DIR + file, FileAccess.get_file_as_string("res://data/" + file).get_slice("\n", 0) + "\n")
	catalog.attack_path = DIR + "attacks.csv"
	catalog.assignment_path = DIR + "enemy_attacks.csv"
	if not catalog.reload(): push_error(catalog.error)

func _all_enemies() -> Array:
	return []

func _select_enemy(i: int) -> void:
	if not ENEMIES.is_empty(): super(i)
