extends PlayerModule
class_name PlayerModuleInput

var demo_mode: bool = false
onready var demo: PlayerModule = player.module_demo

func is_action_pressed(action: String) -> bool:
	if demo_mode:
		return demo.is_action_pressed_on_frame(action)
	return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	if demo_mode:
		return demo.is_action_pressed_on_frame(action) and not demo.is_action_pressed_on_frame(action, -1)
	return Input.is_action_just_pressed(action)

func is_action_just_released(action: String) -> bool:
	if demo_mode:
		return demo.is_action_pressed_on_frame(action, -1) and not demo.is_action_pressed_on_frame(action)
	return Input.is_action_released(action)

func get_pad(just_pressed: bool = false) -> Vector2:
	return Vector2(get_pad_x(just_pressed), get_pad_y(just_pressed))

func get_pad_x(just_pressed: bool = false) -> int:
	if just_pressed:
		return int(is_action_just_pressed("pad_right")) - int(is_action_just_pressed("pad_left"))
	else:
		return int(is_action_pressed("pad_right")) - int(is_action_pressed("pad_left"))

func get_pad_y(just_pressed: bool = false) -> int:
	if just_pressed:
		return int(is_action_just_pressed("pad_down")) - int(is_action_just_pressed("pad_up"))
	else:
		return int(is_action_pressed("pad_down")) - int(is_action_pressed("pad_up"))
