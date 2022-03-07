extends Notification
class_name ButtonPromptNotification

var action_key: String

static func create(text: String, action_key: String, duration: float = Notification.LENGTH_NORMAL, auto_popup: bool = true) -> Notification:
	var notification = get_instance()
	notification.init(text, action_key)
	if auto_popup:
		notification.popup()
	if duration != null:
		notification.clear_after(duration)
	return notification

func init(text: String, action_key: String):
	self.action_key = action_key
	
	$HBoxContainer/Label.text = text
	$HBoxContainer/ButtonIcon.set_action_key(action_key)

	if NotificationManager.left_to_right:
		var style: StyleBoxFlat = get("custom_styles/panel")
		style.expand_margin_left = style.expand_margin_right
		style.expand_margin_right = 0
#
	rect_size = rect_min_size

func get_size():
	return rect_size * rect_scale

func just_pressed():
	return Input.is_action_just_pressed(action_key)

func pressed():
	return Input.is_action_pressed(action_key)

func just_released():
	return Input.is_action_pressed(action_key)

static func get_instance() -> Notification:
	return NotificationManager.types[get_type_name()].instance()

static func get_type_name() -> String:
	return "ButtonPromptNotification"
