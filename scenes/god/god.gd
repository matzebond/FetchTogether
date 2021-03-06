extends StaticBody2D

const DropZone = preload("res://scenes/god/dropZone.tscn")

var drop_zones = []

func _ready():
    call_deferred("start")


var drop_zone_id = 0
func start():
    var num_players = get_tree().get_nodes_in_group("player").size()

    var taken_categories = []
    var d_phi = 2 * PI / num_players
    var phi = 0
    var radius = 130 + num_players*5
    for i in range(num_players):
        # Try to select unique categories, only repeat when not enough categories
        var category = null
        while category == null or (category in taken_categories and i < G.get_item_category_num()):
            category = G.get_random_item_category()
        taken_categories.append(category)

        # Initialize DropZone
        var drop_zone = DropZone.instance()
        drop_zone.name = "drop_zone_" + str(drop_zone_id)
        drop_zone_id += 1
        add_child(drop_zone)
        drop_zone.position = Vector2(0, radius).rotated(phi)
        drop_zone.category = category
        drop_zone.connect("item_changed", self, "_on_dropZone_item_changed")

        drop_zones.append(drop_zone)

        phi += d_phi

    start_revealing_categories()

    for player in get_tree().get_nodes_in_group("player"):
        player.zoom_out_camera()


func _on_dropZone_item_changed():
    if is_network_master():
        # Return if any drop zone not taken
        for drop_zone in drop_zones:
            if !drop_zone.has_item():
                return
        rpc("end_level")

remotesync func end_level():

    # Disable items
    for drop_zone in drop_zones:
        if drop_zone.has_item():
           drop_zone.current_item.disable()

    # Start player teleportation
    for player in get_tree().get_nodes_in_group("player"):
        player.teleport_to_spawn_pos()
    
    var ghost_ant = get_tree().get_nodes_in_group("ghost_ant")[0]    
    ghost_ant.set_active(false)
    ghost_ant.level += 1
    
    start_showing_score()

func get_center()->Vector2:
    return global_position

func set_players_enable_walk(enable:bool):
    for player in get_tree().get_nodes_in_group("player"):
        player.enable_walk = enable

var next_reveal_drop_zone_id
func start_revealing_categories():
    next_reveal_drop_zone_id = -1
    $CategoryRevealTimer.start()

func _on_CategoryRevealTimer_timeout():
    # Cancel on end, allow Players to walk
    if next_reveal_drop_zone_id >= drop_zones.size():
        $CategoryRevealTimer.stop()

        for player in get_tree().get_nodes_in_group("player"):
            player.zoom_out_camera(false)
            set_players_enable_walk(true)
            
        var ghost_ant = get_tree().get_nodes_in_group("ghost_ant")[0]    
        ghost_ant.set_active(true)
            
        for ui in get_tree().get_nodes_in_group("ui"):
            ui.resetTime()
        return
    
    if next_reveal_drop_zone_id == -1:
        $FetchME.play()
        
    # First iteration is -1
    if next_reveal_drop_zone_id >= 0:
        drop_zones[next_reveal_drop_zone_id].play_category_reveal_animation()
    next_reveal_drop_zone_id += 1

var next_score_drop_zone_id
func start_showing_score():
    next_score_drop_zone_id = -1
    $ScoreShowTimer.start(3.2)

func _on_ScoreShowTimer_timeout():
    # On first iteration
    if next_score_drop_zone_id == -1:
        $ScoreShowTimer.stop()
        for player in get_tree().get_nodes_in_group("player"):
            player.zoom_out_camera()
        $ScoreShowTimer.start(1.5)
    # On second to last iteration
    elif next_score_drop_zone_id == drop_zones.size():
        pass # wait one
    # On last iteration
    elif next_score_drop_zone_id == drop_zones.size() + 1:
        restart()
        $ScoreShowTimer.stop()
    # Shouldn't happen
    elif next_score_drop_zone_id > drop_zones.size() + 1:
        $ScoreShowTimer.stop()
    # On iteration
    else:
        drop_zones[next_score_drop_zone_id].play_score_animation()
    next_score_drop_zone_id += 1

func restart():
    for drop_zone in drop_zones:
        drop_zone.clear_and_free()
    drop_zones = []

    start()
