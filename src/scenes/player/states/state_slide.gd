extends PlayerState

func get_id() -> int:
	return Player.STATE.SLIDE

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	
	var direction: int = sign(module_physics.velocity.x) if module_physics.velocity.x != 0 else module_input.get_pad_x()
	if "dash_magnitude" in data and data["dash_magnitude"] != 0.0 and direction != 0:
		module_physics.vel_move_x(self.data["DASH_SPEED"] * direction * data["dash_magnitude"])

func process(delta):
	.process(delta)
	
	player.crouching = module_input.is_action_pressed("pad_down")
	
	if module_input.is_action_just_pressed("jump"):
		var magnitude: float = abs(module_physics.velocity.x) / data["DASH_SPEED"]
		player.change_state(Player.STATE.JUMP, {"boost_magnitude": magnitude if magnitude >= 0.95 else 0.0})
		return
	
	if module_physics.can_fall():
		player.change_state(Player.STATE.JUMP, {"fall": true})
		return
	
	if not player.crouching:
		if module_input.is_action_pressed("run") or abs(module_physics.velocity.x) > player.get_state_data(Player.STATE.WALK)["MAX_SPEED"]:
			player.change_state(Player.STATE.RUN)
		elif module_input.get_pad_x() != 0:
			player.change_state(Player.STATE.WALK)
		else:
			player.change_state(Player.STATE.NEUTRAL)
		return

func physics_process(delta):
	.physics_process(delta)
	
	module_physics.vel_move_x(0.0, data["PASSIVE_DECELERATION"] * delta)
