extends Area2D

export(Enums.UPGRADE) var type: int
onready var particles: CPUParticles2D = $Sprite/CPUParticles2D

func _on_UpgradePickup_body_entered(body: Node):
	body.collect_upgrade(type)
	$Sprite.self_modulate.a = 0.0
	$CollisionShape2D.queue_free()
	$SfxrStreamPlayer.play()
	particles.emitting = true
	yield(Utils.yield_particle_completion(particles), "completed")
	
	queue_free()
