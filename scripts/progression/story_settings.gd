extends RefCounted
const PICKUPS := ["quest_crystal","stress_block","item_pickup"]
const PEOPLE := ["lighthouse_keeper","dialogue_npc"]
static func items(value) -> bool:
	if not value is Dictionary or value.size()>64:return false
	for id in value:
		if not id is String or id.is_empty() or id.length()>64:return false
		var amount=value[id]
		if not (amount is int or amount is float) or not is_finite(float(amount)) or amount<0 or amount>9999 or amount!=floorf(amount):return false
	return true
static func validate(data: Dictionary) -> String:
	if data.t in PICKUPS+PEOPLE+["boat","dead_skeleton"]:
		for field in ["name","item","once_event","locked_text","repeat_text"]:
			if data.has(field) and (not data[field] is String or data[field].length()>500):return "Invalid story text: "+field
	if data.t=="item_pickup":
		var amount=data.get("amount",1)
		if not items({"item":amount}) or amount<1:return "Item amount must be 1 to 9999"
	if data.t=="dialogue_npc":
		for field in ["requires_items","give_items"]:
			if not items(data.get(field,{})):return "Invalid item transaction"
		for field in ["consume_items","repeatable"]:
			if data.has(field) and not data[field] is bool:return "Invalid transaction option"
		for field in ["set_events","requires_events"]:
			var value=data.get(field,[])
			if not value is Array or value.size()>64 or value.any(func(id):return not id is String or id.is_empty() or id.length()>100):return "Invalid event list"
	return ""
