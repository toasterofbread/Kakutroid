extends ExPhysicsBodyArea2D
class_name DamageableExPhysicsBodyArea2D

const DAMAGEABLE_GROUP: String = "DAMAGEABLE"

signal DAMAGED(type, amount, position)
signal DEATH(type)

export var enable_hyperlog: bool = false
var max_health: float = 0.0
var health: float = 0.0 setget set_health
var intangible: bool = false setget set_intangible

func _ready():
	yield(self, "ready")
	if enable_hyperlog:
		HyperLog.log(self).text("health")
		Utils.Callback.new(funcref(HyperLog, "remove_log"), [self]).connect_signal(self, "DEATH", true)
	
	add_to_group(DAMAGEABLE_GROUP)

# Should not be overridden by subclasses, override on_damage() instead
func damage(type: int, amount: float, position: Vector2):
	if amount <= 0.0:
		return
	on_damage(type, amount, position)
	emit_signal("DAMAGED", type, amount, position)

func on_damage(_type: int, amount: float, _position: Vector2):
	health = max(0.0, health - amount)

# Should not be overridden by subclasses, override on_death() instead
func death(type: int):
	on_death(type)
	emit_signal("DEATH", type)

func on_death(_type: int):
	queue_free()

func set_intangible(value: bool):
	if intangible == value:
		return
	intangible = value

func set_health(value: float):
	if health == value:
		return
	health = value

static func is_node_damageable(node: Node):
	return node.is_in_group(DAMAGEABLE_GROUP)
