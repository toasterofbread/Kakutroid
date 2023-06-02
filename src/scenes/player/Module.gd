extends Node
class_name PlayerModule

var player: Player
var player_data: Dictionary

func init(player: Player) -> PlayerModule:
	self.player = player
	player_data = player.player_data
	return self
