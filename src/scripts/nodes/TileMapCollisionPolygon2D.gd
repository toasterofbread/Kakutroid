tool
extends CollisionPolygon2D
class_name TileMapCollisionPolygon2D

export var tilemap_path: NodePath
export var tiles_to_use: PoolIntArray = null
export var set_polygon_now: bool = false setget set_polygon_now

export var draw_data: Dictionary = null
export var draw: bool = false setget draw

func draw(value: bool = false):
	if value:
		update()

const NEIGHBOUR_CELLS: Array = [
	Vector2(-1, 0), # Left
	Vector2(0, -1), # Top
	Vector2(1, 0), # Right
	Vector2(0, 1) # Bottom
]

func set_polygon_now(value: bool):
	if not value:
		return
	
	if not has_node(tilemap_path):
		print("Tilemap path must be set")
		return
	
#	polygon = generate_polygon(get_node(tilemap_path), tiles_to_use)
	generate_polygon(get_node(tilemap_path), tiles_to_use)

static func _using_tile(tile: int, tiles_to_use: PoolIntArray) -> bool:
	return tiles_to_use == null or tile in tiles_to_use

func generate_polygon(tilemap: TileMap, tiles_to_use: PoolIntArray = null) -> PoolVector2Array:
	
	var used_cells: PoolVector2Array = tilemap.get_used_cells()
	var used_rect: Rect2 = tilemap.get_used_rect()
	var cell_size: Vector2 = tilemap.get_cell_size()
	
	var edges: Dictionary = {}
	var next_edges: Dictionary = {}
	
	for cell_pos in used_cells:
		
		var p0: Vector2 = tilemap.map_to_world(cell_pos + Vector2(0, 1)) # Bottom left
		var p1: Vector2 = tilemap.map_to_world(cell_pos + Vector2(0, 0)) # Top left
		var p2: Vector2 = tilemap.map_to_world(cell_pos + Vector2(1, 0)) # Top right
		var p3: Vector2 = tilemap.map_to_world(cell_pos + Vector2(1, 1)) # Bottom right
		
		var cell_edges: Array = [
			[p0, p1], # Left
			[p1, p2], # Top
			[p2, p3], # Right
			[p3, p0]  # Bottom
		]
		
		for edge in 4:
			
			var neighbour_pos: Vector2 = cell_pos + NEIGHBOUR_CELLS[edge]
			var neighbour_tile: int = tilemap.get_cellv(neighbour_pos)
			
			# Neighbour cell blocks this edge, so remove it
			if neighbour_tile != TileMap.INVALID_CELL and _using_tile(neighbour_tile, tiles_to_use):
				cell_edges[edge] = null
		
		edges[cell_pos] = cell_edges
	
	for cell_pos in edges:
		
		for edge in 4:
			
			# No edge here, skip
			if edges[cell_pos] is Vector2 or edges[cell_pos][edge] == null:
				continue
			
			var cell_edge: Array = edges[cell_pos][edge]
			
			if not cell_pos in next_edges:
				next_edges[cell_pos] = {}
			
			# Check for parralel neighbouring edges
			for _a in 1:
				var neighbour_pos: Vector2 = cell_pos + NEIGHBOUR_CELLS[wrapi(edge + 1, 0, 4)]
				if not neighbour_pos in edges:
					break
				
				var neighbour_edge = edges[neighbour_pos][edge]
				if neighbour_edge == null:
					break
				
				var cont: bool = false
				while neighbour_edge is Vector2:
					neighbour_pos = neighbour_edge
					if not neighbour_pos in edges:
						cont = true
						break
					
					neighbour_edge = edges[neighbour_pos][edge]
					if neighbour_edge == null:
						cont = true
				if cont:
					break
				
				assert(neighbour_edge is Array)
				
				if neighbour_edge[0] == cell_edge[1]:
					neighbour_edge[0] = cell_edge[0]
				elif neighbour_edge[1] == cell_edge[0]:
					neighbour_edge[1] = cell_edge[1]
				else:
					break
				
				edges[cell_pos][edge] = neighbour_pos
				next_edges[cell_pos][edge] = [neighbour_pos, edge]
			
			if edge in next_edges[cell_pos]:
				continue
			
			# Parallel edge wasn't found, so check for orthogonal neighbouring edges
			for _a in 1:
				var neighbour_pos: Vector2 = cell_pos + NEIGHBOUR_CELLS[wrapi(edge + 1, 0, 4)] + NEIGHBOUR_CELLS[edge]
				if not neighbour_pos in edges:
					break
				
				var neighbour_edge = edges[neighbour_pos][wrapi(edge - 1, 0, 4)]
				if neighbour_edge == null:
					break
				
				var cont: bool = false
				while neighbour_edge is Vector2:
					neighbour_pos = neighbour_edge
					if not neighbour_pos in edges:
						cont = true
						break
					
					neighbour_edge = edges[neighbour_pos][wrapi(edge - 1, 0, 4)]
					if neighbour_edge == null:
						cont = true
				if cont:
					break
				
				next_edges[cell_pos][edge] = [neighbour_pos, wrapi(edge - 1, 0, 4)]
	
	var ret: PoolVector2Array = PoolVector2Array()
	
	var initial_cell: Vector2 = next_edges.keys()[0]
	var current_cell: Vector2 = initial_cell
	var edge: int = next_edges[initial_cell].keys()[0]
	
	var i = 0
	var j = 0
	while true:
		var data: Array = next_edges[current_cell][edge]
		var cell_edge = edges[current_cell][edge]
		assert(cell_edge != null)
		
		j = 0
		while cell_edge is Vector2:
			current_cell = data[0]
			edge = data[1]
			cell_edge = edges[current_cell][edge]
			
			j += 1
			if j > 5000:
				print("J LIMIT")
				break
			
			assert(cell_edge != null)
		
		ret.append(cell_edge[0])
		ret.append(cell_edge[1])
		
		current_cell = data[0]
		edge = data[1]
		
		if cell_edge == initial_cell:
			break
		
		i += 1
		if i > 5000:
			print("LIMIT")
			break
		
		print(cell_edge)
	
#	for cell_pos in edges:
#
#		var cell_edges: Array = edges[cell_pos]
#		for edge in cell_edges:
#			if edge == null or edge is Vector2:
#				continue
#			ret.append(edge[0])
#			ret.append(edge[1])
	
	draw_data = edges
	update()
	
	return ret

func _draw() -> void:
	
	if not draw_data or not has_node(tilemap_path):
		return
	
	var tilemap: TileMap = get_node(tilemap_path)
	for cell_pos in draw_data:
		
		for edge in 4:
			
			var cell_edge = draw_data[cell_pos][edge]
			if cell_edge == null or cell_edge is Vector2:
				continue
			
			var from: Vector2 = tilemap.to_global(cell_edge[0])
			var to: Vector2 = tilemap.to_global(cell_edge[1])
			
			draw_line(from, to, Color.yellow)
			
			draw_circle(from + Vector2(0.5, 0), 0.7, Color.red)
			draw_circle(to - Vector2(0.5, 0), 0.7, Color.blue)
