extends Node
const Adventure := preload("res://scripts/adventure.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	for energy in [0.0, 17.0, 27.0, 44.0]:
		for stress in [0.0, 250.0]:
			var run := Adventure.new_run({"start":"test"})
			run.blocks = 4
			run.stamina = energy
			run.stress = stress
			for tick in 12000:
				Adventure.regen_stamina(run,1.0/60.0)
				if run.stamina == Adventure.stamina_max(run): break
			check(run.stamina == Adventure.stamina_max(run),"Empty upper bars recover fully from %s energy at %s stress" % [energy,stress])
			Adventure.regen_stamina(run,1000.0)
			check(run.stamina == Adventure.stamina_max(run),"Regeneration never exceeds owned capacity")
	var single := Adventure.new_run({"start":"test"})
	single.stamina = 0.0
	Adventure.regen_stamina(single,1000.0)
	check(single.stamina == Adventure.BASE_STAMINA,"A single-bar run still caps at the base capacity")
	print("STAMINA RECOVERY: %d failure(s)" % failures)
	Game.quit_game(failures)
