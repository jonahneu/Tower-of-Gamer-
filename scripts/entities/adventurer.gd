extends NPC
# Experienced adventurer standing at the ditch hole — the first person the player
# meets who has actually been deep below. Mentions the great frog, references
# forge+scribe training. Serves as a role-model figure for the descent ahead.
# Disappears once the player has spoken to him and left the zone.

func _ready() -> void:
	if not GameManager.player_data.get("dream_seen", false):
		queue_free()
		return
	if GameManager.player_data.get("met_adventurer", false):
		queue_free()
		return
	grid_cell             = Vector2i(43, 16)
	stat_strength         = 12
	stat_dexterity        = 8
	stat_agility          = 7
	stat_constitution     = 14
	stat_willpower        = 9
	stat_perception       = 10
	level                 = 25
	hp_flat_bonus         = 800.0
	skills["melee"]       = 180
	skills["dodge"]       = 60
	drops_loot            = false
	super._ready()
	entity_name  = "Adventurer"
	_set_dialogue()

func prepare_dialogue() -> void:
	if not GameManager.player_data.get("met_adventurer", false):
		GameManager.player_data["met_adventurer"] = true
		# Same quest id a future "saw it with your own eyes" hook would use further
		# in — add_quest no-ops if it's already tracked, so whichever the player
		# hits first is the one that sticks.
		GameManager.add_quest({
			"id":          "great_frog",
			"title":       "The Great Frog",
			"description": "An adventurer at the descent hole said the main route deeper into the undercity is blocked by a great toad from far below. Its kind are usually docile — something disturbed it badly enough to drive it up this high, and it's settled in rather than moving on. Find another way down, or deal with the frog directly.",
			"threads":     [],
			"completed":   false,
		})
		GameManager.add_note({
			"id":    "great_frog",
			"title": "The Great Frog",
			"body":  "An experienced adventurer at the descent hole mentioned that the usual route deeper into the undercity is blocked by a large toad from the deep. He said its kind are usually docile — something must have disturbed it badly to bring it this high up.",
		}, 0)

func _set_dialogue() -> void:
	dialogue_text = "You see a large, heavily armored man, peering down into the darkness below. His armor is finely crafted, and has numerous elegantly scribed talismans hanging off of it. He wears a large warhammer on his back. He looks your way and nods politely as you approach. \"Greetings, are you headed to the depths? I recently returned to the city to visit the Forge Masters and was going to return to my adventures below, but the usual route deeper into the undercity is currently blocked by a large toad from deep below the undercity. I have seen its kind below, they are usually relatively docile. Something must have really disturbed this one for it to have come this high up. I don't really want to kill it, so I'm looking for another way down. Maybe I will jump in this hole, I think I'm tough enough to survive the fall.\""

	var goodbye_opt := {"label": "Thank you for the information.", "closes": true}

	var forge_opt := {
		"label":    "Are you a forge master?",
		"response": "Hahaha, no I am not. Just an adventurer. I have learned much from the Forge Masters over the years, and from the Scribes. Made the majority of my armor and talismans myself, and of course my hammer. Nothing better to protect you below than the power of the metal and scripture of the city.",
	}
	var below_opt := {
		"label":    "You've been below?",
		"response": "Yes, there is a whole world down there. Full of secrets and ancient treasures for one with the strength and cunning to survive down there. If you are headed that way, maybe we will see each other again.",
	}

	below_opt["next_options"] = [forge_opt, goodbye_opt]
	forge_opt["next_options"] = [below_opt, goodbye_opt]

	dialogue_options = [below_opt, forge_opt, goodbye_opt]
