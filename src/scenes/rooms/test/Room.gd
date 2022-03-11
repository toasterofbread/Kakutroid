extends Node2D

onready var crumble_blocks: Array = $WalljumpChamber/CrumbleBlocks.get_children()
onready var tilemap: TileMap = $TileMap
var crumble_triggered: bool = false

#func _input(event: InputEvent) -> void:
#	if event.is_action_pressed("DEBUG_TRIGGER"):
#		tilemap.PulseBg(Game.player.global_position, 1)

func _ready() -> void:
	$WalljumpChamber/ColorRect.visible = true
	Game.current_room = self

func pulse_bg(origin: Vector2, tile: int, speed: float = 1.0, max_distance: float = -1.0, width: float = 50.0):
	tilemap.PulseBG(origin, tile, speed, max_distance, width)

func _on_CRUMBLE_DESTROYED(type: int) -> void:
	for block in crumble_blocks:
		if block.state == DestroyableBlock.STATE.NORMAL:
			block.destroy(type)
	
	if not crumble_triggered:
		crumble_triggered = true
		
		var tween: Tween = Tween.new()
		add_child(tween)
		tween.interpolate_property($WalljumpChamber/ColorRect, "modulate:a", $WalljumpChamber/ColorRect.modulate.a, 0.0, 0.1)
		tween.connect("tween_all_completed", $WalljumpChamber/ColorRect, "queue_free")
		tween.connect("tween_all_completed", tween, "queue_free")
		tween.start()
		
		var functions: GDScriptFunctionState = Utils.yield_funcitons([
			TileMapCrumbleMarker.crumble_tilemap(tilemap, "left"),
			TileMapCrumbleMarker.crumble_tilemap(tilemap, "right"),
			TileMapCrumbleMarker.crumble_tilemap(tilemap, "center")
		])
		
		while functions and functions.is_valid():
			$WalljumpChamber/SfxrStreamPlayer.play()
			yield(get_tree().create_timer(0.1), "timeout")
		
		get_tree().create_timer(2.0).connect("timeout", $WalljumpChamber/DemoPlayerSpawner, "set", ["active", true])
