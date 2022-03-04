extends PlayerState

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.SLIDE

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	
	var direction: int = sign(player.velocity.x) if player.velocity.x != 0 else InputManager.get_pad_x()
	if "dash_magnitude" in data and data["dash_magnitude"] != 0.0 and direction != 0:
		player.vel_move_x(self.data["DASH_SPEED"] * direction * data["dash_magnitude"])

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("pad_down")
	
	if Input.is_action_just_pressed("jump"):
		var magnitude: float = abs(player.velocity.x) / data["DASH_SPEED"]
		player.change_state(Enums.PLAYER_STATE.JUMP, {"boost_magnitude": magnitude if magnitude >= 0.95 else 0.0})
		return
	
	if player.can_fall():
		player.change_state(Enums.PLAYER_STATE.JUMP, {"fall": true})
		return
	
	if not player.crouching:
		if Input.is_action_pressed("run") or abs(player.velocity.x) > player.get_state_data(Enums.PLAYER_STATE.WALK)["MAX_SPEED"]:
			player.change_state(Enums.PLAYER_STATE.RUN)
		elif InputManager.get_pad_x() != 0:
			player.change_state(Enums.PLAYER_STATE.WALK)
		else:
			player.change_state(Enums.PLAYER_STATE.NEUTRAL)
		return

func physics_process(delta):
	.physics_process(delta)
	
	player.vel_move_x(0.0, data["PASSIVE_DECELERATION"] * delta)
