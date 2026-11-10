extends Node
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Bethe Knight", "The application uses its new title")
	if OS.get_name() == "Linux":
		check(OS.get_user_data_dir() == OS.get_data_dir().path_join("godot/app_userdata/Bethe Knight"), "The Linux save and editor directory uses the game title")
	var menu = load("res://scripts/menu.gd").new()
	add_child(menu)
	var labels: Array = menu.body.get_children().filter(func(n): return n is Label).map(func(n): return n.text)
	check("Bethe Knight" in labels, "The main menu shows the new title")
	check(labels.any(func(text): return text.contains("Be") and text.contains("within")), "The main menu introduces Be and the inner conflict")
	var title: Label = menu.body.get_children().filter(func(n): return n is Label and n.text == "Bethe Knight")[0]
	check(title.get_combined_minimum_size().x < 1200, "The renamed title fits the default viewport")
	menu.queue_free()
	await get_tree().process_frame
	print("IDENTITY: %d failure(s)" % failures)
	Game.quit_game(failures)
