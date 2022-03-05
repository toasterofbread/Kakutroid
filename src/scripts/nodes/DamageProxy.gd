extends ExPhysicsBodyArea2D
class_name DamageProxy

signal DAMAGE(type, amount, position)

func _init():
	Game.set_node_damageable(self)

func damage(type: int, amount: float, position: Vector2 = null):
	emit_signal("DAMAGE", type, amount, position)
