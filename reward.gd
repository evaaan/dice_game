extends Control

@onready var game_state = get_node("/root/GameState")

func _ready():
	$ButtonContinue.pressed.connect(_on_continue_pressed)
	
	# Calculate rewards
	var rewards = game_state.calculate_round_reward(game_state.tmp_plays_remaining)
	
	# Update the reward breakdown text
	var reward_text = "Reward Breakdown:\n\n"
	reward_text += "Previous: $%d\n" % game_state.money
	reward_text += "Round Reward: $%d\n" % rewards["base"]
	reward_text += "Unused Sets: %d x $1 = $%d\n" % [game_state.tmp_plays_remaining, rewards["unused_plays"]]
	reward_text += "Interest: $1 x %d = $%d\n" % [rewards["interest"], rewards["interest"]]
	
	# Add Gold joker reward if present
	if rewards["gold"] > 0:
		reward_text += "Gold Joker: $%d\n" % rewards["gold"]
	
	reward_text += "\nTotal Money: $%d" % (game_state.money + rewards["total"])
	
	$LabelRewards.text = reward_text
	
	# Add the money
	game_state.add_money(rewards["total"])

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://Shop.tscn")
