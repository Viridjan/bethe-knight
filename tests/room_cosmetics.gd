extends "res://tests/nonmap_entities.gd"
func _ready() -> void:
	var invalid:=Game.new_level("invalid backdrop",40,20)
	invalid.backdrop="not_a_room_style"
	check(Game.validate_level(invalid).is_empty(),"Unknown cosmetic backdrop IDs are rejected")
	var path:="res://scripts/room_scenery_art.gd"
	if not ResourceLoader.exists(path):
		check(false,"Room cosmetics provide independent interior, ceiling and underwater artwork")
	else:
		var art=load(path)
		check(art.resolve("forest","house")=="house" and art.resolve("cavern_deep","")=="deep_cave","Interior backdrop can override terrain while caves select an enclosed default")
		var level:=Game.new_level("cosmetic fixture",40,20)
		level.environment="forest";level.backdrop="house"
		level.tiles[0]="1".repeat(40)
		level.entities.append({"t":"water","x":80,"y":112,"w":160,"h":32})
		var before:=level.duplicate(true)
		var placements:Array=art.placements(level)
		check(placements.any(func(p):return p.mount=="ceiling"),"Ceiling props are generated on actual roof undersides")
		check(placements.any(func(p):return p.mount=="underwater"),"Water regions receive their own cosmetic set")
		for placed in placements:
			if placed.mount=="ceiling":
				check(level.tiles[placed.cell.y][placed.cell.x]=="1" and placed.rect.position.y==(placed.cell.y+1)*8,"Hanging art is anchored to its source ceiling")
			if placed.mount=="underwater":
				check(Rect2i(80,112,160,32).encloses(placed.clip),"Underwater art is clipped inside the actual water region")
		check(level==before,"Cosmetic placement does not alter terrain, entities or resources")
		for style in art.BACKDROPS:
			if style in ["auto","outdoors"]:continue
			var image:Image=art.background_image(style,false)
			check(image.get_size()==Vector2i(320,180) and not image.is_invisible(),"Backdrop %s has native-size artwork"%style)
		var plain:=Game.new_level("plain interior",64,64)
		plain.backdrop="house"
		var terrain=load("res://scripts/tile_layer.gd").new()
		terrain.setup(plain.tiles,64,64,"",plain)
		check(terrain.mark_cell_dirty(Vector2i(31,29)).has(Vector2i(0,1)),"Interior ceiling edits invalidate props across chunk boundaries even without a terrain theme")
		terrain.free()
		Game.editor_level=level
		var editor=load("res://scripts/editor.gd").new();add_child(editor)
		await get_tree().process_frame
		if editor.get("backdrop_pick")==null:
			check(false,"Editor exposes a cosmetic backdrop selector")
		else:
			var selected:int=art.BACKDROPS.find("tower")
			editor.backdrop_pick.select(selected);editor.backdrop_pick.item_selected.emit(selected)
			check(editor.level.backdrop=="tower" and editor.level.environment=="forest" and not editor.level.has("heat_drain"),"Backdrop changes leave environment and heat behavior unchanged")
			editor._undo()
			check(editor.level.backdrop=="house","Cosmetic backdrop edits participate in undo")
		editor.free()
	Game.adv={}
	print("ROOM COSMETICS: %d failure(s)"%fails)
	Game.quit_game(fails)
