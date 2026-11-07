extends RefCounted
# Persistent run rules. No scene, rendering, or file IO dependencies.
const BAR_CAPACITY := 50.0
const BAR_COUNT := 5
const MAX_STRESS := BAR_CAPACITY * BAR_COUNT
const DEATH_GAIN := 20.0
const EXHAUSTION_GAIN := 5.0
const MONSTER_RELIEF := 50.0
const BOSS_RELIEF := 100.0
const COLLECTIBLE_RELIEF := 100.0
const REST_RELIEF := 100.0
const REST_SECONDS := 12 * 60 * 60
const MAX_PENALTY := 0.30
const MAX_BLOCKS := 20

static func finite_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func blocks(run: Dictionary) -> int:
	var raw = run.get("stress_blocks",BAR_COUNT)  # legacy runs had five bars
	return clampi(int(raw),1,MAX_BLOCKS) if finite_number(raw) else BAR_COUNT

static func capacity(run: Dictionary) -> float:
	return blocks(run)*BAR_CAPACITY

static func value(run: Dictionary) -> float:
	var raw = run.get("stress",0)
	return clampf(float(raw),0.0,capacity(run)) if finite_number(raw) else 0.0

static func change(run: Dictionary, amount: float) -> float:
	var before := value(run)
	run.stress = clampf(before+amount,0.0,capacity(run))
	return run.stress-before

# Dictionary is the production API; numbers retain the legacy five-bar helper API.
static func recovery_multiplier(input, owned_blocks: int = BAR_COUNT) -> float:
	var total := blocks(input) if input is Dictionary else clampi(owned_blocks,1,MAX_BLOCKS)
	var stress := value(input) if input is Dictionary else clampf(float(input),0.0,total*BAR_CAPACITY)
	var full := floori(stress/BAR_CAPACITY)
	return 1.0-MAX_PENALTY*full/total

static func add_block(run: Dictionary) -> bool:
	if blocks(run)>=MAX_BLOCKS: return false
	run.stress_blocks = blocks(run)+1
	return true

static func exhausted(run: Dictionary, capacity: float) -> bool:
	return float(run.stamina) < 0.2 * capacity

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

# The boat controller can show every unmet requirement instead of hiding its gate.
# Underwater capability is supplied by the encounter, not inferred from Dexterity.
static func kraken_requirements(run: Dictionary, base_stamina: float, underwater: bool) -> Array:
	return [
		{"label": "Energy: exactly one full bar", "met": absf(float(run.stamina) - base_stamina) <= 0.001},
		{"label": "Stress: five full bars", "met": value(run) >= MAX_STRESS},
		{"label": "Able to remain underwater", "met": underwater}
	]
