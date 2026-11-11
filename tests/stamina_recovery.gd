extends Node
const Adventure := preload("res://scripts/adventure.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	for energy in [0, 17, 27, 44]:
		for stress in [0, 50]:
			var run := Adventure.new_run({"start":"test"})
			run.blocks = 4
			run.stamina = energy
			run.stress = stress
			var elapsed := 0
			var whole := true
			for tick in 12000:
				elapsed=tick+1
				Adventure.regen_stamina(run,tick)
				whole=whole and run.stamina is int and run.stress is int
				if run.stamina == Adventure.stamina_max(run): break
			print("Refill from %d at stress %d: %d ticks (%s seconds)"%[energy,stress,elapsed,elapsed/5.0])
			check(whole,"Every regeneration update retains integer stamina and stress")
			check(run.stamina == Adventure.stamina_max(run),"Empty upper bars recover fully from %s energy at %s stress" % [energy,stress])
			Adventure.regen_stamina(run,0)
			check(run.stamina == Adventure.stamina_max(run),"Regeneration never exceeds owned capacity")
	var single := Adventure.new_run({"start":"test"})
	single.stamina = 0
	for tick in 200:Adventure.regen_stamina(single,tick)
	check(single.stamina == Adventure.BASE_STAMINA,"A single-bar run still caps at the base capacity")
	var shares: Array = range(60).map(func(f): return Adventure.GameTick.share(8,f,Adventure.GameTick.FRAMES_PER_SECOND))
	var gaps := []
	for f in 60:
		if shares[f] == 1: gaps.append(f)
	check(shares.max() == 1 and gaps.size() == 8 and range(1,8).all(func(i): return gaps[i]-gaps[i-1] in [7,8]),"Per-frame regeneration adds single points at an even pace (8 per second)")
	print("STAMINA RECOVERY: %d failure(s)" % failures)
	Game.quit_game(failures)
