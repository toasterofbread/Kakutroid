extends GameRoom

onready var tutorial_panel_fire: Node = $TutorialPanelFire
onready var crumble_blocks: Array = $WalljumpChamber/CrumbleBlocks.get_children()
var crumble_triggered: bool = false

func ready() -> void:
	$WalljumpChamber/ColorRect.visible = true
	
	if "fire_tutorial_completed" in room_data and room_data["fire_tutorial_completed"]:
		$TutorialPanelFire.queue_free()
		tutorial_panel_fire = null
	
#	yield(tilemap,"ready")
	_on_CRUMBLE_DESTROYED(Enums.DAMAGE_TYPE.CRUMBLE)

func _on_CRUMBLE_DESTROYED(type: int) -> void:
	for block in crumble_blocks:
		if block.state == DestroyableBlock.STATE.NORMAL:
			block.destroy(type)
	
	if not crumble_triggered:
		crumble_triggered = true
		
		pulse_bg($WalljumpChamber/PulseOrigin.global_position, Color.turquoise)
		
		var tween: Tween = Tween.new()
		add_child(tween)
		tween.interpolate_property($WalljumpChamber/ColorRect, "modulate:a", $WalljumpChamber/ColorRect.modulate.a, 0.0, 0.1)
		tween.connect("tween_all_completed", $WalljumpChamber/ColorRect, "queue_free")
		tween.connect("tween_all_completed", tween, "queue_free")
		tween.start()
		
		var functions: GDScriptFunctionState = Utils.yield_functions([
			TileMapCrumbleMarker.crumble_tilemap(tilemap, "left"),
			TileMapCrumbleMarker.crumble_tilemap(tilemap, "right"),
			TileMapCrumbleMarker.crumble_tilemap(tilemap, "center")
		])
		
		while functions and functions.is_valid():
			$WalljumpChamber/SfxrStreamPlayer.play()
			yield(get_tree().create_timer(0.1), "timeout")
		
		get_tree().create_timer(2.0).connect("timeout", $WalljumpChamber/DemoPlayerSpawner, "set", ["active", true])

func _on_DoorRight_OPEN_CHANGED(open: bool) -> void:
	if open and tutorial_panel_fire:
		yield(tutorial_panel_fire.hide_tutorial(), "completed")
		tutorial_panel_fire.queue_free()
		room_data["fire_tutorial_completed"] = true
