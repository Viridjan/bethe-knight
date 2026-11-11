extends Node
func snap(label: String) -> void:
	for frame in 5:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/ordinary-cornered-2026-11-10/"+label+".png")
func _ready() -> void:
	var catalog=load("res://scripts/attack_catalog.gd").new();catalog.reload()
	catalog.enemy_profiles.enemy_hornback={"cornered_coverage_attack":"charge"}
	catalog.enemy_profiles.enemy_monster={"cornered_coverage_attack":"charge"}
	catalog.ordered_attacks("enemy_hornback","default")[0].trigger_condition="player_cornered"
	Game.main=self;Game.goto("menu")
	for frame in 3:await get_tree().process_frame
	var menu=get_child(-1);menu._monster_editor()
	for frame in 3:await get_tree().process_frame
	var editor=menu.body.get_children().filter(func(node):return node.has_method("_show_enemies"))[0]
	editor.catalog=catalog;editor._show_enemies()
	for family in ["enemy_hornback","enemy_monster"]:
		var index:int=editor.ENEMIES.map(func(e):return e[0]).find(family)
		editor._select_enemy(index)
		await snap(family+"-editor")
	Game.quit_game(0)
