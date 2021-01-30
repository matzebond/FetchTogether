extends StaticBody2D

const DropZone = preload("res://scenes/god/dropZone.tscn")

func _ready():
    call_deferred("after_ready")

func after_ready():
    var num_players = get_tree().get_nodes_in_group("player").size()
    
    var d_phi = 2 * PI / num_players
    var phi = 0
    var radius = 130 + num_players*5
    for i in range(num_players):
        var drop_zone = DropZone.instance()
        add_child(drop_zone)
        drop_zone.position = Vector2(0, radius).rotated(phi)
        
        phi += d_phi
