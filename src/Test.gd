extends RigidBody2D

export var tilemap_path: NodePath
var tilemap: TileMap

func _ready():
	Game.set_node_layer(self, Game.LAYER.BACKGROUND)
	
	if has_node(tilemap_path):
		tilemap = get_node(tilemap_path)
		remove_tilemap_tile()
	
	for node in get_children():
		if "position" in node:
			node.position -= Vector2(8, 8)
	position += Vector2(8, 8)
	
	
#	yield(get_tree(), "idle_frame")

func remove_tilemap_tile():
	var cell: Vector2 = tilemap.world_to_map(tilemap.to_local(global_position)) + Vector2(0, 1)
	tilemap.set_cellv(cell, -1)
	tilemap.update_bitmask_area(cell)
