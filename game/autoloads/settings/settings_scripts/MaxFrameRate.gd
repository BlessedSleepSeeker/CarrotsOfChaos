extends Setting

const MAX_FRAME_RATE: Array = [30, 60, 120, 144, 0]
@export var base_value: int = 0

func _ready():
	value = base_value
	default = base_value
	possible_values = MAX_FRAME_RATE

## Called when settings.apply_settings() is triggered
func apply():
	# setting this to 0 uncap the FPS
	Engine.set_max_fps(value)
