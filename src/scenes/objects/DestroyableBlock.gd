extends Sprite

onready var destroyed_particles: CPUParticles2D = $DestroyedParticles

func _ready():
	_on_DestroyableBlock_texture_changed()

func destroy():
	self_modulate.a = 0.0
	$StaticBody2D.queue_free()
	$Area2D.queue_free()
	destroyed_particles.emitting = true
	yield(get_tree().create_timer(destroyed_particles.lifetime * destroyed_particles.speed_scale), "timeout")
	queue_free()

func _on_Area2D_body_entered(body: Node):
	destroy()

func _on_DestroyableBlock_texture_changed():
	destroyed_particles.texture = texture
