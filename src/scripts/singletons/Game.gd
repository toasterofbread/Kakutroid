extends Node

signal settings_changed(path, value)
signal APPLICATION_QUIT()

const DEFAULT_CONFIG_PATH: String = "res://default_config.cfg"

var save_file: SaveFile = null
var other_data: Dictionary = null
var _config: ConfigFile = null
var settings_file_path: String
var user_dir_path: String
var player: Player = null

var quitting: bool = false

func _init():
	pause_mode = Node.PAUSE_MODE_PROCESS
	other_data = Utils.load_json("res://data/other.json").result
	prepare_z_layers()
	
	var engine_config: Dictionary = Utils.load_json("res://config.json").result
	var user_dir_override = engine_config["user_dir_override"]
	user_dir_path = "user://" if user_dir_override == null else user_dir_override
	
	settings_file_path = get_from_user_dir("settings.cfg")
	
	# DEBUG
	if File.new().file_exists("res://debug_save.tres"):
		save_file = load("res://debug_save.tres")
	else:
		save_file = SaveFile.new()
		ResourceSaver.save("res://debug_save.tres", save_file)

func _enter_tree():
	get_tree().connect("node_added", self, "_on_tree_node_added")

func _exit_tree():
	quitting = true

func _ready():
	load_settings()

func quit():
	quitting = true
	for connection in get_signal_connection_list("APPLICATION_QUIT"):
		var function = connection["target"].callv(connection["method"], connection["binds"])
		while function is GDScriptFunctionState and function.is_valid():
			function = yield(function, "completed")
	ResourceSaver.save("res://debug_save.tres", save_file)
	get_tree().quit()

#func set_node_damageable(node: Node, damageable: bool = true):
#
#	if damageable:
#		assert("health" in node and node.health is float)
#
#		node.add_to_group(DAMAGEABLE_GROUP_NAME)
#		HyperLog.log(node).text("health")
#
#	elif not damageable:
#		node.remove_from_group(DAMAGEABLE_GROUP_NAME)

#func is_node_damageable(node: Node) -> bool:
#	return node.is_in_group(DAMAGEABLE_GROUP_NAME)

# Z Layer system
enum LAYERS {BACKGROUND, UPGRADE_PICKUP, ENEMY, ENEMY_WEAPON, PLAYER_WEAPON, PLAYER, WORLD, BLOCK}
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

func save_settings() -> int:
	return _config.save(settings_file_path)

func load_settings() -> int:
	
	if _config == null:
		_config = ConfigFile.new()
	
	var error: int = _config.load(settings_file_path)
	
	if error == ERR_FILE_NOT_FOUND:
		
		# Generate settings file with default data if it doesn't exist
		var default_config: File = File.new()
		error = default_config.open(DEFAULT_CONFIG_PATH, File.READ)
		if error != OK:
			push_error("Could not load default config file. Error code: " + str(error))
			get_tree().quit(1)
			return error
		
		error = _config.parse(default_config.get_as_text())
		if error != OK:
			push_error("Could not parse default config file data. Error code: " + str(error))
			get_tree().quit(1)
			return error
	
	if error != OK:
		# TODO | Fatal error screen
		push_error("Could not load config file at path '" + settings_file_path + "'. Error code: " + str(error) + ".")
		get_tree().quit(1)
	
	return error

func get_setting(path: String):
	return get_setting_split(path.split("/")[0], path.split("/")[1])

func set_setting(path: String, value):
	set_setting_split(path.split("/")[0], path.split("/")[1], value)

func get_setting_split(category: String, option: String):
	return _config.get_value(category, option)

func set_setting_split(category: String, option: String, value):
	emit_signal("settings_changed", category + "/" + option, value)
	_config.set_value(category, option, value)

func get_from_user_dir(path: String):
	path = path.trim_prefix("/")
	return user_dir_path + path

# - Physics layer system -
enum PHYSICS_LAYER {
	WORLD, 
	PLAYER, 
	PLAYER_WEAPON, 
	ENEMY, 
	ENEMY_WEAPON, 
	BACKGROUND, 
	_7,
	_8,
	_9,
	_10,
	_11,
	_12,
	_13,
	_14,
	_15,
	_16,
	_17,
	_18,
	_19
	WORLD_FASTFALL
}
const DISBALED_WORLD_LAYERS_META_NAME: String = "DISABLED_WORLD_LAYERS"
const DISBALED_WORLD_MASKS_META_NAME: String = "DISABLED_WORLD_MASKS"
const WORLD_PHYSICS_LAYERS: Array = [PHYSICS_LAYER.WORLD_FASTFALL]

func set_world_layer_disabled(node: Node, world_layer: int, value: bool):
	assert(world_layer in WORLD_PHYSICS_LAYERS)
	
	if node.has_meta(DISBALED_WORLD_LAYERS_META_NAME):
		var disabled: Array = node.get_meta(DISBALED_WORLD_LAYERS_META_NAME)
		if not value:
			disabled.erase(world_layer)
		elif not world_layer in disabled:
			disabled.append(world_layer)
	elif value:
		node.set_meta(DISBALED_WORLD_LAYERS_META_NAME, [world_layer])

func set_world_mask_disabled(node: Node, world_mask: int, value: bool):
	assert(world_mask in WORLD_PHYSICS_LAYERS)
	
	if node.has_meta(DISBALED_WORLD_MASKS_META_NAME):
		var disabled: Array = node.get_meta(DISBALED_WORLD_MASKS_META_NAME)
		if not value:
			disabled.erase(world_mask)
		elif not world_mask in disabled:
			disabled.append(world_mask)
	elif value:
		node.set_meta(DISBALED_WORLD_MASKS_META_NAME, [world_mask])

func get_disabled_world_layers(node: Node) -> Array:
	if not node.has_meta(DISBALED_WORLD_LAYERS_META_NAME):
		return Array()
	return node.get_meta(DISBALED_WORLD_LAYERS_META_NAME)

func get_disabled_world_masks(node: Node) -> Array:
	if not node.has_meta(DISBALED_WORLD_MASKS_META_NAME):
		return Array()
	return node.get_meta(DISBALED_WORLD_MASKS_META_NAME)

func set_physics_layer(node: Node, layer: int, value: bool):
	assert(is_node_physics_object(node))
	assert(not layer in WORLD_PHYSICS_LAYERS)
	
	if layer == PHYSICS_LAYER.WORLD:
		var disabled_world_layers: Array = get_disabled_world_layers(node)
		for world_layer in WORLD_PHYSICS_LAYERS:
			if world_layer in disabled_world_layers:
				continue
			node.set_collision_layer_bit(world_layer, value)
	
	node.set_collision_layer_bit(layer, value)

func set_physics_mask(node: Node, mask: int, value: bool):
	assert(is_node_physics_object(node))
	assert(not mask in WORLD_PHYSICS_LAYERS)
	
	if mask == PHYSICS_LAYER.WORLD:
		for world_layer in WORLD_PHYSICS_LAYERS:
			if world_layer in get_disabled_world_masks(node):
				continue
			node.set_collision_mask_bit(world_layer, value)
	
	node.set_collision_mask_bit(mask, value)

func set_physics_layers(node: Node, layers: Array, value: bool):
	for layer in layers:
		set_physics_layer(node, layer, value)

func set_physics_masks(node: Node, masks: Array, value: bool):
	for mask in masks:
		set_physics_mask(node, mask, value)

func is_node_physics_object(node: Node):
	return node is Area2D or node is PhysicsBody2D or node is TileMap

func _on_tree_node_added(node: Node):
	if is_node_physics_object(node):
		if node.get_collision_layer_bit(PHYSICS_LAYER.WORLD):
			for world_layer in WORLD_PHYSICS_LAYERS:
				assert(not node.get_collision_layer_bit(world_layer))
				assert(not node.get_collision_mask_bit(world_layer))
				node.set_collision_layer_bit(world_layer, true)
				node.set_collision_mask_bit(world_layer, true)
