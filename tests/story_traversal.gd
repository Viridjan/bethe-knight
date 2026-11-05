extends "res://tests/test_runner.gd"
func _ready() -> void:
	if not has_method("_route_only_world"):
		check(false,"Traversal fixture removes bosses and event entities")
	else:
		var source := {"start":"a","rooms":{"a":{"pos":Vector2i.ZERO,"level":{"w":12,"h":8,"tiles":["000000000000"],"entities":[{"t":"boss_ape"},{"t":"boss_guardian"},{"t":"boss_gate"},{"t":"ape_chase"},{"t":"auto_walk"},{"t":"trigger_zone"},{"t":"pressure_plate"},{"t":"rockfall"},{"t":"note","sound":"roar"},{"t":"spawn"},{"t":"jumpthru"},{"t":"water"},{"t":"spikes_up"}]},"variants":[{"level":{"entities":[{"t":"boss_ape"}]}}]}}}
		var route: Dictionary = call("_route_only_world",source)
		check(route.rooms.a.level.entities.map(func(e): return e.t) == ["spawn","jumpthru","water","spikes_up"],"Route fixture keeps terrain interactions while removing fights and scripted events")
		check(source.rooms.a.level.entities.size() == 13 and source.rooms.a.variants.size() == 1,"Traversal exclusions do not change source story or encounter fixtures")
		check(route.rooms.a.variants.is_empty() and route.rooms.a.level.tiles == source.rooms.a.level.tiles,"Traversal retains authored tiles and bypasses conditional encounter variants")
	print("STORY TRAVERSAL: %d failure(s)" % fails)
	Game.quit_game(fails)
