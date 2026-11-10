extends "res://tests/test_runner.gd"

func _ready() -> void:
	var bounds := Rect2i(0, 0, 480, 240)
	for blocked_sides in [0, 1, 2]:
		var wall: Array = [[6, 12], [6, 13]] if blocked_sides == 2 else []
		for x in 60: wall.append([x, 14])  # floor under the parent: it splits on landing, not in the air
		make_world([], wall)
		var effects = E.AttackEffects.new()
		var at := Vector2(200, 60) if blocked_sides == 0 else Vector2(25, 60)
		effects.spawn(at, Vector2(0, -1), {"split": true})
		var events: Array = effects.update(DT, w.collide_solid, Rect2i(), bounds)
		check(events.is_empty() and effects.projectiles.size() == 1 and effects.projectiles[0].split, "A splitting log does not split at its apex")
		effects.projectiles[0].position.y = 106
		effects.projectiles[0].velocity = Vector2(0, 60)
		events = effects.update(DT, w.collide_solid, Rect2i(), bounds)
		check(events.all(func(event): return event.event != "floor_impact"), "The parent log leaves no spikes of its own")
		var blocked: Array = events.filter(func(event): return event.event == "split_blocked")
		check(blocked.size() == blocked_sides, "Each blocked split child emits one explicit event (%d blocked)" % blocked_sides)
		check(effects.projectiles.size() == 2 - blocked_sides, "Only valid split children are placed (%d blocked)" % blocked_sides)
		check(effects.projectiles.all(func(child): return not child.split and w.collide_solid(child.box()) == null), "Split children never start in solid terrain or split recursively")
		var later: Array = effects.update(DT, w.collide_solid, Rect2i(), bounds)
		check(later.all(func(event): return event.event != "split_blocked"), "Blocked-spawn notifications are not repeated next tick")
	# Test the actual encounter consumer, not just the effect's event output.
	make_world([{"t": "boss_ape", "x": 200, "y": 192}])
	var ape = w.ents.filter(func(ent): return ent is E.Ape)[0]
	ape.effects.spawn(Vector2(25, 218), Vector2(0, 60), {"split": true})
	var before: int = w.parts.size()
	ape._update_logs(DT)
	check(w.parts.size() > before, "The Ape turns a blocked split into visible burst feedback")
	check(w.spawn_queue.is_empty(), "A blocked child does not create a floor-spike patch")
	await get_tree().process_frame
	print("APE SPLIT SPAWNS: %d failure(s)" % fails)
	Game.quit_game(fails)
