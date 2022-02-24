extends Node

func _input(event: InputEvent):
	if event.is_action_pressed("DEBUG_quit"):
		get_tree().quit()
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func get_pad_vector(just_pressed: bool = false) -> Vector2:
	return Vector2(get_pad_x(just_pressed), get_pad_y(just_pressed))

func get_pad_x(just_pressed: bool = false) -> int:
	if just_pressed:
		return int(Input.is_action_just_pressed("pad_right")) - int(Input.is_action_just_pressed("pad_left"))
	else:
		return int(Input.is_action_pressed("pad_right")) - int(Input.is_action_pressed("pad_left"))

func get_pad_y(just_pressed: bool = false) -> int:
	if just_pressed:
		return int(Input.is_action_just_pressed("pad_down")) - int(Input.is_action_just_pressed("pad_up"))
	else:
		return int(Input.is_action_pressed("pad_down")) - int(Input.is_action_pressed("pad_up"))
