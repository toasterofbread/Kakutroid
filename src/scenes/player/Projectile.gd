extends KinematicBody2D

onready var particles: CPUParticles2D = $CPUParticles2D
onready var sprite: Sprite = $Sprite

var direction: int = 1
var shape: int

func init(_direction: int, _shape: int, colour: Color):
	direction = _direction
	shape = _shape
#	modulate = colour

func _ready():
	match shape:
		Enums.SHAPE.CUBE:
			sprite.texture = preload("res://assets/sprites/cube.png")
		Enums.SHAPE.CIRCLE:
			sprite.texture = preload("res://assets/sprites/circle.png")
		Enums.SHAPE.TRIANGLE:
			sprite.texture = preload("res://assets/sprites/triangle.png")
	
	$FireSound.play()
	$CPUParticles2D.texture = sprite.texture

func _process(delta: float):
	sprite.rotation_degrees += 750.0 * delta
	var collision: KinematicCollision2D = move_and_collide(Vector2(500.0 * direction, 0) * delta)
	if collision:
		
		if Game.is_node_damageable(collision.collider):
			collision.collider.damage(Enums.SHAPE_DAMAGE_TYPES[shape], 10.0)
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
