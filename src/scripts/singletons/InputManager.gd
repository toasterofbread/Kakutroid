extends Node

signal UPDATE_BUTTON_ICONS()

var button_icons: Dictionary = Utils.dir2dict(ButtonIcon.icons_directory, Utils.DIR2DICT_MODES.NESTED)
var using_keyboard: bool = false setget set_using_keyboard
var text_input_active: bool = false

func _init():
	pause_mode = Node.PAUSE_MODE_PROCESS

func _input(event: InputEvent):
	if event.is_action_released("DEBUG_quit"):
		Game.quit()
	if event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	if using_keyboard:
		if event is InputEventJoypadButton:
			set_using_keyboard(false)
	elif not text_input_active and event.get_class() in ["InputEventKey", "InputEventMouseButton"]:
		set_using_keyboard(true)

func set_using_keyboard(value: bool):
	using_keyboard = value
	emit_signal("UPDATE_BUTTON_ICONS", null)
	
	Overlay.SET("Using keyboard", value)

func get_pad(just_pressed: bool = false) -> Vector2:
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
