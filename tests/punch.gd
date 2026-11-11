extends "res://tests/test_runner.gd"

const Rules := preload("res://scripts/adventure.gd")

func battle(objects: Array, energy := 40.0) -> void:
	if w: w.free()
	Game.level = Game.new_level("punch",40,30)
	Game.level.entities = [{"t":"spawn","x":76,"y":208}] + objects
	Game.adv_world = {"start":"punch","abilities":[],"rooms":{"punch":{"pos":Vector2i.ZERO,"level":Game.level}}}
	Game.adv = Rules.new_run(Game.adv_world)
	Game.adv.stamina = energy
	Game.adv_temp = true
	Game.settings.infinite_stamina = false
	w = load("res://scripts/world.gd").new()
	add_child(w)
	w.set_physics_process(false)
	p().pos = Vector2(80,216)
	p().facing = 1
	for e in w.ents:
		if e is E.CombatEnemy: e.hp = 2

func targets() -> Array:
	return w.ents.filter(func(e): return e is E.CombatEnemy or e is E.BreakWall)

func swing() -> void:  # one attack button: fist without the sword, sword with it
	p().attack_cooldown_timer = 0
	p().attack_timer = 0
	p().attack_buf = 0.1
	for i in 12: p()._attack_update(DT)

func enemy(x: int, y := 208) -> Dictionary:
	return {"t":"enemy_mosstrot","x":x,"y":y}

func _ready() -> void:
	Game.adv = {}
	make_world([])
	if not p().has_method("punching"):
		check(false,"Player has a separate short punch")
		w.free()
		Game.quit_game(fails)
		return
	battle([enemy(86)])
	var target = targets()[0]
	swing()
	check(target.hp == 1 and is_equal_approx(Game.adv.stamina,34),"Point-blank punch hits once and pays 2 attempt + 4 hit")
	check(Game.adv.abilities.is_empty(),"Punch works before acquiring the sword")
	battle([enemy(90)])
	target = targets()[0]
	swing()
	check(target.hp == 2 and is_equal_approx(Game.adv.stamina,38),"Enemy outside the tiny fist is missed; only attempt cost is charged")
	Game.adv.abilities = ["attack"]
	swing()
	check(target.hp == 1 and is_equal_approx(Game.adv.stamina,32) and p().attack_kind == "sword","The sword replaces the fist on the same button, reaches farther and pays the same 2 + 4 costs")
	battle([enemy(86,196)])
	target = targets()[0]
	swing()
	check(target.hp == 2,"A close enemy above the narrow fist is not hit")
	battle([enemy(86),enemy(86)])
	swing()
	check(targets().all(func(e): return e.hp == 1) and is_equal_approx(Game.adv.stamina,34),"Each enemy is hit once; surcharge is paid once per punch")
	battle([{"t":"enemy_hornback_shielded","x":86,"y":208,"facing":-1}])
	target = targets()[0]
	swing()
	check(target.hp == 2 and is_equal_approx(Game.adv.stamina,38),"A blocked punch does not pay the successful-hit surcharge")
	battle([enemy(86)],2)
	target = targets()[0]
	swing()
	check(target.hp == 2 and Game.adv.stamina == 0,"Without hit stamina an attempted punch cannot deal free damage")
	battle([],1)
	swing()
	check(Game.adv.stamina == 1 and p().attack_log.is_empty(),"Insufficient stamina refuses the punch without spending")
	battle([{"t":"breakwall","x":84,"y":200,"w":8,"h":24}])
	var wall = targets()[0]
	for i in 4: swing()
	check(wall.hp == 3 and wall.collidable,"Repeated punches never damage ordinary breakable walls")
	if not E.TYPES.has("hidden_wall"):
		check(false,"Hidden walls can be authored and directly revealed")
	else:
		check_hidden_walls()
	check(not InputMap.has_action("punch") and Game.DEFAULT_KEYS.attack == KEY_X and Game.DEFAULT_KEYS.dash == KEY_A,"Fist and sword share the attack button: X on the keyboard, dash on A")
	battle([])
	p().attack_buf = 0
	var swings := 0
	for i in 120:  # mash the button every 5 frames for 2 s: one attack per 0.25 s cooldown, none dropped
		if i % 5 == 0: p().attack_buf = p()._attack_press_buffer()
		var before: int = p().attack_log.size()
		p().attack_buf -= DT
		p().attack_cooldown_timer -= DT
		p()._attack_update(DT)
		swings += p().attack_log.size() - before
	check(swings == 8,"Mashing attack gives a steady rhythm (%d swings in 2 s)" % swings)
	if w: w.free()
	Game.adv = {}
	Game.adv_temp = false
	print("PUNCH: %d failure(s)" % fails)
	Game.quit_game(fails)

func check_hidden_walls() -> void:
	battle([{"t":"hidden_wall","x":84,"y":200,"w":8,"h":24}])
	var wall = targets()[0]
	swing()
	check(wall.revealed and wall.hp == 3 and wall.collidable,"Direct punch reveals a hidden wall without damaging it")
	check(Game.adv.revealed_walls.has(wall.id),"Hidden-wall discovery is saved in adventure progress")
	w._build()
	wall = targets()[0]
	check(wall.revealed,"Hidden-wall reveal survives room rebuild")
	Game.adv.abilities = ["attack"]
	for i in 3: swing()
	check(not wall.collidable,"The sword can still break a revealed hidden wall")
	battle([{"t":"breakwall","x":84,"y":200,"w":1,"h":24},{"t":"hidden_wall","x":86,"y":200,"w":8,"h":24},enemy(86)])
	wall = w.ents.filter(func(e): return e.d.t == "hidden_wall")[0]
	swing()
	check(not wall.revealed and w.ents.filter(func(e): return e.d.t.begins_with("enemy"))[0].hp == 2,"Punch cannot reveal walls or hit enemies through intervening rock")
	battle([{"t":"hidden_wall","x":84,"y":218,"w":8,"h":8}])
	wall = targets()[0]
	swing()
	check(not wall.revealed,"A nearby wall outside the fist remains hidden")
