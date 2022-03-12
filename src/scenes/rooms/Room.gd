extends Node2D
class_name GameRoom

onready var tilemap: TileMap = $TileMap # TEMP

func _ready() -> void:
	Game.current_room = self

func pulse_bg(origin: Vector2, colour: Color, force: bool = false, priority: int = 0, speed: float = 1.0, max_distance: float = -1.0, width: float = 50.0):
	tilemap.PulseBG(origin, colour, force, priority, speed, max_distance, width)
