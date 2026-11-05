extends Node2D
## Render the production punch poses at enlarged pixel scale for review.
const Player := preload("res://scripts/player.gd")
var actors := []
class Pose extends Node2D:
	var actor
	func _draw() -> void:
		actor.draw(self)
func _ready() -> void:
	Game.adv = {}
	for index in 6:
		var actor = Player.new(null,Vector2.ZERO)
		actor.facing = 1 if index < 3 else -1
		actor.attack_kind = "punch"
		actor.attack_dir = Vector2(actor.facing,0)
		actor.attack_timer = [0.11,0.06,0.01][index%3]
		actors.append(actor)
		var pose := Pose.new()
		pose.actor = actor
		pose.position = Vector2(220+(index%3)*400,260+(index/3)*330)
		pose.scale = Vector2(10,10)
		add_child(pose)
	queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/punch-2026-11-05/poses.png")
	get_tree().quit()
func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("182434"))
	for index in actors.size():
		var at := Vector2(220+(index%3)*400,260+(index/3)*330)
		draw_string(ThemeDB.fallback_font,at+Vector2(-65,70),["Wind-up","Contact","Recovery"][index%3],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
