extends RefCounted
# Shared authoring rules; mutable current HP stays on each actor.
const FAMILIES := ["enemy_thornmite", "enemy_skree", "enemy_bat", "enemy_skeleton", "enemy_hornback", "enemy_fuzzbob", "enemy_cragjaw", "enemy_murkspore", "enemy_mosstrot", "enemy_monster"]

static func valid(value) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 1 and value <= 10000 and float(value) == floorf(float(value))

static func base(profile: Dictionary, fallback: int) -> int:
	return int(profile.max_hp) if valid(profile.get("max_hp", null)) else fallback

static func modified(base_hp: int, modifier: String) -> int:
	match modifier:
		"swift": return maxi(1, base_hp - 1)
		"armored": return base_hp + 2
		"giant": return base_hp * 2
		"shielded": return base_hp + 1
	return base_hp
