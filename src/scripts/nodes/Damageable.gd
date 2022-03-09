extends Object
class_name Damageable

const DAMAGEABLE_GROUP: String = "DAMAGEABLE"
const DAMAGED_AUTOCONNECT_METHOD: String = "on_damage"
const DEATH_AUTOCONNECT_METHOD: String = "on_death"

signal DAMAGED(type, amount, position)
signal DEATH(type)

var overridable_methods: Dictionary = {
	DAMAGED_AUTOCONNECT_METHOD: funcref(self, "on_damage"),
	DEATH_AUTOCONNECT_METHOD: funcref(self, "on_death"),
	"set_health": funcref(self, "_set_health"),
	"set_intangible": funcref(self, "_set_intangible")
}

var host: Node

var max_health: float = 0.0
var health: float = 0.0
var intangible: bool = false

func _init(_host: Node = null, autoconnect_signals: bool = true, enable_hyperlog: bool = false) -> void:
	host = _host
	
	if host == null:
		assert(self is Node)
		host = self
	else:
		# Connect signals
		if autoconnect_signals:
			if host.has_method(DAMAGED_AUTOCONNECT_METHOD):
				connect("DAMAGED", host, DAMAGED_AUTOCONNECT_METHOD)
			if host.has_method(DEATH_AUTOCONNECT_METHOD):
				connect("DEATH", host, DEATH_AUTOCONNECT_METHOD)
		
		# Override methods
		for method_name in overridable_methods:
			if host.has_method(method_name):
				overridable_methods[method_name] = funcref(host, method_name)
		
		for property in ["health", "intangible", "max_health"]:
			assert(not property in host)
	
	host.add_to_group(DAMAGEABLE_GROUP)
	
	if enable_hyperlog:
		HyperLog.log(host).text("health")
		Utils.Callback.new(funcref(HyperLog, "remove_log"), [host]).connect_signal(self, "DEATH").attach_to_node(host)

func on_damage(_type: int, amount: float, _position: Vector2):
	health = max(0.0, health - amount)

func on_death(_type: int):
	host.queue_free()

func _set_health(value: float):
	if health == value:
		return
	health = value

func _set_intangible(value: bool):
	if intangible == value:
		return
	intangible = value

# - Static functions -
static func is_node_damageable(node: Node) -> bool:
	return node.is_in_group(DAMAGEABLE_GROUP)

static func connect_node_damaged(node: Node, object: Object, method: String):
	assert(is_node_damageable(node))
	get_node_DMG(node).connect("DAMAGED", object, method)

static func connect_node_death(node: Node, object: Object, method: String):
	assert(is_node_damageable(node))
	get_node_DMG(node).connect("DEATH", object, method)

static func damage(node: Node, type: int, amount: float, position: Vector2):
	assert(is_node_damageable(node))
	if amount <= 0.0:
		return
	var DMG: Damageable = get_node_DMG(node)
	DMG.overridable_methods[DAMAGED_AUTOCONNECT_METHOD].call_func(type, amount, position)
	DMG.emit_signal("DAMAGED", type, amount, position)

static func death(node: Node, type: int):
	assert(is_node_damageable(node))
	var DMG: Damageable = get_node_DMG(node)
	DMG.overridable_methods[DEATH_AUTOCONNECT_METHOD].call_func(type)
	DMG.emit_signal("DEATH", type)

static func set_health(node: Node, value: float):
	assert(is_node_damageable(node))
	get_node_DMG(node).overridable_methods["set_health"].call_func(value)

static func set_intangible(node: Node, value: bool):
	assert(is_node_damageable(node))
	get_node_DMG(node).overridable_methods["set_intangible"].call_func(value)

static func get_node_DMG(node: Node) -> Damageable:
	assert(is_node_damageable(node))
	if "DMG" in node:
		return node.DMG
	else:
		return node.get_meta("DMG")
