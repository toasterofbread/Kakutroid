extends KinematicBody2D
class_name Player

# - Signals -
signal STATE_CHANGED(Node, Node) # (previous_state: PlayerState, current_state: PlayerState)

# - Physics values -
const GRAVITY: float = 1000.0
const MAX_FALL_SPEED: float = 300.0
const PARTICLE_EMISSION_SPEED_MIN: float = 200.0
var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO # Read-only

# - States -
var states: Dictionary = {}
var current_state: Node = null

# - Nodes -
onready var main_sprite: AnimatedSprite = $MainSprite
onready var crouch_tween: Tween = $CrouchTween
onready var wall_squeeze_animationplayer: AnimationPlayer = $WallSqueezeAnimationPlayer
onready var trail_emitter: SpriteTrailEmitter = $SpriteTrailEmitter
onready var landing_particles: CPUParticles2D = $LandingParticles

# - Other -
#const MAX_STRETCH: float = 5.0
#const STRETCH_ACCELERATION_MODIFIER: float = 10.0
#const MAX_STRETCH_VELOCITY: float = 1000.0
#var velocity_sign: Vector2 = Vector2.ZERO
const CUBE_SIZE: int = 16
const WALL_SQUEEZE_AMOUNT: float = 0.25
const CROUCH_SQUEEZE_AMOUNT: float = 0.25
var crouching: bool = false setget set_crouching
export var squeeze_amount_x: float = 0.0 setget set_squeeze_amount_x
var squeeze_amount_y: float = 0.0 setget set_squeeze_amount_y

var previous_velocity: Vector2 = Vector2.ZERO

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
	
	change_state(Enums.PLAYER_STATE.NEUTRAL)

func _process(delta):
	if current_state != null:
		current_state.process(delta)
	
	Overlay.SET("Velocity", velocity)
	Overlay.SET("State", Enums.PLAYER_STATE.keys()[current_state.get_id()] if current_state != null else "NONE")
	
	main_sprite.scale.x = 1.0 - abs(squeeze_amount_x)
	main_sprite.position.x = (CUBE_SIZE / -2) * (main_sprite.scale.x - 1) * sign(squeeze_amount_x)
	main_sprite.scale.y = 1.0 - abs(squeeze_amount_y)
	main_sprite.position.y = (CUBE_SIZE / -2) * (main_sprite.scale.y - 1) * sign(squeeze_amount_y)
	previous_velocity = velocity

func _physics_process(delta: float):
	if current_state != null:
		current_state.physics_process(delta)
	
	if velocity.y < MAX_FALL_SPEED:
		vel_move_y(MAX_FALL_SPEED, GRAVITY * delta)
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	Overlay.SET("On floor", is_on_floor())
	Overlay.SET("On wall", is_on_wall())
	
#	if not previous_is_on_wall and is_on_wall() and abs(velocity.x) >= PARTICLE_EMISSION_SPEED_MIN:
#		emit_landing_particles(5)
#
#	squeeze_amount_x = lerp(squeeze_amount_x, (WALL_SQUEEZE_AMOUNT * InputManager.get_pad_x()) if is_on_wall() else 0.0, delta * 50)
#
#	previous_is_on_wall = is_on_wall()

func change_state(state_id: int, data: Dictionary = {}):
	
	if current_state == null:
		current_state = states[state_id]
		current_state.on_enabled(null, data)
		emit_signal("STATE_CHANGED", null, current_state)
	elif current_state.get_id() != state_id:
		var previous_state: PlayerState = current_state
		previous_state.on_disabled(states[state_id])
		
		current_state = states[state_id]
		current_state.on_enabled(previous_state, data)
		
		emit_signal("STATE_CHANGED", previous_state, current_state)

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
	
	if strong:
		emit_landing_particles(5)
	
	wall_squeeze_animationplayer.play("wall_squeeze_" + str(direction))

func is_squeezing_wall() -> bool:
	return squeeze_amount_x != 0

func set_squeeze_amount_x(value: float):
	squeeze_amount_x = max(-1.0, min(1.0, value))

func set_squeeze_amount_y(value: float):
	squeeze_amount_y = max(-1.0, min(1.0, value))

func vel_move_y(to: float, by: float = INF, virtual: bool = false):
	if virtual:
		velocity.y = move_toward(velocity.y, to, by)
		return
	var initial_y: float = velocity.y
	velocity.y = move_toward(velocity.y, to, by)
#	acceleration.y = lerp(acceleration.y, acceleration.y + velocity.y - initial_y, 0.1)
#	acceleration.y += velocity.y - initial_y
#	disable_floor_snap = true

func vel_move_x(to: float, by: float = INF, virtual: bool = false):
	if virtual:
		velocity.x = move_toward(velocity.x, to, by)
		return
	var initial_x: float = velocity.x
	velocity.x = move_toward(velocity.x, to, by)
#	acceleration.x = lerp(acceleration.x, acceleration.x + velocity.x - initial_x, 1)
#	acceleration.x += velocity.x - initial_x

func vel_move(to: Vector2, delta: float = INF, virtual: bool = false):
	if virtual:
		velocity = velocity.move_toward(to, delta)
		return
	var initial: Vector2 = velocity
	velocity = velocity.move_toward(to, delta)
	acceleration += velocity - initial

func emit_landing_particles(amount: int = 2):
	var emitter: CPUParticles2D = landing_particles.duplicate()
	Utils.anchor.add_child(emitter)
	emitter.global_position = landing_particles.global_position
	emitter.z_index = 10
	emitter.amount = amount
	emitter.emitting = true
	
	yield(get_tree().create_timer(emitter.lifetime), "timeout")
	emitter.queue_free()
	
