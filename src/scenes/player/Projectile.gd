extends KinematicBody2D

onready var particles: CPUParticles2D = $CPUParticles2D
onready var sprite: Sprite = $Sprite

var direction: int = 1
var shape: int
var player: KinematicBody2DWithArea2D

func init(_direction: int, _shape: int, _colour: Color, _player: KinematicBody2DWithArea2D):
	direction = _direction
	shape = _shape
	player = _player

func _ready():
	match shape:
		Enums.SHAPE.CUBE:
			sprite.texture = preload("res://assets/sprites/cube.png")
		Enums.SHAPE.CIRCLE:
			sprite.texture = preload("res://assets/sprites/circle.png")
		Enums.SHAPE.TRIANGLE:
			sprite.texture = preload("res://assets/sprites/triangle.png")
	
	Game.set_node_layer(self, Game.LAYERS.PLAYER_WEAPON)
	Game.set_node_layer(particles, Game.LAYERS.PLAYER, 1)
	$FireSound.play()
	$CPUParticles2D.texture = sprite.texture

func _process(delta: float):
	sprite.rotation_degrees += 750.0 * delta
	var collision: KinematicCollision2D = move_and_collide(Vector2(500.0 * direction, 0) * delta)
	if collision:
		
		if Damageable.is_node_damageable(collision.collider):
			Damageable.damage(collision.collider, Enums.SHAPE_DAMAGE_TYPES[shape], player.player_data["BASIC_PROJECTILE_DAMAGE"], collision.position)
			queue_free()
			return
		
		if not $VisibilityNotifier2D.is_on_screen():
			queue_free()
			return
		
		$WallCollideSound.play()
		particles.direction.x = -direction
		particles.global_position = collision.position
		set_process(false)
		sprite.queue_free()
		$CollisionShape2D.queue_free()
		$SpriteTrailEmitter.queue_free()
		particles.emitting = true
		yield(Utils.yield_particle_completion(particles), "completed")
		queue_free()
