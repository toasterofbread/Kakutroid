extends KinematicBody2D

var velocity: Vector2 = Vector2.ZERO
onready var data: Dictionary = Game.other_data["enemy_cube"]

var facing: int = 1
var health: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	health = data["HEALTH"]
	Game.set_node_layer(self, Game.LAYERS.ENEMY)
	Game.set_node_damageable(self)

func damage(type: int, amount: float, position: Vector2 = null):
	health -= amount
	if health <= 0.0:
		death(type)
	else:
		$AnimationPlayer.play("damage")

func death(type: int):
	set_physics_process(false)
	set_process(false)
	
	$CollisionShape2D.queue_free()
	$RayCastContainer.queue_free()
	$Tween.interpolate_property($Sprite, "modulate:a", $Sprite.modulate.a, 0.0, 0.15, Tween.TRANS_SINE)
	$Tween.start()
	$CPUParticles2D.emitting = true
	yield(Utils.yield_particle_completion($CPUParticles2D), "completed")
	queue_free()

func _process(delta: float):
	velocity.x = move_toward(velocity.x, data["MAX_SPEED"] * facing, data["ACCELERATION"] * delta)
	velocity.y = move_toward(velocity.y, data["MAX_FALL_SPEED"], data["GRAVITY"] * delta)

func _physics_process(delta: float):
	move_and_slide(velocity, Vector2.UP)
	if $RayCastContainer/Side.is_colliding() or not $RayCastContainer/Bottom.is_colliding():
		velocity.x *= -1
		facing *= -1
		$RayCastContainer.scale.x = facing

func _on_DamageArea_body_entered(body: Node):
	if health > 0.0 and body != self and Game.is_node_damageable(body):
		body.damage(Enums.DAMAGE_TYPE.CUBE, data["COLLISION_DAMAGE"], $DamageArea.global_position)
