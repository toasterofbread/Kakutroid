extends Node2D
class_name RoomCollisionObject

enum MODULATE_MODE {
	NONE, APPLY, GLOBAL_APPLY
}
export(MODULATE_MODE) var modulate_mode: int = MODULATE_MODE.APPLY
export var particle_colour: Color setget set_particle_colour, get_particle_colour
export var particle_texture: StreamTexture = preload("res://assets/sprites/cube.png") setget set_particle_texture, get_particle_texture

func _ready() -> void:
	Game.set_node_layer(self, Game.LAYER.WORLD)

func set_particle_colour(value: Color):
	particle_colour = value

func get_particle_colour():
	match modulate_mode:
		MODULATE_MODE.NONE:
			return particle_colour
		MODULATE_MODE.APPLY:
			return particle_colour * modulate
		MODULATE_MODE.GLOBAL_APPLY:
			return particle_colour * Utils.get_global_modulate(self)
		_:
			assert(false)
			return null

func set_particle_texture(value: StreamTexture):
	particle_texture = value

func get_particle_texture():
	return particle_texture
