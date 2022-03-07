extends PlayerState

var crouch_mode: bool = false

func get_id() -> int:
	return Player.STATE.WALK

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	crouch_mode = player.crouching
	player.running = false

func process(delta):
	.process(delta)
	
	player.crouching = module_input.is_action_pressed("pad_down")
	if module_input.is_action_just_pressed("jump"):
		player.change_state(Player.STATE.JUMP)
		return
	
	if module_physics.can_fall():
		player.change_state(Player.STATE.JUMP, {"fall": true})
		return
	
#	if not crouch_mode and player.crouching:
#		player.change_state(Player.STATE.SLIDE)
#		return
	
	if module_input.is_action_pressed("run"):
		player.change_state(Player.STATE.RUN)
		return
	
	if module_input.get_pad_x() == 0:
		player.change_state(Player.STATE.NEUTRAL)
		return

func physics_process(delta):
	.physics_process(delta)
	
	var pad_x: int = module_input.get_pad_x()
	if sign(module_physics.velocity.x) != pad_x and module_physics.velocity.x != 0:
		module_physics.vel_move_x(0.0, data["DECELERATION"] * delta)
	else:
		module_physics.vel_move_x(data["MAX_SPEED"] * pad_x, data["ACCELERATION"] * delta)
