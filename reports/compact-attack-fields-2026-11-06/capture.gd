extends Node
var editor
func _ready() -> void:
	editor = load("res://scripts/attack_catalog_editor.gd").new()
	editor.catalog = load("res://scripts/attack_catalog.gd").new()
	editor.catalog.reload()
	editor.writable = true
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	margin.theme = editor._soft_theme(Game.theme)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",20)
	margin.add_child(content)
	for attack in ["ape_leap","ape_throw"]:
		content.add_child(Game.label(attack.replace("_"," ").capitalize(),20))
		editor._build_grouped_values(content,editor.catalog.attack(attack),content.get_child(content.get_child_count()-1))
	for width in [1280,1280,900,600]:
		get_window().size = Vector2i(width,720)
		get_window().content_scale_size = Vector2i(width,720)
		for frame in 5: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var phase := OS.get_environment("CAPTURE_PHASE")
		get_viewport().get_texture().get_image().save_png("res://reports/compact-attack-fields-2026-11-06/%s-%d.png" % [phase,width])
		for group in content.get_children():
			if group is Container: print("%s %d group %s minimum %s" % [phase,width,group.size,group.get_combined_minimum_size()])
	editor.free()
	get_tree().quit()
