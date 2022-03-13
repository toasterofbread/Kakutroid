tool
extends ColorRect
class_name CameraChunk

export var disabled: bool = false setget set_disabled
export(Array, NodePath) var connected_chunks: Array = []

var area: ExArea2D
var shape: CollisionShape2D

var player: Player
var camera: ControlledCamera2D

func get_limits() -> Dictionary:
	return {}

func enter():
	player.camerachunk_entered(self)

func exit():
	player.camerachunk_exited(self)

func set_disabled(value: bool):
	disabled = value
	if shape:
		shape.disabled = disabled

func refresh():
	var original_disabled: bool = disabled
	if not disabled:
		set_disabled(true)
		yield(Utils, "physics_frame")
	set_disabled(false)
	yield(Utils, "physics_frame")
	if original_disabled:
		set_disabled(true)

func _ready():
	player = Game.player
	for i in len(connected_chunks):
		if connected_chunks[i] is NodePath:
			connected_chunks[i] = get_node(connected_chunks[i])
	set("visible", visible)

func _set(property: String, value):
	if property == "visible" and is_inside_tree():
		visible = get_tree().debug_collisions_hint and value
		return true
	return false
