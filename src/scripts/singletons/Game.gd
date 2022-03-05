extends Node

var other_data: Dictionary = null
const DAMAGEABLE_GROUP_NAME: String = "damageable"

func _init():
	other_data = Utils.load_json("res://data/other.json").result
	prepare_z_layers()

func set_node_damageable(node: Node, damageable: bool = true):
	assert(node.has_method("damage"))
	
	if damageable:
		node.add_to_group(DAMAGEABLE_GROUP_NAME)
	elif not damageable:
		node.remove_from_group(DAMAGEABLE_GROUP_NAME)

func is_node_damageable(node: Node) -> bool:
	return node.is_in_group(DAMAGEABLE_GROUP_NAME)

# Z Layer system
enum LAYERS {BACKGROUND, ENEMY, ENEMY_WEAPON, PLAYER, PLAYER_WEAPON, WORLD}
var layer_z_indices: Dictionary = null
var max_layer_offset: int

func prepare_z_layers():
	layer_z_indices = {}
	
	var indices_per_layer: int = int(abs(VisualServer.CANVAS_ITEM_Z_MIN - VisualServer.CANVAS_ITEM_Z_MAX) / len(LAYERS))
	if indices_per_layer % 2 == 0:
		indices_per_layer -= 1
	max_layer_offset = (indices_per_layer - 1) / 2
	
	var previous: int = VisualServer.CANVAS_ITEM_Z_MIN - (indices_per_layer / 2)
	for layer in LAYERS.values():
		layer_z_indices[layer] = previous + (indices_per_layer)
		previous = layer_z_indices[layer]

func set_node_layer(node: Node2D, z_layer: int, offset: int = 0):
	assert(layer_z_indices != null)
	
	if abs(offset) > max_layer_offset:
		push_error("Node " + str(node) + " z_layer offset (" + str(offset) + ") exceeds maximum of " + str(max_layer_offset) + ".")
	
	node.z_as_relative = false
	node.z_index = layer_z_indices[z_layer] + offset

func get_layer_z_index(layer: int) -> int:
	return layer_z_indices[layer]

