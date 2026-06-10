extends NPC
# The Distraught Merchant — sitting outside the city wall at the drain exit, zone_outside_gate.
# Lost cargo somewhere south of the city after being abandoned by hired mercenaries.

func _ready() -> void:
	grid_cell             = Vector2i(55, 44)
	interaction_reach     = 2
	stat_strength         = 5
	stat_dexterity        = 4
	stat_agility          = 4
	stat_constitution     = 5
	stat_willpower        = 4
	stat_perception       = 4
	skills["melee"]       = 3
	skills["dodge"]       = 2
	equipment["torso"]    = DataManager.get_item("tunic")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin"),
							DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Distraught Merchant"
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data
	var reopen := func():
		EventBus.dialogue_closed.connect(func(_e): _reopen_dialogue(), CONNECT_ONE_SHOT)

	dialogue_text = "You see a man in torn clothes, covered in claw marks sitting with his head between his hands. He looks up as you approach."

	var has_quest: bool  = GameManager.has_quest("merchant_lost_cargo")
	var quest_done: bool = pd.get("merchant_cargo_returned", false)

	var inv: Array      = pd.get("inventory", [])
	var has_package: bool = false
	for item in inv:
		if item.get("id", "") == "unnamed_package":
			has_package = true
			break

	if quest_done:
		dialogue_text    = "The merchant nods at you as you approach, looking considerably calmer."
		dialogue_options = [
			{"label": "Any news?", "response": "Still waiting on contacts in the city before I can move on. But I am grateful.", "closes": true},
			{"label": "Goodbye.", "response": "Safe travels.", "closes": true},
		]
		return

	if has_quest and has_package:
		var return_cargo := func():
			var player_inv: Array = pd.get("inventory", [])
			for i in range(player_inv.size() - 1, -1, -1):
				if player_inv[i].get("id", "") == "unnamed_package":
					player_inv.remove_at(i)
					break
			for _c in range(25):
				player_inv.append(DataManager.get_item("coin"))
			pd["inventory"]               = player_inv
			pd["merchant_cargo_returned"] = true
			GameManager.complete_quest_thread("merchant_lost_cargo", "recover_cargo")
			GameManager.complete_quest("merchant_lost_cargo")
			GameManager.add_xp(250)
			EventBus.inventory_changed.emit()

		dialogue_text    = "The merchant's eyes go wide as he sees the package in your hands."
		dialogue_options = [
			{
				"label":    "I found your cargo.",
				"response": "I — yes. That is it. That is exactly it. I cannot believe it. Here, please, take what I promised you. I am in your debt.",
				"action":   return_cargo,
				"next_options": [
					{"label": "Good luck getting where you're going.", "closes": true},
				],
			},
			{"label": "Goodbye.", "response": "Please — if you have it, bring it back.", "closes": true},
		]
		return

	if has_quest:
		dialogue_options = [
			{
				"label":    "Still looking for your cargo.",
				"response": "It is somewhere to the south — we didn't make it far before they scattered. I appreciate you trying.",
				"next_options": [
					{"label": "I'll keep looking.", "closes": true, "action": reopen},
				],
			},
			{"label": "Goodbye.", "response": "Please hurry.", "closes": true},
		]
		return

	var accept_quest := func():
		GameManager.add_quest({
			"id":          "merchant_lost_cargo",
			"title":       "The Merchant's Lost Cargo",
			"summary":     "A merchant lost his cargo somewhere south of the Ditch after being abandoned by hired mercenaries during a coyote attack. He'll pay 25 coins on recovery.",
		})
		GameManager.add_quest_thread("merchant_lost_cargo", {
			"id":    "recover_cargo",
			"title": "Find the lost cargo somewhere to the south of the drainage pipe exit.",
		})

	dialogue_options = [
		{
			"label":    "What's wrong?",
			"action":   func(): GameManager.add_note({
				"id":    "nomad_tribes",
				"title": "The Nomad Tribes",
				"body":  "Craftsmen live among nomad tribes in the desert south of the city. Trade with them is possible but dangerous — coyotes are a serious threat on the desert routes, and hired mercenaries can scatter at the first sign of trouble.",
			}, 5),
			"response": "I am a merchant, and I was travelling into the desert to trade with the craftsmen in the nomad tribes. I hired mercenaries to guide and guard me, but I was scammed. They were useless. They ran when we were attacked by a pack of coyotes. I lost my package when we were fleeing.",
			"next_options": [
				{
					"label":  "Sorry to hear that.",
					"closes": true,
				},
				{
					"label":    "I could find it for you.",
					"response": "It is worth a lot to me if you can recover it. I would pay you 25 coins upon your return with it. It is somewhere to the south of here — we did not make it far before everything fell apart.",
					"action":   accept_quest,
					"next_options": [
						{"label": "I'll look for it.", "closes": true},
						{"label": "On second thought, no.", "closes": true},
					],
				},
			],
		},
		{"label": "Goodbye.", "response": "...", "closes": true},
	]

func _reopen_dialogue() -> void:
	_update_dialogue()
	EventBus.interaction_triggered.emit(self, "talk")
