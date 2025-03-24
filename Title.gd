extends Label

var amplitude_x = 100
var amplitude_y = 50
var speed_x = 1.0
var speed_y = 2.0
var original_y = 0.0
var original_x = 0.0

func _ready():
	original_y = position.y
	original_x = position.x

func _process(delta):
	position.y = original_y + sin(Time.get_ticks_msec() / 1000.0 * speed_y) * amplitude_y
	position.x = original_x + sin(Time.get_ticks_msec() / 1000.0 * speed_x) * amplitude_x
