extends KinematicBody2D
class_name Player

# - Signals -
signal STATE_CHANGED(previous_state)
signal DATA_CHANGED() # TODO

# - Data -
var data: Dictionary = Utils.load_json("res://data/player/default.json").result
var player_data: Dictionary = data["general"]

# - State -
var states: Dictionary = {}
var current_state: Node = null
var facing: int = 1
var velocity: Vector2 = Vector2.ZERO
var air_time: float = -1.0
var health: float = null setget set_health
var intangible: bool = false setget set_intangible
var crouching: bool = false setget set_crouching
var running: bool = false setget set_running

# - Shape -
const SHAPE_TRANSITION_DURATION: float = 0.5
onready var shape_data: Dictionary = {
	Enums.SHAPE.CUBE: {"node": $Shapes/Square},
	Enums.SHAPE.TRIANGLE: {"node": $Shapes/Triangle},
	Enums.SHAPE.CIRCLE: {"node": $Shapes/Circle},
}
var current_shape: int = null setget set_current_shape
var current_shape_node: Node2D = null

# - Nodes -
onready var crouch_tween: Tween = $CrouchTween
onready var shape_transition_tween: Tween = $ShapeTransitionTween
onready var wall_squeeze_animationplayer: AnimationPlayer = $WallSqueezeAnimationPlayer
onready var trail_emitter: NodeTrailEmitter = $NodeTrailEmitter
onready var landing_particles: CPUParticles2D = $LandingParticles
onready var intangibility_timer: Timer = $IntangibilityTimer

# - Scenes -
const projectile_scene: PackedScene = preload("res://src/scenes/player/Projectile.tscn")

# - Other -
const CUBE_SIZE: int = 16
const WALL_SQUEEZE_AMOUNT: float = 0.25
const CROUCH_SQUEEZE_AMOUNT: float = 0.25
const CUBE_TEXTURE: Texture = preload("res://assets/temp/white.png")
export var squeeze_amount_x: float = 0.0 setget set_squeeze_amount_x
var squeeze_amount_y: float = 0.0 setget set_squeeze_amount_y
onready var gradient: Gradient = $Shapes/Square/Polygon.texture.gradient
var previous_velocity: Vector2 = Vector2.ZERO
var was_on_floor: bool = false
var last_damage_time: int = 0.0
var passive_heal_cap: float

func _ready():
	var all_states: Array = [
		preload("res://src/scenes/player/states/state_neutral.gd").new(self),
		preload("res://src/scenes/player/states/state_walk.gd").new(self),
		preload("res://src/scenes/player/states/state_run.gd").new(self),
		preload("res://src/scenes/player/states/state_jump.gd").new(self),
		preload("res://src/scenes/player/states/state_slide.gd").new(self),
	]
	
	for state in all_states:
		assert(not state.get_id() in states, "State ID '" + Enums.PLAYER_STATE.keys()[state.get_id()] + "' is duplicated")
		states[state.get_id()] = state
	
	squeeze_amount_x = 0
	squeeze_amount_y = 0
	
	Game.set_node_damageable(self)
	Game.set_node_layer(self, Game.LAYERS.PLAYER)
	Game.set_node_layer(landing_particles, Game.LAYERS.PLAYER, 1)
	passive_heal_cap = player_data["MAX_HEALTH"]
	set_health(player_data["MAX_HEALTH"])
	change_state(Enums.PLAYER_STATE.NEUTRAL)
	set_current_shape(Enums.SHAPE.CUBE, true)

func _process(delta):
	
	if Input.is_action_pressed("run"):
		set_running(true)
	
	if (OS.get_ticks_msec() - last_damage_time) / 1000.0 > player_data["PASSIVE_HEAL_IDLE_TIME"] and health > 0.0:
		set_health(min(passive_heal_cap, health + (player_data["PASSIVE_HEAL_PERCENTAGE"] * player_data["MAX_HEALTH"] * delta / player_data["PASSIVE_HEAL_DURATION"])))
	
	if current_state != null:
		current_state.process(delta)
	
	Overlay.SET("Health percentage", clamp(health / player_data["MAX_HEALTH"], 0.0, 1.0))
	Overlay.SET("Velocity", velocity)
	Overlay.SET("State", Enums.PLAYER_STATE.keys()[current_state.get_id()] if current_state != null else "NONE")
	Overlay.SET("Intangible", intangible)
	
	current_shape_node.scale.x = 1.0 - abs(squeeze_amount_x)
	current_shape_node.position.x = (CUBE_SIZE / -2) * (current_shape_node.scale.x - 1) * sign(squeeze_amount_x)
	current_shape_node.scale.y = 1.0 - abs(squeeze_amount_y)
	current_shape_node.position.y = (CUBE_SIZE / -2) * (current_shape_node.scale.y - 1) * sign(squeeze_amount_y)
	previous_velocity = velocity
	
	var pad_x: int = InputManager.get_pad_x()
	if pad_x != 0:
		facing = pad_x
	
	if Input.is_action_just_pressed("fire_weapon"):
		fire_weapon()
	else:
		if Input.is_action_just_pressed("fire_weapon_left"):
			fire_weapon(-1)
		if Input.is_action_just_pressed("fire_weapon_right"):
			fire_weapon(1)
	
	if Input.is_action_just_pressed("cycle_shape"):
		set_current_shape(Enums.SHAPE.CIRCLE)

func _physics_process(delta: float):
	
	if current_state != null:
		current_state.physics_process(delta)
	
	if is_on_wall():
		vel_move_y(player_data["MAX_FALL_SPEED_WALL"], player_data["GRAVITY_WALL"] * delta)
	elif velocity.y < player_data["MAX_FALL_SPEED"]:
		vel_move_y(player_data["MAX_FALL_SPEED"], player_data["GRAVITY"] * delta)
	
	velocity = move_and_slide(velocity, Vector2.UP)
	# Emit landing particles
	if get_slide_count() > 0 and is_on_floor() and not was_on_floor and previous_velocity.y >= 200.0:
		
		# Find collided object
		for collision_idx in get_slide_count():
			var collision: KinematicCollision2D = get_slide_collision(collision_idx)
			if not collision.collider is RoomCollisionObject:
				continue
			var collider: RoomCollisionObject = collision.collider
			
#			# Find collided tile
#			var pos: Vector2 = tilemap.world_to_map(tilemap.to_local(collision.position))# - Vector2(1, 0)
#			var tile: int = tilemap.get_cellv(pos)
#			if tile == -1:
#				tile = tilemap.get_cellv(pos - Vector2(1, 0))
#				if tile == -1:
#					continue
			
			# Emit particles with texture and colour of tile
			emit_landing_particles(collider.particle_texture).color = collider.particle_colour
			break
	
	if is_on_floor():
		air_time = -1.0
	elif was_on_floor:
		air_time = 0.0
	else:
		air_time += delta
	
	Overlay.SET("On floor", is_on_floor())
	Overlay.SET("On wall", is_on_wall())
	Overlay.SET("Air time", air_time)
	
	was_on_floor = is_on_floor()

func change_state(state_id: int, data: Dictionary = {}):
	
	if current_state == null:
		current_state = states[state_id]
		current_state.on_enabled(null, data)
		emit_signal("STATE_CHANGED", null)
	elif current_state.get_id() != state_id:
		var previous_state: PlayerState = current_state
		previous_state.on_disabled(states[state_id])
		
		current_state = states[state_id]
		current_state.on_enabled(previous_state, data)
		
		emit_signal("STATE_CHANGED", previous_state)

func set_current_shape(value: int, instant: bool = false):
	if value == current_shape:
		return
	
	current_shape = value
	shape_transition_tween.stop_all()
	
	if trail_emitter.has_trail_node(current_shape_node):
		trail_emitter.remove_trail_node(current_shape_node)
	
	if instant:
		var position: Vector2
		if current_shape_node:
			position = current_shape_node.global_position
			current_shape_node.modulate.a = 1
			Utils.reparent_node(current_shape_node, $Shapes)
		else:
			position = global_position
		current_shape_node = shape_data[current_shape]["node"]
		current_shape_node.visible = true
		Utils.reparent_node(current_shape_node, self)
		current_shape_node.global_position = position
		
		trail_emitter.add_trail_node(current_shape_node)
	else:
		shape_transition_tween.interpolate_property(current_shape_node, "modulate:a", current_shape_node.modulate.a, 0.0, SHAPE_TRANSITION_DURATION / 2.0, Tween.TRANS_EXPO)
		shape_transition_tween.start()
		yield(shape_transition_tween, "tween_all_completed")
		var position: Vector2 = current_shape_node.global_position if current_shape_node != null else global_position
		Utils.reparent_node(current_shape_node, $Shapes)
		current_shape_node = shape_data[current_shape]["node"]
		current_shape_node.modulate.a = 0.0
		current_shape_node.visible = true
		Utils.reparent_node(current_shape_node, self)
		current_shape_node.global_position = position
		
		trail_emitter.add_trail_node(current_shape_node)
		
		shape_transition_tween.interpolate_property(current_shape_node, "modulate:a", current_shape_node.modulate.a, 1.0, SHAPE_TRANSITION_DURATION / 2.0, Tween.TRANS_EXPO)
		shape_transition_tween.start()
		yield(shape_transition_tween, "tween_all_completed")

func set_crouching(value: bool):
	if value == crouching:
		return
	
	crouching = value
	crouch_tween.stop_all()
	crouch_tween.interpolate_property(self, "squeeze_amount_y", squeeze_amount_y, CROUCH_SQUEEZE_AMOUNT if crouching else 0.0, 0.1, Tween.TRANS_ELASTIC)
	crouch_tween.start()

func wall_collided(direction: int, strong: bool = false):
	assert(direction in [1, -1])
	
	if wall_squeeze_animationplayer.is_playing():
		return
	
	# TODO
#	if strong:
#		emit_landing_particles(5)
	
	wall_squeeze_animationplayer.play("wall_squeeze_" + str(direction))

func fire_weapon(direction: int = facing):
	assert(direction in [-1, 1])
	
	var projectile: Node2D = projectile_scene.instance()
	projectile.init(direction, current_shape, Color("fe6fff"))
	Utils.anchor.add_child(projectile)
	projectile.global_position = current_shape_node.global_position

func is_squeezing_wall() -> bool:
	return squeeze_amount_x != 0

func set_squeeze_amount_x(value: float):
	squeeze_amount_x = max(-1.0, min(1.0, value))

func set_squeeze_amount_y(value: float):
	squeeze_amount_y = max(-1.0, min(1.0, value))

func vel_move_y(to: float, by: float = INF):
	velocity.y = move_toward(velocity.y, to, by)

func vel_move_x(to: float, by: float = INF):
	velocity.x = move_toward(velocity.x, to, by)

func vel_move(to: Vector2, delta: float = INF):
	velocity = velocity.move_toward(to, delta)

func emit_landing_particles(texture_or_colour, amount: int = 3) -> CPUParticles2D:
	assert(texture_or_colour is Color or texture_or_colour is Texture)
	
	var emitter: CPUParticles2D = landing_particles.duplicate()
	emitter.global_position = landing_particles.global_position
	emitter.amount = amount
	emitter.emitting = true
	
	if texture_or_colour is Texture:
		emitter.texture = texture_or_colour
		emitter.color = Color.white
	else:
		emitter.color = texture_or_colour
		emitter.texture = CUBE_TEXTURE
	
	Utils.anchor.add_child(emitter)
	get_tree().create_timer(emitter.lifetime).connect("timeout", emitter, "queue_free")
	return emitter

func can_fall() -> bool:
	return !is_on_floor() and air_time > player_data["COYOTE_TIME"]

func get_state_data(state_id: int) -> Dictionary:
	return data[Enums.PLAYER_STATE.keys()[state_id].to_lower()]

func collect_upgrade(upgrade_type: int):
	print("Collect upgrade: ", Enums.UPGRADE.keys()[upgrade_type])

func damage(type: int, amount: float, position: Vector2 = null):
	passive_heal_cap = min(passive_heal_cap, (health - amount) + (player_data["MAX_HEALTH"] * player_data["PASSIVE_HEAL_PERCENTAGE"]))
	
	set_health(health - amount)
	last_damage_time = OS.get_ticks_msec()
	
	if health <= 0.0:
		death(type)
	else:
		$AnimationPlayer.play("damage")
		if position != null:
			velocity = (global_position - position).normalized() * player_data["KNOCKBACK_SPEED"]
			set_intangible(true)

func death(type: int):
	print("Player death")

func set_intangible(value: bool):
	if intangible == value:
		return
	intangible = value
	
	if intangible:
		intangibility_timer.start(player_data["HIT_INTANGIBILITY_DURATION"])
	
	set_collision_layer_bit(1, !intangible)

func _on_IntangibilityTimer_timeout():
	set_intangible(false)

func set_health(value: float):
	if health == value:
		return
	
	health = value
	
	var percentage: float = clamp(health / player_data["MAX_HEALTH"], 0.0, 1.0)
	if percentage == 1.0:
		gradient.colors = [Color(player_data["FULL_COLOUR"])]
		gradient.offsets = [0.0]
	elif percentage == 0.0:
		gradient.colors = [Color(player_data["EMPTY_COLOUR"])]
		gradient.offsets = [0.0]
	else:
		gradient.colors = [Color(player_data["EMPTY_COLOUR"]), Color(player_data["FULL_COLOUR"])]
		gradient.offsets = [clamp((0.5 - percentage) * 2.0, 0.0, 1.0), clamp((percentage - 1.0) * -2.0, 0.0, 1.0)]

func set_running(value: bool):
	running = value and player_data["CAN_RUN"]
