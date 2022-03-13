extends Node2D
class_name GameRoom

export var player_path: NodePath = null

var id: String = null setget , get_id
var doors: Dictionary = {}
onready var tilemap: TileMap = $TileMap # TEMP

func _ready() -> void:
	# DEBUG | Handles launching current scene with F6
	if Game.current_room == null:
		Game.load_savefile(SaveFile.DEBUG_SAVE_PATH)
		Game.load_room(get_id())
		queue_free()
		return
	
	# Get all doors within room
	for door in get_tree().get_nodes_in_group(Door.DOOR_GROUP):
		if is_a_parent_of(door):
			assert(not door.name in doors)
			doors[door.name] = door

func init():
	tilemap.Init()

func has_door(door_name: String) -> bool:
	return door_name in doors

func get_door(door_name: String) -> Door:
	return doors[door_name]

func pulse_bg(origin: Vector2, colour: Color, force: bool = false, priority: int = 0, speed: float = 1.0, max_distance: float = -1.0, width: float = 50.0):
	tilemap.PulseBG(origin, colour, force, priority, speed, max_distance, width)

func get_id():
	if id == null:
		var split: Array = filename.split("/")
		id = split[len(split) - 3] + "/" + split[len(split) - 2]
	return id
