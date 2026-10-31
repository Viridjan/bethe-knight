extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	var path := "res://scripts/attack_catalog.gd"
	if not ResourceLoader.exists(path):
		check(false, "Attack CSV catalogue is implemented")
		Game.quit_game(failures)
		return
	var menu = load("res://scripts/menu.gd").new()
	add_child(menu)
	check(menu.body.get_children().any(func(node): return node is Button and node.text == "Monster Editor"), "Desktop menu has a direct Monster Editor entry")
	menu._monsters(true)
	for frame in 3: await get_tree().process_frame
	var bestiaries: Array = menu.body.get_children().filter(func(node): return node.has_method("_open_catalog"))
	check(bestiaries.size() == 1 and is_instance_valid(bestiaries[0].catalog_window) and bestiaries[0].catalog_window.visible, "Monster Editor entry opens the CSV editor directly")
	menu.queue_free()
	await get_tree().process_frame
	var catalog = load(path).new()
	check(catalog.reload(), "Shipped attack and range CSVs validate")
	check(catalog.attacks.size() >= 9, "Library and Ape attacks are catalogued")
	var sample: Dictionary = catalog.attack("charge").duplicate(true)
	sample.type = "ranged"  # body attacks use the body's area, not this column (checked below)
	sample.coverage_area_units2 = "2"
	sample.initial_speed_units_s = "40"
	sample.windup_s = "0.5"
	var score: Dictionary = catalog.score_attack(sample)
	check(score.valid and is_equal_approx(score.score, 4.0), "Area over 20-unit travel time gives expected score")
	sample.windup_s = "1.25"
	score = catalog.score_attack(sample)
	check(score.valid and is_equal_approx(score.penalty, 3.0) and is_equal_approx(score.score, 4.0/3.0), "Wind-up penalty interpolates from execution time to 2 seconds")
	sample.windup_s = "2"
	check(is_equal_approx(catalog.score_attack(sample).penalty, 5), "Two seconds gives maximum penalty")
	sample.initial_speed_units_s = "10"
	check(not catalog.score_attack(sample).valid, "Unresolved slow attack scoring is explicitly unavailable")
	sample.initial_speed_units_s = "40"
	sample.windup_s = "0.5"
	sample.multishot = "8"
	sample.aimed_shot = "0"
	sample.spread_deg = "0"
	check(is_equal_approx(catalog.score_attack(sample).score, 4 * (1 + 7 * 0.2)), "A full-circle multishot counts the shots away from the player at 20 percent")
	sample.multishot = "3"
	sample.aimed_shot = "1"
	sample.spread_deg = "15"
	check(is_equal_approx(catalog.score_attack(sample).score, 12) and catalog.shot_angles(sample) == [-15.0, 0.0, 15.0], "A tight multishot fan counts every shot; shot 0 is the lowest")
	sample.aimed_shot = "3"
	catalog.attacks.append(sample)
	check(not catalog.validate().is_empty(), "The aimed shot must be one of the shots")
	catalog.attacks.erase(sample)
	var rules: Array = catalog.ordered_attacks("enemy_monster", "default", ["charge", "shoot"])
	check(rules.size() == 2 and rules[0].attack_name == "shoot", "Rules follow priority (highest first) regardless of saved attack order")
	var shoot_rule: Dictionary = rules[0]
	shoot_rule.skip_chance = "100"
	check(catalog.select_attack("enemy_monster", "default", ["charge", "shoot"], 2) == "charge", "A skipped attack passes its turn to the next one in priority order")
	shoot_rule.skip_chance = "0.00"
	catalog.move_binding(shoot_rule, 1)
	check(catalog.ordered_attacks("enemy_monster", "default", ["charge", "shoot"])[0].attack_name == "charge", "Lowering an attack's priority moves it after the next one")
	catalog.move_binding(shoot_rule, -1)
	check(catalog.select_attack("enemy_monster", "default", ["charge", "shoot"], 2, func(a): return a != "shoot") == "charge", "Ineligible first attack falls back to next rule")
	check(catalog.select_attack("enemy_monster", "default", ["charge", "shoot"], 100) == "", "Out-of-range attacks do not execute")
	check(catalog.attack("charge").coverage_area_units2 == "" and is_equal_approx(catalog.score_attack(catalog.attack("charge")).area, 1.5625) and is_equal_approx(catalog.score_attack(catalog.attack("ape_leap")).area, 9.0),
		"Body attacks hit with the body: no area of their own, the reference body is used")
	var open_rule: Dictionary = catalog.ordered_attacks("enemy_monster", "default", ["leap"])[0]
	var keep_max: String = open_rule.max_range_units
	open_rule.max_range_units = "0"
	check(catalog.validate().is_empty() and catalog.select_attack("enemy_monster", "default", ["leap"], 500) == "leap", "A maximum range of 0 means no maximum")
	open_rule.max_range_units = keep_max
	var total: Dictionary = catalog.enemy_score(["charge", "charge"], 2)
	var one: Dictionary = catalog.score_attack(catalog.attack("charge"), 2)
	check(total.valid and is_equal_approx(total.score, 2 + one.score), "Enemy hitbox area is added once and duplicate attack bindings do not double count")
	var ape = load("res://scripts/entities.gd").make(null, {"t": "boss_ape", "x": 0, "y": 0})
	check(ape._select_attack(2, false, false, false) == "ape_scream", "Ape selects its near attack from CSV")
	check(ape._select_attack(8, false, false, false) == "ape_leap", "Ape falls back from ineligible throw to leap")
	check(ape._select_attack(2, false, false, true) == "ape_throw", "Ape executes only first eligible attack in descending rule order")
	ape.hp = 2
	check(ape._select_attack(2, false, false, false) == "ape_scream", "Ape phase two uses its own CSV range bindings")
	ape.hp = 4
	var live = load(path).shared()
	var near_rule: Dictionary = live.ordered_attacks("boss_ape", "normal", ["ape_scream"])[0]
	var old_limit: String = near_rule.max_range_units
	near_rule.max_range_units = "8"
	check(ape._select_attack(7, false, false, false) == "ape_scream", "Editing Ape near range changes attack selection without a hard-coded threshold")
	near_rule.max_range_units = old_limit
	check(catalog.select_attack("enemy_monster", "default", ["charge"], 15) == "", "Range maximum is exclusive")
	var area_attack: Dictionary = catalog.attack("ape_slam").duplicate(true)
	area_attack.type = "melee"
	area_attack.coverage_area_units2 = "2"
	area_attack.animation_s = "0.5"
	area_attack.windup_s = "0"
	check(is_equal_approx(catalog.score_attack(area_attack).score, 4), "Melee and area attacks use coverage over execution time")
	area_attack.animation_s = "1"
	check(is_equal_approx(catalog.score_attack(area_attack).score, 2), "Doubling execution time halves an unpenalized melee score")
	var folder := "user://attack-catalog-test"
	DirAccess.make_dir_recursive_absolute(folder)
	catalog.attack_path = folder + "/attacks.csv"
	catalog.assignment_path = folder + "/enemy_attacks.csv"
	var original: String = catalog.attacks[0].notes
	catalog.attacks[0].notes = "comma, quote \" and\nnewline"
	check(catalog.save_table(false) == "", "CSV saves quoted multiline values atomically")
	check(catalog.save_table(true) == "", "Assignment CSV saves")
	check(catalog.reload() and catalog.attacks[0].notes.contains("\n"), "CSV round trip preserves multiline text")
	check(catalog.attacks[0].windup_s == "0.50" and str(catalog.attacks[0].score).get_slice(".", 1).length() <= 2, "Saved float values have at most two decimals")
	var old_assignment_path: String = catalog.assignment_path
	var before: String = FileAccess.get_file_as_string(catalog.attack_path)
	catalog.assignment_path = folder + "/missing/ranges.csv"
	check(catalog.save_all() != "" and FileAccess.get_file_as_string(catalog.attack_path) == before, "Failure staging range CSV leaves the attack CSV untouched")
	catalog.assignment_path = old_assignment_path
	catalog.attacks[0].windup_s = "nan"
	check(not catalog.validate().is_empty(), "Nonfinite input is rejected")
	check(catalog.save_table(false) != "", "Invalid CSV changes cannot overwrite saved data")
	catalog.attacks[0].windup_s = "0.5"
	var saved_duration: String = catalog.attacks[0].animation_s
	catalog.attacks[0].animation_s = "0.004"
	check(catalog.save_table(false) != "", "Rounding must not silently turn a positive duration into zero")
	catalog.attacks[0].animation_s = saved_duration
	catalog.attacks[0].notes = original
	var ui_path := "res://scripts/attack_catalog_editor.gd"
	if ResourceLoader.exists(ui_path):
		var editor = load(ui_path).new()
		editor.catalog = catalog
		add_child(editor)
		check(editor.table.item_count == catalog.attacks.size(), "Monsters CSV editor lists all attacks")
		check(editor.form.get_children().filter(func(node): return node is GridContainer and node.columns == 4).size() == 4, "Attack form groups fields into four sections with two fields per row")
		check(editor.fields.windup_s.text == "0.50", "Numeric edit fields show two decimal places")
		check(not editor.fields.has("score") and not editor.fields.has("notes") and not editor.fields.has("base_weight") and editor.fields.has("initial_speed_units_s"),
			"The Attacks tab holds only what makes an attack work")
		var grey := func(id: String) -> bool:
			editor._select_row(catalog.attacks.find(catalog.attack(id)))
			return not editor.fields.animation_s.editable
		check(grey.call("shoot") and grey.call("charge") and grey.call("ape_slam") and not grey.call("ape_scream"),
			"Execution is greyed out for projectile and movement attacks, editable for attacks with their own animation")
		editor._select_row(0)
		editor._change("windup_s", "0.75")
		editor._save()
		check(not editor.dirty, "Monsters editor explicitly saves a valid draft")
		var disk = load(path).new()
		disk.attack_path = catalog.attack_path
		disk.assignment_path = catalog.assignment_path
		check(disk.reload() and is_equal_approx(disk.value("charge", "windup_s", -1), 0.75), "Monsters edits round trip through actual CSV files")
		editor._change("windup_s", "invalid")
		check(editor.save_button.disabled, "Invalid form entries disable Save without changing gameplay")
		editor._change("windup_s", "0.75")
		var external := FileAccess.open(catalog.attack_path, FileAccess.READ_WRITE)
		external.seek_end()
		external.store_string("\n")
		external.close()
		editor._save()
		check(editor.dirty and editor.feedback.text.contains("changed on disk"), "Saving refuses to overwrite external CSV edits")
		check(editor._reload(), "Reload can discard the draft and accept externally modified valid CSV")
		editor._show_table(true)
		check(editor.table.item_count == catalog.assignments.size(), "Monsters CSV editor lists range assignments")
		editor._show_enemies()
		check(editor.table.item_count == editor.ENEMIES.size() and editor.form.get_children().any(func(n): return n.get("ent") != null),
			"Enemies tab lists the enemies and shows the selected one's sprite")
		var first: String = catalog.ordered_attacks("enemy_monster", "default")[0].attack_name
		editor._move(catalog.ordered_attacks("enemy_monster", "default")[0], 1)
		check(catalog.ordered_attacks("enemy_monster", "default")[1].attack_name == first and editor.dirty, "The lower-priority button moves an attack down the list")
		var n_before: int = catalog.assignments.size()
		editor._remove_binding(catalog.ordered_attacks("enemy_monster", "default")[0])
		editor._add_binding(editor.ENEMIES[0], catalog.EXECUTABLE.enemy_monster.filter(func(a): return not catalog.ordered_attacks("enemy_monster", "default").any(func(b): return b.attack_name == a))[0])
		check(catalog.assignments.size() == n_before and catalog.validate().is_empty(), "Attacks can be removed from and added to an enemy")
		check(editor.form.get_children().any(func(n): return n is Label and n.text.contains("Scores of the saved builds")), "Enemies tab shows the scores")
		editor._select_enemy(0)
		var top: Dictionary = catalog.attack(catalog.ordered_attacks("enemy_monster", "default")[0].attack_name)
		var edits: Array = []
		var collect := func(node, f):
			for c in node.get_children():
				if c is LineEdit: edits.append(c)
				f.call(c, f)
		collect.call(editor.form, collect)
		var wind: LineEdit = edits.filter(func(x): return x.text == top.windup_s)[0]
		wind.text_changed.emit("0.65")
		check(top.windup_s == "0.65" and editor.dirty and edits.any(func(x): return x.text == top.notes) and edits.any(func(x): return x.text == top.codex_online_name),
			"Enemies tab: each attack's values, name and notes are editable right under it")
		top.windup_s = "0.50"
		editor._select_enemy(2)
		await get_tree().process_frame
		check(editor.form.get_children().any(func(n): return n.get("ent") != null) and editor.form.get_children().any(func(n): return n is Label and n.text.begins_with("Repertoire score")),
			"Enemies tab shows the Ape (enraged) with its repertoire score")
		editor.queue_free()
	else: check(false, "Monsters CSV editor is implemented")
	print("ATTACK CATALOG OK" if failures == 0 else "ATTACK CATALOG FAILED")
	Game.quit_game(failures)
