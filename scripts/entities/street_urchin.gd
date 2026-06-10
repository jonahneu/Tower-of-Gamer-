extends NPC
# The Street Urchin — young, unsettling, knows the Ditch better than anyone.
# Introduction to theft and the criminal economy.

func _ready() -> void:
	grid_cell             = Vector2i(32, 35)
	force_hidden          = true
	stat_strength         = 4
	stat_dexterity        = 7
	stat_agility          = 7
	stat_constitution     = 5
	stat_willpower        = 5
	stat_perception       = 8
	skills["melee"]       = 5
	skills["dodge"]       = 8
	# pocket_items intentionally empty — she has nothing, that's the joke
	super._ready()
	entity_name = "Street Urchin"
	dialogue_text = "You're new. You've got that look — just got out of somewhere. You don't have anything yet."
	dialogue_options = [
		{
			"label": "What look?",
			"response": "Like you're counting what you have and it's not much. It's fine. Everyone down here started that way. Most of them are still that way. You want to not be that way?",
			"next_options": [
				{
					"label": "Yes. What do you know?",
					"response": "I know where things are. I know who has things they won't miss. I know a man who buys things without asking how you got them. Whether that's useful to you depends on what you're willing to do.",
					"next_options": [
						{"label": "Tell me more about the fence.", "response": "Not yet. Show me you can move quietly first. There are ways to practice that. I'll watch.", "closes": true},
						{"label": "I'm not a thief.", "response": "Sure. Come find me when you change your mind.", "closes": true},
					],
				},
				{"label": "Not from you.", "response": "Fair. I'll be around.", "closes": true},
			],
		},
		{
			"label": "How long have you lived down here?",
			"response": "Long enough. The Ditch isn't bad if you know where to stand. The slope down south gets worse at night — don't go down there without a light. Or a god. Preferably both.",
			"next_options": [
				{
						"label": "What's down south?",
						"response": "The undercity. You'll find out eventually. Everyone does.",
						"closes": true,
						"action": func(): GameManager.add_note({
							"id":    "the_undercity",
							"title": "The Undercity",
							"body":  "Below the southern slope of the Ditch lies the Undercity. Do not go without a light or a god — preferably both. Everyone finds out what is down there eventually.",
						}, 5),
					},
				{"label": "Thanks for the warning.", "response": "Wasn't a warning. Just a fact.", "closes": true},
			],
		},
		{
			"label": "Farewell.",
			"response": "Don't get robbed.",
			"closes": true,
		},
	]
