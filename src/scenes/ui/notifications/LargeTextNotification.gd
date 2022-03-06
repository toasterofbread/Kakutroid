extends TextNotification
class_name LargeTextNotification

static func get_instance() -> Notification:
	return NotificationManager.types["LargeTextNotification"].instance()
