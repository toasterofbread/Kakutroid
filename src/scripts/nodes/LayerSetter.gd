tool
extends Node2D
class_name LayerSetter

export(Game.LAYERS) var z_layer: int = 0
export var z_layer_offset: int = 0 setget set_z_layer_offset
#export(Enums.CanvasLayers) var canvas_layer: int = 0
export(Array, NodePath) var z_layer_nodes: = []
#export(Array, NodePath) var canvas_layer_nodes: = []
export var apply_z_layer_to_parent: bool = true
#export var apply_canvas_layer_to_parent: bool = false

export var apply: bool = false setget apply

func apply(value: bool = true):
	if not value:
		return
	for path in z_layer_nodes + ([".."] if apply_z_layer_to_parent else []):
		if has_node(path):
			Game.set_node_layer(get_node(path), z_layer, z_layer_offset)
#	for path in canvas_layer_nodes + ([".."] if apply_canvas_layer_to_parent else []):
#		if has_node(path):
#			get_node(path).layer = canvas_layer - 5

func set_z_layer_offset(value: int):
	z_layer_offset = value
	apply()

func _ready():
	apply()
	
	if not Engine.editor_hint:
		queue_free()
