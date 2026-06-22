extends NPC
# The Mercenary Captain — runs a stall on the southeast side of the Market
# District. Entry point to the mercenary path: first job is the bandit camp's
# leader, the "audition" job from the design doc's [The Mercenary Fixer] notes.

func _ready() -> void:
	grid_cell             = Vector2i(64, 63)
	interaction_reach     = 2
	stat_strength         = 9
	stat_dexterity        = 8
	stat_agility          = 7
	stat_constitution     = 8
	stat_willpower        = 7
	stat_perception       = 7
	level                 = 5
	skills["melee"]       = 35
	skills["dodge"]       = 20
	equipment["hand_1"]   = DataManager.get_item("sword")
	equipment["torso"]    = DataManager.get_item("leather_vest")
	_attack_weapon        = DataManager.get_item("sword")
	pocket_items          = [DataManager.get_item("coin"), DataManager.get_item("coin")]
	drops_loot            = true
	super._ready()
	entity_name = "Mercenary Captain"
	_update_dialogue()

func get_interaction_options() -> Array:
	_update_dialogue()
	return super.get_interaction_options()

func _update_dialogue() -> void:
	var pd: Dictionary = GameManager.player_data

	var has_quest: bool  = GameManager.has_quest("bandit_leader_bounty")
	var quest_done: bool = pd.get("bandit_leader_bounty_done", false)

	var inv: Array = pd.get("inventory", [])
	var has_head: bool = false
	for item in inv:
		if item.get("id", "") == "bandit_leader_head":
			has_head = true
			break

	if quest_done:
		dialogue_text = "[DIALOGUE TBD — Mercenary Captain, after the bandit-leader bounty is paid]"
		dialogue_options = [
			{"label": "Goodbye.", "closes": true},
		]
		return

	if has_quest and has_head:
		var turn_in := func():
			var player_inv: Array = pd.get("inventory", [])
			for i in range(player_inv.size() - 1, -1, -1):
				if player_inv[i].get("id", "") == "bandit_leader_head":
					player_inv.remove_at(i)
					break
			for _c in range(30):
				player_inv.append(DataManager.get_item("coin"))
			pd["inventory"] = player_inv
			pd["bandit_leader_bounty_done"] = true
			GameManager.complete_quest_thread("bandit_leader_bounty", "kill_bandit_leader")
			GameManager.complete_quest("bandit_leader_bounty")
			EventBus.inventory_changed.emit()

		dialogue_text = "[DIALOGUE TBD — Mercenary Captain reacts to the bandit leader's head]"
		dialogue_options = [
			{
				"label":  "Here's your proof.",
				"action": turn_in,
				"closes": true,
			},
			{"label": "Not yet.", "closes": true},
		]
		return

	if has_quest:
		dialogue_text = "[DIALOGUE TBD — Mercenary Captain, bounty still open]"
		dialogue_options = [
			{"label": "Still working on it.", "closes": true},
		]
		return

	var accept_quest := func():
		GameManager.add_quest({
			"id":          "bandit_leader_bounty",
			"title":       "The Bandit Leader's Head",
			"description": "The Mercenary Captain wants proof that the bandit camp's leader is dead. Their camp is said to be north of the path between the market gate and the docks. He'll pay 30 coins for the leader's head.",
			"threads":     [],
			"completed":   false,
		})
		GameManager.add_quest_thread("bandit_leader_bounty", {
			"id":    "kill_bandit_leader",
			"title": "Bring the bandit leader's head back to the Mercenary Captain.",
		})

	var job_offer_response: String = "\"My men are busy right now, but some bandits have been attacking travelers and fishermen between the city and the river. I have word their camp is north of the path from the gate west of here to the docks. I'll pay you if you return with their leader's head. 30 coins.\""

	var job_offer_options: Array = [
		{
			"label":  "I'll do it.",
			"action": accept_quest,
			"closes": true,
		},
		{"label": "No thanks.", "closes": true},
	]

	dialogue_text = "You see a scarred, salt-and-pepper-haired man in tight leather armor with a sword at his side. As you approach he says, \"What is it? Looking for work?\""

	dialogue_options = [
		{
			"label":        "Yes.",
			"response":     job_offer_response,
			"next_options": job_offer_options,
		},
		{
			"label":        "What kind of work?",
			"response":     job_offer_response,
			"next_options": job_offer_options,
		},
		{"label": "No thanks.", "closes": true},
	]
