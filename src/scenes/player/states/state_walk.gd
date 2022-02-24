extends PlayerState

# - Physics values -
const WALK_ACCELERATION: float = 500.0
const WALK_MAX_SPEED: float = 150.0
const WALK_DECELERATION: float = 1000.0
const RUN_TRIGGER_WINDOW: float = 0.3

var crouch_mode: bool = false

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.WALK

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	crouch_mode = player.crouching

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("crouch")
	
	if not crouch_mode and player.crouching:
		player.change_state(Enums.PLAYER_STATE.SLIDE)
		return
	
	if Input.is_action_just_pressed("jump"):
		player.change_state(Enums.PLAYER_STATE.JUMP)
		return
	
	if Input.is_action_pressed("run"):
		player.change_state(Enums.PLAYER_STATE.RUN)
		return
	
	var pad: Vector2 = InputManager.get_pad_vector()
	
	if pad.x == 0:
		player.change_state(Enums.PLAYER_STATE.SLIDE if player.crouching and not crouch_mode else Enums.PLAYER_STATE.NEUTRAL)
		return
	

func physics_process(delta):
	.physics_process(delta)
	
	var pad_x: int = InputManager.get_pad_x()
	if sign(player.velocity.x) != pad_x and player.velocity.x != 0:
		player.vel_move_x(0.0, WALK_DECELERATION * delta)
	else:
		player.vel_move_x(WALK_MAX_SPEED * pad_x, WALK_ACCELERATION * delta)
