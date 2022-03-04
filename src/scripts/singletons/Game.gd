extends Node

var other_data: Dictionary = null
const DAMAGEABLE_GROUP_NAME: String = "damageable"

func _init():
	other_data = Utils.load_json("res://data/other.json")

func set_node_damageable(node: Node, damageable: bool = true):
	assert(node.has_method("damage"))
	
	if damageable:
		node.add_to_group(DAMAGEABLE_GROUP_NAME)
	elif not damageable:
		node.remove_from_group(DAMAGEABLE_GROUP_NAME)

func is_node_damageable(node: Node) -> bool:
	return node.is_in_group(DAMAGEABLE_GROUP_NAME)
