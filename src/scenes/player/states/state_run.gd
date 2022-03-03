extends PlayerState

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.RUN

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	
	player.running = true
	
	var pad_x: int = InputManager.get_pad_x()
	if (("fast_falling" in data and data["fast_falling"]) or player.is_squeezing_wall()) and pad_x != 0:
		player.vel_move_x(physics_data["MAX_SPEED"] * pad_x)

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("crouch")
	
	if Input.is_action_just_pressed("jump"):
		player.change_state(Enums.PLAYER_STATE.JUMP)
		return
	
	if player.can_fall():
		player.change_state(Enums.PLAYER_STATE.JUMP, {"fall": true})
		return
	
	if player.crouching:
		player.change_state(Enums.PLAYER_STATE.SLIDE)
		return
	
	var pad: Vector2 = InputManager.get_pad()
	
	if pad.x == 0:
		player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		return
	
	if player.is_on_wall() and abs(player.previous_velocity.x) >= 100.0:
		player.wall_collided(InputManager.get_pad_x())
		player.running = false
		player.change_state(Enums.PLAYER_STATE.WALK)

func physics_process(delta):
	.physics_process(delta)
	
	var pad: Vector2 = InputManager.get_pad()
	
	if sign(player.velocity.x) != pad.x and sign(player.velocity.x) != 0:
		player.vel_move_x(0, physics_data["DECELERATION"] * delta)
		Overlay.SET("DECEL", true)
	else:
		player.vel_move_x(physics_data["MAX_SPEED"] * pad.x, physics_data["ACCELERATION"] * delta)
		Overlay.SET("DECEL", false)
