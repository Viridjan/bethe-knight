extends Node
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	var catalog = load("res://scripts/attack_catalog.gd").new()
	check(catalog.reload(), "Tooltip fixture loads")
	var ui = load("res://scripts/attack_catalog_editor.gd").new()
	ui.catalog = catalog
	add_child(ui)
	ui._show_enemies()
	catalog.enemy_profile("boss_ape").landing_effects = []
	ui._select_enemy(0)
	var log_hint := _hint(ui, "ape_log")
	check(not log_hint.to_lower().contains("leap") and log_hint.contains(catalog.attack("ape_throw").codex_online_name), "Normal log tooltip describes its remaining throw source")
	ui._select_enemy(0)
	log_hint = _hint(ui, "ape_log")
	check(log_hint.contains(catalog.attack("ape_split").codex_online_name) and log_hint.contains(catalog.attack("ape_throw").codex_online_name) and log_hint.contains("Phase 1") and log_hint.contains("Phase 2"), "Unified log tooltip distinguishes both phase sources")
	catalog.enemy_profile("boss_ape").phase2_throw_effect = "ape_log"
	catalog.attack("ape_throw").codex_online_name = "Custom launcher"
	ui._select_enemy(0)
	check(_hint(ui, "ape_log").contains("Custom launcher") and not _hint(ui, "ape_log").contains("Splitting log"), "Changing the phase-two projectile refreshes source descriptions")
	catalog.enemy_profile("boss_ape").landing_effects = ["ape_slam"]
	catalog.attack("ape_leap").codex_online_name = "Custom jump"
	catalog.attack("ape_retreat").codex_online_name = "Custom retreat"
	ui._select_enemy(0)
	check(_hint(ui, "ape_slam").contains("Custom jump") and _hint(ui, "ape_slam").contains("Custom retreat"), "Wave tooltip uses the current landing-source names")
	var headings: Array = ui.form.get_children().filter(func(node): return node is Label and node.text == "TRIGGERED EFFECTS")
	check(headings.size() == 1 and headings[0].tooltip_text.contains("Custom jump"), "The effect-section legend also comes from the configured graph")
	var jump_fields: Array = ui.form.find_children("*", "LineEdit", true, false).filter(func(node): return node.text == "Custom jump")
	jump_fields[0].text = "Edited jump"
	jump_fields[0].text_changed.emit("Edited jump")
	check(_hint(ui, "ape_slam").contains("Edited jump") and headings[0].tooltip_text.contains("Edited jump"), "Editing a source name refreshes effect help without leaving the page")
	ui.queue_free()
	await get_tree().process_frame
	print("APE EFFECT TOOLTIPS: %d failure(s)" % failures)
	Game.quit_game(failures)

func _hint(ui, effect_id: String) -> String:
	var name: String = ui.catalog.attack(effect_id).codex_online_name
	var fields: Array = ui.form.find_children("*", "LineEdit", true, false).filter(func(node): return node.text == name)
	return "" if fields.is_empty() else fields[0].tooltip_text.get_slice("\n\n", 0)
