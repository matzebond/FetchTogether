extends StaticBody2D

const DropZone = preload("res://scenes/god/dropZone.tscn")

func _ready():
    call_deferred("after_ready")

func after_ready():
    var num_players = get_tree().get_nodes_in_group("player").size()
    num_players = 10
    
    var taken_categories = []
    
    var d_phi = 2 * PI / num_players
    var phi = 0
    var radius = 130 + num_players*5
    for i in range(num_players):
        var drop_zone = DropZone.instance()
        add_child(drop_zone)
        drop_zone.position = Vector2(0, radius).rotated(phi)
        
        # Try to select unique categories, only repeat when not enough categories
        var category = null
        while category == null or (category in taken_categories and i < G.get_item_category_num()):
            category = G.get_random_item_category()
        taken_categories.append(category)
        
        drop_zone.category = category
        
        
        phi += d_phi
    
    
