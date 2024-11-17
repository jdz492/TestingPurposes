extends Node

var websocket_client: WebSocketClient
var server_address: String = "ws://127.0.0.1:4596"  # Change to your server address
var rtcPeer : WebRTCMultiplayerPeer


var my_id = -1
var _match = []
var _rtc_peers = {}
var _player_number = 0
var _initialised = false
var players_ready : bool = false

signal on_start_game_for_host()
signal on_start_game_for_clients()

func _ready() -> void:
	# Initialize the WebSocket client
	websocket_client = WebSocketClient.new()
	rtcPeer = WebRTCMultiplayerPeer.new()

	# Connect signals to handle connection events
	websocket_client.connect("connected_to_socket", _on_connected)
	websocket_client.connect("disconnected_from_socket", _on_disconnected)
	websocket_client.connect("connection_failure", _on_connection_failure)
	websocket_client.connect("received_message", _on_received_message)
	
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	# Connect to the server
	websocket_client._connect(server_address)
	
	

func _process(delta: float) -> void:
	# Regularly poll for WebSocket events
	websocket_client._poll(delta)

func _on_connected() -> void:
	print("Successfully connected to WebSocket server.")

func _on_disconnected() -> void:
	print("Disconnected from WebSocket server.")

func _on_connection_failure() -> void:
	print("Failed to connect to WebSocket server.")
	
func _on_received_message(message: String) -> void:
	#print("Received message from server:", message)
	var result = JSON.parse_string(message)
	if (typeof(result) == TYPE_DICTIONARY):
		if (result.message == Utilities.Message.id):
			my_id = result.id as int
			_initialised = true
			connected(my_id)
		elif (result.message == Utilities.Message.match_start):
			_match = result.listOfPlayers.map(func(element): return int(element))
			for id in _match:
				if (!GameManager.Players.has(id)):
					GameManager.Players[id] = {"id": id, "name": str(id)}
			_player_number = _match.find(my_id)
			print("Match started as player ", _player_number)
			for player_id in _match:
				if (player_id != my_id):
					_rtc_peers[player_id] = false
					createPeer(player_id)
		elif result.message == Utilities.Message.candidate:
			if rtcPeer.has_peer(result.orgPeer):
				rtcPeer.get_peer(result.orgPeer).connection.add_ice_candidate(result.mid, result.index, result.sdp)
		
		elif result.message == Utilities.Message.offer:
			if rtcPeer.has_peer(result.orgPeer):
				rtcPeer.get_peer(result.orgPeer).connection.set_remote_description("offer", result.data)
		
		elif result.message == Utilities.Message.answer:
			if rtcPeer.has_peer(result.orgPeer):
				rtcPeer.get_peer(result.orgPeer).connection.set_remote_description("answer", result.data)
		else:
			print("MESSAGE UNEXEPCETD + " + message)

func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer

func RTCServerConnected():
	print("RTC server connected")

func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	_rtc_peers[id] = true
	 # Add the player to the scene

	for peer in _rtc_peers.keys():
		if not _rtc_peers[peer]:
			return
	players_ready = true
	#emit_signal("on_players_ready")
	_on_on_players_ready()

func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))

func createPeer(id):
	if id != my_id:
		var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})
		#print("binding id " + str(id) + ", my id is " + str(my_id))
		
		peer.session_description_created.connect(self.offerCreated.bind(id))
		peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
		rtcPeer.add_peer(peer, id)
		if id > rtcPeer.get_unique_id():
			peer.create_offer()
func offerCreated(type, data, id):
	if !rtcPeer.has_peer(id):
		return
		
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)
	pass
func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : my_id,
		"message" :  Utilities.Message.offer,
		"data": data,
		#"Lobby": lobbyValue
	}
	websocket_client._send(JSON.stringify(message))
	pass
func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : my_id,
		"message" : Utilities.Message.answer,
		"data": data,
		#"Lobby": lobbyValue
	}
	websocket_client._send(JSON.stringify(message))
	pass
	
func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : my_id,
		"message" :  Utilities.Message.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		#"Lobby": lobbyValue
	}
	websocket_client._send(JSON.stringify(message))
	pass
	

func _on_on_players_ready() -> void:
	emit_signal("on_start_game_for_clients")
	if (my_id < _rtc_peers.keys().min()):
		emit_signal("on_start_game_for_host")
	pass # Replace with function body.

@rpc("any_peer", "call_local", "reliable")
func StartGame():
	var scene = load("res://level_01.tscn").instantiate()
	get_tree().root.add_child(scene)
