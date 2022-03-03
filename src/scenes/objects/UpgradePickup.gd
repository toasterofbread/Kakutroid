extends Area2D

export(Enums.UPGRADE) var type: int
onready var particles: CPUParticles2D = $Sprite/CPUParticles2D

func _on_UpgradePickup_body_entered(body: Node):
	body.collect_upgrade(type)
	$Sprite.self_modulate.a = 0.0
	$CollisionShape2D.queue_free()
	$SfxrStreamPlayer.play()
	particles.emitting = true
	
	while particles.emitting:
		yield(get_tree(), "idle_frame")
	yield(get_tree().create_timer(particles.lifetime / particles.speed_scale), "timeout")
	
	queue_free()
