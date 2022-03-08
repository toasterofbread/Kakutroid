extends PlayerModule
class_name PlayerModulePhysics

var velocity: Vector2 = Vector2.ZERO
var air_time: float = -1.0
var previous_velocity: Vector2 = Vector2.ZERO
var was_on_floor: bool = false

func _physics_process(delta: float):
	
	if player.is_on_wall():
		vel_move_y(player_data["MAX_FALL_SPEED_WALL"], player_data["GRAVITY_WALL"] * delta)
	elif velocity.y < player_data["MAX_FALL_SPEED"]:
		vel_move_y(player_data["MAX_FALL_SPEED"], player_data["GRAVITY"] * delta)
	
	velocity = player.move_and_slide(velocity * player.global_scale, Vector2.UP) / player.global_scale
	
	# Emit landing particles
	if player.get_slide_count() > 0 and player.is_on_floor() and not was_on_floor and previous_velocity.y >= 200.0:
		
		# Find collided object
		for collision_idx in player.get_slide_count():
			var collision: KinematicCollision2D = player.get_slide_collision(collision_idx)
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
			player.emit_landing_particles(collider.particle_texture).color = collider.particle_colour
			break
	
	if player.is_on_floor():
		air_time = -1.0
	elif was_on_floor:
		air_time = 0.0
	else:
		air_time += delta
	
	was_on_floor = player.is_on_floor()
	
	if not player.ghost:
		Overlay.SET("On floor", player.is_on_floor())
		Overlay.SET("On wall", player.is_on_wall())
		Overlay.SET("Air time", air_time)

func can_fall() -> bool:
	return !player.is_on_floor() and air_time > player_data["COYOTE_TIME"]

func vel_move_y(to: float, by: float = INF):
	velocity.y = move_toward(velocity.y, to, by)

func vel_move_x(to: float, by: float = INF):
	velocity.x = move_toward(velocity.x, to, by)

func vel_move(to: Vector2, delta: float = INF):
	velocity = velocity.move_toward(to, delta)
