extends VBoxContainer
# The Monster Lab's own editor (world.gd _toggle_lab): a blank page for now. The Monster Editor
# (attack_catalog_editor.gd) is separate and stays as it is.

func _ready() -> void:
	var title := Game.label("Monster Lab", 25)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(title)
