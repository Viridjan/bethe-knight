extends Node
const Effects := preload("res://scripts/effects/attack_effects.gd")
var failures := 0
var walls: Array[Rect2i] = []
var ground := Rect2i(-1000,100,2000,32)
var gap := Rect2i()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func solid(box: Rect2i) -> bool:
	if ground.intersects(box) and not gap.intersects(box): return true
	return walls.any(func(wall): return wall.intersects(box))
func circle(at := Vector2(96,84), radius := 40.0) -> Dictionary:
	return {"bounds":Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),"hits":func(box): return Effects.circle_hits(at,radius,box)}
func _ready() -> void:
	var path := "res://scripts/combat/cornered_coverage.gd"
	if not ResourceLoader.exists(path):
		check(false,"Reusable attack-coverage corner detector exists")
	else:
		var detector = load(path)
		var enemy := Rect2i(80,68,32,32)
		var body := Rect2i(120,89,8,11)
		var damage := Rect2i(121,93,6,7)
		walls = [Rect2i(136,92,8,8)]
		check(detector.evaluate(enemy,body,damage,true,circle(),solid).cornered,"Grounded player between enemy and a covered wall triggers cornered")
		check(not detector.evaluate(enemy,body,damage,false,circle(),solid).cornered,"An airborne player cannot be ground-level cornered")
		check(not detector.evaluate(enemy,Rect2i(120,105,8,11),Rect2i(121,109,6,7),true,circle(),solid).cornered,"Players on a floor more than one tile lower do not qualify")
		check(not detector.evaluate(enemy,body,damage,true,circle(Vector2(96,84),24),solid).cornered,"An inflated player-centred tracer cannot substitute for real attack reach")
		check(not detector.evaluate(enemy,body,damage,true,circle(Vector2(96,68)),solid).cornered,"Circular coverage rejects bounding-box corner false positives")
		walls = [Rect2i(136,76,8,8)]
		check(detector.evaluate(enemy,body,damage,true,circle(),solid).cornered,"One block in the third row above the floor qualifies as a wall")
		walls = [Rect2i(136,68,8,8)]
		check(not detector.evaluate(enemy,body,damage,true,circle(),solid).cornered,"A block only in the fourth row does not qualify")
		walls = [Rect2i(112,92,8,8)]
		check(not detector.evaluate(enemy,body,damage,true,circle(),solid).cornered,"A wall between enemy and player is not behind the player")
		walls = [Rect2i(136,92,8,8)]
		gap = Rect2i(130,100,3,32)
		check(not detector.evaluate(enemy,body,damage,true,circle(),solid).cornered,"A pit breaks the covered floor corridor")
		gap = Rect2i()
		walls = []
		check(not detector.evaluate(enemy,body,damage,true,circle(),solid).cornered,"No wall means no corner")
		walls = [Rect2i(48,92,8,8)]
		check(detector.evaluate(enemy,Rect2i(64,89,8,11),Rect2i(65,93,6,7),true,circle(),solid).cornered,"The same detection works with the wall on the left")
		walls = [Rect2i(136,92,8,8)]
		var rectangle := Rect2i(80,92,60,8)
		var coverage := {"bounds":Rect2(rectangle),"hits":func(box): return rectangle.intersects(box)}
		check(detector.evaluate(enemy,body,damage,true,coverage,solid).cornered,"Reusable detector also accepts actual rectangular damage footprints")
		var hole := {"bounds":Rect2(rectangle),"hits":func(box): return rectangle.intersects(box) and not box.has_point(Vector2i(120,99))}
		check(not detector.evaluate(enemy,body,damage,true,hole,solid).cornered,"Coverage gaps elsewhere in the corridor prevent the trigger even if the current player is hit")
		check(not detector.evaluate(enemy,body,damage,true,{},solid).cornered,"Unsupported attack geometry cannot claim coverage")
		check_ape_adapter()
	print("CORNERED COVERAGE: %d failure(s)" % failures)
	Game.quit_game(failures)

func check_ape_adapter() -> void:
	Game.adv = {}
	Game.level = Game.new_level("Cornered",30,20)
	Game.level.tiles = []
	for y in 20: Game.level.tiles.append("1".repeat(30) if y>=16 else "0".repeat(30))
	Game.level.tiles[15] = "0".repeat(19)+"1"+"0".repeat(10)
	Game.level.entities = [{"t":"spawn","x":24,"y":120},{"t":"boss_ape","x":96,"y":96}]
	var world = load("res://scripts/world.gd").new()
	add_child(world)
	world.set_physics_process(false)
	world.player.pos = Vector2(140,128)
	world.player.on_ground = true
	var ape = world.ents.filter(func(e): return e.d.t == "boss_ape")[0]
	if not ape.has_method("_cornered_coverage"):
		check(false,"Ape uses the shared coverage detector")
	else:
		check(ape._cornered(world.player),"Actual Ape and player collision boxes detect covered corridor")
		var attack: Dictionary = load("res://scripts/attack_catalog.gd").shared().attack("ape_scream")
		var original_area: String = attack.coverage_area_units2
		attack.coverage_area_units2 = "12.57"
		check(not ape._cornered(world.player),"Changing the selected attack's real area changes corner detection")
		attack.coverage_area_units2 = original_area
		ape.phase = "idle"
		ape.timer = 0
		ape.throw_chance = 0
		ape.update(0)
		check(ape.phase == "crouch" and ape.retreat,"Covered corridor actually starts retreat leap at the next idle decision")
		world.player.on_ground = false
		check(not ape._cornered(world.player),"Actual Ape rejects an airborne player")
		world.player.on_ground = true
		ape.profile.cornered_coverage_attack = ""
		check(not ape._cornered(world.player),"Enemy coverage selection can explicitly disable this condition")
		ape.profile.cornered_coverage_attack = "ape_throw"
		check(not ape._cornered(world.player),"Unsupported moving attacks cannot masquerade as static coverage")
	world.free()
