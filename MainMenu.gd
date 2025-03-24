extends Control

func _ready():
	$ButtonPlay.pressed.connect(_on_play_pressed)
	$ButtonExit.pressed.connect(_on_exit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Planning.tscn")

func _on_exit_pressed():
	get_tree().quit()
