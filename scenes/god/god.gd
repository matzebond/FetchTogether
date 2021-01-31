extends StaticBody2D

const DropZone = preload("res://scenes/god/dropZone.tscn")

var drop_zones = []

func _ready():
    call_deferred("after_ready")

func after_ready():
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
        add_child(drop_zone)
        drop_zone.position = Vector2(0, radius).rotated(phi)
        drop_zone.category = category
        drop_zone.connect("item_changed", self, "_on_dropZone_item_changed")
        
        
        drop_zones.append(drop_zone)
        
        phi += d_phi

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
        
    for player in get_tree().get_nodes_in_group("player"):
        player.teleport_to_spawn_pos()

func get_center()->Vector2:
    return global_position
    
    
