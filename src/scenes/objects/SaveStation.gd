tool
extends Node2D

signal HIDE_SAVE_PROMPT

export var tilemap: NodePath
export var foreground_tile: int = 0 setget set_foreground_tile
export var playing_sound: bool = false

var player: Player
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var activation_area: ExArea2D = $ActivationArea

var frame_lowered: bool = false
var save_prompt: ButtonPromptNotification = null

func _ready() -> void:
	
	assert(has_node(tilemap) or Engine.editor_hint)
	if has_node(tilemap):
		modulate = get_node(tilemap).tile_set.tile_get_modulate(foreground_tile)
	
	if Engine.editor_hint:
		return
	
	player = Game.player
	Game.set_node_layer($Slot, Game.LAYER.PLAYER, -10)
	Game.set_node_layer($Frame, Game.LAYER.PLAYER, 10)
	Game.set_node_layer($OverlayContainer, Game.LAYER.PLAYER, 10)

func set_foreground_tile(value: int):
	foreground_tile = value
	if has_node(tilemap):
		modulate = get_node(tilemap).tile_set.tile_get_modulate(foreground_tile)

func _process(_delta: float) -> void:
	
	if Engine.editor_hint:
		return
	
	if playing_sound:
		play_sound()
	
	if frame_lowered:
		return
	
	if save_prompt:
		if save_prompt.just_pressed():
			save_prompt.clear()
			save_prompt = null
			save()
		elif not player.current_state.get_id() in [Player.STATE.NEUTRAL, Player.STATE.WALK, Player.STATE.RUN]:
			save_prompt.clear()
			save_prompt = null
	elif not player.paused and activation_area.overlaps_body(player):
		if player.module_physics.velocity.x == 0.0 and player.is_on_floor() and player.current_state.get_id() in [Player.STATE.NEUTRAL]:
			save_prompt = ButtonPromptNotification.create("Save game", ButtonPromptNotification.MOVING_INTERACTION_BUTTON, null)

func play_sound():
	if $Sounds/SaveStep.playing:
		return
	$Sounds/SaveStep.play()

func save():
	player.paused = true
	
	$Tween.interpolate_property(player, "global_position", player.global_position, $PlayerPosition.global_position, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	if not frame_lowered:
		frame_lowered = true
		animation_player.play("frame_lower")
		$Sounds/LowerFrame.play()
		yield(animation_player, "animation_finished")
		yield(get_tree().create_timer(0.5), "timeout")
	
	animation_player.play("save")
	yield(animation_player, "animation_finished")
	yield(get_tree().create_timer(0.5), "timeout")
	
	var error: int = Game.save_file.save()
	if error != OK:
		TextNotification.create("An error occurred while saving: " + str(error), Notification.LENGTH_LONG)
	else:
		TextNotification.create("Save completed successfully")
	
	$Sounds/Completed.play()
	player.paused = false

func _on_ActivationArea_body_exited(body: Node) -> void:
	if body != player:
		return
	
	if frame_lowered:
		animation_player.play("frame_raise")
		frame_lowered = false
	
	if save_prompt:
		save_prompt.clear()
		save_prompt = null
