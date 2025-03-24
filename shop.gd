extends Control

func _ready():
	$ButtonContinue.pressed.connect(_on_continue_pressed)

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://Planning.tscn")
