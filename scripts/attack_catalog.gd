extends RefCounted
# CSV source of truth for reusable attacks and per-enemy range bindings.
# Units: tiles (8 pixels), seconds, square tiles. Scores are estimates at reference conditions.
const PIXELS_PER_UNIT := 8.0
const REFERENCE_DISTANCE := 20.0
const TYPES := ["body movement", "melee", "ranged", "area", "movement"]  # movement: the move decides how long it lasts (charge, leaps, dive, slam)
const EXECUTABLE := {"enemy_monster": ["charge", "leap", "shoot", "lob"], "boss_ape": ["ape_retreat", "ape_throw", "ape_leap", "ape_scream"],
	"enemy_skree": ["dropwing_dive"], "enemy_bat": ["charge"], "enemy_skeleton": ["ossling_bone_throw"],
	"enemy_hornback": ["charge"], "enemy_cragjaw": ["cragjaw_leap"], "enemy_murkspore": ["shoot"]}
const NUMERIC := ["windup_s", "animation_s", "base_weight", "coverage_area_units2", "initial_speed_units_s", "multishot", "aimed_shot", "spread_deg", "max_distance_units", "shockwave_s", "follow_up_count", "follow_up_gap_s", "recovery_s", "horizontal_speed_units_s", "vertical_speed_units_s", "flight_time_s", "gravity_units_s2"]
static var _shared = null
var attack_path := "res://data/attacks.csv"
var assignment_path := "res://data/enemy_attacks.csv"
var attacks: Array = []
var assignments: Array = []
var attack_columns := PackedStringArray()
var assignment_columns := PackedStringArray()
var error := ""

static func shared():
	if _shared == null:
		_shared = load("res://scripts/attack_catalog.gd").new()
		if not _shared.reload(): push_error(_shared.error)
	return _shared

func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"error": "Cannot read " + path}
	var columns := file.get_csv_line()
	var rows: Array = []
	if columns.is_empty(): return {"error": "Missing CSV header: " + path}
	var unique := {}
	for column in columns:
		if column.is_empty() or unique.has(column): return {"error": "Duplicate or empty CSV column: " + path}
		unique[column] = true
	while not file.eof_reached():
		var cells := file.get_csv_line()
		if cells.size() == 1 and cells[0].is_empty(): continue
		if cells.size() != columns.size(): return {"error": "Wrong column count in " + path + " at row " + str(rows.size() + 2)}
		var row := {}
		for i in columns.size(): row[columns[i]] = cells[i]
		rows.append(row)
	return {"rows": rows, "columns": columns, "error": ""}

func reload() -> bool:
	var a := _read(attack_path)
	var b := _read(assignment_path)
	if not a.error.is_empty() or not b.error.is_empty():
		error = a.error if not a.error.is_empty() else b.error
		return false
	var previous := [attacks, assignments, attack_columns, assignment_columns]
	attacks = a.rows
	assignments = b.rows
	attack_columns = a.columns
	assignment_columns = b.columns
	error = validate()
	if not error.is_empty():
		attacks = previous[0]; assignments = previous[1]
		attack_columns = previous[2]; assignment_columns = previous[3]
		return false
	return true

# Where the last validate() failure is: {"table": "attacks" / "ranges" / "", "index": row, "field": column}.
var error_at := {"table": "", "index": -1, "field": ""}

func _fail(table: String, index: int, field: String, message: String) -> String:
	error_at = {"table": table, "index": index, "field": field}
	return message

func validate() -> String:
	error_at = {"table": "", "index": -1, "field": ""}
	for field in ["name", "codex_online_name", "type", "windup_s", "animation_s", "score"]:
		if field not in attack_columns: return "Missing attack column: " + field
	for field in ["enemy_id", "phase", "attack_name", "min_range_units", "max_range_units", "priority"]:
		if field not in assignment_columns: return "Missing range column: " + field
	var ids := {}
	for i in attacks.size():
		var row: Dictionary = attacks[i]
		var id := str(row.get("name", ""))
		if id.is_empty() or ids.has(id): return _fail("attacks", i, "name", "Empty or duplicate attack name: " + id)
		ids[id] = true
		if row.get("type", "") not in TYPES: return _fail("attacks", i, "type", "Invalid type for " + id)
		if row.get("status", "") == "implemented":
			var required := ["windup_s", "base_weight", "multishot", "recovery_s"]
			if row.type not in ["body movement", "movement"]: required.append("coverage_area_units2")  # body / movement attacks: the enemy's body
			if row.type in ["body movement", "melee", "area"]: required.append("animation_s")  # ranged / movement: the shot or the move sets the time
			if row.type in ["body movement", "ranged"]: required.append("initial_speed_units_s")
			for field in required:
				if str(row.get(field, "")).is_empty(): return _fail("attacks", i, field, "Implemented attack requires " + id + "." + field)
		for field in NUMERIC:
			var value := str(row.get(field, ""))
			if not value.is_empty() and (not value.is_valid_float() or not is_finite(float(value)) or float(value) < 0):
				return _fail("attacks", i, field, "Invalid nonnegative number: " + id + "." + field)
		for field in ["animation_s", "initial_speed_units_s", "flight_time_s", "horizontal_speed_units_s", "vertical_speed_units_s", "max_distance_units", "shockwave_s"]:
			if str(row.get(field, "")) != "" and float(row[field]) <= 0: return _fail("attacks", i, field, "Must be positive: " + id + "." + field)
		var shots := str(row.get("multishot", ""))
		if shots != "" and (not shots.is_valid_int() or int(shots) < 1): return _fail("attacks", i, "multishot", "Multishot must be a whole number, 1 or more: " + id)
		var aimed := str(row.get("aimed_shot", ""))
		if aimed != "" and (not aimed.is_valid_int() or int(aimed) >= maxi(1, int(shots) if shots != "" else 1)):
			return _fail("attacks", i, "aimed_shot", "Aimed shot is a shot number, 0 to multishot - 1: " + id)
		var then := str(row.get("follow_up", ""))  # a follow-up: another attack, this many times, this far apart
		if then != "":
			if not attacks.any(func(o): return o.get("name", "") == then) or then == id: return _fail("attacks", i, "follow_up", "Follow-up must be another attack: " + id)
			var times := str(row.get("follow_up_count", ""))
			if not times.is_valid_int() or int(times) < 1: return _fail("attacks", i, "follow_up_count", "Follow-up count must be 1 or more: " + id)
			if not str(row.get("follow_up_gap_s", "")).is_valid_float() or float(row.get("follow_up_gap_s", "0")) <= 0: return _fail("attacks", i, "follow_up_gap_s", "Follow-up gap must be over 0 s: " + id)
		var spread := str(row.get("spread_deg", ""))
		if spread != "" and float(spread) >= 360: return _fail("attacks", i, "spread_deg", "Spread must be under 360 degrees: " + id)
	var bindings := {}
	for i in assignments.size():
		var row: Dictionary = assignments[i]
		if str(row.get("enemy_id", "")).is_empty(): return _fail("ranges", i, "enemy_id", "Range requires enemy and phase")
		if str(row.get("phase", "")).is_empty(): return _fail("ranges", i, "phase", "Range requires enemy and phase")
		if not ids.has(row.get("attack_name", "")): return _fail("ranges", i, "attack_name", "Unknown attack binding: " + str(row.get("attack_name", "")))
		if not EXECUTABLE.has(row.enemy_id): return _fail("ranges", i, "enemy_id", "Attack has no implementation for " + str(row.enemy_id) + ": " + str(row.attack_name))
		if row.phase not in (["normal", "enraged"] if row.enemy_id == "boss_ape" else ["default"]): return _fail("ranges", i, "phase", "Unknown phase for " + str(row.enemy_id))
		var key := "%s/%s/%s" % [row.enemy_id, row.phase, row.attack_name]
		if bindings.has(key): return _fail("ranges", i, "attack_name", "Duplicate range binding: " + key)
		bindings[key] = true
		for field in ["min_range_units", "max_range_units", "priority"]:
			var value := str(row.get(field, ""))
			if not value.is_valid_float() or not is_finite(float(value)) or float(value) < 0: return _fail("ranges", i, field, "Invalid range/priority: " + key)
		if not str(row.priority).is_valid_int(): return _fail("ranges", i, "priority", "Priority must be an integer: " + key)
		if float(row.max_range_units) != 0 and float(row.max_range_units) <= float(row.min_range_units): return _fail("ranges", i, "max_range_units", "Range maximum must exceed minimum (0 = no maximum): " + key)
		var skip := str(row.get("skip_chance", ""))
		if skip != "" and (not skip.is_valid_float() or float(skip) < 0 or float(skip) > 100): return _fail("ranges", i, "skip_chance", "Skip chance must be 0-100 %: " + key)
	for enemy_id in EXECUTABLE:
		for id in EXECUTABLE[enemy_id]:
			if not ids.has(id): return "Missing implemented attack: " + id
	return ""

func attack(id: String) -> Dictionary:
	for row in attacks:
		if row.name == id: return row
	return {}

func value(id: String, field: String, fallback: float) -> float:
	var cell := str(attack(id).get(field, ""))
	return fallback if cell.is_empty() else float(cell)

func score_attack(row: Dictionary, area_override: float = -1.0, speed_scale: float = 1.0, warning_scale: float = 1.0) -> Dictionary:
	var area := area_override if area_override >= 0 else (body_area(str(row.get("name", ""))) if uses_body(row) else float(row.get("coverage_area_units2", "0")))
	var wave := str(row.get("shockwave_s", "")) if row.get("type", "") == "movement" else ""  # a landing shockwave: how long it hits
	var time := float(wave if wave != "" else str(row.get("animation_s", "0")))
	if row.get("type", "") in ["body movement", "ranged"] or (row.get("type", "") == "movement" and str(row.get("initial_speed_units_s", "")) != ""):
		var speed := float(row.get("initial_speed_units_s", "0")) * speed_scale
		if speed <= 0: return {"valid": false, "reason": "Missing positive reference speed"}
		time = REFERENCE_DISTANCE / speed
	if time <= 0 or area <= 0: return {"valid": false, "reason": "Missing positive damage area or duration"}
	if time >= 2: return {"valid": false, "reason": "Measured time >= 2 s: wind-up rule not decided"}
	var windup := float(row.get("windup_s", "0")) * warning_scale
	var penalty := 1.0 + 4.0 * clampf((windup - time) / (2.0 - time), 0, 1)
	var count := 0.0  # shots within 30 degrees of the aimed one count fully, the others (they rarely hit) 0.2
	for offset in shot_angles(row):
		count += 1.0 if absf(wrapf(offset, -180.0, 180.0)) <= 30.0 else 0.2
	var raw := float(row.get("base_weight", "1")) * area / time * count
	if not is_finite(raw): return {"valid": false, "reason": "Score exceeds numeric limits"}
	var total := raw / penalty
	var then := str(row.get("follow_up", ""))  # its follow-up, as many times as it comes
	if then != "" and then != str(row.get("name", "")):
		var once: Dictionary = attack(then).duplicate()
		once.follow_up = ""  # one level: a chain that loops back can't recurse
		var follow := score_attack(once, -1.0, speed_scale, warning_scale)
		if follow.get("valid", false):
			total += follow.score * maxi(1, int(str(row.get("follow_up_count", "1")) if str(row.get("follow_up_count", "")) != "" else "1"))
	return {"valid": true, "score": total, "raw": raw, "penalty": penalty, "time": time, "area": area, "count": count}

func enemy_score(ids: Array, body_area: float, speed_scale: float = 1.0, warning_scale: float = 1.0, size_scale: float = 1.0) -> Dictionary:
	var total := body_area
	var seen := {}
	var unscored := PackedStringArray()
	for id in ids:
		if seen.has(id): continue
		seen[id] = true
		var row := attack(id)
		var area := body_area if uses_body(row) else float(row.get("coverage_area_units2", "0")) * size_scale * size_scale
		var effective_speed := speed_scale if id == "charge" else 1.0
		var score := score_attack(row, area, effective_speed, warning_scale)
		if not score.valid:
			unscored.append(str(id) + ": " + score.reason)
			continue
		total += score.score
	return {"valid": unscored.is_empty(), "score": total, "body_area": body_area, "reason": "; ".join(unscored), "unscored": unscored}

func ordered_attacks(enemy_id: String, phase: String, available: Array = []) -> Array:
	var result: Array = []
	for row in assignments:
		if row.enemy_id == enemy_id and row.phase == phase and (available.is_empty() or row.attack_name in available): result.append(row)
	result.sort_custom(func(a, b):  # priority decides (highest first); ties keep the CSV order
		if float(a.priority) != float(b.priority): return float(a.priority) > float(b.priority)
		return assignments.find(a) < assignments.find(b))
	return result

# Multishot: the angles (degrees) of the shots relative to the one aimed at the player, in shot order. Shot 0 is the
# lowest; numbers go upward. spread_deg between neighbours; 0 spaces them evenly around the full circle.
static func shot_angles(row: Dictionary) -> Array:
	var n := maxi(1, int(str(row.get("multishot", "1")) if str(row.get("multishot", "")) != "" else "1"))
	var aimed := clampi(int(str(row.get("aimed_shot", "0")) if str(row.get("aimed_shot", "")) != "" else "0"), 0, n - 1)
	var spread := float(str(row.get("spread_deg", "0")) if str(row.get("spread_deg", "")) != "" else "0")
	var step := spread if spread > 0 else 360.0 / n
	var out: Array = []
	for k in n:
		out.append((k - aimed) * step)
	return out

# Whether the enemy's code can do this attack (bindings to others are plans: kept, shown, skipped in play).
static func performs(enemy_id: String, attack_name: String) -> bool:
	return attack_name in EXECUTABLE.get(enemy_id, [])

# A binding's maximum range in tiles; 0 in the CSV means there's no maximum.
static func max_range(row: Dictionary) -> float:
	var m := float(row.get("max_range_units", "0"))
	return INF if m == 0 else m

# Body and movement attacks without an area of their own hit with the enemy's body.
static func uses_body(row: Dictionary) -> bool:
	return row.get("type", "") in ["body movement", "movement"] and str(row.get("coverage_area_units2", "")) == ""

# Body attacks hit with the enemy's own body, so their area is the body's: the Ape's 3x3 tiles, a library monster's
# 10x10 px as the reference here (each enemy's real size is used in its scores).
static func body_area(id: String) -> float:
	return 9.0 if id.begins_with("ape") else 1.5625

# Move a binding one place up (-1) or down (+1) in its enemy/phase list; priorities are renumbered n-1 .. 0.
func move_binding(row: Dictionary, step: int) -> void:
	var rows := ordered_attacks(row.enemy_id, row.phase)
	var i := rows.find(row)
	var j := clampi(i + step, 0, rows.size() - 1)
	if i < 0 or i == j: return
	rows[i] = rows[j]
	rows[j] = row
	for k in rows.size():
		rows[k].priority = str(rows.size() - 1 - k)

# The first attack in priority order that's in range and eligible; each has a skip chance (percent): when it's rolled,
# that attack passes and the next one is tried.
func select_attack(enemy_id: String, phase: String, available: Array, distance: float, eligible: Callable = Callable(), range_scale: float = 1.0) -> String:
	for row in ordered_attacks(enemy_id, phase, available):
		if distance < float(row.min_range_units) * range_scale or distance >= max_range(row) * range_scale: continue
		if not performs(enemy_id, row.attack_name): continue  # added in the editor, not in its code yet
		if eligible.is_valid() and not eligible.call(row.attack_name): continue
		var skip := str(row.get("skip_chance", ""))
		if skip != "" and randf() * 100.0 < float(skip): continue
		return row.attack_name
	return ""

# Attacks whose gameplay has its own eligibility rule, so covering another's range is intended (the Ape's random throw
# and its leap picked by distance in entities.gd): no overlap warning for them.
const CHOSEN_BY_RULE := ["ape_retreat", "ape_throw", "ape_leap"]

func range_warnings() -> String:
	var warnings := PackedStringArray()
	for row in assignments:
		for other in ordered_attacks(row.enemy_id, row.phase):
			if other == row: break
			if other.attack_name in CHOSEN_BY_RULE: continue
			if row.enemy_id == "enemy_monster": continue  # each build has only some of these attacks: overlaps are expected
			if float(other.min_range_units) <= float(row.min_range_units) and max_range(other) >= max_range(row):
				warnings.append("%s/%s: %s covers %s's range; latter needs an eligibility fallback." % [row.enemy_id, row.phase, other.attack_name, row.attack_name])
	return "\n".join(warnings)

# Keep authored decimals readable without rounding intermediate score calculations.
func format_cell(column: String, cell: String) -> String:
	var integers := ["multishot", "aimed_shot", "priority", "follow_up_count"]
	var numeric := column in NUMERIC or column in ["score", "min_range_units", "max_range_units", "skip_chance"]
	if numeric and column not in integers and cell.is_valid_float() and is_finite(float(cell)):
		return "%.2f" % float(cell)
	return cell

func _rounded_rows(rows: Array) -> Array:
	var result: Array = []
	for row in rows:
		var rounded: Dictionary = row.duplicate(true)
		for column in row: rounded[column] = format_cell(column, str(row[column]))
		result.append(rounded)
	return result

func validate_for_save() -> String:
	var invalid := validate()
	if not invalid.is_empty(): return invalid
	var original := [attacks, assignments]
	attacks = _rounded_rows(attacks)
	assignments = _rounded_rows(assignments)
	invalid = validate()
	attacks = original[0]
	assignments = original[1]
	return invalid

func _stage_table(ranges: bool) -> String:
	var invalid := validate_for_save()
	if not invalid.is_empty(): return invalid
	var path := assignment_path if ranges else attack_path
	var columns := assignment_columns if ranges else attack_columns
	var rows := _rounded_rows(assignments if ranges else attacks)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return "Cannot write " + temp
	file.store_csv_line(columns)
	for row in rows:
		var cells := PackedStringArray()
		for column in columns:
			var cell := str(row.get(column, ""))
			if not ranges and column == "score":
				var calculated := score_attack(row)
				cell = "%.2f" % calculated.score if calculated.valid else ""
			cells.append(cell)
		file.store_csv_line(cells)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return "Could not finish writing " + temp
	return ""

func save_table(ranges: bool) -> String:
	var staged := _stage_table(ranges)
	if not staged.is_empty(): return staged
	var path := assignment_path if ranges else attack_path
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	return "" if result == OK else "Could not replace " + path + ": " + error_string(result)

# Stage both before replacing either; restore the first if the second replacement fails.
func save_all() -> String:
	for ranges in [false, true]:
		var staged := _stage_table(ranges)
		if not staged.is_empty(): return staged
	var old := FileAccess.get_file_as_string(attack_path) if FileAccess.file_exists(attack_path) else ""
	var first := DirAccess.rename_absolute(ProjectSettings.globalize_path(attack_path + ".tmp"), ProjectSettings.globalize_path(attack_path))
	if first != OK: return "Could not replace attack CSV: " + error_string(first)
	var second := DirAccess.rename_absolute(ProjectSettings.globalize_path(assignment_path + ".tmp"), ProjectSettings.globalize_path(assignment_path))
	if second != OK:
		var restore := FileAccess.open(attack_path + ".restore", FileAccess.WRITE)
		if restore == null: return "Range save failed; attack rollback could not be written"
		restore.store_string(old)
		restore.close()
		var restored := DirAccess.rename_absolute(ProjectSettings.globalize_path(attack_path + ".restore"), ProjectSettings.globalize_path(attack_path))
		return "Could not replace range CSV; " + ("attack CSV restored" if restored == OK else "attack rollback failed")
	return ""
