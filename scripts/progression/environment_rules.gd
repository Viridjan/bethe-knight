extends RefCounted
const DEFAULT_HEAT_DRAIN := 2.0
const THICK_SPEED := 0.45
const THICK_STROKE := 0.70
static func heat(data: Dictionary, run: Dictionary = {}) -> float:
	if run.get("abilities",[]).has("heat_resist"): return 0.0
	var fallback := DEFAULT_HEAT_DRAIN if data.get("environment","") in ["volcano","volcanic_cave"] else 0.0
	var raw = data.get("heat_drain",fallback)
	return clampf(float(raw),0,100) if (raw is int or raw is float) and is_finite(float(raw)) else fallback
