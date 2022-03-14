tool
extends TileMap
class_name TileMapCrumbleMarker

const MARKER_META_NAME: String = "FALLING_TILE_MARKERS"
const SETTINGS_META_NAME: String = "FALLING_TILE_SETTINGS"
enum X_SORT_MODE {LEFT_TO_RIGHT, RIGHT_TO_LEFT}
enum Y_SORT_MODE {TOP_TO_BOTTOM, BOTTOM_TO_TOP}
const DEFAULT_SETTINGS: Dictionary = {
	"x_sort_mode": X_SORT_MODE.LEFT_TO_RIGHT,
	"y_sort_mode": Y_SORT_MODE.BOTTOM_TO_TOP,
	"despawn_time": 1.0,
	"settle_before_despawn": true,
	"simultaneous": false
}

export var tilemap_path: NodePath
export var key: String = "" setget set_key
export var replace_with_tile: int = -1
export(X_SORT_MODE) var x_sort_mode: int
export(Y_SORT_MODE) var y_sort_mode: int
export var despawn_time: float = 1.0
export var settle_before_despawn: bool = true
export var simultaneous: bool = false

var tilemap: TileMap

func _ready():
	if not Engine.editor_hint:
		
		tilemap = get_node(tilemap_path)
		if tilemap.has_meta(MARKER_META_NAME):
			tilemap.get_meta(MARKER_META_NAME)[key] = self
		else:
			tilemap.set_meta(MARKER_META_NAME, {key: self})
		
		modulate = tilemap.modulate
		modulate.a = 0.5
		visible = false
	
	material = preload("res://assets/resources/materials/visibility_shader.tres")
	material.set_shader_param("visible", Engine.editor_hint)
	tile_set = preload("res://assets/resources/tile_sets/MarkerTileset.tres")
	cell_size = Vector2(16, 16)

func crumble(cell_pos: Vector2, despawn_queue: ExArray = null):
	var body: RigidBody2D = RigidBody2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	body.add_child(collision)
	
	var global_pos: Vector2 = to_global(map_to_world(cell_pos + Vector2(0, 0)))
	var tilemap_pos: Vector2 = tilemap.world_to_map(tilemap.to_local(global_pos))
	
	var sprite: Sprite = Utils.get_tilemap_tile_sprite(tilemap, tilemap_pos, false)
	body.add_child(sprite)
	body.scale = tilemap.scale
	body.global_position = global_pos + (sprite.get_rect().size / 2.0)# - Vector2(16, 16)
	
	collision.shape = RectangleShape2D.new()
	collision.shape.extents = sprite.get_rect().size / 2
	
	Game.set_physics_layer(body, Game.PHYSICS_LAYER.BACKGROUND, true)
	Game.set_physics_masks(body, [Game.PHYSICS_LAYER.BACKGROUND, Game.PHYSICS_LAYER.WORLD], true)
	Game.set_node_layer(self, Game.LAYER.BACKGROUND)
	
	visible = true
	call_deferred("add_child", body)
	yield(body, "tree_entered")
	
	tilemap.SetCellvManual(tilemap_pos, replace_with_tile)
	tilemap.update_bitmask_area(tilemap_pos)
	
	if despawn_time >= 0.0:
		if settle_before_despawn:
			yield(body, "sleeping_state_changed")
			body.can_sleep = false
			body.sleeping = false
		
		var timer: SceneTreeTimer = get_tree().create_timer(despawn_time)
		if despawn_queue != null:
			timer.connect("timeout", despawn_queue, "append", [body])
		else:
			timer.connect("timeout", self, "despawn_cell", [body])

static func crumble_tilemap(tilemap: TileMap, key: String):
	
	var marker: TileMapCrumbleMarker = get_tile_marker(tilemap, key)
	if marker == null:
		push_warning("No marker registered with key " + key)
		return
	
	var marked_cells: Array = marker.get_marked_cells()
	var despawn_queue: ExArray = null
	if marker.despawn_time >= 0.0:
		despawn_queue = ExArray.new()
		marker._process_despawn_queue(despawn_queue, marked_cells.size())
	
	if marker.simultaneous:
		for cell in marked_cells:
			marker.crumble(cell, despawn_queue)
	else:
		var cells: Dictionary = {}
		for cell in marked_cells:
			
			var x: int = cell.x
			var y: int = cell.y
			
			if x in cells:
				cells[x].append(y)
			else:
				cells[x] = [y]
		
		var x_values: Array = cells.keys().duplicate()
		match marker.x_sort_mode:
			X_SORT_MODE.LEFT_TO_RIGHT:
				x_values.sort_custom(marker, "_sort_markers_positive")
			X_SORT_MODE.RIGHT_TO_LEFT:
				x_values.sort_custom(marker, "_sort_markers_negative")
		
		var tree: SceneTree = marker.get_tree()
		for x in x_values:
			var y_values: Array = cells[x].duplicate()
			match marker.y_sort_mode:
				Y_SORT_MODE.TOP_TO_BOTTOM:
					y_values.sort_custom(marker, "_sort_markers_positive")
				Y_SORT_MODE.BOTTOM_TO_TOP:
					y_values.sort_custom(marker, "_sort_markers_negative")
			
			for y in y_values:
				marker.crumble(Vector2(x, y), despawn_queue)
#				if settings["y_sort_mode"] != Y_SORT_MODE.SIMULTANEOUS:
				yield(tree.create_timer(Utils.RNG.randf_range(0.01, 0.05)), "timeout")

#			if settings["y_sort_mode"] == Y_SORT_MODE.SIMULTANEOUS:
#				yield(tree.create_timer(0.5), "timeout")

func despawn_cell(cell: RigidBody2D):
	var tween: Tween = Tween.new()
	cell.add_child(tween)
	tween.interpolate_property(cell, "modulate:a", modulate.a, 0.0, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.connect("tween_all_completed", cell, "queue_free")
	tween.start()

func _process_despawn_queue(queue: ExArray, marker_amount: int):
	var despawned: int = 0
	while despawned < marker_amount:
		if queue.empty():
			yield(queue, "items_added")
		var cell: RigidBody2D = queue.pop_front()
		despawn_cell(cell)
		despawned += 1
		
		if despawned < marker_amount:
			yield(get_tree().create_timer(1.0 / max(queue.size(), 10)), "timeout")
		elif get_used_cells().empty():
			get_tree().create_timer(0.5).connect("timeout", self, "queue_free")

static func _sort_markers_positive(a: int, b: int):
	if a < b:
		return true
	return false

static func _sort_markers_negative(a: int, b: int):
	if a > b:
		return true
	return false

static func get_tile_marker(tilemap: TileMap, key: String) -> TileMapCrumbleMarker:
	
	if not tilemap.has_meta(MARKER_META_NAME):
		return null
	
	var sets: Dictionary = tilemap.get_meta(MARKER_META_NAME)
	if not key in sets:
		return null
	
	return sets[key]

func get_marked_cells() -> Array:
	var ret: Array = []
	for cell_pos in get_used_cells():
		ret.append(cell_pos)
	return ret

func set_key(value: String):
	key = value
	
	# Create modulate colour from key hash
	if Engine.editor_hint:
		modulate = Color(key.hash())
