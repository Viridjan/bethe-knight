extends Node
## A room keeps every plane alive. Only one World receives input, simulation and audio.
const Settings := preload("res://scripts/layers/layer_settings.gd")
var worlds := {}
var active := "main"
var history: Array[String] = ["main"]
var root_world

class Shade extends Node2D:
	var area := Rect2()
	func _draw() -> void:
		draw_rect(area,Color(0,0,0,0.90))

func setup(world, definition: Dictionary, resume := "main") -> void:
	root_world=world
	worlds={"main":world}
	world.layer_manager=self
	world.layer_key="main"
	_add_shade(world)
	var defs:=Settings.definitions(definition)
	for id in defs:
		if id=="main":continue
		var child=load("res://scripts/world.gd").new()
		child.layer_key=id
		child.layer_manager=self
		child.layer_definition=defs[id]
		child.layer_active=false
		child.visible=false
		worlds[id]=child
		add_child(child)
		_add_shade(child)
		child._set_layer_activity(false)
	active="main"
	if worlds.has(resume) and resume!="main": activate(resume,worlds[resume].spawn)

func _add_shade(world) -> void:
	world.layer_shade=Shade.new()
	world.layer_shade.area=Rect2(world.bounds)
	world.layer_shade.z_index=50
	world.layer_shade.visible=not world.layer_active
	world.add_child(world.layer_shade)

func activate(id: String, at: Vector2) -> bool:
	if not worlds.has(id):return false
	var target=worlds[id]
	var actor=worlds[active].player
	var body:=Rect2i(Vector2i(at)-Vector2i(4,11),Vector2i(8,11))
	if not target.bounds.encloses(body) or target.collide_solid(body)!=null or target.touching_spikes(body):return false
	if id==active:return true
	var old=worlds[active]
	old.layer_followers=actor.followers
	old._set_layer_activity(false)
	# Stop instead of pausing: old transient sounds must never resume on a later visit.
	Game.get_sfx().stop_all()
	Game.get_music_engine().stop()
	for key in ["time","deaths","broken","collected","revealed_walls","stamina_log","stamina_totals","spawn","spawn_room","spawn_layer"]:target.set(key,old.get(key))
	target.player=actor
	actor.w=target
	actor.followers=target.layer_followers
	actor.climb_hop_solid=null
	actor.current_booster=null
	actor.dream_block=null
	actor.attack_hit.clear()
	actor.attack_timer=0
	actor.attack_buf=0
	actor.dash_attack_timer=0
	actor._set_state(actor.ST_NORMAL)
	actor.speed=Vector2.ZERO
	actor.force_move_x_timer=0
	actor.interact=false
	actor.jump_buf=0
	actor.pos=at
	actor.prev_pos=at
	active=id
	if history.has(id): history.resize(history.find(id)+1)
	else: history.append(id)
	for name in worlds:
		if name=="main":continue
		worlds[name].visible=history.has(name)
		worlds[name].z_index=maxi(1,history.find(name))*100
	target._set_layer_activity(true)
	target.cam_pos=target.cam_goal()
	target.snap_interp()
	target.cam.make_current()
	Game.get_music_engine().follow_environment(target.data.get("environment",""))
	if target.adventure():
		target.activate_checkpoint(actor)
		target._save_run()
	old._redraw()
	target._redraw()
	return true

func travel(world, passage) -> bool:
	if world!=worlds[active]:return false
	var id:String=str(passage.d.get("to_layer",""))
	if not worlds.has(id):return false
	var target=worlds[id]
	var name:String=str(passage.d.get("to",""))
	for exit in target.ents:
		if exit.d.t=="layer_passage" and exit.d.get("id","")==name:
			var at:=Vector2(exit.rect.position)+Vector2(exit.rect.size.x/2.0,exit.rect.size.y)
			if not activate(id,at):return false
			target.door_block=exit.rect
			Game.play_sfx("door")
			return true
	return false

func release() -> void:
	Game.get_sfx().stop_all()
	var current=worlds[active]
	if current!=root_world:
		for key in ["player","time","deaths","broken","collected","revealed_walls","spawn","spawn_room","spawn_layer","stamina_log","stamina_totals"]:root_world.set(key,current.get(key))
		root_world.player.w=root_world
	for world in worlds.values():world._set_layer_activity(false)
	root_world._set_layer_activity(true)
	root_world.cam.make_current()
	root_world.layer_manager=null
	root_world.layer_key="main"
	root_world.layer_shade.queue_free()
	root_world.layer_shade=null
	worlds.clear()
	queue_free()
