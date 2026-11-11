extends SceneTree
const Art := preload("res://scripts/room_scenery_art.gd")
func save(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
func _initialize() -> void:
	var manifest := {"source":"scripts/room_scenery_art.gd","provenance":"Original deterministic pixel art; no third-party images.","cosmetic_only":true,"backdrop_size":[320,180],"decoration_cell":[16,24],"decoration_columns":8,"backdrops":[],"themes":Art.EnvironmentArt.THEMES}
	var gallery := Image.create(960,720,false,Image.FORMAT_RGBA8)
	gallery.fill(Color("111725"))
	var index := 0
	for style in Art.BACKDROPS:
		if style in ["auto","outdoors"]:continue
		var path: String = "res://assets/room-scenery/backdrops/"+style+"/"
		var far := Art.background_image(style,false)
		var near := Art.background_image(style,true)
		save(far,path+"background.png");save(near,path+"foreground.png")
		var preview := far.duplicate()
		preview.blend_rect(near,Rect2i(0,0,320,180),Vector2i.ZERO)
		save(preview,path+"preview.png")
		gallery.blit_rect(preview,Rect2i(0,0,320,180),Vector2i(index%3,index/3)*Vector2i(320,180))
		manifest.backdrops.append(style)
		index+=1
	for theme in Art.EnvironmentArt.THEMES:
		for mount in ["ceiling","underwater"]:
			save(Art.decoration_image(theme,mount),"res://assets/room-scenery/"+theme+"/"+mount+".png")
	save(gallery,"res://assets/room-scenery/contact-sheet.png")
	var file := FileAccess.open("res://assets/room-scenery/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n");file.close()
	print("ROOM SCENERY EXPORT OK: %d backdrops, %d themed prop sets"%[index,Art.EnvironmentArt.THEMES.size()])
	quit(0)
