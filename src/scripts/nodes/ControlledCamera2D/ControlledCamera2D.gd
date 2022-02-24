extends Node2D
class_name ControlledCamera2D, "icon.png"

signal stopped
signal _process_frame

# Discrete - Limit is set instantly
# Continuous X - The horizontal limit(s) are set according to the camera's Y position
# Continuous Y - The vertical limit(s) are set according to the camera's X position
enum LIMIT_SET_MODES {DISCRETE, CONTINUOUS_X, CONTINUOUS_Y}

export var current: bool = false setget set_current
export var zoom: Vector2 = Vector2.ONE setget set_zoom
export var offset: Vector2 = Vector2.ZERO setget set_offset

# If true, the camera will zoom in/out to fit its limits and stay centred, instead of following the parent
export var expand_view_to_limits: bool = false setget set_expand_view_to_limits

# 1.0 = No smoothing, direct follow
# 0.0 = No camera movement
export(float, 0.0, 1.0) var x_smoothing: float = 0.15
export(float, 0.0, 1.0) var y_smoothing: float = 0.15

export var follow_active: bool = true
var follow_pos: Vector2 = Vector2.ZERO
export var follow_node_path: NodePath
var follow_node: Node2D
export var follow_node_pos: bool = false

const default_limits: Dictionary = {
	"limit_left": -10000000,
	"limit_right": 10000000,
	"limit_top": -10000000,
	"limit_bottom": 10000000
	}
export var limit_left: float = default_limits["limit_left"] setget set_limit_left
export var limit_right: float = default_limits["limit_right"] setget set_limit_right
export var limit_top: float = default_limits["limit_top"] setget set_limit_top
export var limit_bottom: float = default_limits["limit_bottom"] setget set_limit_bottom

#var _limit_left_offset: float = 0.0
#var _limit_right_offset: float = 0.0
#var _limit_top_offset: float = 0.0
#var _limit_bottom_offset: float = 0.0

# Dim
#onready var dimColorRectContainer: Node2D = Node2D.new()
#onready var dimColorRect: ColorRect = ColorRect.new()
#var dim_colour: Color = Color.transparent setget set_dim_colour
#var dim_layer: int = 0 setget set_dim_layer

var camera: Camera2D = Camera2D.new()

# DEBUG
var lerp_mode: bool = true

func _ready():
	set_as_toplevel(true)
	add_child(camera)
	camera.set_as_toplevel(true)
	set_current(current)
	
	x_smoothing *= 60
	y_smoothing *= 60
#	limit_smoothing *= 60
	
	if has_node(follow_node_path):
		follow_node = get_node(follow_node_path)
	
#	dimColorRectContainer.z_as_relative = false
	z_index = 0
	z_as_relative = false
	
#	add_child(dimColorRectContainer)
#	dimColorRectContainer.add_child(dimColorRect)
#	set_dim_colour(dim_colour)
#	print(dimColorRect.position)
#	print(dimColorRect.position)
#	dimColorRect.rect_size = get_view_size()*200

func _process(delta: float):
	if follow_active and not expand_view_to_limits:
		process_follow(delta)

const _movement_threshold: float = 3.0
func process_follow(delta: float):
#	var a: Vector2 = follow_node.global_position if follow_node_pos else follow_pos
	
#	var x_smoothing: float = smoothing
#	var y_smoothing: float = smoothing
	
#	var smooth_x: bool = target_pos.x - global_position.x > 1 or true
#	var smooth_y: bool = target_pos.y - global_position.y > 1 or true
	
	emit_signal("_process_frame", delta)
	
	var target_pos: Vector2 = follow_node.global_position if follow_node_pos else follow_pos
	var view_size: Vector2 = get_view_size()
	
	
#	global_position.x = lerp(global_position.x, target_pos.x, delta*x_smoothing)
#	global_position.y = lerp(global_position.y, target_pos.y, delta*y_smoothing)
#	if not lerp_mode:
	global_position = target_pos
	
	var l: float = limit_left + (view_size.x / 2)
	var r: float = limit_right - (view_size.x / 2)
	var t: float = limit_top + (view_size.y / 2)
	var b: float = limit_bottom - (view_size.y / 2)
	
	target_pos.x = max(min(target_pos.x, r), l)
	target_pos.y = max(min(target_pos.y, b), t)
	
#	camera.global_position.x = lerp(camera.global_position.x, target_pos.x, delta*x_smoothing)
#	camera.global_position.y = lerp(camera.global_position.y, target_pos.y, delta*y_smoothing)
	if lerp_mode:
		
		if (camera.global_position - target_pos).length() < _movement_threshold:
			return
		
		camera.global_position.x = lerp(camera.global_position.x, target_pos.x, x_smoothing*delta)
		camera.global_position.y = lerp(camera.global_position.y, target_pos.y, y_smoothing*delta)
		
		if (camera.global_position - target_pos).length() < _movement_threshold:
			emit_signal("stopped")
	else:
		camera.global_position = target_pos
	
	
#	print(target_pos.x, " | ", l)
#	print(abs(target_pos.x - global_position.x))
	
#	if abs(target_pos.x - global_position.x) > 0.1:
#		print(1)
#		x_smoothing = limit_smoothing
#	else:
#		print(2)
#		pass
#	if abs(target_pos.y - global_position.y) > 0.1:
#		y_smoothing = limit_smoothing
#	else:
#		pass
		
#	var moving = (target_pos - global_position).length() != 0
	
#	if moving:
#
#		var x_mod: float = abs(global_position.x - target_pos.x)
#		if x_mod < 20:
#			x_mod *= 2
##		global_position.x = move_toward(global_position.x, target_pos.x, x_smoothing*delta*x_mod)
#
#		var y_mod: float = abs(global_position.y - target_pos.y)
#		if y_mod < 20:
#			y_mod *= 2
##		global_position.y = move_toward(global_position.y, target_pos.y, y_smoothing*delta*y_mod)
##		global_position.x = lerp(global_position.x, target_pos.x, x_smoothing*delta)
##		global_position.y = lerp(global_position.y, target_pos.y, y_smoothing*delta)
#
#		if (target_pos - global_position).length() == 0:
#			emit_signal("stopped")
#			moving = false
	
func get_view_bounds(ignore_limits: bool = false) -> Dictionary:
	var view_size: Vector2 = get_view_size()/2
	var pos: Vector2 = global_position if ignore_limits else camera.global_position
	var min_pos: Vector2 = pos - view_size
	var max_pos: Vector2 = pos + view_size

	return {
		"limit_left": min_pos.x,
		"limit_right": max_pos.x,
		"limit_top": min_pos.y,
		"limit_bottom": max_pos.y
	}

func get_view_size() -> Vector2:
	return get_viewport_rect().size * zoom

#func affected_by_limit(limit_key: String) -> bool:
#	var limit: float = get(limit_key)
#
#	if limit == default_limits[limit_key]:
#		return false
#
#	var view_bound: float = get_view_bounds(true)[limit_key]
#
#	match limit_key:
#		"limit_left", "limit_top":
#			return view_bound < limit
#		_: # limit_right, limit_bottom
#			return view_bound > limit

func is_limit_shrinking(limit_key: String, current: float, target: float) -> bool:
	match limit_key:
		"limit_left", "limit_top":
			return target < current
		_: # limit_right, limit_bottom
			return target > current

func reset_limits(limits_to_reset: Array = default_limits.keys()):
	for limit_key in limits_to_reset:
		set(limit_key, default_limits[limit_key])

func set_limits(limits: Dictionary):
	for limit in limits:
		set(limit, limits[limit])

func set_limit_left(value: float, _set: bool = false):
	if _set or lerp_mode:
		limit_left = value
	else:
		_interpolate_limit("limit_left", "x", value)
func set_limit_right(value: float, _set: bool = false):
	if _set or lerp_mode:
		limit_right = value
	else:
		_interpolate_limit("limit_right", "x", value)
func set_limit_top(value: float, _set: bool = false):
	if _set or lerp_mode:
		limit_top = value
	else:
		_interpolate_limit("limit_top", "y", value)
func set_limit_bottom(value: float, _set: bool = false):
	if _set or lerp_mode:
		limit_bottom = value
	else:
		_interpolate_limit("limit_bottom", "y", value)

const tween_time: float = 0.5
var _current_limit_interpolations: Dictionary = {}
func _interpolate_limit(limit_key: String, axis: String, target_value: float):
	
	print(limit_key)
	
	# Get unique timestamp
	var id: float = OS.get_ticks_msec()
	_current_limit_interpolations[limit_key] = id
	
	var setter: FuncRef = funcref(self, "set_" + limit_key)
	
	var shrinking: bool = is_limit_shrinking(limit_key, get(limit_key), target_value)
	setter.call_func(get_view_bounds()[limit_key], true)
	
	var is_default: bool = target_value == default_limits[limit_key] 
	if is_default:
		target_value = get_view_bounds(true)[limit_key]
	
	var start_pos: float = global_position[axis]
	var speed: float = abs(get(limit_key) - target_value) / tween_time
	
	var virtual_limit_value: float = get(limit_key)
	while true:
		var delta: float = yield(self, "_process_frame")
		
		# Return if another interpolation of the same limit has started
		if _current_limit_interpolations[limit_key] != id:
			return
		# If the limit is moving away from the camera, the interpolation must
		# compensate for camera movement in case it moves toward the limit
		if shrinking:
			# Difference between camera starting position and current position
			var diff: float = (global_position[axis] - start_pos)
			virtual_limit_value = move_toward(virtual_limit_value, target_value, delta*speed)
			setter.call_func(virtual_limit_value + diff, true)
			
			if virtual_limit_value == target_value:
#				setter.call_func(target_value, true)
				break
		else:
			setter.call_func(move_toward(get(limit_key), target_value, delta*speed), true)
			
			if get(limit_key) == target_value:
				break
	
	_current_limit_interpolations.erase(limit_key)
	if len(_current_limit_interpolations) == 0:
		emit_signal("stopped")
	
	if is_default:
		setter.call_func(default_limits[limit_key], true)

func set_current(value: bool):
	current = value
	camera.current = current
#	if current:
#		Loader.current_camera = self
#	elif Loader.current_camera == self:
#		Loader.current_camera = null

func set_zoom(value: Vector2):
	zoom = value
	camera.zoom = zoom

func set_offset(value: Vector2):
	offset = value
	camera.offset = offset

#func set_dim_layer(layer: int, offset: int = 0):
#	dim_layer = layer
#	Enums.set_node_layer(dimColorRectContainer, layer, offset)

#func set_dim_colour(colour: Color):
#	dimColorRect.rect_global_position = camera.get_camera_screen_center() - (dimColorRect.rect_size / 2)
#	dim_colour = colour
#	dimColorRect.color = colour
#	dimColorRectContainer.visible = colour.a > 0

func set_expand_view_to_limits(value: bool):
	if expand_view_to_limits == value:
		return
	expand_view_to_limits = value
	
	if expand_view_to_limits:
		expand_view_to_limits()
	else:
		camera.zoom = zoom

# TODO
func expand_view_to_limits():
	pass
