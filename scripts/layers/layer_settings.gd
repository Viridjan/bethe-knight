extends RefCounted
const MAX_LAYERS := 8
const MAIN := "main"

static func definitions(level: Dictionary) -> Dictionary:
	var base := level.duplicate(true)
	base.erase("layers")
	var result := {MAIN:base}
	for id in level.get("layers",{}): result[id]=level.layers[id]
	return result

static func validate(level: Dictionary) -> String:
	var layers=level.get("layers",{})
	if not layers is Dictionary or layers.size()>=MAX_LAYERS: return "At most eight room layers are allowed"
	for id in layers:
		if not id is String or id.is_empty() or id.length()>40 or id==MAIN or not id.is_valid_identifier(): return "Invalid layer ID"
		var data=layers[id]
		if not data is Dictionary or data.has("layers") or data.get("w")!=level.w or data.get("h")!=level.h: return "Layers must share room dimensions and cannot nest"
	var defs:=definitions(level)
	for id in defs:
		var exits := {}
		for entity in defs[id].get("entities",[]):
			if entity.get("t")!="layer_passage": continue
			var name=entity.get("id","")
			if not name is String or name.is_empty() or exits.has(name): return "Layer passages require unique IDs"
			exits[name]=true
			var destination=entity.get("to_layer","")
			if not destination is String or not defs.has(destination): return "Missing passage layer"
			var target=entity.get("to","")
			if not target is String or not defs[destination].get("entities",[]).any(func(e):return e.get("t")=="layer_passage" and e.get("id")==target): return "Missing layer passage destination"
	return ""
