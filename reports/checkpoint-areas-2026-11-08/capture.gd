extends Node
func _ready() -> void:
	Game.editor_level=Game.load_level("c1_lake_cave","res://worlds/story/")
	Game.editor_return="menu"
	var editor=load("res://scripts/editor.gd").new()
	add_child(editor)
	editor.tool="spawn"
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/checkpoint-areas-2026-11-08/editor.png")
	Game.quit_game(0)
