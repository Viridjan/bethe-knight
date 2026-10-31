extends SceneTree
# Refresh the generated score column after editing CSV data outside the game.
func _initialize() -> void:
	var catalog = load("res://scripts/attack_catalog.gd").new()
	if not catalog.reload():
		push_error(catalog.error)
		quit(1)
		return
	var error: String = catalog.save_all()
	if not error.is_empty():
		push_error(error)
		quit(1)
		return
	print("ATTACK SCORES UPDATED")
	quit(0)
