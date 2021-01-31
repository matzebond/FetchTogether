extends Node2D

onready var tween:Tween = $Tween

remotesync func receive_item(item_path):
    if !has_node(item_path): return
    
    var item = get_node(item_path)

    tween.interpolate_property(item, "global_position", null, global_position, 0.4)
    tween.start()
    
