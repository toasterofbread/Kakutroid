extends Node2D
class_name SpriteTrailEmitter

onready var TrailSpriteTemplate: Node2D = $TrailSprite

export var profiles: Dictionary = {
	"default": {
		"frequency": 60, # int (per second)
		"linger_time": 1.0, # float
		"fade_out": false, # bool
		"modulate": null, # Color or NodePath or null
		"material": null # Material or NodePath or null
	}
}

var current_profile = "default" setget set_current_profile
var current_profile_data = null
export(Array, NodePath) var sprites: = []
var sprite_nodes: Array = []
export var emitting: bool = true
export var trailsprite_scale_override: Vector2 = Vector2.ZERO
var emission_timer: float = 0.0

onready var trail_anchor: Node = Utils.get_unique_anchor()

func _process(delta: float):
	
	if not emitting:
		emission_timer = 0.0
		return
	
	if current_profile_data["frequency"] < 0:
		emit_trail()
	else:
		emission_timer += delta
		if emission_timer >= 1.0 / current_profile_data["frequency"]:
			emit_trail()
			emission_timer = 0.0
	

func set_current_profile(value, force_update:=false):
	
	if not force_update and value == current_profile:
		return
	
	if current_profile == null:
		$EmissionTimer.start()
	
	current_profile = value
	if current_profile == null:
		current_profile_data = null
		$EmissionTimer.stop()
		return
	
	current_profile_data = profiles[current_profile]
	$EmissionTimer.wait_time = 1.0 / current_profile_data["frequency"]
	TrailSpriteTemplate.get_node("DeletionTimer").wait_time = current_profile_data["linger_time"]
	
	for property in ["modulate", "material"]:
		if current_profile_data[property] is NodePath:
			current_profile_data[property] = get_node_or_null(current_profile_data[property])

func _ready():
	
	remove_child(TrailSpriteTemplate)
	TrailSpriteTemplate.get_node("DeletionTimer").autostart = true
	
#	var spritepaths = sprites.duplicate()
#	sprites.clear()
	for spritepath in sprites:
		var sprite = get_node_or_null(spritepath)
		if sprite != null:
			sprite_nodes.append(sprite)
	
	set_current_profile(current_profile, true)

func _notification(what: int):
	if what == NOTIFICATION_PREDELETE and is_instance_valid(trail_anchor):
		trail_anchor.queue_free()

func clear_trail():
	for node in trail_anchor.get_children():
		node.queue_free()

func emit_trail():
	for sprite in sprite_nodes:
		if not sprite.visible or (sprite.has_meta("no_trail") and sprite.get_meta("no_trail")):
			continue
		
		var SpriteContainer: Node2D = TrailSpriteTemplate.duplicate()
		var TrailSprite: Node2D = sprite.duplicate()# if current_profile_data["sprite"] == null else Sprite.new()
		TrailSprite.z_as_relative = false
		TrailSprite.z_index = z_index
		if trailsprite_scale_override != Vector2.ZERO:
			TrailSprite.scale = trailsprite_scale_override
#		Enums.set_node_layer(TrailSprite, trail_layer)
		if get_parent() is Node2D:
			TrailSprite.rotation = get_parent().rotation
		SpriteContainer.add_child(TrailSprite)
		
		trail_anchor.add_child(SpriteContainer)
		SpriteContainer.init(TrailSprite, sprite, current_profile_data)
		TrailSprite.global_position = sprite.global_position
