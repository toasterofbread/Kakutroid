tool
extends Door

func _ready() -> void:
	update_colour()
	
	if Engine.editor_hint:
		return
	
	assert(not camera_chunks.empty())
	assert(Game.room_exists(target_room_id))
	
	for i in len(camera_chunks):
		camera_chunks[i] = get_node(camera_chunks[i])
	
	$AnimationPlayer.play("close", -1, INF)
	Game.set_node_layer(self, Game.LAYER.DOOR)
	add_to_group(DOOR_GROUP)
	
	# Load target room in background
	var loader = ResourceLoader.load_interactive(Game.rooms[target_room_id])
	if loader == null: # Check for errors.
		push_error("Room could not be loaded: " + Game.rooms[target_room_id])
		return

	while true:
		var err = loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			var resource = loader.get_resource()
			target_room_instance = resource.instance()
#			emit_signal("target_room_loaded")
			break
#		elif err == OK:
#			var progress = float(loader.get_stage()) / loader.get_stage_count()
#			print("Loading room '" + target_room_id + "': " + str(progress*100) + "%")
		elif err != OK:
			push_error("Error occured while loading room '" + target_room_id + "': " + err)
			break
	loader = null

func on_damage(type: int, _amount: float, _position: Vector2 = null) -> bool:
	if locked or not type in TYPE_DAMAGE_TYPES[door_type]:
		$Sounds/ImmuneHit.play()
		return false
	elif not open:
		set_open(true)
		var pulse: Object = Game.current_room.pulse_bg($Cover/PulseOrigin.global_position, $Cover.modulate, true, 9)
		pulse.Speed = 0.75
		pulse.MaxDistance = 125.0
	return true

func set_open(value: bool, animate: bool = true):
	if open == value:
		return
	open = value
	emit_signal("OPEN_CHANGED", open)
	
	if not visual:
		return
	
	$AnimationPlayer.play("open" if open else "close")
	set_disabled(open)
	
	if animate:
		$Sounds.get_node("Open" if open else "Close").play()
#		yield($AnimationPlayer, "animation_finished")
	else:
		$AnimationPlayer.seek(100.0)

func set_locked(value: bool, animate: bool = true):
	if locked == value:
		return
	locked = value
	emit_signal("LOCKED_CHANGED", locked)
	
	$Cover.self_modulate = Color("2b2b2b") if locked else Color.white
	if locked and open:
		set_open(false, animate)
	
	if visual and animate:
		$Sounds.get_node("Lock" if locked else "Unlock").play()

func door_entered():
	yield(get_tree().create_timer(0.1), "timeout")
	set_locked(false, false)
	if $FullDoorArea.overlaps_body(Game.player):
		while true:
			var body: Node = yield($FullDoorArea, "body_exited")
			if body == Game.player:
				break
	set_open(false)

func update_colour():
	if tilemap_path != null and has_node(tilemap_path):
		$FrameFG.modulate = get_node(tilemap_path).tile_set.tile_get_modulate(foreground_tile)
		$FrameBG.modulate = get_node(tilemap_path).tile_set.tile_get_modulate(background_tile)

func set_tilemap_path(value: NodePath):
	tilemap_path = value
	update_colour()

func set_foreground_tile(value: int):
	foreground_tile = value
	update_colour()

func set_background_tile(value: int):
	background_tile = value
	update_colour()

func _on_ActivationArea2D_body_entered(body: Node) -> void:
	if body != Game.player or locked:
		return
	Game.door_entered(self)
