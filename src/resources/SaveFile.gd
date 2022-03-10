extends Resource
class_name SaveFile

const PATH_SPLITTER: String = "/"

# Contains all save data
export var data: Dictionary = {}

func get_dict(path: String) -> Dictionary:
	var current: Dictionary = data
	for item in path.split(PATH_SPLITTER):
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
	
