extends TextNotification
class_name LargeTextNotification

static func get_instance() -> Notification:
	return NotificationManager.types[get_type_name()].instance()

static func get_type_name() -> String:
	return "LargeTextNotification"
