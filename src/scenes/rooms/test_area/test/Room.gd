extends GameRoom

onready var crumble_blocks: Array = $WalljumpChamber/CrumbleBlocks.get_children()
var crumble_triggered: bool = false

func _ready() -> void:
	$WalljumpChamber/ColorRect.visible = true

func _on_CRUMBLE_DESTROYED(type: int) -> void:
	var emit_pulse: bool = false
	for block in crumble_blocks:
		if block.state == DestroyableBlock.STATE.NORMAL:
			block.destroy(type)
			emit_pulse = true
	
	if emit_pulse:
		pulse_bg($WalljumpChamber/PulseOrigin.global_position, Color.turquoise)
	
	if not crumble_triggered:
		crumble_triggered = true
		
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
