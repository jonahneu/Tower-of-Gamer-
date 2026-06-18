extends RefCounted
class_name LightLevels

# Three light tiers used by fog-of-war vision capping, enemy aggro/detection,
# and the combat-manager group-awareness state machine. Single source of
# truth for the tiering rules so all three stay consistent.

enum { DARK = 0, DIM = 1, FULL = 2 }

const DARK_PEEK: int = 2

# Max distance an observer in `observer_level` light can resolve a target
# standing in `target_level` light, given an unmodified `base_radius`.
static func vision_cap(observer_level: int, target_level: int, base_radius: int) -> int:
	if observer_level == FULL:
		if target_level == FULL:
			return base_radius
		elif target_level == DIM:
			return maxi(1, base_radius / 2)
		else:
			return DARK_PEEK
	elif observer_level == DIM:
		if target_level == DARK:
			return DARK_PEEK
		else:
			return maxi(1, base_radius / 2)
	else:  # observer DARK — tiny FOV regardless of what's being looked at
		return DARK_PEEK

# Flat penalty to a detector's effective Perception when the target being
# perceived stands in `target_level` light. Penalizes the detector, keyed by
# the TARGET's light — a well-lit detector still struggles to spot someone
# standing in the dark.
static func perception_penalty(target_level: int) -> int:
	match target_level:
		DARK:
			return -5
		DIM:
			return -2
		_:
			return 0
