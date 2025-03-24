extends Control

@onready var game_state = get_node("/root/GameState")
var available_jokers = []

func _ready():
	$ButtonContinue.pressed.connect(_on_continue_pressed)
	
	# Get 3 random jokers to display
	available_jokers = game_state.get_random_jokers(3)
	
	# Set up joker buttons
	for i in range(3):
		if i < available_jokers.size():
			var joker_id = available_jokers[i]
			var joker_data = game_state.all_jokers[joker_id]
			var button = get_node("JokerButton" + str(i+1))
			
			# Set color based on joker type
			var color = Color.WHITE
			if joker_data["type"] == "rare":
				color = Color(0.27, 0.53, 1.0)  # Blue for rare
			elif joker_data["type"] == "epic":
				color = Color(0.67, 0.27, 1.0)  # Purple for epic
			
			button.add_theme_color_override("font_color", color)
			button.text = joker_data["name"] + "\n$" + str(joker_data["cost"]) + "\n" + joker_data["description"]
			
			# Connect button signal
			if not button.pressed.is_connected(_on_joker_button_pressed.bind(i)):
				button.pressed.connect(_on_joker_button_pressed.bind(i))
	
	# Update money display
	$LabelMoney.text = "Money: $" + str(game_state.money)

func _on_joker_button_pressed(button_index):
	var joker_id = available_jokers[button_index]
	var joker_data = game_state.all_jokers[joker_id]
	
	# Check if player can afford the joker and has space
	if game_state.money >= joker_data["cost"] and game_state.active_jokers.size() < 5:
		# Purchase the joker
		if game_state.add_joker(joker_id):
			# Update money display
			$LabelMoney.text = "Money: $" + str(game_state.money)
			
			# Disable the button
			var button = get_node("JokerButton" + str(button_index+1))
			button.disabled = true
			button.text = "SOLD OUT"
			button.add_theme_color_override("font_color", Color.DARK_GRAY)

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://Planning.tscn")
