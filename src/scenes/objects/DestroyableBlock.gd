extends Sprite

enum RESPAWN_TIME {
	SHORT,
	NORMAL,
	LONG,
	NO_RESPAWN
}
export(Array, Enums.DAMAGE_TYPE) var damage_types: Array = [Enums.DAMAGE_TYPE.FASTFALL]
export(RESPAWN_TIME) var respawn_time: int = RESPAWN_TIME.NORMAL

enum STATE {NORMAL, DESTROYED, RESPAWNING}
var state: int = STATE.NORMAL

onready var static_body: StaticBody2D = $StaticBody2D
onready var area: Area2D = $Area2D
onready var destroyed_particles: CPUParticles2D = $DestroyedParticles
onready var respawn_timer: Timer = $RespawnTimer
onready var tween: Tween = $Tween

func _ready():
	_on_DestroyableBlock_texture_changed()
	Game.set_node_layer(self, Game.LAYERS.WORLD, -1)
	
	static_body.set_collision_layer_bit(0, not Enums.DAMAGE_TYPE.FASTFALL in damage_types)

func get_actual_respawn_time() -> float:
	match respawn_time:
		RESPAWN_TIME.SHORT: return 2.0
		RESPAWN_TIME.NORMAL: return 5.0
		RESPAWN_TIME.LONG: return 10.0
		RESPAWN_TIME.NONE: return -1.0
	
	return 0.0

func destroy():
	if state != STATE.NORMAL:
		return
	
	state = STATE.DESTROYED
	
	tween.stop_all()
	tween.interpolate_property(self, "self_modulate:a", 1.0, 0.0, 0.05, Tween.TRANS_SINE)
	tween.start()
	
	static_body.disable()
	
	if respawn_time != RESPAWN_TIME.NO_RESPAWN:
		respawn_timer.start(get_actual_respawn_time())
	
	destroyed_particles.emitting = true
	yield(Utils.yield_particle_completion(destroyed_particles), "completed")
	
	if state == STATE.DESTROYED:
		if respawn_time == RESPAWN_TIME.NO_RESPAWN:
			queue_free()
		else:
			visible = false

func respawn():
	
	if state != STATE.DESTROYED:
		return
	
	state = STATE.RESPAWNING
	
	# Don't respawn if overlapping body exists
	while not area.get_overlapping_bodies().empty():
		yield(get_tree(), "physics_frame")
	
	visible = true
	static_body.enable()
	tween.stop_all()
	tween.interpolate_property(self, "self_modulate:a", 0.0, 1.0, 0.05, Tween.TRANS_SINE)
	tween.start()
	
	state = STATE.NORMAL

func _on_StaticBody2D_DAMAGE(type: int, amount: float, position: Vector2 = null):
	if type in damage_types and amount > 0.0:
		destroy()

func _on_DestroyableBlock_texture_changed():
	if not destroyed_particles:
		return
	destroyed_particles.texture = texture
