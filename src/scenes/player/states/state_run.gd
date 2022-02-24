extends PlayerState

# - Physics values -
const RUN_ACCELERATION: float = 500.0
const RUN_MAX_SPEED: float = 300.0
const RUN_DECELERATION: float = 1500.0

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.RUN

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)

	var pad_x: int = InputManager.get_pad_x()
	if (("fast_falling" in data and data["fast_falling"]) or player.is_squeezing_wall()) and pad_x != 0:
		player.vel_move_x(RUN_MAX_SPEED * pad_x)

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("crouch")
	
	if player.crouching:
		player.change_state(Enums.PLAYER_STATE.SLIDE)
		return
	
	if Input.is_action_just_pressed("jump"):
		player.change_state(Enums.PLAYER_STATE.JUMP)
		return
	
	var pad: Vector2 = InputManager.get_pad_vector()
	
	if pad.x == 0:
		player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		return
	
	if player.is_on_wall() and abs(player.previous_velocity.x) >= 100.0:
		player.wall_collided(InputManager.get_pad_x())

func physics_process(delta):
	.physics_process(delta)
	
	var pad: Vector2 = InputManager.get_pad_vector()
	
	if sign(player.velocity.x) != pad.x and sign(player.velocity.x) != 0:
		player.vel_move_x(0, RUN_DECELERATION * delta)
		Overlay.SET("DECEL", true)
	else:
		player.vel_move_x(RUN_MAX_SPEED * pad.x, RUN_ACCELERATION * delta)
		Overlay.SET("DECEL", false)
