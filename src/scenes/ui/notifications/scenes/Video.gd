extends HBoxContainer

signal FINISHED

func _ready():
	$VideoPlayer.connect("finished", self, "emit_signal", ["FINISHED"])
