extends Node2D

const MAX_ROLLS = 4
const MAX_PLAYS = 4
const DICE_COUNT = 5

@onready var game_state = get_node("/root/GameState")

var dice_values = []
var dice_locked = []
var rolls_left = MAX_ROLLS
var plays_left = MAX_PLAYS
var total_score = 0

var set_data = {
	"high": {"points": 10, "mult": 1},
	"double": {"points": 10, "mult": 2},
	"double double": {"points": 20, "mult": 2},
	"triple": {"points": 30, "mult": 3},
	"quad": {"points": 40, "mult": 4},
	"penta": {"points": 50, "mult": 5},
	"full house": {"points": 40, "mult": 4},
	"little": {"points": 30, "mult": 4},
	"big": {"points": 40, "mult": 5},
	"None": {"points": 0, "mult": 0}
}
var dice_start_positions = []

# Variables for joker effects
var additional_chips = 0
var additional_multiplier = 0
var permanent_chips = 0
var permanent_multiplier = 0

func _ready():
	randomize()
	dice_values.resize(DICE_COUNT)
	dice_locked.resize(DICE_COUNT)
	dice_start_positions.resize(DICE_COUNT)

	for i in range(DICE_COUNT):
		var dice_sprite = get_node("DiceContainer/Dice%d" % (i + 1))
		dice_start_positions[i] = dice_sprite.position

	$ButtonRoll.pressed.connect(_on_roll_pressed)
	$ButtonPlay.pressed.connect(_on_play_pressed)
	$ButtonDebug.pressed.connect(_on_debug_pressed)
	$ButtonMainMenu.pressed.connect(_on_main_menu_pressed)
	
	start_new_round()
	
	# Set up joker display boxes
	update_joker_display()

func update_joker_display():
	# Hide all joker boxes first
	for i in range(1, 6):
		var joker_box = get_node_or_null("JokerContainer/JokerBox" + str(i))
		if joker_box:
			joker_box.visible = false
	
	# Show active jokers
	for i in range(game_state.active_jokers.size()):
		var joker_id = game_state.active_jokers[i]
		var joker_data = game_state.all_jokers[joker_id]
		var joker_box = get_node("JokerContainer/JokerBox" + str(i+1))
		
		joker_box.visible = true
		var label = joker_box.get_node("Label")
		
		# Set color based on joker type
		var color_code = ""
		if joker_data["type"] == "common":
			color_code = "[color=#ffffff]"  # White for common
		elif joker_data["type"] == "rare":
			color_code = "[color=#4488ff]"  # Blue for rare
		elif joker_data["type"] == "epic":
			color_code = "[color=#aa44ff]"  # Purple for epic
		
		label.text = color_code + joker_data["name"] + "[/color]"
		
		# Set tooltip
		joker_box.tooltip_text = joker_data["description"]

func start_new_round():
	reset_set_score()
	for i in range(DICE_COUNT):
		dice_locked[i] = false
		dice_values[i] = randi() % 6 + 1
		
		var dice_sprite = get_node("DiceContainer/Dice%d" % (i + 1))
		dice_sprite.position = dice_start_positions[i]
		update_dice_border(dice_sprite, false)

	display_dice([0,1,2,3,4])  # clearly animate all dice initially
	update_ui()


func display_dice(rolled_indices=[]):
	for i in range(DICE_COUNT):
		var dice_sprite = get_node("DiceContainer/Dice%d" % (i + 1))
		dice_sprite.texture = load("res://dice_%d.png" % dice_values[i])
		
		if i in rolled_indices:
			animate_dice_roll(dice_sprite)  # animate clearly only rolled dice


func update_dice_border(dice_sprite, selected):
	if selected:
		dice_sprite.modulate = Color(1, 1, 0.4)  # Slightly yellow tint
	else:
		dice_sprite.modulate = Color(1, 1, 1)  # No tint
		
func animate_dice_roll(dice_sprite):
	var tween = create_tween()
	var original_rotation = dice_sprite.rotation_degrees

	# Rocking animation (rotate slightly back and forth)
	tween.tween_property(dice_sprite, "rotation_degrees", original_rotation - 10, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(dice_sprite, "rotation_degrees", original_rotation + 10, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# tween.tween_property(dice_sprite, "rotation_degrees", original_rotation - 10, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# tween.tween_property(dice_sprite, "rotation_degrees", original_rotation + 10, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dice_sprite, "rotation_degrees", original_rotation, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func roll_unlocked_dice():
	var rolled_indices = []
	for i in range(DICE_COUNT):
		if not dice_locked[i]:
			dice_values[i] = randi() % 6 + 1
			rolled_indices.append(i)
	return rolled_indices

			
func get_scoring_dice():
	var selected_values = []
	var selected_indices = []
	for i in range(DICE_COUNT):
		if dice_locked[i]:
			selected_values.append(dice_values[i])
			selected_indices.append(i)

	var counts = {}
	for val in selected_values:
		counts[val] = counts.get(val, 0) + 1
	
	var scoring_indices = []
	var set_type = detect_set_type()

	match set_type:
		"penta", "quad", "triple", "double":
			var required = {"penta":5, "quad":4, "triple":3, "double":2}[set_type]
			for val in counts:
				if counts[val] >= required:
					var count = 0
					for idx in selected_indices:
						if dice_values[idx] == val and count < required:
							scoring_indices.append(idx)
							count += 1
					break
		"double double":
			var pairs_found = 0
			for val in counts:
				if counts[val] >= 2 and pairs_found < 2:
					var count = 0
					for idx in selected_indices:
						if dice_values[idx] == val and count < 2:
							scoring_indices.append(idx)
							count += 1
					pairs_found += 1
		"full house":
			var triple_val = null
			var double_val = null
			for val in counts:
				if counts[val] >= 3 and triple_val == null:
					triple_val = val
				elif counts[val] >= 2 and double_val == null:
					double_val = val
			for idx in selected_indices:
				if dice_values[idx] == triple_val and scoring_indices.count(idx) < 3:
					scoring_indices.append(idx)
				elif dice_values[idx] == double_val and scoring_indices.count(idx) < 2:
					scoring_indices.append(idx)
		"little":
			var little_sets = [[1,2,3,4],[2,3,4,5],[3,4,5,6]]
			for little in little_sets:
				if little.all(func(n): return n in selected_values):
					for idx in selected_indices:
						if dice_values[idx] in little:
							scoring_indices.append(idx)
					break
		"big":
			var big_sets = [[1,2,3,4,5],[2,3,4,5,6]]
			for big in big_sets:
				if big.all(func(n): return n in selected_values):
					for idx in selected_indices:
						if dice_values[idx] in big:
							scoring_indices.append(idx)
					break
		"high":
			var highest_val = -1
			var highest_idx = -1
			for idx in selected_indices:
				if dice_values[idx] > highest_val:
					highest_val = dice_values[idx]
					highest_idx = idx
			scoring_indices.append(highest_idx)

	return scoring_indices


func calculate_score(dice_set):
	var set_type = detect_set_type(dice_set)
	var points = set_data[set_type].points
	var mult = set_data[set_type].mult

	var dice_sum = 0
	for val in dice_set:
		dice_sum += val

	return {"points": (points + dice_sum) * mult, "type": set_type}
	
func show_set_score(score):
	$LabelContainer/LabelSetScore.text = "%d" % score

func reset_set_score():
	$LabelContainer/LabelSetScore.text = ""


func update_ui():
	var set_type = detect_set_type()
	var points = set_data[set_type].points
	var mult = set_data[set_type].mult

	$LabelContainer/LabelRollsLeft.text = "Rolls Left: %d" % rolls_left
	$LabelContainer/LabelPlaysLeft.text = "Plays Left: %d" % plays_left
	$LabelContainer/LabelTotalScore.text = "Total Score: %d" % total_score
	$LabelContainer/LabelTotalScore.visible = true
	
	$LabelContainer/LabelMoney.text = "Money: $%d" % game_state.money

	if set_type == "None":
		$LabelContainer/LabelSetType.text = ""
	else:
		$LabelContainer/LabelSetType.text = "%s" % set_type

	$LabelContainer/LabelPoints.text = "Points: %d" % points
	$LabelContainer/LabelMult.text = "Multiplier: %d" % mult
	$LabelContainer/LabelMinScore.text = "Minimum Score: %d" % game_state.get_current_score_threshold()
	$LabelContainer/LabelRoundNumber.text = "Round %d of %d" % [game_state.current_round, game_state.round_min_scores.size()]


func _on_roll_pressed():
	if rolls_left > 0:
		var rolled_indices = roll_unlocked_dice()  # clearly capture indices rolled
		rolls_left -= 1
		display_dice(rolled_indices)  # clearly pass rolled dice indices
		update_ui()


func _on_play_pressed():
	if plays_left > 0:
		plays_left -= 1
		
		# Apply Green joker effect (if active) when playing
		if "green" in game_state.active_jokers:
			game_state.green_mult += 1
		
		# Reset temporary joker effects for this play
		additional_chips = 0
		additional_multiplier = 0
		
		# Calculate score based on selected dice
		var selected_dice = []
		var selected_indices = []
		
		for i in range(dice_values.size()):
			if dice_locked[i]:
				selected_dice.append(dice_values[i])
				selected_indices.append(i)
		
		var score_result = calculate_score(selected_dice)
		var points = score_result["points"]
		var score_type = score_result["type"]
		
		# Apply joker effects based on score type and dice values
		apply_joker_effects(selected_dice.duplicate(), score_type)
		
		# Apply additional points from jokers
		points += additional_chips
		points *= (1 + (additional_multiplier / 100.0))
		
		# Apply permanent bonuses
		points += permanent_chips
		points *= (1 + (permanent_multiplier / 100.0))
		
		# Round to integer
		points = int(points)
		
		# Update total score
		# total_score += points
		
		# Play scoring animation
		play_scoring_animation(selected_indices, 0, 0, points)
		
		# Update UI
		update_ui()
		
		# Check if all plays are used
		if plays_left <= 0:
			# Create timer for delay then transition
			var timer = get_tree().create_timer(1.0)
			timer.timeout.connect(func(): 
				game_state.tmp_plays_remaining = plays_left
				get_tree().change_scene_to_file("res://Reward.tscn")
			)
		
func apply_joker_effects(dice_set, score_type):
	# Reset temporary effects
	additional_chips = 0
	additional_multiplier = 0
	
	# Check each active joker
	for joker_id in game_state.active_jokers:
		match joker_id:
			"blue":
				# Odd dice give +20 chips
				for value in dice_set:
					if value % 2 == 1:  # Odd dice
						additional_chips += 20
			
			"red":
				# Even dice give +4 mult
				for value in dice_set:
					if value % 2 == 0:  # Even dice
						additional_multiplier += 4
			
			"snake_eyes":
				# 1s add +10 chips on score
				for value in dice_set:
					if value == 1:
						additional_chips += 10
			
			"blue_double":
				# Double gives +40 chips
				if score_type == "double":
					additional_chips += 40
			
			"red_double":
				# Doubles give +10 mult
				if score_type == "double":
					additional_multiplier += 10
			
			"blue_triple":
				# Triple gives +60 chips
				if score_type == "triple":
					additional_chips += 60
			
			"red_triple":
				# Triple gives +15 mult
				if score_type == "triple":
					additional_multiplier += 15
			
			"little_scale":
				# Little adds +20 chips permanently on score
				if score_type == "little":
					permanent_chips += 20
			
			"half":
				# +20 mult on 2 dice or less
				if dice_set.size() <= 2:
					additional_multiplier += 20
			
			"sixes":
				# Scored 6s give +15 chips and +4 mult
				for value in dice_set:
					if value == 6:
						additional_chips += 15
						additional_multiplier += 4
			
			"scaling_lows":
				# Scoring 1s, 2s, 3s permanently gives +1 mult scaling to the joker
				for value in dice_set:
					if value >= 1 and value <= 3:
						game_state.scaling_lows_mult += 1
				additional_multiplier += game_state.scaling_lows_mult
			
			"green":
				# Permanently gains +1 mult per play, -1 mult per reroll
				additional_multiplier += game_state.green_mult
			
			"pair_scale":
				# x2 mult for pair
				if score_type == "double":
					additional_multiplier += 1  # x2 multiplier
			
			"triple_scale":
				# x3 mult for triple
				if score_type == "triple":
					additional_multiplier += 2  # x3 multiplier
			
			"quad_scale":
				# x3 mult for quad
				if score_type == "quad":
					additional_multiplier += 2  # x3 multiplier

func _on_debug_pressed():
	total_score += 100
	update_ui()

func _on_main_menu_pressed():
	# Reset game state
	total_score = 0
	plays_left = MAX_PLAYS
	rolls_left = MAX_ROLLS
	game_state.current_round = 1
	game_state.money = 5  # Reset money to starting amount
	game_state.active_jokers = []  # Reset jokers
	game_state.scaling_lows_mult = 0
	game_state.green_mult = 0
	permanent_chips = 0
	permanent_multiplier = 0
	
	# Return to main menu
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func detect_set_type(dice_set = null):
	var selected_values = []
	
	if dice_set == null:
		for i in range(DICE_COUNT):
			if dice_locked[i]:
				selected_values.append(dice_values[i])
	else:
		selected_values = dice_set

	if selected_values.size() == 0:
		return "None"

	selected_values.sort()
	var counts = {}
	for val in selected_values:
		counts[val] = counts.get(val, 0) + 1

	var count_values = counts.values()
	var unique_counts = count_values.duplicate()
	unique_counts.sort()

	var little_sets = [[1,2,3,4],[2,3,4,5],[3,4,5,6]]
	var big_sets = [[1,2,3,4,5],[2,3,4,5,6]]

	var is_little = false
	var is_big = false

	for little in little_sets:
		if little.all(func(n): return n in selected_values):
			is_little = true
			break

	for big in big_sets:
		if big.all(func(n): return n in selected_values):
			is_big = true
			break

	if 5 in count_values:
		return "penta"
	elif 4 in count_values:
		return "quad"
	elif 3 in count_values and 2 in count_values:
		return "full house"
	elif 3 in count_values:
		return "triple"
	elif unique_counts.count(2) >= 2:
		return "double double"
	elif 2 in count_values:
		return "double"
	elif is_big:
		return "big"
	elif is_little:
		return "little"
	else:
		return "high"  # <-- fixed here, default to 'high'

func play_scoring_animation(selected_indices, current_index, cumulative_score, current_points):
	if current_index >= selected_indices.size():
		var tween_final = create_tween()
		tween_final.tween_interval(0.5)
		tween_final.tween_callback(func():
			end_scoring_animation(cumulative_score)
		)
		return
	
	var dice_index = selected_indices[current_index]
	var dice_sprite = get_node("DiceContainer/Dice%d" % (dice_index + 1))
	var original_scale = dice_sprite.scale
	var dice_value = dice_values[dice_index]

	# Immediately update points at start clearly
	current_points += dice_value
	$LabelContainer/LabelPoints.text = "Points: %d" % current_points

	# Animate dice scale-up
	var tween = create_tween()
	tween.tween_property(dice_sprite, "scale", original_scale * 1.3, 0.2).set_trans(Tween.TRANS_BACK)

	# Show temporary score label above dice
	var label = $LabelDiceScore
	label.text = "+%d" % dice_value
	label.global_position = dice_sprite.global_position + Vector2(0, -60)
	label.visible = true
	label.modulate = Color(1, 1, 1, 1)

	# Animate score label moving up and fading
	var label_tween = create_tween()
	label_tween.tween_property(label, "global_position", label.global_position + Vector2(0, -30), 0.5)
	label_tween.parallel().tween_property(label, "modulate:a", 0, 0.5)

	# Scale-down dice after short pause
	tween.tween_interval(0.15)
	tween.tween_property(dice_sprite, "scale", original_scale, 0.2).set_trans(Tween.TRANS_BACK)

	tween.tween_callback(func():
		label.visible = false

		if current_index == selected_indices.size() - 1:
			var final_tween = create_tween()
			# final_tween.tween_interval(0.25)
			final_tween.tween_callback(func():
				end_scoring_animation(cumulative_score + dice_value)
			)
		else:
			play_scoring_animation(selected_indices, current_index + 1, cumulative_score + dice_value, current_points)
	)

func end_scoring_animation(dice_total_score):
	var set_type = detect_set_type()
	var points = set_data[set_type].points
	var mult = set_data[set_type].mult
	
	var round_score = (points + dice_total_score) * mult
	total_score += round_score
	
	show_set_score(round_score)
	
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		reset_set_score()
		
		var round_min_score = game_state.get_current_score_threshold()
		
		if total_score >= round_min_score:
			print("Round cleared! Score: %d" % total_score)
			
			# Calculate rewards before resetting
			var plays_remaining = plays_left
			
			# Reset score 
			total_score = 0
			
			# Advance to next round
			game_state.advance_round()
			
			# Create timer for delay then transition
			plays_left = MAX_PLAYS
			rolls_left = MAX_ROLLS
			# start_new_round()
			var timer = get_tree().create_timer(1.0)
			timer.timeout.connect(func(): 
				game_state.tmp_plays_remaining = plays_remaining
				get_tree().change_scene_to_file("res://Reward.tscn")
			)
		else:
			if plays_left <= 0:
				game_over()
			else:
				start_new_round()
		
		$ButtonRoll.disabled = false
		$ButtonPlay.disabled = false
	)


func game_won():
	$ButtonRoll.disabled = true
	$ButtonPlay.disabled = true
	$LabelContainer/LabelPlaysLeft.text = "You Won!"
	$LabelContainer/LabelTotalScore.text = "Final Score: %d" % total_score
	print("Congratulations! You won with score:", total_score)


func game_over():
	$ButtonRoll.disabled = true
	$ButtonPlay.disabled = true
	$LabelContainer/LabelPlaysLeft.text = "Game Over!"
	$LabelContainer/LabelTotalScore.text = "Final Score: %d" % total_score
	print("Game Over! Your final score:", total_score)


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		for i in range(DICE_COUNT):
			var dice_sprite = get_node("DiceContainer/Dice%d" % (i + 1))
			var sprite_rect = Rect2(
				dice_sprite.global_position - dice_sprite.texture.get_size() / 2,
				dice_sprite.texture.get_size()
			)
			if sprite_rect.has_point(event.position):
				dice_locked[i] = !dice_locked[i]
				update_dice_border(dice_sprite, dice_locked[i])

				# Move dice up or down based on selection
				if dice_locked[i]:
					dice_sprite.position.y -= 50
				else:
					dice_sprite.position.y += 50

				update_ui()

func _on_reroll_pressed():
	if rolls_left > 0 and plays_left > 0:
		rolls_left -= 1
		
		# Apply Green joker effect (if active) when rerolling
		if "green" in game_state.active_jokers:
			game_state.green_mult -= 1
		
		# Reroll unselected dice
		for i in range(DICE_COUNT):
			if not dice_locked[i]:
				dice_values[i] = randi() % 6 + 1
				var dice_sprite = get_node("DiceContainer/Dice%d" % (i + 1))
				dice_sprite.texture = load("res://dice_%d.png" % dice_values[i])
		
		# Update UI
		update_ui()
