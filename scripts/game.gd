extends Node
# Application-wide service, registered as the Game autoload in project.godot.
# An autoload is created before the main scene and remains available while screens are replaced.
# Owns shared settings, input bindings, audio services, level files and adventure progress.
# The actual player movement and room simulation belong to player.gd and world.gd.
# res:// means this project; user:// means Godot's per-user save-data directory.
# Dictionaries are named groups of values (like a small record); JSON stores portable room data.
# Reading help: docs/CODE_GUIDE.md.

# Autoload "Game": settings, controls, level files, save progress, screen switching.

const Entities := preload("res://scripts/entities.gd")
const Tuning := preload("res://scripts/tuning.gd")
const Adventure := preload("res://scripts/adventure.gd")
const LEVEL_DIR := "user://levels/"
const WORLDS_DIR := "res://worlds/"  # worlds: one folder each with world.json + rooms (docs/WORLD_DESIGN.md)
const STORY_WORLD := WORLDS_DIR + "story/world.json"  # the default world
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_PATH := "user://save.cfg"
var save_path := SAVE_PATH  # tests point this at a scratch file

# Art caches live in static vars, which outlive the scene tree: drop them on quit so Godot
# doesn't report the cached textures as leaked at exit.
# They're loaded at runtime here: a const preload in this autoload would itself keep a script alive at exit.
# Clear generated art caches during shutdown so textures do not remain referenced after the scene tree exits.
# Quit cleanly: stop every sound first and give the audio thread a few frames to release the playbacks,
# otherwise they are still alive at exit (and reported as leaked).
func quit_game(code := 0) -> void:
	await get_tree().create_timer(0.1, true, false, true).timeout  # a just-started sound isn't registered by the audio thread yet: stopping it now would be ignored
	if is_instance_valid(sfx):
		for v in sfx.voices:
			v.stop()
	if is_instance_valid(music_engine):
		music_engine.stop()
		music_engine.queue_free()  # the synth's stream lives as long as its driver node
	await get_tree().create_timer(0.25, true, false, true).timeout  # real time: the audio thread runs on its own clock
	get_tree().quit(code)

# Closing the window goes through quit_game too (auto_accept_quit is off, see _ready).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

static func is_ps_pad(name: String) -> bool:
	var n := name.to_lower()
	return n.contains("playstation") or n.contains("dualshock") or n.contains("dualsense") or n.contains("sony") or n.contains("ps4") or n.contains("ps5")

# Track the device in use, for button prompts.
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_pad = true
		pad_ps = is_ps_pad(Input.get_joy_name(event.device))
	elif event is InputEventKey or event is InputEventScreenTouch:
		using_pad = false

func _exit_tree() -> void:
	load("res://scripts/ape_art.gd")._textures.clear()
	load("res://scripts/environment_art.gd")._textures.clear()
	load("res://scripts/block_art.gd")._textures.clear()
	load("res://scripts/character_art.gd")._textures.clear()
	load("res://scripts/art.gd")._hair_cache.clear()
	load("res://scripts/button_art.gd")._cache.clear()
	load("res://scripts/enemy_art.gd")._texture = null

# Default controls (Celeste keyboard layout + gamepad).
const DEFAULT_KEYS := {
	"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN,
	"jump": KEY_C, "dash": KEY_A, "grab": KEY_Z, "pause": KEY_ESCAPE,
	"map": KEY_M, "debug": KEY_F1, "attack": KEY_X, "hitboxes": KEY_F2,
	"assist": KEY_F12, "interact": KEY_S, "stamina_debug": KEY_F3, "state_debug": KEY_F4,
}
const ALT_KEYS := {"jump": KEY_SPACE, "dash": KEY_SHIFT, "grab": KEY_V}
# Gamepad: one button per action (JOY_BUTTON_*), PAD_AXIS + axis for a trigger, -1 = none.
const PAD_AXIS := 100
const DEFAULT_PAD := {
	"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
	"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN,
	"jump": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "dash": JOY_BUTTON_RIGHT_SHOULDER,
	"grab": PAD_AXIS + JOY_AXIS_TRIGGER_RIGHT, "pause": JOY_BUTTON_START,
	"map": JOY_BUTTON_BACK, "debug": -1, "hitboxes": -1, "assist": -1, "stamina_debug": -1, "state_debug": -1, "interact": JOY_BUTTON_B,
}
const PAD_NAMES := {
	JOY_BUTTON_A: "A / Cross", JOY_BUTTON_B: "B / Circle", JOY_BUTTON_X: "X / Square", JOY_BUTTON_Y: "Y / Triangle",
	JOY_BUTTON_LEFT_SHOULDER: "LB / L1", JOY_BUTTON_RIGHT_SHOULDER: "RB / R1",
	PAD_AXIS + JOY_AXIS_TRIGGER_LEFT: "LT / L2", PAD_AXIS + JOY_AXIS_TRIGGER_RIGHT: "RT / R2",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_BACK: "Back / Select",
	JOY_BUTTON_START: "Start", JOY_BUTTON_GUIDE: "Home",
	JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right", -1: "-",
}
const ACTION_NAMES := ["left", "right", "up", "down", "jump", "dash", "grab", "attack", "interact", "pause", "map", "debug", "hitboxes", "assist", "stamina_debug", "state_debug"]

var main: Node
var sfx: Node
var music_engine: Node
var theme: Theme
# Settings affect the application; adv below is different data: progress belonging to one adventure run.
var settings := {
	"sfx_volume": 1.0, "music_volume": 1.0,
	"fullscreen": false, "vsync": true, "shake": true, "hitboxes": false,
	"game_speed": 1.0, "infinite_stamina": false, "air_dashes": 0, "invincible": false,
	"keys": DEFAULT_KEYS.duplicate(),
	"pad": DEFAULT_PAD.duplicate(),
	"tuning_preset": "",  # active movement preset in user://tuning/ ("" = project defaults)
	"tuning_open_groups": [],  # debug panel variable groups left open (all collapsed by default)
}
# Player tuning overrides (var name -> value), applied to every new Player. See tuning.gd.
var tuning: Dictionary = {}
# Level being played. playtest = launched from the editor (exit goes back there).
var level: Dictionary = {}
var playtest := false
var lab_enemy := ""  # Monster Lab: the enemy in its dummy room ("" = not in the lab)
var editor_level: Dictionary = {}
var editor_resize_resume: Dictionary = {}  # transient resize/undo state while playtesting
var editor_dir := LEVEL_DIR  # where the level editor saves (the world folder when editing a world room)
var editor_file := ""  # fixed file name when editing a world room (renaming must not break world.json)
var editor_return := "menu"  # screen the editor's Menu button goes back to
var adv: Dictionary = {}  # active adventure run (see start_adventure); empty outside it
var adv_world: Dictionary = {}  # Adventure.load_world() result for that run
var using_pad := false  # last input came from a gamepad: button prompts show pad buttons, else keys
var pad_ps := false  # that pad is a PlayStation one: prompts show its symbols
var stress_rest_notice := 0.0
var adv_temp := false  # world-editor playtest: never saved, exits back to the world editor
var progression_job = null  # background analysis survives screen navigation
var last_progression_report := ""
var world_path := STORY_WORLD  # tests point this at a scratch file

# Prepare user storage, shared interface styling, saved options, tuning and the chosen adventure world.
func _ready() -> void:
	get_tree().auto_accept_quit = false  # the window's close button calls quit_game()
	DirAccess.make_dir_recursive_absolute(LEVEL_DIR)
	theme = Theme.new()
	theme.default_font_size = 26
	_load_settings()
	apply_settings()
	tuning = Tuning.startup(settings.tuning_preset)
	get_sfx()  # synthesizes every effect (~190 ms) during the boot splash, not on the first click or scream
	var quit_key := QuitKey.new()
	quit_key.process_mode = Node.PROCESS_MODE_ALWAYS  # also in the pause menu
	add_child(quit_key)

# Cmd+Q (macOS) / Ctrl+Q: quit from anywhere, paused or not, also with a dialog or an editor window focused.
class QuitKey extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q \
				and event.is_command_or_control_pressed() and not OS.has_feature("web"):
			get_viewport().set_input_as_handled()
			Game.quit_game()


# Return the shared effects service, creating it if needed; all callers then reuse the same voice pool.
func get_sfx() -> Node:
	if not is_instance_valid(sfx):
		sfx = load("res://scripts/sfx.gd").new()
		add_child(sfx)
	return sfx

# Forward a named effect and pitch to the shared sound service.
func play_sfx(key: String, pitch: float = 1.0) -> void:
	get_sfx().play(key, pitch)

# Return the single shared synth; SiON uses global state and must not have competing drivers.
func get_music_engine() -> Node:
	# SiON has global synthesis state. Keep one driver for the application lifetime.
	if not is_instance_valid(music_engine):
		music_engine = load("res://scripts/music_engine.gd").new()
		add_child(music_engine)
	return music_engine

# ---------- screens ----------
# Schedule the old screen for deletion and create the requested screen under the main root.
# queue_free() deletes at the end of the frame; a newly added screen can briefly coexist with the old one.
func goto(screen: String) -> void:
	if OS.has_feature("web") and screen in ["world_editor", "music_studio", "art_gallery"]:
		screen = "menu"
	if is_instance_valid(music_engine):
		music_engine.stop()
	for c in main.get_children():
		c.queue_free()
	main.add_child(load("res://scripts/%s.gd" % screen).new())

# Start a standalone level, recording whether it came from the editor so returning goes to the right place.
func play(level_data: Dictionary, from_editor: bool) -> void:
	adv = {}
	level = level_data
	playtest = from_editor
	lab_enemy = ""
	goto("world")

# Monster Lab: an empty room with one enemy; the Monster Editor opens over it (world.gd _toggle_lab).
func play_lab(enemy_id: String) -> void:
	adv = {}
	level = load("res://scripts/attack_catalog_editor.gd").test_room(enemy_id)
	playtest = false
	lab_enemy = enemy_id  # before the world is built: it reads this
	goto("world")

# ---------- crash-safe files ----------
# Every file the game writes goes through write_safe: the text goes to path.tmp first, the previous file is kept as
# path.bak, then the .tmp is renamed over it. A crash leaves either the old file or the new one, never half of one,
# and readers fall back to the .bak. (The Monster Editor's CSV set has its own multi-file version in attack_catalog.gd.)
static func write_safe(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	var ok := f.get_error() == OK
	f.close()
	var g := func(p: String) -> String: return ProjectSettings.globalize_path(p)
	if ok and FileAccess.file_exists(path):
		ok = DirAccess.copy_absolute(g.call(path), g.call(path + ".bak")) == OK
	if ok:
		ok = DirAccess.rename_absolute(g.call(tmp), g.call(path)) == OK
	if not ok:
		DirAccess.remove_absolute(g.call(tmp))
	return ok

# Load a ConfigFile, falling back to its .bak. Null when a file exists but neither copy can be read:
# callers must not save then, or they'd replace the player's progress with an empty file.
static func read_config(path: String) -> ConfigFile:
	for p in [path, path + ".bak"]:
		var cf := ConfigFile.new()
		if FileAccess.file_exists(p) and cf.load(p) == OK:
			return cf
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		push_error("Unreadable save file (and backup): " + path)
		return null
	return ConfigFile.new()  # nothing saved yet

# ---------- settings ----------
# Merge saved options with defaults, including defaults for actions added after the file was written.
func _load_settings() -> void:
	var cf := read_config(SETTINGS_PATH)
	if cf == null or not cf.has_section("s"):
		return
	for k in settings:
		settings[k] = cf.get_value("s", k, settings[k])
	if not cf.has_section_key("s", "music_volume"):  # saved before the volume sliders: effects start at 100%
		settings.sfx_volume = 1.0
	settings.keys.erase("punch")  # the fist now shares the attack button
	settings.pad.erase("punch")
	if settings.keys.get("attack") == KEY_A and settings.keys.get("dash") == KEY_X:  # the old defaults: attack moved to X
		settings.keys.attack = KEY_X
		settings.keys.dash = KEY_A
	for a in DEFAULT_KEYS:  # keep any new actions added after the file was saved
		if not settings.keys.has(a):
			settings.keys[a] = DEFAULT_KEYS[a]
		if not settings.pad.has(a):
			settings.pad[a] = DEFAULT_PAD[a]

# Write options and input bindings to the per-user configuration file.
func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings:
		cf.set_value("s", k, settings[k])
	write_safe(SETTINGS_PATH, cf.encode_to_text())

# Apply volume, window mode, synchronization and input bindings from the current settings dictionary.
func apply_settings() -> void:
	if is_instance_valid(sfx):
		sfx.set_volume(float(settings.sfx_volume))
	if is_instance_valid(music_engine):
		music_engine.set_level(float(settings.music_volume))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		_fit_window.call_deferred()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	_apply_input()

# A windowed game can't be squeezed below 640x360. Its size is the window manager's (niri: a rule in the dots repo
# gives the game column 60% of the monitor width); resizing it from here only fought the tiling.
func _fit_window() -> void:
	if OS.has_feature("web") or OS.has_feature("mobile") or DisplayServer.get_name() == "headless":
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	DisplayServer.window_set_min_size(Vector2i(640, 360))

# Rebuild Godot actions from saved keys/pad bindings, with analog movement and menu navigation fallbacks.
func _apply_input() -> void:
	for a in ACTION_NAMES:
		if InputMap.has_action(a):
			InputMap.action_erase_events(a)
		else:
			InputMap.add_action(a, 0.3)
		var k := InputEventKey.new()
		k.physical_keycode = settings.keys[a]
		InputMap.action_add_event(a, k)
		if ALT_KEYS.has(a) and ALT_KEYS[a] != settings.keys[a]:
			var k2 := InputEventKey.new()
			k2.physical_keycode = ALT_KEYS[a]
			InputMap.action_add_event(a, k2)
		var pb: int = settings.pad[a]
		if pb >= PAD_AXIS:
			var t := InputEventJoypadMotion.new()
			t.axis = pb - PAD_AXIS
			t.axis_value = 1.0
			InputMap.action_add_event(a, t)
		elif pb >= 0:
			var jb := InputEventJoypadButton.new()
			jb.button_index = pb
			InputMap.action_add_event(a, jb)
	for pair in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)
	# Menus: jump key confirms, dash key goes back (like Celeste), on top of Enter/Esc.
	for m in [["ui_accept", "jump", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], JOY_BUTTON_A], ["ui_cancel", "dash", [KEY_ESCAPE], JOY_BUTTON_B]]:
		InputMap.action_erase_events(m[0])
		for code in m[2] + [settings.keys[m[1]]]:
			var e := InputEventKey.new()
			e.physical_keycode = code
			InputMap.action_add_event(m[0], e)
		var jb := InputEventJoypadButton.new()
		jb.button_index = m[3]
		InputMap.action_add_event(m[0], jb)

# Convert a saved keyboard code into a label readable in menus.
func key_name(action: String) -> String:
	return OS.get_keycode_string(settings.keys[action])

# Convert a saved gamepad button/trigger code into a label readable in menus.
func pad_name(action: String) -> String:
	return PAD_NAMES.get(settings.pad[action], "Button %d" % settings.pad[action])

# ---------- levels ----------
# Create an editable blank room dictionary with solid edges/floor and a starting spawn marker.
static func new_level(level_name := "untitled", w := 40, h := 23) -> Dictionary:
	var rows := []
	for y in h:
		var row := ""
		for x in w:
			row += "1" if (y >= h - 2 or x == 0 or x == w - 1) else "0"
		rows.append(row)
	return {"name": level_name, "w": w, "h": h, "tiles": rows, "enemy_count": -1,
		"entities": [{"t": "spawn", "x": 16, "y": (h - 3) * 8}]}

# List user-created level names in sorted order without their JSON file extension.
func list_levels() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(LEVEL_DIR):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	out.sort()
	return out

# Replace unsuitable filename characters and provide a fallback for an empty name.
static func file_safe(s: String) -> String:
	var out := ""
	for ch in s.strip_edges():
		out += ch if (ch.is_valid_identifier() or ch.is_valid_int() or ch == "-") else "_"
	return out if out != "" else "untitled"

# Write a level dictionary as JSON and return its filename, or an empty string when writing fails.
func save_level(d: Dictionary, dir := LEVEL_DIR, fname := "") -> String:
	if fname == "":
		fname = file_safe(d.name)
	return fname if write_safe(dir + fname + ".json", JSON.stringify(whole_numbers(d), "\t")) else ""

# Level data is in whole units (JSON reads every number as a float): 8.0 is saved as 8, real fractions stay.
static func whole_numbers(v: Variant) -> Variant:
	if v is float and is_finite(v) and v == floorf(v):
		return int(v)
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = whole_numbers(v[k])
		return out
	if v is Array:
		return v.map(whole_numbers)
	return v

# Read and parse a level file, then reject malformed data before gameplay constructs objects from it.
func load_level(fname: String, dir := LEVEL_DIR) -> Dictionary:
	var f := FileAccess.open(dir + fname + ".json", FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()  # instance parse: bad JSON returns an error code instead of logging one
	if json.parse(f.get_as_text()) != OK:
		return {}
	return validate_level(json.data, fname)

const MAX_LEVEL_SIZE := 400  # tiles; matches the editor's size spinners
const MAX_COORD := 1 << 20  # pixels; far beyond any level, keeps int() conversion sane

# Normalizes a parsed level in place and returns it, or {} if anything is malformed.
# Validate room dimensions, tile rows and object fields; return an empty dictionary on invalid input.
static func validate_level(d, fallback_name := "untitled", layer_child := false) -> Dictionary:
	if not d is Dictionary:
		return {}
	var backdrop = d.get("backdrop", "auto")
	if not backdrop is String or backdrop not in preload("res://scripts/room_scenery_art.gd").BACKDROPS: return {}
	var environment = d.get("environment", "")
	if not environment is String or (environment != "" and environment not in load("res://scripts/environment_art.gd").THEMES):
		return {}
	if d.has("heat_drain") and (not _is_num(d.heat_drain,0,100) or d.heat_drain != floor(d.heat_drain)): return {}
	var w = d.get("w")
	var h = d.get("h")
	if not (_is_whole(w) and _is_whole(h)):
		return {}
	var name = d.get("name", fallback_name)
	var tiles = d.get("tiles")
	var ents = d.get("entities")
	if not name is String or not tiles is Array or tiles.size() != h or not ents is Array:
		return {}
	# Retired crystal types must not make otherwise valid legacy rooms unreadable.
	var retired_ids := {}
	for e in ents:
		if e is Dictionary and e.get("t","") in ["refill","refill_two"] and e.has("object_id"):
			retired_ids[e.object_id] = true
	ents = ents.filter(func(e): return not (e is Dictionary and e.get("t","") in ["refill","refill_two"]))
	for e in ents:
		if not e is Dictionary or not e.get("trigger") is Dictionary: continue
		for edge in ["on_enter","on_exit"]:
			if e.trigger.get(edge) is Array:
				e.trigger[edge] = e.trigger[edge].filter(func(link): return not (link is Dictionary and retired_ids.has(link.get("target"))))
	d.entities = ents
	var tile_re := RegEx.create_from_string("^[01]*$")
	for row in tiles:
		if not row is String or row.length() != w or tile_re.search(row) == null:
			return {}
	for e in ents:
		if e is Dictionary and e.get("t") == "leaf":  # leaf platforms are jump-throughs with the jungle look
			e.t = "jumpthru"
			e.look = "forest"
		if not e is Dictionary or not e.get("t") is String or not Entities.TYPES.has(e.t):
			return {}
		if not (_is_num(e.get("x"), -MAX_COORD, MAX_COORD) and _is_num(e.get("y"), -MAX_COORD, MAX_COORD)):
			return {}
		if not preload("res://scripts/progression/story_settings.gd").validate(e).is_empty(): return {}
		if e.t in ["spawn","respawn"] and (e.has("w") or e.has("h")):
			if not e.has("w") or not e.has("h"):return {}
			var at:=preload("res://scripts/progression/checkpoint_area.gd").resolve(d,Rect2i(int(e.x),int(e.y),int(e.w),int(e.h)))
			if at==Vector2(-1,-1):return {}
			var previous=e.get("respawn_at")
			if not previous is Array or previous.size()!=2 or previous[0]!=at.x or previous[1]!=at.y:e.respawn_at=[int(at.x),int(at.y)]
		if e.has("motion"):
			var settings = preload("res://scripts/motion/patrol_settings.gd")
			if not settings.supports(e) or not settings.validate(e.motion, Vector2i(w * 8, h * 8)).is_empty(): return {}
		for k in ["tx", "ty"]:  # optional
			if e.has(k) and not _is_num(e[k], -MAX_COORD, MAX_COORD):
				return {}
		# entity draw/build loops walk every 8px cell, so sizes must stay level-sized
		if e.has("text") and not (e.text is String and e.text.length() <= 500):  # optional (notes)
			return {}
		for k in ["id", "to"]:  # optional (doors)
			if e.has(k) and not (e[k] is String and e[k].length() <= 100):
				return {}
		for k in ["w", "h"]:  # optional
			if e.has(k) and not _is_num(e[k], 1, MAX_LEVEL_SIZE * 8):
				return {}
		if e.has("hp") and not _is_num(e.hp, 1, 99):  # optional (breakable walls)
			return {}
		for k in ["facing", "patrol"]:  # optional (enemies)
			if e.has(k) and not _is_num(e[k], -MAX_COORD, MAX_COORD):
				return {}
		if e.has("top") and not e.top is bool:  # optional (liquids)
			return {}
	if not preload("res://scripts/interaction/trigger_settings.gd").validate_level(ents).is_empty(): return {}
	if not layer_child:
		var settings=preload("res://scripts/layers/layer_settings.gd")
		# Basic layer shape is checked before recursive level validation.
		if not d.get("layers",{}) is Dictionary:return {}
		for layer in d.get("layers",{}).values():
			if not layer is Dictionary or layer.has("layers") or validate_level(layer,fallback_name,true).is_empty():return {}
		if not settings.validate(d).is_empty():return {}
	d.name = name
	d.w = int(w)
	d.h = int(h)
	return d

# NaN fails both comparisons, so this also rejects non-finite values.
# Check that a value is a finite number inside the supplied bounds before converting it.
static func _is_num(v, lo: float, hi: float) -> bool:
	return (v is float or v is int) and v >= lo and v <= hi

# Check that a dimension is a valid whole tile count within the editor limits.
static func _is_whole(v) -> bool:
	return _is_num(v, 1, MAX_LEVEL_SIZE) and v == floor(v)

# Delete the named custom level file from user storage.
func delete_level(fname: String) -> void:
	DirAccess.remove_absolute(LEVEL_DIR + fname + ".json")

# ---------- adventure ----------
# One run per world; saved under [adventure] in the save file. Empty adv = not in the adventure.
# Check whether the selected world has stored adventure progress.
func has_adventure_save() -> bool:
	var cf := read_config(save_path)
	return cf != null and cf.has_section_key("adventure", _run_key())

# Build the configuration key used to keep progress for different worlds separate.
func _run_key() -> String:
	return "run_" + world_path.get_base_dir().get_file()

# Load the selected world and either create fresh progress or restore its saved run.
func start_adventure(fresh: bool) -> void:
	adv_world = Adventure.load_world(world_path)
	if adv_world.rooms.is_empty():
		return
	var cf := read_config(save_path)
	var run = cf.get_value("adventure", _run_key()) if cf != null and cf.has_section_key("adventure", _run_key()) else null
	adv = Adventure.new_run(adv_world) if fresh else Adventure.restore_run(adv_world, run)
	adv_temp = false
	stress_rest_notice = 0.0
	if not fresh: claim_stress_rest(int(Time.get_unix_time_from_system()))
	_enter_adventure()

# World-editor playtest: a throwaway run from any room that is never saved.
# Start a temporary adventure from a chosen room without overwriting normal player progress.
func playtest_adventure(world: Dictionary, room: String) -> void:
	adv_world = world
	adv = Adventure.new_run(world)
	adv.room = room
	adv.visited = [room]
	adv_temp = true
	_enter_adventure()

# Select the restored room level and open the World screen.
func _enter_adventure() -> void:
	level = Adventure.room_level(adv_world, adv.room, adv.get("broken", []))
	playtest = false
	goto("world")

# Write current adventure progress, except for temporary world-editor playtests.
func save_adventure(now: int = -1) -> bool:
	if adv.is_empty() or adv_temp: return false
	var cf := read_config(save_path)
	if cf == null: return false
	var candidate := adv.duplicate(true)
	candidate.last_saved_at = int(Time.get_unix_time_from_system()) if now < 0 else now
	if not _write_adventure(cf, candidate): return false
	adv.last_saved_at = candidate.last_saved_at
	return true

func _write_adventure(cf: ConfigFile, candidate: Dictionary) -> bool:
	cf.set_value("adventure", _run_key(), candidate)
	return write_safe(save_path, cf.encode_to_text())

# Commit recovery and its claim timestamp together. A failed write changes neither.
func claim_stress_rest(now: int) -> bool:
	if adv.is_empty() or adv_temp or not Adventure.Stress.rest_due(adv, now): return false
	var cf := read_config(save_path)
	if cf == null: return false
	var candidate := adv.duplicate(true)
	var delta := Adventure.Stress.change(candidate, -Adventure.Stress.REST_RELIEF)
	candidate.last_saved_at = now
	if not _write_adventure(cf, candidate): return false
	adv.clear()
	adv.merge(candidate, true)
	stress_rest_notice = -delta
	return true

# Outside the adventure every move is available.
# Check adventure unlocks; standalone levels allow the normal moves without pickups.
func has_ability(a: String) -> bool:
	return adv.is_empty() or adv.abilities.has(a)

# ---------- progress ----------
# Read the stored best result for one custom level.
func get_record(fname: String) -> Dictionary:
	var cf := read_config(save_path)
	return cf.get_value("levels", fname, {}) if cf != null else {}

# Merge a completed level result with previous best time, deaths and collectible counts.
func submit_record(fname: String, time: float, deaths: int, berries: int, total: int) -> void:
	var cf := read_config(save_path)
	if cf == null:
		return  # unreadable save: keep it for recovery rather than overwrite it
	var r: Dictionary = cf.get_value("levels", fname, {})
	r.best_time = min(r.get("best_time", INF), time)
	r.berries = max(r.get("berries", 0), berries)
	r.total = total
	r.fewest_deaths = min(r.get("fewest_deaths", 1 << 30), deaths)
	r.clears = r.get("clears", 0) + 1
	cf.set_value("levels", fname, r)
	write_safe(save_path, cf.encode_to_text())

# Format elapsed seconds as a compact result display.
static func fmt_time(t: float) -> String:
	var m := int(t) / 60
	return "%d:%02d.%03d" % [m, int(t) % 60, int(t * 1000) % 1000]

# ---------- small UI helpers shared by menus ----------
# Create a consistently styled button and connect its sound and activation callback.
func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func(): play_sfx("ui"))
	b.pressed.connect(cb)
	return b

# Create a consistently styled text label with the requested font size.
func label(text: String, size := 26) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
