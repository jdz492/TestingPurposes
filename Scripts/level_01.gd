extends Node2D

@export var PlayerScene : PackedScene
var p = []
func _ready() -> void:
	var index = 1
	for i in GameManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		currentPlayer.name = str(GameManager.Players[i].id)
		print("player ID %s, position %s" % [currentPlayer.name, str(currentPlayer.position)])
		p.append(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
				break;
		
		index += 1
	print(p)
	for player in p:
		player.collision_layer = 1
		player.collision_mask = 1
		self.add_child(player)
