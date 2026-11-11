extends RefCounted
## Original cosmetic pixel artwork. This module never creates gameplay entities.
const EnvironmentArt := preload("res://scripts/environment_art.gd")
const BACKDROPS := ["auto","outdoors","cave","deep_cave","sand_cave","volcanic_cave","house","tower","ruins","underwater","flooded_ruins","canopy","marsh","plateau"]
const DEFAULTS := {"cavern":"cave","cavern_deep":"deep_cave","volcanic_cave":"volcanic_cave","marsh":"marsh","rocky_plateau":"plateau","ruins":"ruins"}
const PALETTES := {
	"cave":["172b32","263d43","38535a","55716c","749184"],
	"deep_cave":["111c30","1c2c43","2c4057","425a71","6a8192"],
	"sand_cave":["302825","493b32","64503e","8b7353","b69c71"],
	"volcanic_cave":["241f29","342b33","4a3940","685052","98644f"],
	"house":["292632","40333a","59453f","795d4b","a08060"],
	"tower":["202a35","303d48","465563","657683","9b9b87"],
	"ruins":["1c3036","2a4247","3c5757","59736b","879382"],
	"underwater":["102d3d","174355","245c68","3b7880","72aaa2"],
	"flooded_ruins":["142c3c","213e50","305668","477483","719994"],
	"canopy":["182d2b","263f34","3c5140","5c6b49","8d8a5c"],
	"marsh":["243840","314d4e","45665c","628172","8da087"],
	"plateau":["293542","3b4b56","52636b","72818a","a4a79a"]}
static var cache := {}

static func resolve(environment: String, backdrop := "") -> String:
	return DEFAULTS.get(environment,"outdoors") if backdrop in ["","auto"] else backdrop

static func box(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var area := Rect2i(x,y,w,h).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if area.has_area(): image.fill_rect(area,color)

static func line(image: Image, a: Vector2i, b: Vector2i, color: Color) -> void:
	var count := maxi(absi(b.x-a.x),absi(b.y-a.y))
	for i in count+1:
		var at := Vector2i(Vector2(a).lerp(Vector2(b),float(i)/maxi(1,count)).round())
		box(image,at.x,at.y,1,1,color)

static func background_image(style: String, foreground: bool) -> Image:
	var image := Image.create(320,180,false,Image.FORMAT_RGBA8)
	var palette: Array = PALETTES.get(style,PALETTES.cave)
	var dark := Color(palette[0]); var rear := Color(palette[1])
	var middle := Color(palette[2]); var edge := Color(palette[3]); var accent := Color(palette[4])
	image.fill(Color.TRANSPARENT if foreground else dark)
	if not foreground:
		# Quiet stepped value bands; no sky or horizon in enclosed rooms.
		for band in 6: box(image,0,band*30,320,30,dark.lerp(rear,float(band)/10))
	var far := rear if foreground else middle.darkened(0.12)
	match style:
		"house":
			if not foreground:
				for y in range(16,180,18):
					for x in range(-8,320,32):
						box(image,x+(8 if y%36==16 else 0),y,28,15,rear)
				for x in [20,112,216,302]:
					box(image,x,0,7,180,middle);box(image,x,0,2,180,edge.darkened(0.2))
				box(image,0,18,320,7,middle);box(image,0,25,320,2,edge.darkened(0.25))
				# Inset window, shelves and a quiet cupboard behind the walkable plane.
				box(image,151,48,42,53,dark);box(image,155,52,34,44,middle)
				box(image,157,54,30,39,accent.darkened(0.18));box(image,170,52,3,44,rear)
				box(image,155,74,34,3,rear);box(image,149,98,46,4,edge.darkened(0.2))
				for x in [39,235]:
					box(image,x,106,47,4,middle);box(image,x+5,96,9,10,edge.darkened(0.3))
					box(image,x+20,99,12,7,accent.darkened(0.4));box(image,x+6,110,3,9,rear)
				box(image,241,134,45,46,middle);box(image,244,137,39,40,rear)
				box(image,261,137,2,40,middle)
			else:
				for x in [5,301]:box(image,x,0,9,180,far)
				box(image,0,5,320,5,far)
		"tower","ruins","flooded_ruins":
			if not foreground:
				for y in range(0,180,14):
					for x in range(-24,320,38):
						box(image,x+(19 if y%28 else 0),y,36,12,rear)
			for i in 5:
				var x := i*77-5+(14 if foreground else 0)
				box(image,x,43,11,137,far);box(image,x-4,39,19,7,far)
				box(image,x+11,29,10,7,far);box(image,x+21,23,36,6,far)
				box(image,x+57,29,10,7,far);box(image,x+67,39,18,7,far)
				if not foreground:
					box(image,x+2,47,2,130,middle);box(image,x+26,51,24,65,dark)
					box(image,x+24,57,28,53,dark);box(image,x+36,51,2,65,rear)
					box(image,x+24,78,28,3,rear)
					for mark in 3:box(image,x+29,128+mark*8,14-mark*3,2,middle)
			if style=="flooded_ruins":
				for i in 25:
					var x := (i*47+13)%320; var y := (i*31+15)%180
					box(image,x,y,7+i%9,1,edge.darkened(0.35))
		"underwater":
			for i in 17:
				var x := (i*41+7)%320
				var top := 65+(i*17)%90
				box(image,x,top,3,180-top,far)
				for y in range(top+8,174,11):
					box(image,x-5,y,6,2,far);box(image,x+2,y+5,6,2,far)
			if not foreground:
				for i in 22:
					var x := (i*59+19)%320;var y := (i*29+9)%160
					box(image,x,y,10+i%12,1,middle)
					box(image,x+5,y+2,8,1,rear)
				for i in 5:
					var x := i*67+22; var y := 40+i%3*24
					box(image,x,y,7,2,middle);box(image,x-2,y-1,2,4,middle)
		"canopy","marsh":
			for i in 9:
				var x := i*43-15+(13 if foreground else 0)
				var width := 10+i%3*5
				box(image,x,0,width,180,far)
				for y in range(14+i%4*9,170,23):
					box(image,x+2,y,width-4,2,middle if not foreground else rear)
					box(image,x-8,y+5,10,4,far);box(image,x+width-2,y+14,11,4,far)
			if style=="canopy":
				for i in 20:
					var x := i*17
					box(image,x,0,19,12+i%4*5,far)
			else:
				for y in [115,142,164]:box(image,0,y,320,3,rear)
		"plateau":
			for i in 12:
				var x := i*31-15;var top := 74+(i*19)%65
				box(image,x,top,29,180-top,far);box(image,x+3,top-7,22,7,far)
				if not foreground:box(image,x+2,top+4,18,2,edge.darkened(0.35))
		_:
			# Mineral caves: distinct strata, pillars and closed stepped roof silhouettes.
			for i in 22:
				var x := i*17-8
				var ceiling := 10+(i*13)%28
				box(image,x,0,19,ceiling,far)
				box(image,x+4,ceiling,9,5+i%4*5,far)
				if i%4==0:box(image,x+5,ceiling+8,7,150-ceiling,far)
			if not foreground:
				for i in 26:
					var x := (i*43)%320;var y := 40+(i*23)%132
					box(image,x,y,16+i%17,2,middle)
					box(image,x+4,y+3,10+i%9,1,rear)
					if style=="sand_cave":box(image,x-3,y+5,23,2,middle.darkened(0.1))
					if style=="deep_cave" and i%3==0:
						line(image,Vector2i(x,y),Vector2i(x+7,y+7),edge.darkened(0.15))
					if style=="volcanic_cave" and i%4==0:
						box(image,x,y,2,11,accent.darkened(0.3));box(image,x+2,y+8,6,2,accent.darkened(0.3))
	return image

static func palette_for(environment: String) -> Array:
	var style := resolve(environment)
	if style=="outdoors":
		style = "house" if environment=="building" else ("underwater" if environment in ["sea","island_shore"] else ("canopy" if environment in ["forest","sky"] else "sand_cave"))
	return PALETTES.get(style,PALETTES.cave)

static func decoration_image(environment: String, mount: String) -> Image:
	var image := Image.create(128,24,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var palette := palette_for(environment)
	var shade := Color(palette[1]);var base := Color(palette[3]);var lit := Color(palette[4])
	for variant in 8:
		var x := variant*16
		if mount=="ceiling":
			if environment in ["building","temple","ruins"]:
				box(image,x,0,16,2,base)
				if variant%3==0:
					box(image,x+7,2,1,9,shade);box(image,x+4,11,7,8,shade)
					box(image,x+5,12,5,5,lit.darkened(0.12));box(image,x+4,19,7,1,base)
				elif variant%3==1:
					for y in range(2,20,3):box(image,x+7,y,2,2,base)
					box(image,x+3,19,10,2,shade)
				else:
					box(image,x+3,2,10,14,shade);box(image,x+4,2,8,11,base.darkened(0.25))
					box(image,x+4,14,3,4,base);box(image,x+10,14,2,2,base)
			elif environment in ["forest","marsh","sky"]:
				line(image,Vector2i(x+3,0),Vector2i(x+7,10),shade)
				line(image,Vector2i(x+7,10),Vector2i(x+5,21-variant%5),base)
				for y in [4,9,14]:
					box(image,x+4,y,5,2,base);box(image,x+8,y+2,5,2,lit.darkened(0.15))
				if variant%2==0:box(image,x+6,18,5,3,shade)
			else:
				for tooth in 3:
					var at := x+tooth*5
					var length := 7+(variant*3+tooth*7)%15
					box(image,at,0,5,length/2,shade)
					box(image,at+1,length/2,3,length/2,base)
					box(image,at+2,length-1,1,2,lit.darkened(0.2))
		else:
			match variant:
				0,1,2:
					for stem in 3:
						var at := x+3+stem*4;var top := 4+(variant*3+stem*5)%11
						line(image,Vector2i(at,23),Vector2i(at+stem-1,top),base)
						for y in range(top+3,22,5):
							box(image,at-3,y,4,2,shade);box(image,at+1,y+2,4,2,lit.darkened(0.2))
				3:
					box(image,x+3,18,11,6,shade);box(image,x+5,15,7,4,base)
					box(image,x+6,17,5,2,lit);box(image,x+9,20,4,2,base)
				4:
					for i in 4:
						box(image,x+2+i*3,12+i%2*3,3,12-i%2*3,base)
						box(image,x+3+i*3,14+i%2*3,1,2,shade)
				5:
					box(image,x+4,14,9,9,shade);box(image,x+3,15,11,5,base)
					box(image,x+6,10,5,4,base);box(image,x+6,11,5,1,lit)
				6:
					box(image,x+1,20,13,4,shade);box(image,x+3,17,9,4,base)
					box(image,x+5,15,5,3,lit.darkened(0.1))
				7:
					for i in 4:
						line(image,Vector2i(x+7,23),Vector2i(x+2+i*4,9+i%2*5),base)
						box(image,x+1+i*4,8+i%2*5,3,3,lit.darkened(0.15))
	return image

static func texture(style: String, foreground: bool) -> Texture2D:
	var key := style+str(foreground)
	if not cache.has(key):cache[key]=ImageTexture.create_from_image(background_image(style,foreground))
	return cache[key]

static func decorations(environment: String, mount: String) -> Texture2D:
	var key := environment+"/"+mount
	if not cache.has(key):cache[key]=ImageTexture.create_from_image(decoration_image(environment,mount))
	return cache[key]

static func theme_for(level: Dictionary) -> String:
	var style := resolve(level.get("environment",""),level.get("backdrop",""))
	if style=="house":return "building"
	if style=="tower":return "temple"
	if style in ["ruins","flooded_ruins"]:return "ruins"
	return level.get("environment","")

static func placements(level: Dictionary, region := Rect2i()) -> Array:
	var result := []
	var environment := theme_for(level)
	if environment not in EnvironmentArt.THEMES:return result
	var tiles: Array = level.tiles;var w:int=level.w;var h:int=level.h
	var cells := Rect2i(0,0,w,h)
	if region.has_area():cells=cells.intersection(region)
	var pools := []
	for entity in level.get("entities",[]):
		if entity.get("t","") in ["water","thick_water"]:pools.append(Rect2i(int(entity.x),int(entity.y),int(entity.w),int(entity.h)))
	for y in range(cells.position.y,cells.end.y):
		for x in range(cells.position.x,cells.end.x):
			if tiles[y].unicode_at(x)!=49:continue
			var code := absi(hash(Vector2i(x,y)))
			if y+3<h and x+1<w and code%5==0:
				var clear := true
				for dy in range(1,4):
					for dx in 2:
						if tiles[y+dy].unicode_at(x+dx)==49:clear=false
				if clear:result.append({"mount":"ceiling","cell":Vector2i(x,y),"rect":Rect2i(x*8,(y+1)*8,16,24),"variant":code/5%8,"environment":environment})
			if y<2 or x+1>=w or tiles[y-1].unicode_at(x)==49:continue
			var above := Rect2i(x*8,y*8-24,16,24)
			var wet := false
			for pool in pools:
				var part:Rect2i=pool.intersection(above)
				if part.has_area():
					wet=true
					if code%3==0:result.append({"mount":"underwater","cell":Vector2i(x,y),"rect":above,"clip":part,"variant":code/3%8,"environment":environment})
			if wet or code%11!=0:continue
			if tiles[y-1].unicode_at(x)==49 or tiles[y-2].unicode_at(x)==49 or tiles[y-1].unicode_at(x+1)==49 or tiles[y-2].unicode_at(x+1)==49:continue
			result.append({"mount":"floor","cell":Vector2i(x,y),"rect":Rect2i(x*8,y*8-16,16,16),"variant":code/11%8,"environment":environment})
	return result

static func draw_decorations(ci: CanvasItem, level: Dictionary, cells: Rect2i) -> void:
	for placed in placements(level,cells):
		var tex:Texture2D=EnvironmentArt.texture(placed.environment,"decorations") if placed.mount=="floor" else decorations(placed.environment,placed.mount)
		var dest:Rect2i=placed.get("clip",placed.rect)
		var source:=Rect2i(Vector2i(placed.variant*16,0)+dest.position-placed.rect.position,dest.size)
		ci.draw_texture_rect_region(tex,Rect2(dest),Rect2(source))

static func interior_bounds(level: Dictionary) -> Rect2:
	var area:=Rect2i()
	for y in int(level.h):
		for x in int(level.w):
			if level.tiles[y].unicode_at(x)==49:
				var tile:=Rect2i(x*8,y*8,8,8)
				area=area.merge(tile) if area.has_area() else tile
	return Rect2(area)

static func draw_background(ci: CanvasItem, view: Rect2, style: String, area: Rect2, clip: Rect2) -> void:
	var slack:=view.size*0.1
	var shift:=EnvironmentArt.parallax_shift(view,area)
	var dest:=Rect2(view.position-slack+(shift*0.12).floor(),view.size*1.2)
	EnvironmentArt._painting(ci,texture(style,false),dest,clip)
	EnvironmentArt._painting(ci,texture(style,true),Rect2(dest.position+(shift*0.2).floor(),dest.size),clip)
