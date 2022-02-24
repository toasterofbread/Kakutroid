extends PlayerState

# - Physics values -
const JUMP_MAX_DURATION: float = 0.25
const JUMP_MIN_DURATION: float = 0.1
const JUMP_ACCELERATION: float = 2000.0
const JUMP_ACCELERATION_BOOST: float = 600.0 # Goes on top of JUMP_ACCELERATION
const FAST_FALL_ACCELERATION: float = 3000.0
const FAST_FALL_MAX_SPEED: float = 500.0
var DRIFT_ACCELERATION: float = 0.0
var DRIFT_DECELERATION: float = 0.0
var DRIFT_MAX_SPEED: float = 0.0

const WALLJUMP_BOOST_Y: float = 0.0
const WALLJUMP_BOOST_Y_FAST: float = 200.0
const WALLJUMP_BOOST_X: float = 200.0
const WALLJUMP_BOOST_X_FAST: float = 300.0

var fast_fall_locked: bool = false
var run_mode: bool = null setget set_run_mode
var current_jump_time: float = 0.0
var boost_magnitude: float = 0.0

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.JUMP

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	
	current_jump_time = 0.0
	fast_fall_locked = player.crouching
	set_run_mode(previous_state.get_id() == Enums.PLAYER_STATE.RUN)
	
	if "boost_magnitude" in data:
		boost_magnitude = data["boost_magnitude"]
		print(boost_magnitude)
	else:
		boost_magnitude = 0.0

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("pad_down")
	
	if player.is_on_floor():
		if InputManager.get_pad_x() == 0:
			player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		elif is_fast_falling():
			player.change_state(Enums.PLAYER_STATE.SLIDE, {"dash_magnitude": player.previous_velocity.y / FAST_FALL_MAX_SPEED})
		elif run_mode:
			player.change_state(Enums.PLAYER_STATE.RUN)
		else:
			player.change_state(Enums.PLAYER_STATE.WALK)
		
		if abs(player.previous_velocity.y) >= player.PARTICLE_EMISSION_SPEED_MIN:
			player.emit_landing_particles(4 if is_fast_falling() else 2)
		
		return
	
	if (!Input.is_action_pressed("jump") and current_jump_time >= JUMP_MIN_DURATION) or player.is_on_ceiling():
		current_jump_time = JUMP_MAX_DURATION
	elif player.is_squeezing_wall() and Input.is_action_just_pressed("jump"):
		current_jump_time = 0.0
		player.vel_move_y((-WALLJUMP_BOOST_Y_FAST if is_fast_falling() else -WALLJUMP_BOOST_Y) * 0.8)
		player.vel_move_x((-WALLJUMP_BOOST_X_FAST if is_fast_falling() else -WALLJUMP_BOOST_X) * sign(player.squeeze_amount_x))
	
	if InputManager.get_pad_x() == 0:
		run_mode = false
	
	if not player.crouching:
		fast_fall_locked = false
	
	if player.is_on_wall() and sign(player.previous_velocity.x) == InputManager.get_pad_x():
		player.wall_collided(InputManager.get_pad_x())

func physics_process(delta):
	.physics_process(delta)
	
	if current_jump_time < JUMP_MAX_DURATION:
		player.vel_move_y(-INF, (JUMP_ACCELERATION + (JUMP_ACCELERATION_BOOST * boost_magnitude)) * delta)
		current_jump_time += delta
	elif is_fast_falling() and player.velocity.y < FAST_FALL_MAX_SPEED:
		player.vel_move_y(FAST_FALL_MAX_SPEED, FAST_FALL_ACCELERATION * delta)
	
	var pad_x: int = InputManager.get_pad_x()
	if pad_x == 0:
		player.vel_move_x(0, DRIFT_DECELERATION * delta)
	elif sign(player.velocity.x) != pad_x and player.velocity.x != 0:
		player.vel_move_x(0.0, DRIFT_DECELERATION * delta)
		Overlay.SET("DECEL", true)
	else:
		player.vel_move_x(DRIFT_MAX_SPEED * pad_x, DRIFT_ACCELERATION * delta)
		Overlay.SET("DECEL", false)

func set_run_mode(value: bool):
	run_mode = value
	
	if run_mode:
		var run_state: PlayerState = player.states[Enums.PLAYER_STATE.RUN]
		DRIFT_ACCELERATION = run_state.RUN_ACCELERATION
		DRIFT_DECELERATION = run_state.RUN_DECELERATION
		DRIFT_MAX_SPEED = run_state.RUN_MAX_SPEED
	else:
		var walk_state: PlayerState = player.states[Enums.PLAYER_STATE.WALK]
		DRIFT_ACCELERATION = walk_state.WALK_ACCELERATION
		DRIFT_DECELERATION = walk_state.WALK_DECELERATION
		DRIFT_MAX_SPEED = walk_state.WALK_MAX_SPEED

func is_fast_falling() -> bool:
	return player.crouching and not fast_fall_locked
