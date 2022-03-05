extends Node

signal settings_changed(path, value)

const DAMAGEABLE_GROUP_NAME: String = "damageable"
const DEFAULT_CONFIG_PATH: String = "res://default_config.cfg"

var other_data: Dictionary = null
var _config: ConfigFile = null
var settings_file_path: String
var user_dir_path: String

func _init():
	other_data = Utils.load_json("res://data/other.json").result
	prepare_z_layers()
	
	var engine_config: Dictionary = Utils.load_json("res://config.json").result
	var user_dir_override = engine_config["user_dir_override"]
	user_dir_path = "user://" if user_dir_override == null else user_dir_override
	
	settings_file_path = get_from_user_dir("settings.cfg")

func _ready():
	load_settings()

func set_node_damageable(node: Node, damageable: bool = true):
	assert(node.has_method("damage"))
	
	if damageable:
		node.add_to_group(DAMAGEABLE_GROUP_NAME)
	elif not damageable:
		node.remove_from_group(DAMAGEABLE_GROUP_NAME)

func is_node_damageable(node: Node) -> bool:
	return node.is_in_group(DAMAGEABLE_GROUP_NAME)

# Z Layer system
enum LAYERS {BACKGROUND, ENEMY, ENEMY_WEAPON, PLAYER_WEAPON, PLAYER, WORLD}
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
