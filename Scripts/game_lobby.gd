extends Control

@onready var finding_match_label: Control = $finding_match_label
@onready var finding_match_button: Button = $Buttons_List/FindingMatch_Button
@onready var match_finder_label: Label = $Match_Finder_Label

func _ready() -> void:
	finding_match_label.visible = false


func _on_finding_match_button_button_down() -> void:
	# show finding match label
	finding_match_label.visible = true
	finding_match_button.visible = false
	match_finder_label.visible = false
	var scene = load("res://Scenes/client.tscn").instantiate()
	scene.connect("on_start_game_for_clients", _on_start_game_clients)
	scene.connect("on_start_game_for_host", _on_start_game)
	get_tree().root.add_child(scene)

func _on_start_game_clients():
	finding_match_label.visible = false

func _on_start_game():
	StartGame.rpc()
@rpc("any_peer", "call_local", "reliable")
func StartGame():
	print("StartingGame")
	var scene = load("res://Scenes/Level01.tscn").instantiate()
	get_tree().root.add_child(scene)
