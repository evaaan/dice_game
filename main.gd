extends Node2D

const MAX_ROLLS = 3
const MAX_PLAYS = 3
const DICE_COUNT = 5

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
	"None": {"points": 0, "mult": 1}
}
var dice_start_positions = []


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
	$ButtonRestart.pressed.connect(_on_restart_pressed)

	start_new_round()


func start_new_round():
	rolls_left = MAX_ROLLS
	for i in range(DICE_COUNT):
		dice_locked[i] = false
		dice_values[i] = randi() % 6 + 1
		
		var dice_sprite = get_node("DiceContainer/Dice%d" % (i + 1))
		dice_sprite.position = dice_start_positions[i]  # Reset position clearly
		update_dice_border(dice_sprite, false)

	display_dice()
	update_ui()


func display_dice():
	for i in range(DICE_COUNT):
		var dice_sprite = get_node("DiceContainer/Dice%d" % (i + 1))
		dice_sprite.texture = load("res://dice_%d.png" % dice_values[i])
		update_dice_border(dice_sprite, dice_locked[i])

func update_dice_border(dice_sprite, selected):
	if selected:
		dice_sprite.modulate = Color(1, 1, 0.4)  # Slightly yellow tint
	else:
		dice_sprite.modulate = Color(1, 1, 1)  # No tint

func roll_unlocked_dice():
	for i in range(DICE_COUNT):
		if not dice_locked[i]:
			dice_values[i] = randi() % 6 + 1

func calculate_round_score():
	var selected_values = []
	for i in range(DICE_COUNT):
		if dice_locked[i]:
			selected_values.append(dice_values[i])

	var set_type = detect_set_type()
	var points = set_data[set_type].points
	var mult = set_data[set_type].mult

	var dice_sum = 0
	for val in selected_values:
		dice_sum += val

	return (points + dice_sum) * mult

func update_ui():
	var set_type = detect_set_type()
	var points = set_data[set_type].points
	var mult = set_data[set_type].mult

	$LabelContainer/LabelRollsLeft.text = "Rolls Left: %d" % rolls_left
	$LabelContainer/LabelPlaysLeft.text = "Plays Left: %d\nTotal Score: %d" % [plays_left, total_score]
	$LabelContainer/LabelSetType.text = "Set: %s" % set_type
	$LabelContainer/LabelPoints.text = "Points: %d" % points
	$LabelContainer/LabelMult.text = "Multiplier: %d" % mult

func _on_roll_pressed():
	if rolls_left > 0:
		roll_unlocked_dice()
		rolls_left -= 1
		display_dice()
		update_ui()


func _on_play_pressed():
	if plays_left > 0:
		var round_score = calculate_round_score()
		total_score += round_score
		print("Round Score: %d, Total Score: %d" % [round_score, total_score])
		plays_left -= 1
		if plays_left > 0:
			start_new_round()
		else:
			game_over()
	update_ui()

func _on_restart_pressed():
	# Reset entire game
	total_score = 0
	plays_left = MAX_PLAYS
	start_new_round()
	$ButtonRoll.disabled = false
	$ButtonPlay.disabled = false

func detect_set_type():
	var selected_values = []
	for i in range(DICE_COUNT):
		if dice_locked[i]:
			selected_values.append(dice_values[i])

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


func game_over():
	$ButtonRoll.disabled = true
	$ButtonPlay.disabled = true
	$LabelContainer/LabelPlaysLeft.text = "Game Over!\nFinal Score: %d" % total_score
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
