extends "res://tests/ape_composition.gd"
# Run the existing behavioral assertions under a valid non-default runtime profile.
func _ready() -> void:
	var profile: Dictionary = E.AttackCatalog.shared().enemy_profile("boss_ape")
	profile.max_hp = 5
	profile.phase2_hp = 3
	profile.phase2_wave_scales = [1.1, 1.4, 1.8]
	await super._ready()
