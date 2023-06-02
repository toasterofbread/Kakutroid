extends CanvasLayer

const SEPARATION: float = 10.0
const REORDER_TIME: float = 0.1

export var default_preset: NodePath

var allow_new_notifications: bool = true

onready var container: Control = $Container/Notifications
const moving_interaction_button: String = "pad_up"

var node_data: Dictionary = {}
var types = {}
var left_to_right: bool = false

func _ready():
	
	var all_types: Array = [
		preload("res://src/scenes/ui/notifications/TextNotification.tscn"),
		preload("res://src/scenes/ui/notifications/LargeTextNotification.tscn"),
		preload("res://src/scenes/ui/notifications/ButtonPromptNotification.tscn"),
		preload("res://src/scenes/ui/notifications/SceneNotification.tscn")
	]
	for type in all_types:
		var instance: Notification = type.instance()
		types[instance.get_type_name()] = type
		instance.queue_free()
	
	$LayoutPresets.visible = false
	
	if has_node(default_preset):
		set_preset(get_node(default_preset).name, false)

func add(notification: Notification):
	
	if not allow_new_notifications:
		notification.queue_free()
		return
	
	if Utils.node_has_parent(notification):
		notification.get_parent().remove_child(notification)
	notification.init_notification()

func reposition_notifications():
	var destinations: Array = []
	for i in range(container.get_child_count()):
		
		if i >= container.get_child_count():
			break
		
		var notification: Notification = container.get_child(i)
		if i == 0:
			destinations.append(0.0)
		else:
			destinations.append(destinations[i - 1] + container.get_child(i - 1).get_size().y + SEPARATION)
		
		notification.tween.interpolate_property(notification, "rect_position:y", notification.rect_position.y, destinations[i], REORDER_TIME)
		notification.tween.start()
#		yield(Utils.wait(0.5, true), "completed")

func clear_all():
	for notification in container.get_children():
		notification.clear()
		yield(get_tree().create_timer(0.1), "completed")

func get_last_notification() -> Notification:
	return container.get_children()[-1] if container.get_child_count() > 0 else null

func set_preset(preset_name: String, animate: bool):
	var preset: Control = $LayoutPresets.get_node(preset_name)
	if animate:
		for property in ["rect_size", "rect_global_position", "rect_clip_content"]:
			$LayoutPresets/Tween.interpolate_property(container, property, container.get(property), preset.get(property), 1.0, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
		$LayoutPresets/Tween.start()
	else:
		for property in ["rect_size", "rect_global_position", "rect_clip_content"]:
			container.set(property, preset.get(property))
