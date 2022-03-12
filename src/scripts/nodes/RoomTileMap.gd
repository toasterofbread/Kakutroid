extends RoomCollisionObject

const BG_TILES: Array = [1, 2]
enum BG_COLOUR {
	NORMAL
}
const BG_DEFAULT: int = 1

var s: TileMap = self
var tileset: TileSet = s.tile_set
var pulses: Array = []

func _ready() -> void:
	z_index = 0
	z_as_relative = false
	
	tileset.tile_set_modulate(0, modulate)
	modulate = Color.white
	for tile in tileset.get_tiles_ids():
		tileset.tile_set_z_index(tile, Game.get_layer_z_index(Game.LAYERS.BACKGROUND if tile in BG_TILES else Game.LAYERS.WORLD))
	
	set_process(false)

var b: int = 0
func _process(delta: float) -> void:
	for cell in s.get_used_cells():
		var current_cell: int = s.get_cellv(cell)
		if not s.get_cellv(cell) in BG_TILES:
			continue
		
		var cell_pos: Vector2 = s.to_global(s.map_to_world(cell))
		var set: int = BG_DEFAULT
#		var cubes: bool = false
		
		for pulse in pulses:
			var distance: int = round(pulse["origin"].distance_to(cell_pos))
			if distance <= pulse["max_distance"] and abs(int(distance) - pulse["current_distance"]) <= pulse["width"]:
				set = 2
#			if pulse["cubes"]:
#				cubes = true
		
		if set != current_cell:
			s.set_cellv(cell, set)
			s.update_bitmask_area(cell)
	
	var i: int = 0
	while i < pulses.size():
		var pulse: Dictionary = pulses[i]
		pulse["current_distance"] += pulse["speed"]
		if pulse["current_distance"] > pulse["max_distance"] + pulse["width"]:
			pulses.remove(i)
			if pulses.empty():
				set_process(false)
		else:
			i += 1
	
#	for cell in s.get_used_cells():
#		if not s.get_cellv(cell) in BG_TILES:
#			continue
#		if max_distance <= 0:
#			max_distance = max(max_distance, origin.distance_to(s.to_global(s.map_to_world(cell))))
	
	
#	var current_distance: int = 0
#	var done: Array = []
#	while current_distance <= max_distance + width:
#
#		for cell in s.get_used_cells():
#			var current_cell: int = s.get_cellv(cell)
#			if not s.get_cellv(cell) in BG_TILES:
#				continue
#
#			var distance: int = round(origin.distance_to(s.to_global(s.map_to_world(cell))))
#
#			var set: int = -1
#			if distance <= max_distance and abs(int(distance) - current_distance) <= width:
#				set = 2
#			else:
#				set = 1
#
#			if set != current_cell:
#				s.set_cellv(cell, set)
#
#				if not cubes or set == 1:
#					s.update_bitmask_area(cell)
#
##				minimum.x = min(minimum.x, cell.x)
##				minimum.y = min(minimum.y, cell.y)
##
##				maximum.x = max(maximum.x, cell.x)
##				maximum.y = max(maximum.y, cell.y)
#
##		s.update_bitmask_region(minimum, maximum)
#		yield(get_tree(), "idle_frame")
#
#		current_distance += speed * 10
#
#	for cell in s.get_used_cells():
#		if not s.get_cellv(cell) in BG_TILES:
#			continue
#		s.set_cellv(cell, 1)
#
#	s.update_bitmask_region(minimum, maximum)

func pulse_bg(origin: Vector2, speed: int = 1, max_distance: int = -1, width: int = 50, cubes: bool = false):
	
	if max_distance <= 0:
		for cell in s.get_used_cells():
			if not s.get_cellv(cell) in BG_TILES:
				continue
			max_distance = max(max_distance, origin.distance_to(s.to_global(s.map_to_world(cell))))
	
	pulses.append({
		"origin": origin,
		"speed": speed * 10,
		"max_distance": max_distance,
		"width": width,
		"cubes": cubes,
		"current_distance": 0
	})
	
	set_process(true)
