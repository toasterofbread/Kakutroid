extends Player

onready var DMG: Damageable = Damageable.new(self)

const DEBUG_SAVE_DATA: Dictionary = {
	"upgrades": {
		UPGRADE.WALLJUMP: {"acquired": 1, "enabled": true},
		UPGRADE.MORPH_CUBE: {"acquired": 1, "enabled": true},
		UPGRADE.MORPH_TRIANGLE: {"acquired": 1, "enabled": true},
		UPGRADE.MORPH_CIRCLE: {"acquired": 1, "enabled": true},
	}
}

export var _a: int = 0

func _ready():
	
	if Game.player != self and not ghost:
		queue_free()
		return
	
	module_demo = PlayerModuleDemo.new().init(self)
	module_input = PlayerModuleInput.new().init(self)
	module_physics = PlayerModulePhysics.new().init(self)
	
	camera.current = !ghost
	camera.pause_mode = Node.PAUSE_MODE_PROCESS
	area_main.set_disabled(ghost)
	
	add_child(module_demo)
	add_child(module_input)
	add_child(module_physics)
	
	var all_states: Array = [
		preload("res://src/scenes/player/states/state_neutral.gd").new(),
		preload("res://src/scenes/player/states/state_walk.gd").new(),
		preload("res://src/scenes/player/states/state_run.gd").new(),
		preload("res://src/scenes/player/states/state_jump.gd").new(),
		preload("res://src/scenes/player/states/state_slide.gd").new(),
	]
	
	for state in all_states:
		assert(not state.get_id() in states, "State ID '" + Player.STATE.keys()[state.get_id()] + "' is duplicated")
		state.init(self)
		states[state.get_id()] = state
	
	squeeze_amount_x = 0
	squeeze_amount_y = 0
	
	save_data = Game.save_file.get_dict("player")
	if not "upgrades" in save_data:
		save_data["upgrades"] = {}
		for upgrade in UPGRADE.values():
			save_data["upgrades"][upgrade] = {"acquired": 0, "enabled": true}
	
	if not ghost:
		area_main.connect("body_entered", self, "_on_area_main_body_entered")
		area_main.set_collision_mask_bit(19, true)
		area_main.set_collision_mask_bit(3, true)
		
		# TODO | Player spawning system
		if Game.player == null:
			Game.player = self
		
		# DEBUG
		save_data = DEBUG_SAVE_DATA
#		Game.save_file.set_dict("player", save_data)
	else:
		background = true
	
	Game.set_node_layer(self, get_z_layer())
	Game.set_node_layer(landing_particles, get_z_layer(), 1)
	Game.set_node_layer(trail_emitter, get_z_layer(), -1)
	
	Game.set_all_physics_layers(self, false)
	Game.set_all_physics_masks(self, false)
	Game.set_physics_layer(self, get_player_layer(), true)
	Game.set_physics_mask(self, Game.PHYSICS_LAYER.CAMERA_CHUNK, !ghost)
	Game.set_physics_mask(self, get_world_mask(), true)
	
	set_background(true)
	
	passive_heal_cap = player_data["MAX_HEALTH"]
	Damageable.set_health(self, player_data["MAX_HEALTH"])
	set_fast_falling(false)
	change_state(Player.STATE.NEUTRAL)
	set_current_shape(Enums.SHAPE.CUBE, true)
	wind_sprite.visible = false
	

func _process(delta: float):
	
	if is_paused():
		return
	
#	if module_input.is_action_pressed("run"):
	set_running(true)
	
	if not ghost:
		var health_percentage: float = DMG.health / player_data["MAX_HEALTH"]
		if health_percentage > 0.0:
			if health_percentage <= 0.3 and not sound_playing("low_health"):
				if low_health_sound_wait_time >= 0.1 + (0.4 * (health_percentage / 0.3)):
					play_sound("low_health")
					low_health_sound_wait_time = 0.0
				else:
					low_health_sound_wait_time += delta
		
		if (OS.get_ticks_msec() - last_damage_time) / 1000.0 > player_data["PASSIVE_HEAL_IDLE_TIME"] and DMG.health > 0.0:
			Damageable.set_health(self, min(passive_heal_cap, DMG.health + (player_data["PASSIVE_HEAL_PERCENTAGE"] * player_data["MAX_HEALTH"] * delta / player_data["PASSIVE_HEAL_DURATION"])))
	
		Overlay.SET("Health percentage", clamp(DMG.health / player_data["MAX_HEALTH"], 0.0, 1.0))
		Overlay.SET("State", Player.STATE.keys()[current_state.get_id()] if current_state != null else "NONE")
		Overlay.SET("Intangible", DMG.intangible)
	
	if wind_sprite.playing:
		if module_physics.velocity != Vector2.ZERO and (!wind_sprite.get_meta("falling_only") or module_physics.velocity.y >= 0.0):
			wind_sprite.visible = true
			wind_sprite.rotation = (module_physics.velocity * Vector2(1, -1)).angle_to(Vector2.UP) - deg2rad(90)
			wind_sprite.scale.y = abs(wind_sprite.scale.y) * (-1 if abs(wind_sprite.rotation_degrees) > 90.0 else 1)
		else:
			wind_sprite.visible = false
	
	if current_state != null:
		current_state.process(delta)
	
	current_shape_node.scale.x = 1.0 - abs(squeeze_amount_x)
	current_shape_node.position.x = (CUBE_SIZE / -2) * (current_shape_node.scale.x - 1) * sign(squeeze_amount_x)
	current_shape_node.scale.y = 1.0 - abs(squeeze_amount_y)
	current_shape_node.position.y = (CUBE_SIZE / -2) * (current_shape_node.scale.y - 1) * sign(squeeze_amount_y)
	
	module_physics.previous_velocity = module_physics.velocity
	
	var pad_x: int = module_input.get_pad_x()
	if pad_x != 0:
		facing = pad_x
	
	if module_input.is_action_just_pressed("fire_weapon"):
		fire_weapon()
	else:
		if module_input.is_action_just_pressed("fire_weapon_left"):
			fire_weapon(-1)
		if module_input.is_action_just_pressed("fire_weapon_right"):
			fire_weapon(1)
	
	if module_input.is_action_just_pressed("cycle_shape"):
		set_current_shape(Enums.SHAPE.CIRCLE)
	elif module_input.is_action_just_pressed("switch_world_layer"):
		attempt_background_transition()

func _physics_process(delta: float):
	
	if is_paused():
		return
	
	if current_state != null:
		current_state.physics_process(delta)
	physics_frame += 1

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

func set_current_shape(value: int, instant: bool = false):
	if value == current_shape:
		return
	
	current_shape = value
	shape_transition_tween.stop_all()
	
	if current_shape_node != null and trail_emitter.has_trail_node(current_shape_node.get_child(0)):
		trail_emitter.remove_trail_node(current_shape_node.get_child(0))
	
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
		on_current_shape_changed()
		
		trail_emitter.add_trail_node(current_shape_node.get_child(0))
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
		on_current_shape_changed()
		
		trail_emitter.add_trail_node(current_shape_node.get_child(0))
		
		shape_transition_tween.interpolate_property(current_shape_node, "modulate:a", current_shape_node.modulate.a, 1.0, SHAPE_TRANSITION_DURATION / 2.0, Tween.TRANS_EXPO)
		shape_transition_tween.start()
		yield(shape_transition_tween, "tween_all_completed")

func on_current_shape_changed():
	pass

func set_crouching(value: bool):
	if value == crouching:
		return
	
	crouching = value
	crouch_tween.stop_all()
	crouch_tween.interpolate_property(self, "squeeze_amount_y", squeeze_amount_y, CROUCH_SQUEEZE_AMOUNT if crouching else 0.0, 0.1, Tween.TRANS_ELASTIC)
	crouch_tween.start()

func wall_collided(direction: int, _strong: bool = false):
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

func emit_landing_particles(texture_or_colour, amount: int = 3) -> CPUParticles2D:
	assert(texture_or_colour is Color or texture_or_colour is Texture)
	
	var emitter: CPUParticles2D = landing_particles.duplicate()
	emitter.global_transform = landing_particles.global_transform
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

func get_state_data(state_id: int) -> Dictionary:
	return data[Player.STATE.keys()[state_id].to_lower()]

func collect_upgrade(upgrade_type: int):
	save_data["upgrades"][upgrade_type]["acquired"] += 1

func on_damage(type: int, amount: float, position: Vector2 = null):
	
	if ghost:
		return
	
	passive_heal_cap = min(passive_heal_cap, (DMG.health - amount) + (player_data["MAX_HEALTH"] * player_data["PASSIVE_HEAL_PERCENTAGE"]))
	
	Damageable.set_health(self, DMG.health - amount)
	last_damage_time = OS.get_ticks_msec()
	
	if DMG.health <= 0.0:
		Damageable.death(self, type)
	else:
		$AnimationPlayer.play("damage")
		play_sound("hurt")
		if position != null:
			module_physics.velocity = (global_position - position).normalized() * player_data["KNOCKBACK_SPEED"]
			set_intangible(true)

func on_death(_type: int):
	play_sound("death")

func is_paused() -> bool:
	return (get_tree().paused and paused == null) or paused

var entered_camerachunks:  Array = []
func camerachunk_entered(chunk: Node):
	if not chunk in entered_camerachunks:
		entered_camerachunks.append(chunk)

func camerachunk_exited(chunk: Node):
	entered_camerachunks.erase(chunk)
	for connected_chunk in chunk.connected_chunks:
		if connected_chunk in entered_camerachunks:
			connected_chunk.enter()

func set_intangible(value: bool, no_timer: bool = false):
	if DMG.intangible == value:
		return
	DMG.intangible = value
	
	if DMG.intangible and not no_timer:
		intangibility_timer.start(player_data["HIT_INTANGIBILITY_DURATION"])
	
	if !ghost:
		Game.set_physics_layer(self, get_player_layer(), !DMG.intangible)

func _on_IntangibilityTimer_timeout():
	set_intangible(false)

func set_health(value: float):
	if DMG.health == value:
		return
	
	DMG.health = clamp(value, 0.0, player_data["MAX_HEALTH"])
	
	var percentage: float = DMG.health / player_data["MAX_HEALTH"]
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
	
	set_collision_mask_bit(19, !fast_falling and !ghost and !background)
	area_main.disabled = not fast_falling and not wind_sprite.visible

func _on_area_main_body_entered(body: Node):
	if not ghost and (fast_falling or wind_sprite.visible) and Damageable.is_node_damageable(body):
		Damageable.damage(body, Enums.DAMAGE_TYPE.FASTFALL, player_data["HIGHSPEED_COLLISION_DAMAGE"], global_position)

func play_sound(sound_key: String):
	if ghost:
		return
	$Sounds.get_node(sound_key).play()

func sound_playing(sound_key: String):
	return $Sounds.get_node(sound_key).playing

func play_wind_animation(falling_only: bool = false):
	wind_sprite.set_meta("falling_only", falling_only)
	wind_sprite.frame = 0
	wind_sprite.play()
	
	set_intangible(true, true)
	area_main.enable()
	yield(wind_sprite, "animation_finished")
	area_main.disabled = not fast_falling
	set_intangible(false, true)
	
	wind_sprite.visible = false
	wind_sprite.playing = false

func using_upgrade(upgrade: int) -> bool:
	return get_upgrade_amount(upgrade) >= 1 and save_data["upgrades"][upgrade]["enabled"]

func get_upgrade_amount(upgrade: int) -> int:
	if save_data == null or not upgrade in save_data["upgrades"]:
		return 0
	return save_data["upgrades"][upgrade]["acquired"]

func set_background(value: bool):
	var old_layer: bool = get_collision_layer_bit(get_player_layer())
	var old_mask: bool = get_collision_mask_bit(get_world_mask())
	Game.set_physics_layer(self, get_player_layer(), false)
	Game.set_physics_mask(self, get_world_mask(), false)
	
	background = value
	
	Game.set_physics_layer(self, get_player_layer(), old_layer)
	Game.set_physics_mask(self, get_world_mask(), old_mask)
	
	Game.set_node_layer(self, get_z_layer())
	
	if landing_particles:
		Game.set_node_layer(landing_particles, get_z_layer(), 1)
	if trail_emitter:
		Game.set_node_layer(trail_emitter, get_z_layer(), -1)

func get_player_layer() -> int:
	if ghost:
		return Game.PHYSICS_LAYER.GHOST_PLAYER
	return Game.PHYSICS_LAYER.PLAYER_BACKGROUND if background else Game.PHYSICS_LAYER.PLAYER

func get_world_mask() -> int:
	return Game.PHYSICS_LAYER.WORLD_BACKGROUND if background else Game.PHYSICS_LAYER.WORLD

func get_z_layer() -> int:
	return Game.LAYER.PLAYER_BACKGROUND if background else Game.LAYER.PLAYER

func background_transition_blocked():
	play_sound("bump_wall")
	current_shape_node.modulate.a = 0.5
	trail_emitter.modulate.a = 0.5
	squeeze_amount_y = 0.1
	yield(get_tree().create_timer(0.1), "timeout")
	squeeze_amount_y = 0.0
	current_shape_node.modulate.a = 1.0
	trail_emitter.modulate.a = 1.0

func attempt_background_transition():
	
#	if not background:
#		shapecast.set_collision_mask_bit(Game.PHYSICS_LAYER.WORLD_BACKGROUND, true)
#		shapecast.set_collision_mask_bit(Game.PHYSICS_LAYER.BACKGROUND_ENTRY_AREA_POINT, false)
#		shapecast.force_shapecast_update()
#
#		if shapecast.is_colliding():
#			background_transition_blocked()
#			return
	
	var shapecast: ShapeCast2D = Utils.get_physicsbody2d_shapecast(self, [Game.PHYSICS_LAYER.BACKGROUND_ENTRY_AREA_POINT])
	
	if not shapecast.is_colliding():
		background_transition_blocked()
		shapecast.queue_free()
		return
	
	var cell_pos: Vector2 = shapecast.collision_result[0]["metadata"]
	var tilemap: BackgroundTileMap = shapecast.get_collider(0)
	
	var use_shape: int = null
	
	for shape in tilemap.get_cell_compatible_shapes(cell_pos):
		if using_upgrade(SHAPE_UPGRADES[shape]):
			if shape == current_shape:
				use_shape = shape
				break
			elif use_shape == null:
				use_shape = shape
	
	# No useable shape is compatible with cell
	if use_shape == null:
		print(2)
		background_transition_blocked()
		return
	elif use_shape != current_shape:
		set_current_shape(use_shape)
	
	if not tilemap.is_cell_point(cell_pos):
		
		for edge in edge_collisionshapes.get_child_count():
			
			if (edge == 1 or edge == 3) and is_on_floor():
				continue
			
			shapecast.shape = edge_collisionshapes.get_child(edge).shape
			shapecast.force_shapecast_update()
			
			if not shapecast.is_colliding():
				background_transition_blocked()
				shapecast.queue_free()
				return
	
	shapecast.queue_free()
	tilemap.handle_player_transition(self, cell_pos)
