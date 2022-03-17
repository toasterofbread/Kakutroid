extends TileMap
class_name BackgroundTileMap

export var guide_tilemap_path: NodePath
export var guide_tile: int
export var overlay_tile: int

const OVERLAY_TILE: int = 0
const ENTRY_AREA_TILES: Dictionary = {
	1: Enums.SHAPE.CUBE
}
const ENTRY_POINT_TILES: Dictionary = {
	2: Enums.SHAPE.CUBE
}

func _ready() -> void:
	
	assert(has_node(guide_tilemap_path) and get_node(guide_tilemap_path) is TileMap)
	
	var guide_tilemap: TileMap = get_node(guide_tilemap_path)
	for cell_pos in guide_tilemap.get_used_cells():
		if guide_tilemap.get_cellv(cell_pos) != guide_tile:
			continue
		
		cell_pos = world_to_map(to_local(guide_tilemap.to_global(guide_tilemap.map_to_world(cell_pos))))
		if get_cellv(cell_pos) == INVALID_CELL:
			set_cellv(cell_pos, overlay_tile)
	
	for tile in ENTRY_AREA_TILES:
		assert(not tile in ENTRY_POINT_TILES)
		tile_set.tile_set_modulate(tile, Color.transparent)
	for tile in ENTRY_POINT_TILES:
		assert(not tile in ENTRY_AREA_TILES)
		tile_set.tile_set_modulate(tile, Color.transparent)
	
	Game.set_physics_layer(self, Game.PHYSICS_LAYER.BACKGROUND_ENTRY_AREA_POINT, true)
	
	z_index = 0
	z_as_relative = false
	
	for tile in tile_set.get_tiles_ids():
		tile_set.tile_set_z_index(tile, Game.get_layer_z_index(Game.LAYER.BACKGROUND_OVERLAY))

func is_cell_point(cell_pos: Vector2) -> bool:
	assert(get_cellv(cell_pos) != INVALID_CELL)
	return get_cellv(cell_pos) in ENTRY_POINT_TILES

func handle_player_transition(player: Player, cell_pos: Vector2):
	
	player.play_sound("background_transition")
	if is_cell_point(cell_pos):
		
		var tween: Tween = Tween.new()
		add_child(tween)
		
		tween.interpolate_property(player, "global_position", player.global_position, to_global(map_to_world(cell_pos)) + (Vector2(Player.CUBE_SIZE, Player.CUBE_SIZE) / 2.0), 0.15, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
		tween.start()
		
		yield(tween, "tween_all_completed")
		tween.queue_free()
		player.module_physics.velocity = Vector2.ZERO
	
	player.set_background(!player.background)

func get_cell_compatible_shapes(cell_pos: Vector2) -> PoolIntArray:
	assert(get_cellv(cell_pos) != INVALID_CELL)
	
	var cell_shape: int = ENTRY_POINT_TILES[get_cellv(cell_pos)] if is_cell_point(cell_pos) else ENTRY_AREA_TILES[get_cellv(cell_pos)]
	match cell_shape:
		Enums.SHAPE.CUBE:
			return PoolIntArray([Enums.SHAPE.CUBE, Enums.SHAPE.TRIANGLE, Enums.SHAPE.CIRCLE])
		_:
			return PoolIntArray([cell_shape])
