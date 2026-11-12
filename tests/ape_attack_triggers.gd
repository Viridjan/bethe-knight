extends Node
const Catalog := preload("res://scripts/attack_catalog.gd")
const Entities := preload("res://scripts/entities.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	var catalog = Catalog.shared()
	catalog.reload()
	if not catalog.has_method("attack_condition"):
		check(false,"Attack bindings expose editable trigger conditions")
	else:
		var row: Dictionary = catalog.ordered_attacks("boss_ape","normal",["ape_retreat"])[0]
		var original := row.duplicate(true)
		var ape = Entities.make(null,{"t":"boss_ape","x":0,"y":0})
		check(catalog.attack_condition(row) == "player_cornered","Retreat exposes its existing player-cornered trigger")
		check(ape._select_attack(2,false,true,false) == "ape_retreat" and ape._select_attack(2,true,true,false) == "ape_retreat","Retreat consumes the geometric corner result without a second angle heuristic")
		row.trigger_condition = "always"
		check(ape._select_attack(2,false,false,false) == "ape_retreat","A configured trigger replaces retreat's hidden corner-only restriction")
		row.trigger_condition = "player_vertical"
		check(ape._select_attack(2,true,false,false) == "ape_retreat" and ape._select_attack(2,false,true,false) != "ape_retreat","Vertical-player condition reads actual Ape decision context")
		row.max_range_units = "1"
		check(ape._select_attack(2,true,false,false) != "ape_retreat","Trigger conditions still respect Range")
		row.max_range_units = "0"
		row.skip_chance = "100"
		check(ape._select_attack(2,true,false,false) != "ape_retreat","Triggered reactions still respect Skip percent")
		row.trigger_condition = "unknown"
		check(not catalog.validate().is_empty(),"Unknown attack triggers cannot be saved")
		row.clear()
		row.merge(original,true)
		check(catalog.validate().is_empty(),"Restoring trigger fixture leaves valid catalogue")
		var ui = load("res://scripts/attack_catalog_editor.gd").new()
		ui.catalog = catalog
		add_child(ui)
		check(ui.has_method("_attack_trigger_picker"),"Ape binding rows offer a trigger selector")
		var picker = ui._attack_trigger_picker(row)
		check(picker.get_item_text(picker.selected) == "Player cornered","Retreat's trigger is visible in the editor")
		picker.free()
		var coverage = ui._cornered_coverage_picker("boss_ape")
		check(coverage.get_item_text(coverage.selected) == catalog.attack("ape_scream").codex_online_name,"Coverage attack is a separate enemy setting from the reaction")
		coverage.free()
		ui.queue_free()
		check_saved_conditions(catalog)
	print("APE ATTACK TRIGGERS: %d failure(s)" % failures)
	Game.quit_game(failures)

func check_saved_conditions(source) -> void:
	var folder := "user://ape-attack-triggers"
	DirAccess.make_dir_recursive_absolute(folder)
	var files: Array = source.source_texts()
	for index in 3:
		Game.write_safe(folder.path_join(["attacks.csv","enemy_attacks.csv","enemy_profiles.json"][index]),files[index])
	var saved = Catalog.new()
	saved.attack_path = folder.path_join("attacks.csv")
	saved.assignment_path = folder.path_join("enemy_attacks.csv")
	check(saved.reload(),"Saved-trigger fixture loads")
	var normal: Dictionary = saved.ordered_attacks("boss_ape","normal",["ape_retreat"])[0]
	var enraged: Dictionary = saved.ordered_attacks("boss_ape","enraged",["ape_retreat"])[0]
	saved.enemy_profiles.boss_ape.cornered_coverage_attack = ""
	normal.trigger_condition = "always"
	enraged.trigger_condition = "player_vertical"
	check(saved.save_all().is_empty() and saved.reload(),"Trigger choices save and reload with catalogue")
	check(saved.enemy_profile("boss_ape").cornered_coverage_attack == "","Separate coverage choice survives profile save/reload")
	check(saved.attack_condition(saved.ordered_attacks("boss_ape","normal",["ape_retreat"])[0]) == "always" and saved.attack_condition(saved.ordered_attacks("boss_ape","enraged",["ape_retreat"])[0]) == "player_vertical","Each phase keeps its own attack trigger")
	# Legacy files gain the field using the same cornered-retreat default.
	var lines := FileAccess.get_file_as_string(saved.assignment_path).strip_edges().split("\n")
	var legacy := PackedStringArray()
	for line in lines: legacy.append(line.left(line.rfind(",")))
	Game.write_safe(saved.assignment_path,"\n".join(legacy)+"\n")
	check(saved.reload() and saved.attack_condition(saved.ordered_attacks("boss_ape","normal",["ape_retreat"])[0]) == "player_cornered","Old CSV files migrate without changing the retreat condition")
