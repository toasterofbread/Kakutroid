extends Sprite
class_name DestroyableBlock

signal DESTROYED(type)
signal RESPAWNED

enum RESPAWN_TIME {
	SHORT,
	NORMAL,
	LONG,
	NO_RESPAWN
}
export(Array(Enums.DAMAGE_TYPE)) var damage_types: Array = [Enums.DAMAGE_TYPE.FASTFALL]
export(RESPAWN_TIME) var respawn_time: int = RESPAWN_TIME.NORMAL

enum STATE {NORMAL, DESTROYED, RESPAWNING}
var state: int = STATE.NORMAL

onready var static_body: StaticBody2D = $StaticBody2D
onready var area: Area2D = $Area2D
onready var step_area: Area2D = $StepArea
onready var destroyed_particles: CPUParticles2D = $DestroyedParticles
onready var respawn_timer: Timer = $RespawnTimer
onready var tween: Tween = $Tween

func _ready():
	_on_DestroyableBlock_texture_changed()
	Game.set_node_layer(self, Game.LAYER.BLOCK)
	
	Game.set_physics_layer(static_body, Game.PHYSICS_LAYER.WORLD, not Enums.DAMAGE_TYPE.FASTFALL in damage_types)

	static_body.set_meta("DMG", Damageable.new(static_body))
	Damageable.connect_node_damaged(static_body, self, "_on_StaticBody2D_DAMAGED")

func get_actual_respawn_time() -> float:
	match respawn_time:
		RESPAWN_TIME.SHORT: return 2.0
		RESPAWN_TIME.NORMAL: return 5.0
		RESPAWN_TIME.LONG: return 10.0
		RESPAWN_TIME.NONE: return -1.0
	
	return 0.0

func destroy(type: int):
	if state != STATE.NORMAL:
		return
	
	state = STATE.DESTROYED
	emit_signal("DESTROYED", type)
	
	var soft: bool = type == Enums.DAMAGE_TYPE.CRUMBLE
	
	tween.stop_all()
	tween.interpolate_property(self, "self_modulate:a", 1.0, 0.0, 0.1 if soft else 0.05, Tween.TRANS_SINE)
	tween.start()
	
	static_body.disable()
	
	if respawn_time != RESPAWN_TIME.NO_RESPAWN:
		respawn_timer.start(get_actual_respawn_time())
	
	if not soft:
		destroyed_particles.emitting = true
		yield(Utils.yield_particle_completion(destroyed_particles), "completed")
	
	if tween.is_active():
		yield(tween, "tween_all_completed")
	
	if state == STATE.DESTROYED:
		if respawn_time == RESPAWN_TIME.NO_RESPAWN:
			queue_free()
		else:
			visible = false

func respawn():
	
	if state != STATE.DESTROYED:
		return
	
	state = STATE.RESPAWNING
	emit_signal("RESPAWNED")
	
	# Don't respawn if overlapping body exists
	while not area.get_overlapping_bodies().empty():
		yield(get_tree(), "physics_frame")
	
	visible = true
	static_body.enable()
	tween.stop_all()
	tween.interpolate_property(self, "self_modulate:a", 0.0, 1.0, 0.5, Tween.TRANS_SINE)
	tween.start()
	
	state = STATE.NORMAL

func _on_StaticBody2D_DAMAGED(type: int, amount: float, _position: Vector2):
	if type in damage_types and amount > 0.0:
		destroy(type)

func _on_DestroyableBlock_texture_changed():
	if not destroyed_particles:
		return
	destroyed_particles.texture = texture

func _on_StepArea_body_entered(_body: Node):
	if Enums.DAMAGE_TYPE.CRUMBLE in damage_types:
		destroy(Enums.DAMAGE_TYPE.CRUMBLE)
