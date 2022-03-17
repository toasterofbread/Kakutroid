extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://src/scenes/player/Player.tscn")

export(int, 0, 100) var player_amount: int = 1
export(float, 0, 60) var min_wait_time: float = 3.0
export(float, 0, 60) var max_wait_time: float = 3.0
export(Array, Resource) var demo_resources: Array
export(Array, float) var demo_weights: PoolRealArray
export var active: bool = true setget set_active
export var alternate: bool = false

onready var rng: RandomNumberGenerator = Utils.get_RNG()
var players: Dictionary
var tweens: Array
var alternation_index: int = 0

func _ready():
	if Game.current_room == null:
		return
	
	$PreviewPlayer.queue_free()
	
	yield(get_tree().create_timer(1), "timeout")
	
	for resource in demo_resources:
		assert(resource is InputDemo)
	
	for _i in player_amount:
		var tween: Tween = Tween.new()
		tweens.append(tween)
		add_child(tween)
	
	while demo_resources.size() > demo_weights.size():
		demo_weights.append(1.0)
	
	if active:
		_run()

func _run():
	
	while active:
		
		while players.size() >= player_amount:
			yield(get_tree(), "idle_frame")
		
		var player: Player = PLAYER_SCENE.instance()
		player.ghost = true
		player.modulate.a = 0.0
		add_child(player)
		player.global_transform = global_transform
		
		var demo: InputDemo = get_next_demo()
		player.module_demo.demo_data = demo
		if "player_data" in demo.metadata:
			player.save_data = demo.metadata["player_data"].duplicate(true)
		if "player_background" in demo.metadata:
			player.background = demo.metadata["player_background"]
		
		var tween: Tween = tweens[players.size()]
		players[player] = true
		
		tween.interpolate_property(player, "modulate:a", 0.0, 1.0, 5.0)
		tween.start()
		player.module_demo.play()
		
		yield(get_tree().create_timer(rng.randf_range(min_wait_time, max_wait_time)), "timeout")

func _physics_process(_delta: float):
	
	var i: int = -1
	for player in players:
		i += 1
		
		if not players[player]:
			continue
		
		var demo: PlayerModuleDemo = player.module_demo
		if demo.playback_frame >= demo.demo_data.get_frame_count() - (0.5*Engine.iterations_per_second):
			
			var tween: Tween = tweens[i]
			tween.stop_all()
			tween.interpolate_property(player, "modulate:a", player.modulate.a, 0.0, 0.5, Tween.TRANS_SINE)
			
			tween.connect("tween_completed", self, "on_tween_completed")
#			Utils.Callback.new(funcref(player, "queue_free")).attach_to_node(player).connect_signal(tween, "tween_completed")
			tween.start()
			
			players[player] = false
			yield(player, "tree_exited")
			players.erase(player)

func on_tween_completed(object: Node, _key: NodePath):
	object.queue_free()

func get_next_demo() -> InputDemo:
	if alternate:
		var ret = demo_resources[alternation_index]
		alternation_index = wrapi(alternation_index + 1, 0, demo_resources.size())
		return ret
	else:
		return Utils.random_array_item(demo_resources, demo_weights)

func set_active(value: bool):
	if active == value:
		return
	active = value
	if active:
		_run()
