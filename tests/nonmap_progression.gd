extends Node
const Adventure := preload("res://scripts/adventure.gd")
var Stress = load("res://scripts/progression/stress.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	if not ResourceLoader.exists("res://scripts/progression/story_progress.gd"):
		check(false,"Persistent quest and inventory service exists")
		Game.quit_game(failures)
		return
	else:
		var story = load("res://scripts/progression/story_progress.gd")
		var world := {"start":"test","rooms":{"test":{}}}
		var run := Adventure.new_run(world)
		check(not story.can_sail(run),"Boat is quest-locked initially")
		story.lighthouse_talk(run)
		check(run.abilities.has("attack") and run.quests.get("lighthouse_crystals") == "started","Lighthouse quest grants sword and records its stage")
		for i in 3:
			check(story.collect_crystal(run,"crystal_%d"%i),"A unique quest crystal is collected")
		check(not story.collect_crystal(run,"crystal_0") and story.count(run,"crystal") == 3,"Crystal collection cannot duplicate on reload or interaction")
		story.lighthouse_talk(run)
		check(story.can_sail(run) and story.count(run,"crystal") == 0 and run.quests.lighthouse_crystals == "completed","Turning in exactly three crystals unlocks boat and consumes items once")
		story.lighthouse_talk(run)
		check(story.count(run,"crystal") == 0 and not story.collect_crystal(run,"fourth"),"Completed quest cannot turn in or collect again")
		check(not story.transact(run,{"red_key":1},true,{"gem":1},["door_open"]),"Missing key refuses an entire transaction")
		story.give_item(run,"red_key",1)
		check(story.transact(run,{"red_key":1},true,{"gem":1},["door_open"]) and story.count(run,"red_key")==0 and story.count(run,"gem")==1,"Key consumption, reward and event commit together")
		var restored := Adventure.restore_run(world,JSON.parse_string(JSON.stringify(run)))
		check(story.can_sail(restored) and story.count(restored,"gem")==1 and restored.events.has("door_open"),"Quest, inventory and events survive real JSON save round-trip")
		story.finish_crossing(restored)
		check(not story.can_sail(restored) and restored.events.has("sea_crossed") and restored.events.has("boat_lost"),"Shipwreck persists one completed crossing and no reusable boat")
	for bars in [1,4,5,8]:
		var run := {"stamina":10.0,"stress_blocks":bars,"stress":0.0}
		for full in bars+1:
			run.stress=50.0*full
			check(is_equal_approx(Stress.recovery_multiplier(run),1.0-0.3*full/bars),"Stress penalty follows completed blocks / owned blocks")
			run.stress=mini(full*50+49,bars*50)
			check(is_equal_approx(Stress.recovery_multiplier(run),1.0-0.3*full/bars),"Partial stress blocks add no penalty")
	print("NONMAP PROGRESSION: %d failure(s)"%failures)
	Game.quit_game(failures)
