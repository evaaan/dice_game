extends Node

var current_round: int = 1
var round_min_scores = [200, 250, 300, 350, 400, 500, 600, 700, 850, 1000, 1200, 1500]
var money: int = 5  # Start with $5
var tmp_plays_remaining: int = 0

# Player's active jokers (up to 5)
var active_jokers = []

# All available jokers in the game
var all_jokers = {
	"blue": {
		"name": "Blue",
		"type": "common",
		"cost": 4,
		"description": "Odd dice give +20 chips"
	},
	"red": {
		"name": "Red",
		"type": "common",
		"cost": 4,
		"description": "Even dice give +4 mult"
	},
	"snake_eyes": {
		"name": "Snake Eyes",
		"type": "rare",
		"cost": 6,
		"description": "1s add +10 chips on score"
	},
	"blue_double": {
		"name": "Blue Double",
		"type": "common",
		"cost": 4,
		"description": "Double gives +40 chips"
	},
	"red_double": {
		"name": "Red Double",
		"type": "common",
		"cost": 4,
		"description": "Doubles give +10 mult"
	},
	"blue_triple": {
		"name": "Blue Triple",
		"type": "common",
		"cost": 4,
		"description": "Triple gives +60 chips"
	},
	"red_triple": {
		"name": "Red Triple",
		"type": "common",
		"cost": 4,
		"description": "Triple gives +15 mult"
	},
	"little_scale": {
		"name": "Little Scale",
		"type": "common",
		"cost": 4,
		"description": "Little adds +20 chips permanently on score"
	},
	"half": {
		"name": "Half",
		"type": "common",
		"cost": 4,
		"description": "+20 mult on 2 dice or less"
	},
	"sixes": {
		"name": "6s",
		"type": "common",
		"cost": 4,
		"description": "Scored 6s give +15 chips and +4 mult"
	},
	"scaling_lows": {
		"name": "Scaling Lows",
		"type": "rare",
		"cost": 6,
		"description": "Scoring 1s, 2s, 3s permanently gives +1 mult scaling to the joker"
	},
	"green": {
		"name": "Green",
		"type": "common",
		"cost": 4,
		"description": "Permanently gains +1 mult per play, -1 mult per reroll"
	},
	"pair_scale": {
		"name": "Pair Scale",
		"type": "epic",
		"cost": 8,
		"description": "x2 mult for pair"
	},
	"triple_scale": {
		"name": "Triple Scale",
		"type": "epic",
		"cost": 8,
		"description": "x3 mult for triple"
	},
	"quad_scale": {
		"name": "Quad Scale",
		"type": "epic",
		"cost": 8,
		"description": "x3 mult for quad"
	},
	"shortcut": {
		"name": "Shortcut",
		"type": "rare",
		"cost": 6,
		"description": "Littles can have gaps, i.e. 1 3 4 6"
	},
	"gold": {
		"name": "Gold",
		"type": "common",
		"cost": 4,
		"description": "Earn an extra $5 at end of the round"
	}
}

# Joker-specific state variables
var scaling_lows_mult = 0
var green_mult = 0

func get_current_score_threshold() -> int:
	return round_min_scores[current_round - 1]

func advance_round():
	if current_round < round_min_scores.size():
		current_round += 1

func calculate_round_reward(plays_left: int) -> Dictionary:
	var reward = {}
	
	# Base reward for completing a round
	reward["base"] = 5
	
	# Reward for unused plays
	reward["unused_plays"] = plays_left
	
	# Calculate subtotal (money + base + unused_plays)
	var subtotal = money + reward["base"] + reward["unused_plays"]
	
	# Interest (1 per 5 money) based on subtotal
	reward["interest"] = subtotal / 5
	
	# Check for Gold joker
	var extra_gold = 0
	for joker in active_jokers:
		if joker == "gold":
			extra_gold = 5
			break
	
	reward["gold"] = extra_gold
	
	# Total reward
	reward["total"] = reward["base"] + reward["unused_plays"] + reward["interest"] + reward["gold"]
	
	return reward

func add_money(amount: int):
	money += amount

func add_joker(joker_id):
	if active_jokers.size() < 5 and joker_id in all_jokers:
		var joker_cost = all_jokers[joker_id]["cost"]
		if money >= joker_cost:
			money -= joker_cost
			active_jokers.append(joker_id)
			return true
	return false

func get_random_jokers(count: int) -> Array:
	var available_jokers = all_jokers.keys()
	available_jokers.shuffle()
	
	var result = []
	for i in range(min(count, available_jokers.size())):
		result.append(available_jokers[i])
	
	return result

func reset():
	current_round = 1
	money = 5
	active_jokers = []
	scaling_lows_mult = 0
	green_mult = 0
