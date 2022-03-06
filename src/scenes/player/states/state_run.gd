extends PlayerState

func _init(_player: KinematicBody2D).(_player):
	pass

func get_id() -> int:
	return Player.STATE.RUN

func on_enabled(previous_state: PlayerState, data: Dictionary = {}):
	.on_enabled(previous_state, data)
	
	if not player_data["CAN_RUN"]:
		player.change_state(Player.STATE.WALK)
		return
	
	player.running = true
	
	var pad_x: int = player.get_pad_x()
	if (("fast_falling" in data and data["fast_falling"]) or player.is_squeezing_wall()) and pad_x != 0:
		player.vel_move_x(self.data["MAX_SPEED"] * pad_x)

func process(delta):
	.process(delta)
	
	player.crouching = player.is_action_pressed("pad_down")
	
	if player.is_action_just_pressed("jump"):
		player.change_state(Player.STATE.JUMP)
		return
	
	if player.can_fall():
		player.change_state(Player.STATE.JUMP, {"fall": true})
		return
	
	if player.crouching:
		player.change_state(Player.STATE.SLIDE)
		return
	
	var pad: Vector2 = player.get_pad()
	
	if pad.x == 0:
		player.change_state(Player.STATE.NEUTRAL)
		return
	
	if player.is_on_wall() and abs(player.previous_velocity.x) >= 100.0:
		player.wall_collided(player.get_pad_x())
		player.running = false
		player.change_state(Player.STATE.WALK)

func physics_process(delta):
	.physics_process(delta)
	
	var pad: Vector2 = player.get_pad()
	
	if sign(player.velocity.x) != pad.x and sign(player.velocity.x) != 0:
		player.vel_move_x(0, data["DECELERATION"] * delta)
		Overlay.SET("DECEL", true)
	else:
		player.vel_move_x(data["MAX_SPEED"] * pad.x, data["ACCELERATION"] * delta)
		Overlay.SET("DECEL", false)
