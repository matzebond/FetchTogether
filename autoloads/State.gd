extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567


const USE_WEBSOCKET = true

# Max number of players.
const MAX_PEERS = 12

var peer = null

# Name for my player.
var player_name = "The Warrior"
var true_player = true

# Names for remote players in id:name format.
var players = {}
var players_ready = []
remote var leader = null

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree.
func _player_connected(id):
    # Registration of a client beings here, tell the connected player that we are here.
    if true_player:
        rpc_id(id, "register_player", player_name)
        
    # send leader id to connected players
    if get_tree().is_network_server():
        if not leader:
            leader = id
        rset_id(id, "leader", leader)


# Callback from SceneTree.
func _player_disconnected(id):
    print("Player " + players[id] + " disconnected")
    
    if has_node("/root/World"): # Game is in progress.
        unregister_player(id)
        if len(players) == 0:
            emit_signal("game_error", "All other Players disconnected")
            end_game()
    else: # Game is not in progress.
        # Unregister this player.
        unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
    # We just connected to a server
    emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
    emit_signal("game_error", "Server disconnected")
    end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
    peer = null
    get_tree().set_network_peer(null) # Remove peer
    emit_signal("connection_failed")
    if OS.get_name() == "HTML5": # I think Web is not happy when failing
        get_tree().quit()


# Lobby management functions.

remote func register_player(new_player_name):
    var id = get_tree().get_rpc_sender_id()
    players[id] = new_player_name
    print("Player " + players[id] + " connected")
    emit_signal("player_list_changed")


func unregister_player(id):
    players.erase(id)
    emit_signal("player_list_changed")


remote func pre_start_game(spawn_points, new_seed):
    Rand.set_seed(new_seed)
    
    # Change scene.
    var world = load("res://scenes/screens/world.tscn").instance()
    get_tree().get_root().add_child(world)

    get_tree().get_root().get_node("Lobby").hide()

    var player_scene = load("res://scenes/player/player.tscn")


    var d_phi = 2 * PI / spawn_points.size()
    var phi = 0
    var radius = 260 + spawn_points.size()*7
    for p_id in spawn_points:
        
        var player = player_scene.instance()
        
        player.set_name(str(p_id)) # Use unique ID as node name.
        player.position = get_tree().get_nodes_in_group("god")[0].position + Vector2(0, radius).rotated(phi)
        player.spawn_pos = player.position
        player.set_network_master(p_id) #set unique id as master.

        if p_id == get_tree().get_network_unique_id():
            # If node for this peer id, set name.
            player.set_player_name(player_name)
        else:
            # Otherwise set name from peer.
            player.set_player_name(players[p_id])
        
        get_tree().get_nodes_in_group("ysort")[0].add_child(player)
        
        phi += d_phi

    if not get_tree().is_network_server():
        # Tell server we are ready to start.
        rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
    elif players.size() == 0:
        post_start_game()


remote func post_start_game():
    get_tree().set_refuse_new_network_connections(true)
    get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id):
    assert(get_tree().is_network_server())

    if not id in players_ready:
        players_ready.append(id)

    if players_ready.size() == players.size():
        for p in players:
            rpc_id(p, "post_start_game")
        post_start_game()


func host_game(new_player_name):
    player_name = new_player_name

    if USE_WEBSOCKET:
        peer = WebSocketServer.new();
        peer.listen(DEFAULT_PORT, PoolStringArray(), true);
    else:
        peer = NetworkedMultiplayerENet.new()
        peer.create_server(DEFAULT_PORT, MAX_PEERS)
    get_tree().set_network_peer(peer);
    
    if true_player:
        leader = 1

    
func join_game(ip, new_player_name):
    player_name = new_player_name
    
    if USE_WEBSOCKET:
        print("try join websocket")
        peer = WebSocketClient.new();
        var url = "wss://maschm.de/FetchTogether/ws"
        if ip:
            url = "ws://%s:%d" % [ip, DEFAULT_PORT]
        var error = peer.connect_to_url(url, PoolStringArray(), true);
        if error:
            emit_signal("game_error", "Websocket connection error(%d)" % error )
            print("websocket connection error", error)
            get_tree().quit()
    else:
        peer = NetworkedMultiplayerENet.new()
        peer.create_client(ip, DEFAULT_PORT)
    get_tree().set_network_peer(peer)


func get_player_list():
    return players.values()


func get_player_name():
    return player_name


remote func begin_game():
    if not get_tree().is_network_server():
        rpc_id(1, "begin_game")
        return
        
    if get_tree().get_rpc_sender_id() != leader:
        print("%s is trying to start the game bus is not the leader" % players[get_tree().get_rpc_sender_id()])
        return
    
    print("Beginning new game")
    
    # Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
    var spawn_points = {}
    var spawn_point_idx = 0
    
    if true_player: # TODO flag for adding server to players
        spawn_points[1] = spawn_point_idx # Server in spawn point 0.
        spawn_point_idx += 1

    for p in players:
        spawn_points[p] = spawn_point_idx
        spawn_point_idx += 1
    # Call to pre-start game with the spawn points.
    
    randomize() # seed
    var new_seed = randi()
    for p in players:
        rpc_id(p, "pre_start_game", spawn_points, new_seed)

    pre_start_game(spawn_points, new_seed)


func end_game():
    if has_node("/root/World"): # Game is in progress.
        # End it
        get_node("/root/World").queue_free()
    emit_signal("game_ended")
    players.clear()
    players_ready.clear()
    leader = null
    get_tree().set_refuse_new_network_connections(false)


func _ready():
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")
    
    if "--server" in OS.get_cmdline_args():
        true_player = false
        print("Headless server started")
        host_game("Server")

func _process(delta):
    if peer and get_tree().is_network_server():
        peer.poll();

    if peer and not get_tree().is_network_server() and (peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED ||
        peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
        peer.poll();
        
    if has_node("/root/World") and (!peer or peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED):
        emit_signal("game_error", "Got disconnected")
        end_game()
