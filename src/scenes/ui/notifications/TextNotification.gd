extends Notification
class_name TextNotification

static func create(text: String, auto_popup: bool = true) -> Notification:
	var notification = get_instance()
	notification.init(text)
	if auto_popup:
		notification.popup()
	return notification

func init(text: String):
	$Label.text = text
	
	if NotificationManager.left_to_right:
		var style: StyleBoxFlat = get("custom_styles/panel")
		style.expand_margin_left = style.expand_margin_right
		style.expand_margin_right = 0

func get_size():
	return rect_size * rect_scale

static func get_instance() -> Notification:
	return NotificationManager.types[get_type_name()].instance()

static func get_type_name() -> String:
	return "TextNotification"
