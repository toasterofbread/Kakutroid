extends KinematicBody2D

export var background: bool = false

onready var DMG: Damageable = Damageable.new(self, true)

var velocity: Vector2 = Vector2.ZERO
onready var data: Dictionary = Game.other_data["enemy_cube"]
onready var raycast_side: RayCast2D = $RayCastContainer/Side
onready var raycast_bottom: RayCast2D = $RayCastContainer/Bottom
onready var raycast_container: Node2D = $RayCastContainer
var raycast_bottom_float_frames: int = 0

var facing: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	DMG.health = data["HEALTH"]
	Game.set_node_layer(self, Game.LAYER.ENEMY)
	
	Game.set_all_physics_layers(self, false)
	Game.set_all_physics_masks(self, false)
	
	Game.set_physics_layer(self, Game.PHYSICS_LAYER.ENEMY, true)
	Game.set_physics_mask(self, Game.PHYSICS_LAYER.WORLD_BACKGROUND if background else Game.PHYSICS_LAYER.WORLD, true)
	Game.set_physics_mask(self, Game.PHYSICS_LAYER.PLAYER_WEAPON_BACKGROUND if background else Game.PHYSICS_LAYER.PLAYER_WEAPON, true)
	Game.set_physics_mask(self, Game.PHYSICS_LAYER.PLAYER if background else Game.PHYSICS_LAYER.PLAYER_BACKGROUND, true)

func on_damage(type: int, amount: float, _position: Vector2 = null) -> bool:
	DMG.health -= amount
	if DMG.health <= 0.0:
		Damageable.death(self, type)
	else:
		$HurtSound.play()
		$AnimationPlayer.play("damage")
	return true

func on_death(_type: int):
	set_physics_process(false)
	set_process(false)
	
	var pulse: Object = Game.current_room.pulse_bg(global_position, Color.red, true, 10)
	pulse.Speed = 1.5
	pulse.MaxDistance = 150.0
	
	$CollisionShape2D.queue_free()
	$RayCastContainer.queue_free()
	$Sprite.queue_free()
	$DeathSound.play()
	
	$CPUParticles2D.emitting = true
	yield(Utils.yield_particle_completion($CPUParticles2D), "completed")
	
	queue_free()

func _process(delta: float):
	velocity.x = move_toward(velocity.x, data["MAX_SPEED"] * facing, data["ACCELERATION"] * delta)
	velocity.y = move_toward(velocity.y, data["MAX_FALL_SPEED"], data["GRAVITY"] * delta)

func _physics_process(_delta: float):
	move_and_slide(velocity, Vector2.UP)
	if raycast_side.is_colliding() or raycast_bottom_float_frames >= 5:
		raycast_bottom_float_frames = 0
		velocity.x *= -1
		facing *= -1
		raycast_container.scale.x = facing
	
	if not raycast_bottom.is_colliding():
		raycast_bottom_float_frames += 1
	else:
		raycast_bottom_float_frames = 0

func _on_DamageArea_body_entered(body: Node):
	if DMG.health > 0.0 and body != self and Damageable.is_node_damageable(body):
		Damageable.damage(body, Enums.DAMAGE_TYPE.CUBE, data["COLLISION_DAMAGE"], $DamageArea.global_position)
