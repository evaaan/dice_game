extends Control

@onready var game_state = get_node("/root/GameState")

func _ready():
	update_labels()
	$ButtonContinue.pressed.connect(_on_continue_pressed)

func update_labels():
	$LabelRound.text = "Round %d of 12" % game_state.current_round
	$LabelScore.text = "Next Score to Beat: %d" % game_state.get_current_score_threshold()
	$LabelMoney.text = "Money: $%d" % game_state.money

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")
