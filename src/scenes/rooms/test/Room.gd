extends Node2D

onready var crumble_blocks: Array = $WalljumpChamber/CrumbleBlocks.get_children()
onready var tilemap: TileMap = $TileMap
var crumble_triggered: bool = false

func _ready() -> void:
	$WalljumpChamber/ColorRect.visible = true

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
			FallingTileMarker.crumble_tilemap(tilemap, 0),
			FallingTileMarker.crumble_tilemap(tilemap, 1),
			FallingTileMarker.crumble_tilemap(tilemap, 2)
		])
		
		while functions.is_valid():
			$WalljumpChamber/SfxrStreamPlayer.play()
			yield(get_tree().create_timer(0.1), "timeout")
		
		get_tree().create_timer(2.0).connect("timeout", $WalljumpChamber/DemoPlayerSpawner, "set", ["active", true])
