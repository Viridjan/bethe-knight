extends RefCounted
## Whole resource points distributed over five ticks; physics remains at 60 Hz.
const FRAMES := 12
const PER_SECOND := 5
# Regeneration spreads its whole points over every physics frame instead: single points at an even pace.
const FRAMES_PER_SECOND := FRAMES * PER_SECOND
static func share(rate_per_s: int, tick: int, per_second := PER_SECOND) -> int:
	var phase := tick % per_second
	return (phase + 1) * rate_per_s / per_second - phase * rate_per_s / per_second
