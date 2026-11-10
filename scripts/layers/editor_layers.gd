extends RefCounted
## Edits one plane with the ordinary room tools, serializes the complete room as one file.
const Settings := preload("res://scripts/layers/layer_settings.gd")
var editor
var documents := {}
var active := "main"
var saved := {}
var picker: OptionButton

func _init(owner) -> void:
	editor=owner
	load_document(editor.level)
	saved=pack().duplicate(true)

func load_document(data: Dictionary) -> void:
	var document:=data.duplicate(true)
	active=str(document.get("_editor_layer","main"))
	document.erase("_editor_layer")
	documents=Settings.definitions(document)
	if not documents.has(active):active="main"
	editor.level=documents[active]
	refresh_picker()

func pack() -> Dictionary:
	documents[active]=editor.level
	var result:Dictionary=documents.main.duplicate(true)
	result.erase("layers")
	if documents.size()>1:
		result.layers={}
		for id in documents:
			if id!="main":result.layers[id]=documents[id].duplicate(true)
	return result

func snapshot() -> Dictionary:
	var result:=pack()
	if documents.size()>1:result._editor_layer=active
	return result

func dirty() -> bool:return pack()!=saved

func select(id: String) -> bool:
	if not documents.has(id):return false
	documents[active]=editor.level
	active=id
	editor.level=documents[id]
	editor.saved_level=documents[id].duplicate(true) if not dirty() else {}
	editor.zip_pending=null
	editor.rect_start=null
	editor.sel=Rect2i()
	editor._sync_fields()
	editor.tile_layer.setup(editor.level.tiles,editor.level.w,editor.level.h,editor.level.get("environment",""))
	editor._refresh()
	refresh_picker()
	return true

func add(id: String) -> bool:
	if documents.size()>=Settings.MAX_LAYERS or id.is_empty() or not id.is_valid_identifier() or id.length()>40 or documents.has(id):return false
	editor._push_undo()
	var data=Game.new_level(id,editor.level.w,editor.level.h)
	# New planes start empty: the designer supplies their terrain and safe entry markers.
	data.tiles=[]
	for y in int(data.h):data.tiles.append("0".repeat(int(data.w)))
	data.entities=[]
	documents[id]=data
	select(id)
	return true

func controls() -> Control:
	var box:=VBoxContainer.new()
	box.add_child(Game.label("Room layer",16))
	picker=OptionButton.new()
	picker.tooltip_text="All planes stay loaded during play; passages choose the active plane."
	picker.item_selected.connect(func(i):select(picker.get_item_text(i)))
	box.add_child(picker)
	var add_button:=Game.button("+ Layer",_ask_add)
	add_button.tooltip_text="Add an empty retained interior plane, then paint terrain and place linked Layer Passages."
	box.add_child(add_button)
	refresh_picker()
	return box

func refresh_picker() -> void:
	if picker==null:return
	picker.clear()
	for id in documents:picker.add_item(id)
	picker.select(documents.keys().find(active))

func _ask_add() -> void:
	var dialog:=ConfirmationDialog.new()
	dialog.title="New room layer"
	dialog.dialog_hide_on_ok=false
	var box:=VBoxContainer.new()
	var field:=LineEdit.new()
	field.placeholder_text="Layer ID, e.g. cave"
	field.custom_minimum_size.x=340
	box.add_child(field)
	var error:=Label.new()
	box.add_child(error)
	dialog.add_child(box)
	dialog.confirmed.connect(func():
		if add(field.text.strip_edges()):dialog.hide()
		else:error.text="Use a unique identifier; maximum eight layers.")
	dialog.visibility_changed.connect(func():
		if not dialog.visible:dialog.queue_free())
	editor.add_child(dialog)
	dialog.popup_centered()
	field.grab_focus()

func resized(active_data: Dictionary, bounds: Rect2i) -> Dictionary:
	var defs:=Settings.definitions(pack())
	defs[active]=active_data
	for id in defs:
		if id==active:continue
		var data:Dictionary=defs[id]
		var rows:=[]
		for y in bounds.size.y:
			var row:=""
			for x in bounds.size.x:
				var old:=Vector2i(x,y)+bounds.position
				row+=str(data.tiles[old.y][old.x]) if Rect2i(0,0,data.w,data.h).has_point(old) else "0"
			rows.append(row)
		var fit:Dictionary=editor._fit_resize_entities(data.entities,bounds)
		if fit.has("error"):return fit
		data.tiles=rows;data.entities=fit.entities;data.w=bounds.size.x;data.h=bounds.size.y
	var result:Dictionary=defs.main
	result.layers={}
	for id in defs:
		if id!="main":result.layers[id]=defs[id]
	var error:=Settings.validate(result)
	if not error.is_empty():return {"error":"Resize would break a layer passage: "+error}
	return result
