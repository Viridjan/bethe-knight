extends RefCounted
## Attached rows share one width; geometry contains no labels or icons.
const Adventure := preload("res://scripts/adventure.gd")
static func layout(run: Dictionary, at := Vector2(16,16), limit := 360.0) -> Dictionary:
	var width := minf(limit,maxf(96.0,Adventure.stamina_max(run)*1.84))
	var energy := []
	var maximum := Adventure.stamina_max(run)
	var previous := 0.0
	for i in int(run.blocks):
		var capacity: float = Adventure.BASE_STAMINA if i==0 else Adventure.STAMINA_PER_BLOCK
		var left := roundf(previous/maximum*width)
		var right := roundf((previous+capacity)/maximum*width)
		energy.append({"rect":Rect2(at+Vector2(left,0),Vector2(right-left,14)),"fill":clampf((float(run.stamina)-previous)/capacity,0,1)})
		previous += capacity
	var stress := []
	for i in Adventure.Stress.blocks(run):
		var left := roundf(float(i)/Adventure.Stress.blocks(run)*width)
		var right := roundf(float(i+1)/Adventure.Stress.blocks(run)*width)
		stress.append({"rect":Rect2(at+Vector2(left,14),Vector2(right-left,10)),"fill":clampf(Adventure.Stress.value(run)/Adventure.Stress.BAR_CAPACITY-i,0,1)})
	return {"rect":Rect2(at,Vector2(width,24)),"stamina":energy,"stress":stress}

static func draw(ci: CanvasItem, run: Dictionary, energy_color: Color, limit := 360.0) -> void:
	var geometry := layout(run,Vector2(16,16),limit)
	ci.draw_rect(geometry.rect.grow(2),Color("080b16"))
	for row in ["stamina","stress"]:
		for segment in geometry[row]:
			var rect: Rect2 = segment.rect
			ci.draw_rect(rect,Color("172633") if row=="stamina" else Color("302239"))
			ci.draw_rect(Rect2(rect.position,Vector2(rect.size.x*segment.fill,rect.size.y)),energy_color if row=="stamina" else Color("b77bb7"))
			if rect.position.x>geometry.rect.position.x: ci.draw_line(rect.position,rect.position+Vector2(0,rect.size.y),Color("0b101c"),2)
