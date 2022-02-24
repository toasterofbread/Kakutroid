extends PlayerState

const PASSIVE_DECELERATION: float = 1000.0

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Enums.PLAYER_STATE.NEUTRAL

func process(delta):
	.process(delta)
	
	player.crouching = Input.is_action_pressed("crouch")
	
	if Input.is_action_just_pressed("jump"):
		player.change_state(Enums.PLAYER_STATE.JUMP)
		return
	
	if InputManager.get_pad_x() != 0:
		
		if not player.crouching:
			if Input.is_action_pressed("run"):
				player.change_state(Enums.PLAYER_STATE.RUN)
			
			var walk_state: PlayerState = player.states[Enums.PLAYER_STATE.WALK]
			if walk_state.get_time_since_activated() <= walk_state.RUN_TRIGGER_WINDOW:
				player.change_state(Enums.PLAYER_STATE.RUN)
				return
			
			var run_state: PlayerState = player.states[Enums.PLAYER_STATE.RUN]
			if run_state.get_time_since_disactivated() <= 0.1:
				player.change_state(Enums.PLAYER_STATE.RUN)
				return
		
		player.change_state(Enums.PLAYER_STATE.WALK)
		return
	

func physics_process(delta):
	.physics_process(delta)
	
	player.vel_move_x(0.0, PASSIVE_DECELERATION * delta)
