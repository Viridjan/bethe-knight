extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func _ready() -> void:
	if not ResourceLoader.exists("res://scripts/progression/sea_crossing.gd"):
		check(false,"Playable tentacle-dodging crossing controller exists")
	else:
		var Model = load("res://scripts/progression/sea_crossing.gd")
		var sea = Model.new()
		sea.phase="evade"
		sea.tentacles=[{"x":120.0,"y":122.0,"velocity":300.0}]
		sea.advance(1.0/60,0,false)
		check(sea.integrity==2,"A low rushing tentacle damages the boat when Be stays on deck")
		sea=Model.new();sea.phase="evade";sea.player.y=98
		sea.tentacles=[{"x":120.0,"y":122.0,"velocity":300.0}]
		sea.advance(1.0/60,0,false)
		check(sea.integrity==3,"Jumping above a low tentacle avoids contact")
		sea=Model.new();sea.phase="evade"
		sea.tentacles=[{"x":120.0,"y":100.0,"velocity":300.0}]
		sea.advance(1.0/60,0,false)
		check(sea.integrity==3,"Remaining on deck avoids an overhead tentacle")
		sea=Model.new();sea.phase="evade";sea.integrity=1
		sea.tentacles=[{"x":120.0,"y":122.0,"velocity":300.0}]
		sea.advance(1.0/60,0,false)
		check(sea.phase=="failed","Failed dodge sequence offers a retry rather than arrival")
		sea=Model.new();sea.phase="evade";sea.wave_index=Model.WAVES;sea.wave_timer=0
		sea.advance(1.0/60,0,false)
		check(sea.phase=="wreck","Surviving all waves still destroys the boat")
		for i in 240: sea.advance(1.0/60,0,false)
		check(sea.phase=="done","Shipwreck completes with a washed-ashore arrival")
	print("SEA CROSSING: %d failure(s)"%failures)
	Game.quit_game(failures)
