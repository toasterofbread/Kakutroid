extends Node

export var tilemap_path: NodePath
export var id: int = 0
export(FallingTileMarker.X_SORT_MODE) var x_sort_mode: int
export(FallingTileMarker.Y_SORT_MODE) var y_sort_mode: int
export var despawn_time: float = 1.0
export var settle_before_despawn: bool = true
export var simultaneous: bool = false

func _ready():
	
	var tilemap: TileMap = get_node(tilemap_path)
	
	var settings: Dictionary 
	if tilemap.has_meta(FallingTileMarker.SETTINGS_META_NAME):
		settings = tilemap.get_meta(FallingTileMarker.SETTINGS_META_NAME)
	else:
		settings = {}
		tilemap.set_meta(FallingTileMarker.SETTINGS_META_NAME, settings)
	
	assert(not id in settings)
	
	settings[id] = {
		"x_sort_mode": x_sort_mode,
		"y_sort_mode": y_sort_mode,
		"despawn_time": despawn_time,
		"settle_before_despawn": settle_before_despawn,
		"simultaneous": simultaneous
	}
	
	set_script(Node)
