tool
extends CameraChunk
class_name DiscreteCameraChunk

export var apply_left: = false
export var apply_right: = false
export var apply_top: = false
export var apply_bottom: = false

func _ready():
	
	color = Color(0, 1, 0.529412, 0.25)
	if Engine.editor_hint:
		return
	
	._ready()
	
	if not player.camera:
		yield(player, "ready")
	camera = player.camera
	
	area = ExArea2D.new()
	area.pause_mode = Node.PAUSE_MODE_PROCESS
	Game.set_physics_layer(area, Game.PHYSICS_LAYER.CAMERA_CHUNK, true)
#	area.set_collision_layer_bit(0, false)
#	area.set_collision_layer_bit(15, true)
#	area.set_collision_mask_bit(0, false)
	
	shape = CollisionShape2D.new()
	shape.disabled = disabled
	shape.shape = RectangleShape2D.new()
	shape.shape.extents = rect_size / 2
	shape.position = shape.shape.extents
	
	add_child(area)
	area.add_child(shape)
	
	area.connect("body_entered_safe", self, "body_entered")
	area.connect("body_exited_safe", self, "body_exited")

func get_limits() -> Dictionary:
	var limits: Dictionary = ControlledCamera2D.default_limits.duplicate()

	var pos: Vector2 = shape.global_position

	if apply_left:
		limits["limit_left"] = pos.x - shape.shape.extents.x
	if apply_right:
		limits["limit_right"] = pos.x + shape.shape.extents.x
	if apply_top:
		limits["limit_top"] = pos.y - shape.shape.extents.y
	if apply_bottom:
		limits["limit_bottom"] = pos.y + shape.shape.extents.y
	
	return limits

func enter():
	.enter()
	if not camera:
		yield(self, "ready")
	
	if not camera.is_inside_tree():
		yield(camera, "tree_entered")
	
	camera.set_limits(get_limits())
	yield(camera, "STOPPED")

func body_entered(body: PhysicsBody2D):
	if body == player:
		enter()

func body_exited(body: PhysicsBody2D):
	if body == player:
		exit()
