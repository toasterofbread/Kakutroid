# Header file for Player.gd
extends KinematicBody2DWithArea2D
class_name Player

# - Signals -
signal STATE_CHANGED(previous_state)
signal DATA_CHANGED() # TODO

# - Enums -
enum STATE { NONE, NEUTRAL, WALK, RUN, JUMP, SLIDE }
enum UPGRADE { WALLJUMP }

# - Nodes -
onready var crouch_tween: Tween = $CrouchTween
onready var shape_transition_tween: Tween = $ShapeTransitionTween
onready var wall_squeeze_animationplayer: AnimationPlayer = $WallSqueezeAnimationPlayer
onready var trail_emitter: NodeTrailEmitter = $NodeTrailEmitter
onready var landing_particles: CPUParticles2D = $LandingParticles
onready var intangibility_timer: Timer = $IntangibilityTimer
onready var wind_sprite: AnimatedSprite = $WindSprite

# - Variables -
var states: Dictionary = {}
var current_state: Node = null
var facing: int = 1
var velocity: Vector2 = Vector2.ZERO
var air_time: float = -1.0
var health: float = null setget set_health
var intangible: bool = false setget set_intangible
var crouching: bool = false setget set_crouching
var running: bool = false setget set_running
var fast_falling: bool = null setget set_fast_falling
var physics_frame: int = 0

# - Data -
var data: Dictionary = Utils.load_json("res://data/player/default.json").result
var player_data: Dictionary = data["general"]
var save_data: Dictionary = {
	"upgrades": {
		UPGRADE.WALLJUMP: {"acquired": 1, "enabled": true}
	}
}

# - Shape -
const SHAPE_TRANSITION_DURATION: float = 0.5
onready var shape_data: Dictionary = {
	Enums.SHAPE.CUBE: {"node": $Shapes/Square},
	Enums.SHAPE.TRIANGLE: {"node": $Shapes/Triangle},
	Enums.SHAPE.CIRCLE: {"node": $Shapes/Circle},
}
var current_shape: int = null setget set_current_shape
var current_shape_node: Node2D = null

# - Scenes -
const projectile_scene: PackedScene = preload("res://src/scenes/player/Projectile.tscn")

# - Demofile recording and playback -
const DEMO_IGNORED_ACTIONS: Array = ["DEBUG_quit", "demo_start_recording", "demo_stop_recording"]
const DEMOFILE_DIRECTORY: String = "res://data/demofiles/"

enum DEMO_MODE {PLAY, PLAY_TEST, RECORD, NONE}
export(DEMO_MODE) var demo_mode: int = DEMO_MODE.NONE
export var demofile_path: String = ""
var demofile_data: Array = []
var demo_enabled: bool = false
var demo_playback_head: int = 0

# - Other -
const CUBE_SIZE: int = 16
const WALL_SQUEEZE_AMOUNT: float = 0.25
const CROUCH_SQUEEZE_AMOUNT: float = 0.25
const CUBE_TEXTURE: Texture = preload("res://assets/temp/white.png")
var squeeze_amount_x: float = 0.0 setget set_squeeze_amount_x
var squeeze_amount_y: float = 0.0 setget set_squeeze_amount_y
onready var gradient: Gradient = $Shapes/Square/Polygon.texture.gradient
var previous_velocity: Vector2 = Vector2.ZERO
var was_on_floor: bool = false
var last_damage_time: int = 0.0
var passive_heal_cap: float
var low_health_sound_wait_time: float = 0.0

# - Public function declarations -
func change_state(state_id: int, data: Dictionary = {}):
	return
func wall_collided(direction: int, strong: bool = false):
	return
func fire_weapon(direction: int = facing):
	return
func is_squeezing_wall() -> bool:
	return null
func vel_move_y(to: float, by: float = INF):
	return
func vel_move_x(to: float, by: float = INF):
	return
func vel_move(to: Vector2, delta: float = INF):
	return
func emit_landing_particles(texture_or_colour, amount: int = 3) -> CPUParticles2D:
	return null
func can_fall() -> bool:
	return null
func get_state_data(state_id: int) -> Dictionary:
	return null
func collect_upgrade(upgrade_type: int):
	return
func damage(type: int, amount: float, position: Vector2 = null):
	return
func play_sound(sound_key: String):
	return
func is_sound_playing(sound_key: String):
	return
func play_wind_animation(falling_only: bool = false):
	return
func using_upgrade(upgrade: int) -> bool:
	return null
func is_action_pressed(action: String) -> bool:
	return null
func is_action_just_pressed(action: String) -> bool:
	return null
func is_action_just_released(action: String) -> bool:
	return null
func get_pad(just_pressed: bool = false) -> Vector2:
	return null
func get_pad_x(just_pressed: bool = false) -> int:
	return null
func get_pad_y(just_pressed: bool = false) -> int:
	return null

# - Setter declarations -
func set_health(value: float):
	return
func set_intangible(value: bool):
	return
func set_crouching(value: bool):
	return
func set_running(value: bool):
	return
func set_fast_falling(value: bool):
	return
func set_current_shape(value: int):
	return
func set_squeeze_amount_x(value: float):
	return
func set_squeeze_amount_y(value: float):
	return
