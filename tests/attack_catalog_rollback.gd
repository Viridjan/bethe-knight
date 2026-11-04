extends Node
const Catalog := preload("res://scripts/attack_catalog.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	for mode in ["new", "existing", "stale_backup"]:
		var catalog = Catalog.new()
		check(catalog.reload(), "Rollback fixture loads")
		var folder := "user://attack_rollback_%s_%d" % [mode, Time.get_ticks_usec()]
		DirAccess.make_dir_recursive_absolute(folder + "/enemy_attacks.csv")
		catalog.attack_path = folder + "/attacks.csv"
		catalog.assignment_path = folder + "/enemy_attacks.csv"
		var before := FileAccess.get_file_as_string("res://data/attacks.csv")
		if mode == "existing": _write(catalog.attack_path, before)
		if mode == "stale_backup": _write(catalog.attack_path + ".bak", "old unrelated backup")
		catalog.attack("ape_throw").windup_s = "0.91"
		var result: String = catalog.save_all()
		check(result != "", "A directory at the assignment destination causes a save failure")
		if mode == "existing":
			check(FileAccess.get_file_as_string(catalog.attack_path) == before, "A failed replacement restores the previous attack CSV exactly")
		else:
			check(not FileAccess.file_exists(catalog.attack_path), "Failed first save leaves no new attack CSV (%s)" % mode)
		check(not FileAccess.file_exists(catalog.profile_path()), "The last-written profile is not created after an earlier failure")
		check(DirAccess.dir_exists_absolute(catalog.assignment_path), "Rollback preserves the pre-existing blocking directory")
		for path in [catalog.attack_path, catalog.assignment_path, catalog.profile_path()]:
			check(not FileAccess.file_exists(path + ".tmp"), "Failed save cleans its staged temporary file: " + path.get_file())
		if mode == "stale_backup":
			check(FileAccess.get_file_as_string(catalog.attack_path + ".bak") == "old unrelated backup", "An unrelated old backup is neither restored nor deleted")
	var catalog = Catalog.new()
	catalog.reload()
	var folder := "user://attack_rollback_success_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(folder)
	catalog.attack_path = folder + "/attacks.csv"
	catalog.assignment_path = folder + "/enemy_attacks.csv"
	check(catalog.save_all().is_empty() and catalog.reload(), "Successful first saves still publish a complete readable catalogue")
	catalog.assignment_path = folder + "/missing/ranges.csv"
	check(catalog.save_all() != "", "Failure while staging a later table is reported")
	check(not FileAccess.file_exists(catalog.attack_path + ".tmp"), "Staging failure cleans an earlier staged table too")
	print("ATTACK CATALOG ROLLBACK: %d failure(s)" % failures)
	Game.quit_game(failures)

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
