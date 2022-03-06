extends Control
class_name Notification

signal CLEARED()
signal ADDED()

const slide_time: float = 0.35
const LENGTH_SHORT: float = 1.0
const LENGTH_NORMAL: float = 3.0
const LENGTH_LONG: float = 5.0

var free_on_clear: bool = true
var tween: Tween

func _notification(what: int):
	if what == NOTIFICATION_CREATED_USING_NEW:
		push_error("Notifications must be instanced with their scene")
		get_tree().quit(1)

static func get_instance() -> Notification:
	push_error("Cannot get base notification instance")
	return null

static func get_type_name() -> String:
	return "Notification"

func _ready():
	rect_size = rect_min_size

func popup():
	tween = Tween.new()
	tween.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(tween)
	
	var last_notification: Notification = NotificationManager.get_last_notification()
	NotificationManager.container.add_child(self)
	
	rect_position.y = 0 if last_notification == null else last_notification.rect_position.y + last_notification.get_size().y + NotificationManager.separation
	
	if NotificationManager.left_to_right:
		rect_position.x = -get_size().x
		tween.interpolate_property(self, "rect_position:x", rect_position.x, rect_position.x + get_size().x, slide_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	else:
		rect_position.x = NotificationManager.container.rect_size.x
		tween.interpolate_property(self, "rect_position:x", rect_position.x, rect_position.x - get_size().x, slide_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	tween.start()
	emit_signal("ADDED")

func clear_after(time: float):
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", self, "clear")
	timer.start(time)

func clear():
	if NotificationManager.left_to_right:
		tween.interpolate_property(self, "rect_position:x", rect_position.x, rect_position.x - get_size().x, slide_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	else:
		tween.interpolate_property(self, "rect_position:x", rect_position.x, NotificationManager.container.rect_size.x, slide_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	tween.start()
	yield(tween, "tween_completed")
	
	if free_on_clear:
		queue_free()
	else:
		get_parent().remove_child(self)
	
	if is_inside_tree():
		yield(self, "tree_exited")
	NotificationManager.reposition_notifications()
	
	emit_signal("CLEARED")

func is_showing() -> bool:
	return Utils.node_has_parent(self)
