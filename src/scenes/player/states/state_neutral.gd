extends PlayerState

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.NEUTRAL

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("crouch")
	
	if Input.is_action_just_pressed("jump") or player.can_fall():
		player.change_state(Enums.PLAYER_STATE.JUMP, {"fall": !player.is_on_floor()})
		return
	
	if InputManager.get_pad_x() != 0:
		
		if not player.crouching:
			if Input.is_action_pressed("run"):
				player.change_state(Enums.PLAYER_STATE.RUN)
			
			if player.running or player.states[Enums.PLAYER_STATE.WALK].get_time_since_activated() <= general_physics_data["RUN_TRIGGER_WINDOW"]:
				player.change_state(Enums.PLAYER_STATE.RUN)
				return
			
			if player.states[Enums.PLAYER_STATE.RUN].get_time_since_disactivated() <= 0.1:
				player.change_state(Enums.PLAYER_STATE.RUN)
				return
		
		player.change_state(Enums.PLAYER_STATE.WALK)
		return

func physics_process(delta):
	.physics_process(delta)
	
	player.vel_move_x(0.0, physics_data["PASSIVE_DECELERATION"] * delta)
