extends "res://tests/test_runner.gd"

func _ready() -> void:
	if not ResourceLoader.exists("res://scripts/actors/enemy_health.gd"):
		check(false, "Shared enemy health definition exists")
		Game.quit_game(fails)
		return
	Game.adv = {}
	var catalog = E.AttackCatalog.shared()
	var before: Dictionary = catalog.enemy_profiles.duplicate(true)
	catalog.enemy_profiles.enemy_hornback = {"max_hp": 7}
	check(E.make(null, {"t": "enemy_hornback", "x": 0, "y": 0}).hp == 7, "Family HP profile reaches real enemies")
	check(E.make(null, {"t": "enemy_hornback_giant", "x": 0, "y": 0}).hp == 14, "Variants modify the authored base health")
	catalog.enemy_profiles.enemy_monster = {"max_hp": 8}
	var lib := {"t": "enemy_monster", "x": 0, "y": 0, "move": "patrol", "attacks": ["charge"], "traits": ["armored", "giant"], "tier": 0, "look": "enemy_hornback"}
	check(E.make(null, lib).hp == 20, "Library monster health applies stacked traits exactly once")
	catalog.enemy_profiles.enemy_hornback.max_hp = 0
	check(not catalog.validate().is_empty(), "Zero authored family health is rejected")
	catalog.enemy_profiles.enemy_hornback.max_hp = 7
	var ui = load("res://scripts/attack_catalog_editor.gd").new()
	ui.catalog = catalog
	add_child(ui)
	var index: int = ui.ENEMIES.map(func(e): return e[0]).find("enemy_hornback")
	ui._select_enemy(index)
	var edits: Array = ui.form.find_children("FamilyHealth", "LineEdit", true, false)
	check(edits.size() == 1, "Family health is editable in the real Monster Editor")
	if not edits.is_empty():
		edits[0].text_changed.emit("9")
		check(catalog.enemy_profile("enemy_hornback").max_hp == 9, "Health input updates the shared authoring profile")
		check(E.make(null, {"t": "enemy_hornback", "x": 0, "y": 0}).hp == 9, "Subsequent enemy spawns use edited health")
		check(E.make(null, {"t": "enemy_hornback_giant", "x": 0, "y": 0}).hp == 18, "Edited family HP preserves giant scaling")
		edits[0].text_changed.emit("")
		check(E.make(null, {"t": "enemy_hornback", "x": 0, "y": 0}).hp == 3, "Clearing the override restores legacy health")
	var folder := "user://partial_foundations"
	DirAccess.make_dir_recursive_absolute(folder)
	catalog.attack_path = folder + "/attacks.csv"
	catalog.assignment_path = folder + "/enemy_attacks.csv"
	check(catalog.save_all().is_empty() and catalog.reload() and catalog.enemy_profile("enemy_monster").max_hp == 8, "Family health survives real catalogue save/load")
	catalog.attack_path = "res://data/attacks.csv"
	catalog.assignment_path = "res://data/enemy_attacks.csv"
	catalog.enemy_profiles = before
	ui.queue_free()
	await get_tree().process_frame
	check_patrol_and_death()
	if w: w.queue_free()
	await get_tree().process_frame
	print("PARTIAL FOUNDATIONS: %d failure(s)" % fails)
	Game.quit_game(fails)

func check_patrol_and_death() -> void:
	make_world([{"t": "enemy_hornback", "x": 200, "y": 200}, {"t": "enemy_thornmite", "x": 280, "y": 200}, {"t": "enemy_bat_brood", "x": 360, "y": 190}])
	var walker = w.ents.filter(func(e): return e.d.t == "enemy_hornback")[0]
	walker.rect.position = Vector2i(200, 224 - walker.rect.size.y)
	walker.facing = 1
	var start: Vector2i = walker.rect.position
	check(not walker.walk(0.5) and walker.rect.position == start, "Shared floor motion preserves fractional displacement")
	check(not walker.walk(0.5) and walker.rect.position.x == start.x + 1, "Fractional patrol motion accumulates to a pixel")
	walker.rect.position.x = w.bounds.end.x - walker.rect.size.x
	check(walker.walk(5), "Shared floor motion stops at an unsafe edge")
	var crawler = w.ents.filter(func(e): return e.d.t == "enemy_thornmite")[0]
	crawler.rect.position = Vector2i(280, 224 - crawler.rect.size.y)
	crawler.update(0.1)
	check(crawler.rect.position.x != 280, "Real crawler uses the extracted surface controller")
	var brood = w.ents.filter(func(e): return e.d.t == "enemy_bat_brood")[0]
	brood.hp = 1
	brood.hit(p())
	brood.hit(p())
	check(w.spawn_queue.size() == 2, "Brood death emits two children once through the shared death action")
	check(w.spawn_queue.all(func(d): return d.brood_child and d.t == "enemy_bat_swift"), "Shared death action preserves family and child flags")
