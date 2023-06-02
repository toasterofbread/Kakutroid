tool
extends CameraChunk
class_name ContinuousCameraChunk

enum POSITION_INPUTS {X, Y}
export(POSITION_INPUTS) var position_input: int
export var invert: bool = false

enum LIMIT_KEYS {limit_left, limit_right, limit_top, limit_bottom}
export(LIMIT_KEYS) var limit_to_set: int

export var max_limit: bool = false

func update_limit_info():
	
	track_axis = "y" if position_input == POSITION_INPUTS.Y else "x"
	
	track_small_limit = "limit_top" if track_axis == "y" else "limit_left"
	track_large_limit = "limit_bottom" if track_axis == "y" else "limit_right"
	if invert:
		Utils.swap_values(self, "track_small_limit", "track_large_limit")
	
	set_target_limit = LIMIT_KEYS.keys()[limit_to_set]
	set_origin_limit = {
		"limit_left": "limit_right",
		"limit_right": "limit_left",
		"limit_top": "limit_bottom",
		"limit_bottom": "limit_top"
	}[set_target_limit]
	
#	match mode:
#		MODES.X_LEFT, MODES.X_RIGHT:
#			track_axis = "y"
#			track_small_limit = "limit_top"
#			track_large_limit = "limit_bottom"
#
#			set_target_limit = "limit_left" if mode == MODES.X_LEFT else "limit_right"
#			set_origin_limit = "limit_right" if mode == MODES.X_LEFT else "limit_left"
#		MODES.Y_TOP, MODES.Y_BOTTOM:
#			track_axis = "x"
#			track_small_limit = "limit_left"
#			track_large_limit = "limit_right"
#
#			set_target_limit = "limit_top" if mode == MODES.Y_TOP else "limit_bottom"
#			set_origin_limit = "limit_bottom" if mode == MODES.Y_TOP else "limit_top"

var track_axis: String
var track_large_limit: String
var track_small_limit: String
var set_origin_limit: String
var set_target_limit: String
func _process(_delta: float):
	
	var limits: Dictionary = get_limits()
	var progress: float = (player.global_position[track_axis] - limits[track_small_limit]) / (limits[track_large_limit] - limits[track_small_limit])
	progress = min(1, max(0, progress))
	
	var target_limit: float = limits[set_target_limit]
	if get(set_target_limit + "_max"):
		target_limit = camera.get_view_bounds(true)[set_target_limit]
	
	if progress == 1 and max_limit:
		camera.set(set_target_limit, camera.default_limits[set_target_limit])
	else:
		camera.set(set_target_limit, lerp(limits[set_origin_limit], target_limit, progress))

func _ready():
	set_process(false)
	if Engine.editor_hint:
		return
	
	._ready()
	update_limit_info()
	
	if not player.camera:
		yield(player, "ready")
	camera = player.camera
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	area = ExArea2D.new()
	Game.set_physics_layer(area, Game.PHYSICS_LAYER.CAMERA_CHUNK, true)
#	area.set_collision_layer_bit(0, false)
#	area.set_collision_layer_bit(15, true)
#	area.set_collision_mask_bit(0, false)
	add_child(area)
	
	shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.extents = rect_size / 2
	shape.position = shape.shape.extents
	area.add_child(shape)
	
	area.connect("body_entered_safe", self, "body_entered")
	area.connect("body_exited_safe", self, "body_exited")

func get_limits():
	var ret: Dictionary = {}
	var pos = $Limits.rect_global_position
	
	ret["limit_left"] = pos.x
	ret["limit_right"] = pos.x + $Limits.rect_size.x
	ret["limit_top"] = pos.y
	ret["limit_bottom"] = pos.y + $Limits.rect_size.y
	
	return ret

func enter():
	.enter()
	set_process(true)

func exit():
	.exit()
	set_process(false)

func body_entered(body: PhysicsBody2D):
	if body == player:
		enter()

func body_exited(body: PhysicsBody2D):
	if body == player:
		exit()
