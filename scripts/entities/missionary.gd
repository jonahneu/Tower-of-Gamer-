extends NPC
# The Fire Cult Missionary — soft-spoken, attentive, recognizes the godless.
# First faction contact. Offers shelter and protection in exchange for attendance.

func _ready() -> void:
	grid_cell             = Vector2i(18, 32)
	force_hidden          = true
	stat_strength         = 5
	stat_dexterity        = 5
	stat_agility          = 5
	stat_constitution     = 5
	stat_willpower        = 7
	stat_perception       = 7
	skills["melee"]       = 4
	skills["dodge"]       = 3
	equipment["torso"]    = DataManager.get_item("tunic")
	# pocket_items empty — ascetic, carries nothing material
	drops_loot            = true
	super._ready()
	entity_name = "Missionary"
	dialogue_text = "You just got out. I can tell. No — don't explain yourself. I'm not asking. Are you sleeping somewhere tonight?"
	dialogue_options = [
		{
			"label": "I haven't figured that out yet.",
			"response": "I thought so. You're exposed right now — no patron god, no household to shelter under. The spirits here know it before you do. Come to the sermon tonight. Sleep safely. No obligation beyond listening.",
			"next_options": [
				{
					"label": "A sermon? Who do you serve?",
					"response": "The undying flame. The fire that does not need fuel. Very old. Very patient. The cult doesn't ask you to give anything up — not yet. Tonight is just a fire and some words and somewhere to sleep that isn't the open street. That's all.",
					"next_options": [
						{"label": "Where is this sermon?", "response": "The inn, after dark. Ask for Brother Nesim. I'll be there.", "closes": true},
						{"label": "I'll think about it.", "response": "Don't think too long. The night here comes on fast.", "closes": true},
						{"label": "I'm not interested.", "response": "I understand. The offer stands if you change your mind.", "closes": true},
					],
				},
				{"label": "I'll manage on my own.", "response": "Of course. But if you're still out after dark and you reconsider — the inn. Ask for Brother Nesim.", "closes": true},
			],
		},
		{
			"label": "I'm fine. Leave me alone.",
			"response": "Of course. Forgive the intrusion. If you find yourself at the inn tonight — the offer stands.",
			"closes": true,
		},
		{
			"label": "Farewell.",
			"response": "May the flame find you before the dark does.",
			"closes": true,
		},
	]
