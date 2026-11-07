extends RefCounted
## Persistent item/quest transactions. No scenes or map-file dependencies.
const VERSION := 1
const QUEST := "lighthouse_crystals"
const CRYSTAL := "crystal"
const REQUIRED := 3
const MAX_COUNT := 9999

static func ensure(run: Dictionary) -> void:
	for key in ["items","quests"]:
		if not run.get(key) is Dictionary: run[key] = {}
	for key in ["events","taken","abilities"]:
		if not run.get(key) is Array: run[key] = []
	run.story_version = VERSION

static func normalize(run: Dictionary) -> void:
	ensure(run)
	var items := {}
	for id in run.items:
		var value = run.items[id]
		if id is String and not id.is_empty() and id.length()<=64 and (value is float or value is int) and is_finite(float(value)) and value>0 and value==floorf(value):
			items[id] = mini(int(value),MAX_COUNT)
	run.items = items
	var quests := {}
	for id in run.quests:
		if id is String and run.quests[id] in ["started","completed"]: quests[id]=run.quests[id]
	run.quests = quests
	run.events = run.events.filter(func(id): return id is String)

static func count(run: Dictionary, id: String) -> int:
	return int(run.get("items",{}).get(id,0))

static func has_event(run: Dictionary, id: String) -> bool:
	return id in run.get("events",[])

static func set_event(run: Dictionary, id: String) -> void:
	ensure(run)
	if not id.is_empty() and not run.events.has(id): run.events.append(id)

static func give_item(run: Dictionary, id: String, amount: int) -> bool:
	ensure(run)
	if id.is_empty() or id.length()>64 or amount<=0 or count(run,id)+amount>MAX_COUNT: return false
	run.items[id] = count(run,id)+amount
	return true

# Preflight the entire exchange before any mutation. Keeping keys is supported.
static func transact(run: Dictionary, needs: Dictionary, consume: bool, rewards: Dictionary, flags: Array = []) -> bool:
	for id in needs:
		if not id is String or id.is_empty() or id.length()>64 or not (needs[id] is int or needs[id] is float) or needs[id]<0 or needs[id]!=floorf(needs[id]) or count(run,id)<needs[id]: return false
	for id in rewards:
		if not id is String or id.is_empty() or id.length()>64 or not (rewards[id] is int or rewards[id] is float) or rewards[id]<0 or rewards[id]!=floorf(rewards[id]): return false
		var remaining := count(run,id)-(int(needs.get(id,0)) if consume else 0)
		if remaining+rewards[id]>MAX_COUNT: return false
	ensure(run)
	if consume:
		for id in needs:
			run.items[id] = count(run,id)-int(needs[id])
			if run.items[id]==0: run.items.erase(id)
	for id in rewards:
		if rewards[id]>0: run.items[id] = count(run,id)+int(rewards[id])
	for flag in flags:
		if flag is String: set_event(run,flag)
	return true

static func lighthouse_talk(run: Dictionary) -> String:
	ensure(run)
	if run.quests.get(QUEST,"") == "completed":
		return "The three crystals are safe. The boat is yours." if not has_event(run,"boat_lost") else "You survived the crossing. The boat was lost at sea."
	if run.quests.get(QUEST,"") != "started":
		run.quests[QUEST] = "started"
		if not run.abilities.has("attack"): run.abilities.append("attack")
		return "Take this sword. Recover three crystals from the old ruins below the lighthouse. Their entrance is open, but the sword can break the barriers inside. Bring all three back and you may sail."
	if count(run,CRYSTAL)<REQUIRED:
		return "You have %d of %d crystals. Use the sword to break the old barriers in the ruins." % [count(run,CRYSTAL),REQUIRED]
	if transact(run,{CRYSTAL:REQUIRED},true,{},["boat_unlocked"]):
		run.quests[QUEST] = "completed"
		return "All three crystals! The boat is ready. Speak to its captain to cross the sea."
	return "Bring me the three crystals."

static func collect_crystal(run: Dictionary, key: String) -> bool:
	ensure(run)
	if run.quests.get(QUEST,"") != "started" or run.taken.has(key) or count(run,CRYSTAL)>=REQUIRED: return false
	if not give_item(run,CRYSTAL,1): return false
	run.taken.append(key)
	return true

static func can_sail(run: Dictionary) -> bool:
	return has_event(run,"boat_unlocked") and not has_event(run,"boat_lost")

static func finish_crossing(run: Dictionary) -> void:
	set_event(run,"sea_crossed")
	set_event(run,"boat_lost")
