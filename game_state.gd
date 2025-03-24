extends Node

var current_round: int = 1
var round_min_scores = [200, 250, 300, 350, 400, 500, 600, 700, 850, 1000, 1200, 1500]
var money: int = 5  # Start with $5
var tmp_plays_remaining: int = 0

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
	
	# Total reward
	reward["total"] = reward["base"] + reward["unused_plays"] + reward["interest"]
	
	return reward

func add_money(amount: int):
	money += amount
