extends Resource
class_name SaveFile

signal ABOUT_TO_SAVE()

const PATH_SPLITTER: String = "/"
const DEBUG_SAVE_PATH: String = "res://debug_save.tres"

# Contains all save data
export var data: Dictionary = {}

func save(path: String = null) -> int:
	assert((path != null and path.begins_with("res://")) or resource_path != "")
	
	if path == null:
		return ResourceSaver.save(resource_path, self)
	else:
		return ResourceSaver.save(path, self)

func get_dict(path: String) -> Dictionary:
	return get_dict_split(path.split(PATH_SPLITTER))

func get_dict_split(path: Array) -> Dictionary:
	var current: Dictionary = data
	for item in path:
		if item in current:
			current = current[item]
		else:
			current[item] = {}
			current = current[item]
	return current

func set_dict(path: String, value):
	var current: Dictionary = data
	var split: PoolStringArray = path.split(PATH_SPLITTER)
	for i in split.size():
		var item = split[i]
		if i + 1 == split.size():
			current[split[i]] = value
		elif item in current:
			current = current[item]
		else:
			current[item] = {}
			current = current[item]
	
