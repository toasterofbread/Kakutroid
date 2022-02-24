extends PlayerState

# - Physics values -
const PASSIVE_DECELERATION: float = 100.0
const DASH_SPEED: float = 400.0

var dash_magnitude: float = 0.0

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.SLIDE

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	
	var direction: int = sign(player.velocity.x) if player.velocity.x != 0 else InputManager.get_pad_x()
	if "dash_magnitude" in data and data["dash_magnitude"] != 0.0 and direction != 0:
		player.vel_move_x(DASH_SPEED * direction * data["dash_magnitude"])
		dash_magnitude = data["dash_magnitude"]
	else:
		dash_magnitude = 0.0
	

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("crouch")
	
	if Input.is_action_just_pressed("jump"):
		player.change_state(Enums.PLAYER_STATE.JUMP, {"boost_magnitude": dash_magnitude})
		return
	
	var pad: Vector2 = InputManager.get_pad_vector()
	
	if not player.crouching:
		if Input.is_action_pressed("run") or abs(player.velocity.x) > player.states[Enums.PLAYER_STATE.WALK].WALK_MAX_SPEED:
			player.change_state(Enums.PLAYER_STATE.RUN)
		elif InputManager.get_pad_x() != 0:
			player.change_state(Enums.PLAYER_STATE.WALK)
		else:
			player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		return
	
	if player.velocity.x == 0:
		player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		return
	

func physics_process(delta):
	.physics_process(delta)
	
	player.vel_move_x(0.0, PASSIVE_DECELERATION * delta)
