extends Player

func _ready():
	
	var all_states: Array = [
		preload("res://src/scenes/player/states/state_neutral.gd").new(self),
		preload("res://src/scenes/player/states/state_walk.gd").new(self),
		preload("res://src/scenes/player/states/state_run.gd").new(self),
		preload("res://src/scenes/player/states/state_jump.gd").new(self),
		preload("res://src/scenes/player/states/state_slide.gd").new(self),
	]
	
	for state in all_states:
		assert(not state.get_id() in states, "State ID '" + Player.STATE.keys()[state.get_id()] + "' is duplicated")
		states[state.get_id()] = state
	
	demofile_path = DEMOFILE_DIRECTORY.plus_file(demofile_path)
	if demo_mode in [DEMO_MODE.PLAY, DEMO_MODE.PLAY_TEST]:
		assert(File.new().file_exists(demofile_path), "No file exists at path '" + demofile_path + "'")
		demofile_data = Utils.load_json(demofile_path).result
		demo_enabled = demo_mode == DEMO_MODE.PLAY
	
	squeeze_amount_x = 0
	squeeze_amount_y = 0
	
	area.connect("body_entered", self, "_on_area_body_entered")
	area.set_collision_mask_bit(19, true)
	area.set_collision_mask_bit(3, true)
	
	Game.set_node_damageable(self)
	Game.set_node_layer(self, Game.LAYERS.PLAYER)
	Game.set_node_layer(landing_particles, Game.LAYERS.PLAYER, 1)
	passive_heal_cap = player_data["MAX_HEALTH"]
	set_health(player_data["MAX_HEALTH"])
	set_fast_falling(false)
	change_state(Player.STATE.NEUTRAL)
	set_current_shape(Enums.SHAPE.CUBE, true)
	wind_sprite.visible = false

func _process(delta: float):
	
	if is_action_pressed("run"):
		set_running(true)
	
	if demo_mode == DEMO_MODE.RECORD or demo_mode == DEMO_MODE.PLAY_TEST:
		if Input.is_action_just_pressed("demo_start_recording") and not demo_enabled:
			demo_enabled = true
			modulate = Color.blue
			demo_playback_head = -physics_frame
		
		elif Input.is_action_just_pressed("demo_stop_recording") and demo_enabled:
			demo_enabled = false
			modulate = Color.white
			
			if demo_mode == DEMO_MODE.RECORD:
				var write: bool = true
				var file: File = File.new()
				if file.file_exists(demofile_path):
					var action: CustomDialog.Action = yield(CustomDialog.create_and_yield_option({
						"buttons": ["Yes", "No"], 
						"pause": true, 
						"title": "Overwrite file?", 
						"body": "A file already exists at path '" + demofile_path + "'. Overwrite it?"
					}), "completed")
					
					write = action.is_button() and action.get_button() == "Yes"
				
				if write:
					file.open(demofile_path, File.WRITE)
					file.store_string(to_json(demofile_data))
					file.close()
					
					yield(CustomDialog.create_and_yield_option({
						"buttons": ["OK"], 
						"pause": true, 
						"title": "File saved", 
						"body": "Recorded input data saved to file '" + demofile_path + "'. Size: " + str(len(demofile_data)) + " frames."
					}), "completed")
			
				demofile_data.clear()
	
	var health_percentage: float = health / player_data["MAX_HEALTH"]
	if health_percentage > 0.0:
		if health_percentage <= 0.3 and not sound_playing("low_health"):
			if low_health_sound_wait_time >= 0.1 + (0.4 * (health_percentage / 0.3)):
				play_sound("low_health")
				low_health_sound_wait_time = 0.0
			else:
				low_health_sound_wait_time += delta
	
	if wind_sprite.playing:
		if velocity != Vector2.ZERO and (!wind_sprite.get_meta("falling_only") or velocity.y >= 0.0):
			wind_sprite.visible = true
			wind_sprite.rotation = (velocity * Vector2(1, -1)).angle_to(Vector2.UP) - deg2rad(90)
			wind_sprite.scale.y = abs(wind_sprite.scale.y) * (-1 if abs(wind_sprite.rotation_degrees) > 90.0 else 1)
		else:
			wind_sprite.visible = false
	
	if (OS.get_ticks_msec() - last_damage_time) / 1000.0 > player_data["PASSIVE_HEAL_IDLE_TIME"] and health > 0.0:
		set_health(min(passive_heal_cap, health + (player_data["PASSIVE_HEAL_PERCENTAGE"] * player_data["MAX_HEALTH"] * delta / player_data["PASSIVE_HEAL_DURATION"])))
	
	if current_state != null:
		current_state.process(delta)
	
	Overlay.SET("Health percentage", clamp(health / player_data["MAX_HEALTH"], 0.0, 1.0))
	Overlay.SET("Velocity", velocity)
	Overlay.SET("State", Player.STATE.keys()[current_state.get_id()] if current_state != null else "NONE")
	Overlay.SET("Intangible", intangible)
	
	current_shape_node.scale.x = 1.0 - abs(squeeze_amount_x)
	current_shape_node.position.x = (CUBE_SIZE / -2) * (current_shape_node.scale.x - 1) * sign(squeeze_amount_x)
	current_shape_node.scale.y = 1.0 - abs(squeeze_amount_y)
	current_shape_node.position.y = (CUBE_SIZE / -2) * (current_shape_node.scale.y - 1) * sign(squeeze_amount_y)
	previous_velocity = velocity
	
	var pad_x: int = get_pad_x()
	if pad_x != 0:
		facing = pad_x
	
	if is_action_just_pressed("fire_weapon"):
		fire_weapon()
	else:
		if is_action_just_pressed("fire_weapon_left"):
			fire_weapon(-1)
		if is_action_just_pressed("fire_weapon_right"):
			fire_weapon(1)
	
	if is_action_just_pressed("cycle_shape"):
		set_current_shape(Enums.SHAPE.CIRCLE)

func _physics_process(delta: float):
	
	if demo_mode == DEMO_MODE.RECORD and demo_enabled:
		
		var pressed_actions: Array = []
		for action in InputMap.get_actions():
			if action in DEMO_IGNORED_ACTIONS:
				continue
			if is_action_pressed(action):
				pressed_actions.append(action)
		demofile_data.append(pressed_actions)
	elif demo_mode == DEMO_MODE.PLAY_TEST and demo_enabled and not is_frame_within_demofile(get_demo_playback_head()):
		demo_enabled = false
		modulate = Color.white
	
	physics_frame += 1
	
	if current_state != null:
		current_state.physics_process(delta)
	
	if is_on_wall():
		vel_move_y(player_data["MAX_FALL_SPEED_WALL"], player_data["GRAVITY_WALL"] * delta)
	elif velocity.y < player_data["MAX_FALL_SPEED"]:
		vel_move_y(player_data["MAX_FALL_SPEED"], player_data["GRAVITY"] * delta)
	
	velocity = move_and_slide(velocity, Vector2.UP)
	# Emit landing particles
	if get_slide_count() > 0 and is_on_floor() and not was_on_floor and previous_velocity.y >= 200.0:
		
		# Find collided object
		for collision_idx in get_slide_count():
			var collision: KinematicCollision2D = get_slide_collision(collision_idx)
			if not collision.collider is RoomCollisionObject:
				continue
			var collider: RoomCollisionObject = collision.collider
			
#			# Find collided tile
#			var pos: Vector2 = tilemap.world_to_map(tilemap.to_local(collision.position))# - Vector2(1, 0)
#			var tile: int = tilemap.get_cellv(pos)
#			if tile == -1:
#				tile = tilemap.get_cellv(pos - Vector2(1, 0))
#				if tile == -1:
#					continue
			
			# Emit particles with texture and colour of tile
			emit_landing_particles(collider.particle_texture).color = collider.particle_colour
			break
	
	if is_on_floor():
		air_time = -1.0
	elif was_on_floor:
		air_time = 0.0
	else:
		air_time += delta
	
	Overlay.SET("On floor", is_on_floor())
	Overlay.SET("On wall", is_on_wall())
	Overlay.SET("Air time", air_time)
	
	was_on_floor = is_on_floor()

func change_state(state_id: int, data: Dictionary = {}):
	
	if current_state == null:
		current_state = states[state_id]
		current_state.on_enabled(null, data)
		emit_signal("STATE_CHANGED", null)
	elif current_state.get_id() != state_id:
		var previous_state: PlayerState = current_state
		previous_state.on_disabled(states[state_id])
		
		current_state = states[state_id]
		current_state.on_enabled(previous_state, data)
		
		emit_signal("STATE_CHANGED", previous_state)

func is_frame_within_demofile(frame: int) -> bool:
	return frame < len(demofile_data)

func get_demo_playback_head() -> int:
	return physics_frame + demo_playback_head

func is_demo_controlled() -> bool:
	return demo_mode in [DEMO_MODE.PLAY, DEMO_MODE.PLAY_TEST] and demo_enabled

func is_action_pressed(action: String) -> bool:
	if not is_demo_controlled():
		return Input.is_action_pressed(action)
	elif is_frame_within_demofile(get_demo_playback_head()):
		return action in demofile_data[get_demo_playback_head()]
	else:
		return false

func is_action_just_pressed(action: String) -> bool:
	if not is_demo_controlled():
		return Input.is_action_just_pressed(action)
	elif is_frame_within_demofile(get_demo_playback_head()):
		if is_frame_within_demofile(get_demo_playback_head() - 1) and action in demofile_data[get_demo_playback_head() - 1]:
			return false
		return action in demofile_data[get_demo_playback_head()]
	else:
		return false

func is_action_just_released(action: String) -> bool:
	if not is_demo_controlled():
		return Input.is_action_released(action)
	elif is_frame_within_demofile(get_demo_playback_head()):
		if is_frame_within_demofile(get_demo_playback_head() - 1) and not action in demofile_data[get_demo_playback_head() - 1]:
			return false
		return not action in demofile_data[get_demo_playback_head()]
	else:
		return false

func get_pad(just_pressed: bool = false) -> Vector2:
	return Vector2(get_pad_x(just_pressed), get_pad_y(just_pressed))

func get_pad_x(just_pressed: bool = false) -> int:
	if just_pressed:
		return int(is_action_just_pressed("pad_right")) - int(is_action_just_pressed("pad_left"))
	else:
		return int(is_action_pressed("pad_right")) - int(is_action_pressed("pad_left"))

func get_pad_y(just_pressed: bool = false) -> int:
	if just_pressed:
		return int(is_action_just_pressed("pad_down")) - int(is_action_just_pressed("pad_up"))
	else:
		return int(is_action_pressed("pad_down")) - int(is_action_pressed("pad_up"))

func set_current_shape(value: int, instant: bool = false):
	if value == current_shape:
		return
	
	current_shape = value
	shape_transition_tween.stop_all()
	
	if trail_emitter.has_trail_node(current_shape_node):
		trail_emitter.remove_trail_node(current_shape_node)
	
	if instant:
		var position: Vector2
		if current_shape_node:
			position = current_shape_node.global_position
			current_shape_node.modulate.a = 1
			Utils.reparent_node(current_shape_node, $Shapes)
		else:
			position = global_position
		current_shape_node = shape_data[current_shape]["node"]
		current_shape_node.visible = true
		Utils.reparent_node(current_shape_node, self)
		current_shape_node.global_position = position
		
		trail_emitter.add_trail_node(current_shape_node)
	else:
		shape_transition_tween.interpolate_property(current_shape_node, "modulate:a", current_shape_node.modulate.a, 0.0, SHAPE_TRANSITION_DURATION / 2.0, Tween.TRANS_EXPO)
		shape_transition_tween.start()
		yield(shape_transition_tween, "tween_all_completed")
		var position: Vector2 = current_shape_node.global_position if current_shape_node != null else global_position
		Utils.reparent_node(current_shape_node, $Shapes)
		current_shape_node = shape_data[current_shape]["node"]
		current_shape_node.modulate.a = 0.0
		current_shape_node.visible = true
		Utils.reparent_node(current_shape_node, self)
		current_shape_node.global_position = position
		
		trail_emitter.add_trail_node(current_shape_node)
		
		shape_transition_tween.interpolate_property(current_shape_node, "modulate:a", current_shape_node.modulate.a, 1.0, SHAPE_TRANSITION_DURATION / 2.0, Tween.TRANS_EXPO)
		shape_transition_tween.start()
		yield(shape_transition_tween, "tween_all_completed")

func set_crouching(value: bool):
	if value == crouching:
		return
	
	crouching = value
	crouch_tween.stop_all()
	crouch_tween.interpolate_property(self, "squeeze_amount_y", squeeze_amount_y, CROUCH_SQUEEZE_AMOUNT if crouching else 0.0, 0.1, Tween.TRANS_ELASTIC)
	crouch_tween.start()

func wall_collided(direction: int, strong: bool = false):
	assert(direction in [1, -1])
	
	if wall_squeeze_animationplayer.is_playing():
		return
	
	# TODO
#	if strong:
#		emit_landing_particles(5)
	
	wall_squeeze_animationplayer.play("wall_squeeze_" + str(direction))

func fire_weapon(direction: int = facing):
	assert(direction in [-1, 1])
	
	var projectile: Node2D = projectile_scene.instance()
	projectile.init(direction, current_shape, Color("fe6fff"), self)
	Utils.anchor.add_child(projectile)
	projectile.global_position = current_shape_node.global_position

func is_squeezing_wall() -> bool:
	return squeeze_amount_x != 0

func set_squeeze_amount_x(value: float):
	squeeze_amount_x = max(-1.0, min(1.0, value))

func set_squeeze_amount_y(value: float):
	squeeze_amount_y = max(-1.0, min(1.0, value))

func vel_move_y(to: float, by: float = INF):
	velocity.y = move_toward(velocity.y, to, by)

func vel_move_x(to: float, by: float = INF):
	velocity.x = move_toward(velocity.x, to, by)

func vel_move(to: Vector2, delta: float = INF):
	velocity = velocity.move_toward(to, delta)

func emit_landing_particles(texture_or_colour, amount: int = 3) -> CPUParticles2D:
	assert(texture_or_colour is Color or texture_or_colour is Texture)
	
	var emitter: CPUParticles2D = landing_particles.duplicate()
	emitter.global_position = landing_particles.global_position
	emitter.amount = amount
	emitter.emitting = true
	
	if texture_or_colour is Texture:
		emitter.texture = texture_or_colour
		emitter.color = Color.white
	else:
		emitter.color = texture_or_colour
		emitter.texture = CUBE_TEXTURE
	
	Utils.anchor.add_child(emitter)
	get_tree().create_timer(emitter.lifetime).connect("timeout", emitter, "queue_free")
	return emitter

func can_fall() -> bool:
	return !is_on_floor() and air_time > player_data["COYOTE_TIME"]

func get_state_data(state_id: int) -> Dictionary:
	return data[Player.STATE.keys()[state_id].to_lower()]

func collect_upgrade(upgrade_type: int):
	print("Collect upgrade: ", UPGRADE.keys()[upgrade_type])

func damage(type: int, amount: float, position: Vector2 = null):
	if amount <= 0.0:
		return
	
	passive_heal_cap = min(passive_heal_cap, (health - amount) + (player_data["MAX_HEALTH"] * player_data["PASSIVE_HEAL_PERCENTAGE"]))
	
	set_health(health - amount)
	last_damage_time = OS.get_ticks_msec()
	
	if health <= 0.0:
		death(type)
	else:
		$AnimationPlayer.play("damage")
		play_sound("hurt")
		if position != null:
			velocity = (global_position - position).normalized() * player_data["KNOCKBACK_SPEED"]
			set_intangible(true)

func death(type: int):
	print("Player death")
	play_sound("death")

func set_intangible(value: bool, no_timer: bool = false):
	if intangible == value:
		return
	intangible = value
	
	if intangible and not no_timer:
		intangibility_timer.start(player_data["HIT_INTANGIBILITY_DURATION"])
	
	set_collision_layer_bit(1, !intangible)

func _on_IntangibilityTimer_timeout():
	set_intangible(false)

func set_health(value: float):
	if health == value:
		return
	
	health = clamp(value, 0.0, player_data["MAX_HEALTH"])
	
	var percentage: float = health / player_data["MAX_HEALTH"]
	if percentage == 1.0:
		gradient.colors = [Color(player_data["FULL_COLOUR"])]
		gradient.offsets = [0.0]
	elif percentage == 0.0:
		gradient.colors = [Color(player_data["EMPTY_COLOUR"])]
		gradient.offsets = [0.0]
	else:
		gradient.colors = [Color(player_data["EMPTY_COLOUR"]), Color(player_data["FULL_COLOUR"])]
		gradient.offsets = [clamp((0.5 - percentage) * 2.0, 0.0, 1.0), clamp((percentage - 1.0) * -2.0, 0.0, 1.0)]

func set_running(value: bool):
	running = value and player_data["CAN_RUN"]

func set_fast_falling(value: bool):
	if fast_falling == value:
		return
	fast_falling = value
	set_collision_mask_bit(19, !fast_falling)
	area.disabled = not fast_falling and not wind_sprite.visible

func _on_area_body_entered(body: Node):
	if (fast_falling or wind_sprite.visible) and Game.is_node_damageable(body):
		body.damage(Enums.DAMAGE_TYPE.FASTFALL, player_data["HIGHSPEED_COLLISION_DAMAGE"], global_position)

func play_sound(sound_key: String):
	$Sounds.get_node(sound_key).play()

func sound_playing(sound_key: String):
	return $Sounds.get_node(sound_key).playing

func play_wind_animation(falling_only: bool = false):
	wind_sprite.set_meta("falling_only", falling_only)
	wind_sprite.frame = 0
	wind_sprite.play()
	
	set_intangible(true, true)
	area.enable()
	yield(wind_sprite, "animation_finished")
	area.disabled = not fast_falling
	set_intangible(false, true)
#	var awaiting: GDScriptFunctionState = Utils.remote_yield(wind_sprite, "animation_finished")
#	while awaiting.is_valid():
#		yield(get_tree(), "idle_frame")
	
	wind_sprite.visible = false
	wind_sprite.playing = false

func using_upgrade(upgrade: int) -> bool:
	return save_data["upgrades"][upgrade]["acquired"] >= 1 and save_data["upgrades"][upgrade]["enabled"]
