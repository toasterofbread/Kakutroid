extends PlayerState

func get_id() -> int:
	return Player.STATE.NEUTRAL

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	player.running = false

func process(delta: float):
	.process(delta)
	
	player.crouching = module_input.is_action_pressed("pad_down")
	
	if module_input.is_action_just_pressed("jump") or module_physics.can_fall():
		player.change_state(Player.STATE.JUMP, {"fall": !player.is_on_floor()})
		return
	
	if module_input.get_pad_x() != 0:
		
		if not player.crouching:
			if module_input.is_action_pressed("run"):
				player.change_state(Player.STATE.RUN)
			
			if player.running or player.states[Player.STATE.WALK].get_time_since_activated() <= player_data["RUN_TRIGGER_WINDOW"]:
				player.change_state(Player.STATE.RUN)
				return
			
			if player.states[Player.STATE.RUN].get_time_since_disactivated() <= 0.1:
				player.change_state(Player.STATE.RUN)
				return
		
		player.change_state(Player.STATE.WALK)
		return

func physics_process(delta):
	.physics_process(delta)
	
	module_physics.vel_move_x(0.0, data["PASSIVE_DECELERATION"] * delta)
