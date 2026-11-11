extends RefCounted
# Persistent run rules. No scene, rendering, or file IO dependencies.
const BAR_CAPACITY := 50
const BAR_COUNT := 5
const MAX_STRESS := BAR_CAPACITY * BAR_COUNT
const DEATH_GAIN := 20
const EXHAUSTION_GAIN := 5
const MONSTER_RELIEF := 50
const BOSS_RELIEF := 100
const COLLECTIBLE_RELIEF := 100
const REST_RELIEF := 100
const REST_SECONDS := 12 * 60 * 60
const MAX_PENALTY_PERCENT := 30
const MAX_BLOCKS := 20

static func finite_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func blocks(run: Dictionary) -> int:
	var raw = run.get("stress_blocks",BAR_COUNT)  # legacy runs had five bars
	return clampi(int(raw),1,MAX_BLOCKS) if finite_number(raw) else BAR_COUNT

static func capacity(run: Dictionary) -> int:
	return blocks(run)*BAR_CAPACITY

static func value(run: Dictionary) -> int:
	var raw = run.get("stress",0)
	return clampi(int(raw),0,capacity(run)) if finite_number(raw) else 0

static func change(run: Dictionary, amount: float) -> int:
	var before := value(run)
	run.stress = clampi(before+int(amount),0,capacity(run))
	return run.stress-before

# Dictionary is the production API; numbers retain the legacy five-bar helper API.
static func recovery_percent(input, owned_blocks: int = BAR_COUNT) -> int:
	var total := blocks(input) if input is Dictionary else clampi(owned_blocks,1,MAX_BLOCKS)
	var stress := value(input) if input is Dictionary else clampi(int(input),0,total*BAR_CAPACITY)
	var full := stress / BAR_CAPACITY
	return 100 - MAX_PENALTY_PERCENT * full / total

static func recovery_multiplier(input, owned_blocks: int = BAR_COUNT) -> float:
	return recovery_percent(input, owned_blocks) / 100.0

static func add_block(run: Dictionary) -> bool:
	if blocks(run)>=MAX_BLOCKS: return false
	run.stress_blocks = blocks(run)+1
	return true

static func exhausted(run: Dictionary, capacity: float) -> bool:
	return int(run.stamina) < int(capacity) / 5

# Resource transitions own this event, never hair rendering or dash availability.
static func observe_exhaustion(run: Dictionary, capacity: float) -> void:
	var low := exhausted(run, capacity)
	if low and not run.get("stress_exhausted", false): change(run, EXHAUSTION_GAIN)
	run.stress_exhausted = low

static func normalize(run: Dictionary, capacity: float) -> void:
	run.stress_blocks = blocks(run)
	run.stress = value(run)
	var timestamp = run.get("last_saved_at", 0)
	run.last_saved_at = maxi(0, int(timestamp)) if finite_number(timestamp) else 0
	# Restoring a run is not a fresh exhaustion event.
	run.stress_exhausted = exhausted(run, capacity)

static func rest_due(run: Dictionary, now: int) -> bool:
	var saved = run.get("last_saved_at", 0)
	return finite_number(saved) and saved > 0 and now >= saved and now - saved >= REST_SECONDS
