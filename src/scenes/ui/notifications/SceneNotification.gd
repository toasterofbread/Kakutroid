extends Notification
class_name SceneNotification

var scene: Node = null

static func create(scene: Node, text: String = null, auto_popup: bool = true) -> TextNotification:
	var notification = get_instance()
	notification.init(scene, text)
	if auto_popup:
		notification.popup()
	return notification

func init(scene: Node, text: String = null):
	self.scene = scene
	
	$VBoxContainer.add_child(scene)
	$VBoxContainer.move_child(scene, 0)
	
	if NotificationManager.left_to_right:
		var style: StyleBoxFlat = get("custom_styles/panel")
		style.expand_margin_left = style.expand_margin_right
		style.expand_margin_right = 0
	
	if text != null:
		$VBoxContainer/Label.text = text
	else:
		$VBoxContainer/Label.queue_free()
	
	rect_size = rect_min_size

func get_size():
	return rect_size * rect_scale

static func get_instance() -> Notification:
	return NotificationManager.types["SceneNotification"].instance()
