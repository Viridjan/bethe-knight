extends Control
signal completed
signal cancelled
const Model := preload("res://scripts/progression/sea_crossing.gd")
const CharacterArt := preload("res://scripts/character_art.gd")
var model := Model.new()
var world
var retry: Button
var notified := false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var back:=Game.button("Return to dock",func(): cancelled.emit();queue_free())
	back.position=Vector2(20,20)
	add_child(back)
	retry=Game.button("Retry crossing",func(): model=Model.new();notified=false)
	retry.position=Vector2(20,75)
	retry.visible=false
	add_child(retry)
	if load("res://scripts/touch_controls.gd").wanted(): add_child(load("res://scripts/touch_controls.gd").new())
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		cancelled.emit()
		queue_free()
func _physics_process(dt: float) -> void:
	if world != null and not world.paused:
		world.time+=dt
	model.advance(dt,Input.get_axis("left","right"),Input.is_action_just_pressed("jump"))
	retry.visible=model.phase=="failed"
	if model.phase=="failed" and not notified:
		notified=true
		if world != null:
			world.deaths+=1
			if world.adventure():
				world.Adventure.Stress.change(Game.adv,world.Adventure.Stress.DEATH_GAIN)
				world._save_run()
	if model.phase=="done" and not notified:
		notified=true
		completed.emit()
		queue_free()
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0d2032"))
	var scale_factor:=minf(size.x/320.0,size.y/180.0)
	var offset:=(size-Vector2(320,180)*scale_factor)/2
	draw_set_transform(offset,0,Vector2.ONE*scale_factor)
	for row in 6:
		for column in 12:
			var x:=column*30+fmod(model.clock*8+row*7,30)
			draw_line(Vector2(x,145+row*6),Vector2(x+12,145+row*6),Color("30556a"),1)
	var sinking:=model.phase in ["wreck","done"]
	var sink:float= (3-model.timer)*12 if sinking else 0
	var boat:=Rect2(40,130+sink,240,25)
	draw_colored_polygon(PackedVector2Array([boat.position-Vector2(6,0),Vector2(boat.end.x+6,boat.position.y),boat.end-Vector2(15,0),Vector2(boat.position.x+15,boat.end.y)]),Color("8a6044"))
	for x in range(48,280,24): draw_line(Vector2(x,132+sink),Vector2(x+8,150+sink),Color("4f3c35"),1)
	draw_line(Vector2(200,130+sink),Vector2(200,32+sink),Color("b59d76"),3)
	draw_colored_polygon(PackedVector2Array([Vector2(203,34+sink),Vector2(255,93+sink),Vector2(203,93+sink)]),Color("d6d8ce"))
	if model.warning>0:
		var y:=105.0 if model.pending_high else 127.0
		draw_line(Vector2(0,y),Vector2(320,y),Color(1,0.65,0.2,0.5+sin(model.clock*20)*0.3),1)
		draw_string(ThemeDB.fallback_font,Vector2(115,70),"STAY LOW" if model.pending_high else "JUMP",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd17d"))
	for tentacle in model.tentacles:
		var box:=Rect2(tentacle.x,tentacle.y,Model.WIDTH,10)
		draw_rect(box,Color("90627d"))
		for x in range(int(box.position.x)+4,int(box.end.x),12): draw_circle(Vector2(x,box.end.y-2),2,Color("d49b9e"))
	var hero:Vector2=model.player+Vector2(0,sink) if sinking else model.player
	if sinking:
		draw_colored_polygon(PackedVector2Array([Vector2(120,180),Vector2(135,70+sink),Vector2(155,55+sink),Vector2(170,180)]),Color("98677e"))
		hero=Vector2(92,148+sin(model.clock*4)*2)
	if model.invulnerable<=0 or int(model.clock*20)%2==0:
		draw_texture_rect_region(CharacterArt.texture(Color("734a32")),Rect2(hero-Vector2(8,16),Vector2(16,16)),Rect2(0,0,16,16))
	var instruction:="Move and jump. Dodge the tentacles." if model.phase!="failed" else "The crossing failed. Retry or return to the dock."
	if sinking: instruction="The boat is breaking apart..."
	draw_string(ThemeDB.fallback_font,Vector2(36,20),instruction,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
	for index in model.integrity: draw_rect(Rect2(275+index*8,28,5,5),Color("d8ad71"))
	draw_set_transform(Vector2.ZERO)
