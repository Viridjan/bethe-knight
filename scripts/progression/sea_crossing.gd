extends RefCounted
## A deterministic survival encounter; there is no Kraken health or attack button.
const WAVES := 8
const DECK := 130.0
const WIDTH := 72.0
var phase := "intro"
var timer := 1.5
var player := Vector2(160,DECK)
var vertical_speed := 0.0
var integrity := 3
var invulnerable := 0.0
var wave_index := 0
var wave_timer := 1.0
var warning := 0.0
var pending_high := false
var pending_side := 1
var tentacles: Array = []
var clock := 0.0
func player_box() -> Rect2:
	return Rect2(player-Vector2(4,12),Vector2(8,12))
func advance(dt: float, axis: float, jump: bool) -> void:
	dt = clampf(dt,0,0.05)
	clock += dt
	if phase in ["failed","done"]: return
	if phase=="intro":
		timer-=dt
		if timer<=0: phase="evade"
		return
	if phase=="wreck":
		timer-=dt
		if timer<=0: phase="done"
		return
	invulnerable=maxf(0,invulnerable-dt)
	player.x=clampf(player.x+axis*80*dt,52,268)
	if jump and player.y>=DECK: vertical_speed=-165
	vertical_speed+=500*dt
	player.y=minf(DECK,player.y+vertical_speed*dt)
	if player.y>=DECK: vertical_speed=0
	if warning>0:
		warning-=dt
		if warning<=0:
			tentacles.append({"x":-WIDTH if pending_side>0 else 320.0,"y":100.0 if pending_high else 122.0,"velocity":pending_side*300.0})
			wave_index+=1
			wave_timer=1.6
	else:
		wave_timer-=dt
		if wave_timer<=0 and wave_index<WAVES:
			pending_side=1 if wave_index%2==0 else -1
			pending_high=wave_index%3==2
			warning=1.0
	for index in range(tentacles.size()-1,-1,-1):
		var tentacle: Dictionary=tentacles[index]
		var old := Rect2(tentacle.x,tentacle.y,WIDTH,10)
		tentacle.x+=tentacle.velocity*dt
		var box := Rect2(tentacle.x,tentacle.y,WIDTH,10)
		if invulnerable<=0 and old.merge(box).intersects(player_box()):
			integrity-=1
			invulnerable=0.9
			if integrity<=0: phase="failed"
		if tentacle.x>400 or tentacle.x<-160: tentacles.remove_at(index)
	if phase=="evade" and wave_index>=WAVES and tentacles.is_empty() and warning<=0:
		phase="wreck"
		timer=3.0
