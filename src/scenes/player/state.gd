extends Node
class_name PlayerState

var player_data: Dictionary
var data: Dictionary
var player: KinematicBody2D = null
var activation_time: int = 0
var disactivation_time: int = 0

func _init(_player: KinematicBody2D):
	player = _player
	player_data = player.player_data
	data = player.get_state_data(get_id())

func get_id() -> int:
	return Enums.PLAYER_STATE.NONE

func get_name() -> String:
	return Enums.PLAYER_STATE.keys()[get_id()].to_lower()

func process(_delta: float):
	pass

func physics_process(_delta: float):
	pass

func on_enabled(_previous_state: PlayerState, _data: Dictionary = {}):
	activation_time = OS.get_ticks_msec()

func on_disabled(_next_state: PlayerState):
	disactivation_time = OS.get_ticks_msec()

func get_time_since_activated() -> float:
	return (OS.get_ticks_msec() - activation_time) / 1000.0
func get_time_since_disactivated() -> float:
	return (OS.get_ticks_msec() - disactivation_time) / 1000.0
