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
		Enums.SHAPE.SQUARE:
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
		$WallCollideSound.play()
		set_process(false)
		particles.direction.x = -direction
		particles.global_position = collision.position
		particles.emitting = true
		sprite.queue_free()
		$CollisionShape2D.queue_free()
		$SpriteTrailEmitter.queue_free()
		while particles.emitting:
			yield(get_tree(), "idle_frame")
		yield(get_tree().create_timer(particles.lifetime * particles.speed_scale), "timeout")
		queue_free()
	
