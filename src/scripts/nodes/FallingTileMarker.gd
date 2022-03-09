tool
extends Node2D
class_name FallingTileMarker

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
export var id: int = 0

var tilemap: TileMap
var sprite: Sprite
var cell_pos: Vector2

func _ready():
	if not Engine.editor_hint:
		
		tilemap = get_node(tilemap_path)
		if tilemap.has_meta(MARKER_META_NAME):
			tilemap.get_meta(MARKER_META_NAME).append(self)
		else:
			tilemap.set_meta(MARKER_META_NAME, [self])
		
		cell_pos = get_cell_pos()
		sprite = Utils.get_tilemap_tile_sprite(tilemap, cell_pos, false)
		
		modulate = tilemap.modulate
		modulate.a = 0.5
		visible = false
		
	elif not has_node("Indicator"):
		var indicator: Position2D = Position2D.new()
		add_child(indicator)
		indicator.name = "Indicator"
		indicator.gizmo_extents = 8
		indicator.position += Vector2(8, 8)

func get_cell_pos() -> Vector2:
	return tilemap.world_to_map(tilemap.to_local(global_position)) + Vector2(0, 1)

func crumble(settings: Dictionary = DEFAULT_SETTINGS, despawn_queue: ExArray = null):
	var body: RigidBody2D = RigidBody2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	body.add_child(collision)
	body.add_child(sprite)
	body.scale = tilemap.scale
	body.position += sprite.get_rect().size / 2
	
	collision.shape = RectangleShape2D.new()
	collision.shape.extents = sprite.get_rect().size / 2
	
	Game.set_physics_layer(body, Game.PHYSICS_LAYER.BACKGROUND, true)
	Game.set_physics_masks(body, [Game.PHYSICS_LAYER.BACKGROUND, Game.PHYSICS_LAYER.WORLD], true)
	Game.set_node_layer(self, Game.LAYERS.BACKGROUND)
	
	visible = true
	call_deferred("add_child", body)
	yield(body, "tree_entered")
	
	tilemap.set_cellv(cell_pos, -1)
	tilemap.update_bitmask_area(cell_pos)
	
	if settings["despawn_time"] >= 0.0:
		if settings["settle_before_despawn"]:
			yield(body, "sleeping_state_changed")
			body.can_sleep = false
			body.sleeping = false
		
		var timer: SceneTreeTimer = get_tree().create_timer(settings["despawn_time"])
		if despawn_queue != null:
			timer.connect("timeout", despawn_queue, "append", [self])
		else:
			timer.connect("timeout", self, "_despawn")

func _despawn():
	var tween: Tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.connect("tween_all_completed", self, "queue_free")
	tween.start()

static func crumble_tilemap(tilemap: TileMap, id: int):
	
	var tilemap_markers: Array = get_tilemap_markers(tilemap, id)
	if tilemap_markers.empty():
		push_warning("No markers registered with id " + str(id))
		return
	
	var settings: Dictionary
	if tilemap.has_meta(SETTINGS_META_NAME) and id in tilemap.get_meta(SETTINGS_META_NAME):
		settings = tilemap.get_meta(SETTINGS_META_NAME)[id]
	else:
		settings = DEFAULT_SETTINGS
	
	var despawn_queue: ExArray = null
	if settings["despawn_time"] >= 0.0:
		despawn_queue = ExArray.new()
		_process_despawn_queue(despawn_queue, tilemap_markers.size())
	
	if settings["simultaneous"]:
		for marker in tilemap_markers:
			marker.crumble(settings, despawn_queue)
	else:
		var markers: Dictionary = {}
		var m: FallingTileMarker
		for marker in tilemap_markers:
			m = marker
			
			var x: int = marker.cell_pos.x
			var y: int = marker.cell_pos.y
			
			if x in markers:
				if y in markers[x]:
					markers[x][y].append(marker)
				else:
					markers[x][y] = [marker]
			else:
				markers[x] = {y: [marker]}
		
		var x_values: Array = markers.keys().duplicate()
		match settings["x_sort_mode"]:
			X_SORT_MODE.LEFT_TO_RIGHT:
				x_values.sort_custom(m, "_sort_markers_positive")
			X_SORT_MODE.RIGHT_TO_LEFT:
				x_values.sort_custom(m, "_sort_markers_negative")
		
		var tree: SceneTree = m.get_tree()
		for x in x_values:
			var y_values: Array = markers[x].keys().duplicate()
			match settings["y_sort_mode"]:
				Y_SORT_MODE.TOP_TO_BOTTOM:
					y_values.sort_custom(m, "_sort_markers_positive")
				Y_SORT_MODE.BOTTOM_TO_TOP:
					y_values.sort_custom(m, "_sort_markers_negative")
			
			for y in y_values:
				for marker in markers[x][y]:
					marker.crumble(settings, despawn_queue)
#					if settings["y_sort_mode"] != Y_SORT_MODE.SIMULTANEOUS:
					yield(tree.create_timer(Utils.RNG.randf_range(0.01, 0.05)), "timeout")

#			if settings["y_sort_mode"] == Y_SORT_MODE.SIMULTANEOUS:
#				yield(tree.create_timer(0.5), "timeout")

static func _process_despawn_queue(queue: ExArray, marker_amount: int):
	var despawned: int = 0
	while despawned < marker_amount:
		if queue.empty():
			yield(queue, "items_added")
		var marker: FallingTileMarker = queue.pop_back()
		marker._despawn()
		despawned += 1
		
		if despawned < marker_amount:
			yield(marker.get_tree().create_timer(0.1), "timeout")

static func _sort_markers_positive(a: int, b: int):
	if a < b:
		return true
	return false

static func _sort_markers_negative(a: int, b: int):
	if a > b:
		return true
	return false

static func get_tilemap_markers(tilemap: TileMap, id: int = null) -> Array:
	
	if not tilemap.has_meta(MARKER_META_NAME):
		return []
	elif id == null:
		return tilemap.get_meta(MARKER_META_NAME)
	
	var ret: Array = []
	for marker in tilemap.get_meta(MARKER_META_NAME):
		if marker.id == id:
			ret.append(marker)
	
	return ret
