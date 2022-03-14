tool
extends Node2D

var tween: ExTween = ExTween.new()
var showing: bool = false
var completed: bool = false
var player_area: Area2D = null
var player_inside_time: float = 0.0
var player_inside: bool = false

export var action_key: String
export var text: String = "Text" setget set_text
export var size: Vector2 = Vector2(112, 32) setget set_size
export var player_area_path: NodePath = null
export var show_wait_time: float = 0.0
export var hide_wait_time: float = 0.0
export var start_hidden: bool = true
export var enabled_gradients: Dictionary = {
	"left": false,
	"right": false,
	"top": false,
	"bottom": false
} setget set_enabled_gradients

func _ready() -> void:
	set_size(size)
	set_text(text)
	
	update_gradients()
	
	if Engine.editor_hint:
		return
	
	if start_hidden:
		visible = false
	
	modulate.a = 1.0 if visible else 0.0
	showing = visible
	Game.set_node_layer(self, Game.LAYER.BACKGROUND, 1)
	$MarginContainer/HBoxContainer/ButtonIcon.set_action_key(action_key)
	add_child(tween)
	
	if player_area_path != null:
		player_area = get_node(player_area_path)
		player_area.connect("body_entered", self, "_on_player_area_body_entered")
		player_area.connect("body_exited", self, "_on_player_area_body_exited")
		
		Game.set_all_physics_layers(player_area, false)
		Game.set_all_physics_masks(player_area, false)
		Game.set_physics_mask(player_area, Game.PHYSICS_LAYER.PLAYER, true)
	
	set_process(show_wait_time > 0.0)

func update_gradients():
	if !is_inside_tree():
		return
	
	$MarginContainer/Background/Left.visible = enabled_gradients["left"]
	$MarginContainer/Background/Right.visible = enabled_gradients["right"]
	$MarginContainer/Background/Top.visible = enabled_gradients["top"]
	$MarginContainer/Background/Bottom.visible = enabled_gradients["bottom"]
	
	$MarginContainer/Background/CornerLeftBottom.visible = enabled_gradients["left"] and enabled_gradients["bottom"]
	$MarginContainer/Background/CornerRightBottom.visible = enabled_gradients["right"] and enabled_gradients["bottom"]
	$MarginContainer/Background/CornerLeftTop.visible = enabled_gradients["left"] and enabled_gradients["top"]
	$MarginContainer/Background/CornerRightTop.visible = enabled_gradients["right"] and enabled_gradients["top"]

func set_enabled_gradients(value: Dictionary):
	enabled_gradients = value
	update_gradients()

func _process(delta: float) -> void:
	player_inside_time += delta
	
	if player_inside:
		if player_inside_time >= show_wait_time:
			show_tutorial()
			set_process(false)
	else:
		if player_inside_time >= hide_wait_time:
			hide_tutorial()
			set_process(false)

func _on_player_area_body_entered(body: Node):
	if body != Game.player:
		return
	player_inside = true
	player_inside_time = 0.0
	set_process(true)

func _on_player_area_body_exited(body: Node):
	if body != Game.player:
		return
	player_inside = false
	player_inside_time = 0.0
	set_process(true)

func show_tutorial():
	if showing:
		yield(get_tree(), "physics_frame")
		return
	showing = true
	visible = true
	
	tween.stop_all()
	tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.25, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed_or_stopped")

func hide_tutorial():
	if not showing:
		yield(get_tree(), "physics_frame")
		return
	showing = false
	
	tween.stop_all()
	tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.25, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed_or_stopped")

func set_text(value: String):
	text = value
	$MarginContainer/HBoxContainer/Label.text = text

func set_size(value: Vector2):
	size = value
	$MarginContainer.rect_size = size
