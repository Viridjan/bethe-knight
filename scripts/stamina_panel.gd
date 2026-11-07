extends Control
## F3: everything about adventure stamina, live. What raises it, what lowers it, the rule values, a 10 s graph
## (with block boundaries) and the last changes with their cause. Reads only; World records the one-off changes
## (World.stamina_event) and the continuous ones (regen, water) are shown as the current rate.
const Adventure := preload("res://scripts/adventure.gd")
const Player := preload("res://scripts/player.gd")
const W := 430.0
const HISTORY := 10.0  # seconds of graph
var world
var history: Array = []  # [time, stamina]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)  # offsets from the top-right corner (position would be from the left)
	offset_left = -W - 12
	offset_right = -12
	offset_top = 40
	offset_bottom = 40 + 670

func _process(_dt: float) -> void:
	if world == null or not world.adventure():
		return
	history.append([world.time, float(Game.adv.stamina)])
	while history.size() > 2 and world.time - history[0][0] > HISTORY:
		history.pop_front()
	queue_redraw()

# Current continuous rate and why, using the same capacity/stress rules as gameplay.
func rate() -> Array:
	var run: Dictionary = Game.adv
	if world.player.dead:
		return [0.0, "dead"]
	var heat: float = world.heat_drain()
	if heat > 0:
		return [-heat - (Adventure.WATER_DRAIN if world.in_water() else 0.0), "heat: drain (no regen)"]
	if world.player.stun_blocks_regen():
		return [0.0, "stunned: no regen"]
	if world.player.state == Player.ST_CLIMB:
		return [0.0, "climbing: no regen"]
	if world.in_water():
		return [-Adventure.WATER_DRAIN, "in water: drain (no regen)"]
	var top := regen_top(run)
	if run.stamina < top:
		var k := Adventure.regen_factor(run.stamina / top) * Adventure.Stress.recovery_multiplier(run)
		return [Adventure.STAMINA_REGEN_MAX * k, "regen x%.2f to %.0f (full capacity)" % [k, top]]
	return [0.0, "idle (all stamina bars full)"]

# Empty bars remain recoverable; owned blocks alone determine the target.
static func regen_top(run: Dictionary) -> float:
	return Adventure.stamina_max(run)

func _line(font: Font, y: float, s: String, col := Color.WHITE) -> float:
	draw_multiline_string(font, Vector2(12, y), s, HORIZONTAL_ALIGNMENT_LEFT, W - 24, 15, -1, col)  # wraps, never cut off
	var lines := maxi(1, roundi(font.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, W - 24, 15).y / font.get_height(15)))
	return y + 19 * lines

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.09, 0.86))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.49, 0.94, 0.75, 0.6), false, 1.0)
	var font := get_theme_font("font", "Label")
	var y := 22.0
	if world == null or not world.adventure():
		_line(font, y, "Stamina (F3): only in the adventure", Color("ffd84a"))
		return
	var run: Dictionary = Game.adv
	var mx := Adventure.stamina_max(run)
	var r := rate()
	y = _line(font, y, "STAMINA (F3)   %.1f / %.0f   (%d%%)" % [run.stamina, mx, int(100.0 * run.stamina / mx)], Color("7cf0c0"))
	y = _line(font, y, "blocks %d = base %.0f + %d x %.0f" % [run.blocks, Adventure.BASE_STAMINA, run.blocks - 1, Adventure.STAMINA_PER_BLOCK])
	y = _line(font, y, "now: %+.1f/s  %s" % [r[0], r[1]], Color("ffd84a") if r[0] < 0 else Color("9fe0ff"))
	y += 6
	y = _line(font, y, "GAIN", Color("7cf0c0"))
	y = _line(font, y, "• regen: %.0f/s empty, %.0f/s at half, %.0f/s full (out of water, not climbing)" % [Adventure.STAMINA_REGEN_EMPTY, Adventure.STAMINA_REGEN_MAX, Adventure.STAMINA_REGEN_FULL])
	y = _line(font, y, "• stamina block: +%.0f capacity and stamina (once each)" % Adventure.STAMINA_PER_BLOCK)
	y = _line(font, y, "• stamina orb: refill to max, back after 2.5 s")
	y = _line(font, y, "LOSS", Color("ff8a6a"))
	y = _line(font, y, "• jump / wall jump: -%.0f, needs %.0f (swimming free) · can jump now: %s" % [Player.JUMP_STAMINA, Player.JUMP_STAMINA, "yes" if run.stamina >= Player.JUMP_STAMINA else "NO"])
	y = _line(font, y, "• water: -%.0f/s, drown at 0" % Adventure.WATER_DRAIN)
	y = _line(font, y, "• respawn: base bar refilled to %.0f (a hit is always a death)" % Adventure.BASE_STAMINA, Color(0.7, 0.7, 0.7))
	y = _line(font, y, "• hair turns grey below 20%% (%.1f)" % (0.2 * mx), Color(0.7, 0.7, 0.7))
	# graph: last HISTORY s, max at the top, dashed lines at block boundaries
	y += 4
	var g := Rect2(12, y, W - 24, 110)
	draw_rect(g, Color(0, 0, 0, 0.5))
	var top := maxf(mx, 1.0)
	for e in history:
		top = maxf(top, e[1])
	var bound := Adventure.BASE_STAMINA
	while bound < top:
		var by := g.end.y - g.size.y * bound / top
		draw_dashed_line(Vector2(g.position.x, by), Vector2(g.end.x, by), Color(1, 1, 1, 0.25), 1.0, 4.0)
		bound += Adventure.STAMINA_PER_BLOCK
	var my := g.end.y - g.size.y * mx / top
	draw_line(Vector2(g.position.x, my), Vector2(g.end.x, my), Color(0.49, 0.94, 0.75, 0.6), 1.0)
	if history.size() > 1:
		var pts := PackedVector2Array()
		for e in history:
			var px: float = g.end.x - g.size.x * (world.time - e[0]) / HISTORY
			pts.append(Vector2(px, g.end.y - g.size.y * e[1] / top))
		draw_polyline(pts, Color("ffd84a"), 2.0)
	draw_string(font, g.position + Vector2(4, 14), "last %ds" % int(HISTORY), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.6))
	y = g.end.y + 20
	y = _line(font, y, "GRAPH", Color("9fe0ff"))
	y = _line(font, y, "• yellow line: your stamina over the last %d s (right edge = now)" % int(HISTORY), Color("ffd84a"))
	y = _line(font, y, "• green line: maximum (%.0f)" % mx, Color(0.49, 0.94, 0.75))
	y = _line(font, y, "• dashed lines: where one block ends and the next begins", Color(0.75, 0.75, 0.75))
	y += 6
	y = _line(font, y, "RECAP (since the level started)", Color("9fe0ff"))
	var spent := 0.0
	var gained := 0.0
	for why in world.stamina_totals:
		var t: Array = world.stamina_totals[why]
		var n := "%5.1fs" % t[0] if why in ["regen", "water"] else "%4dx " % int(t[0])
		y = _line(font, y, "  %s  %+7.1f  %s" % [n, t[1], why], Color("7cf0c0") if t[1] >= 0 else Color("ff8a6a"))
		if t[1] < 0:
			spent -= t[1]
		else:
			gained += t[1]
	y = _line(font, y, "  spent %.1f, gained %.1f" % [spent, gained])
