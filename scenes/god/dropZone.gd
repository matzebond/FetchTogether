extends Node2D



remotesync func receive_item(item_path):
    if !has_node(item_path): return
    
    var item = get_node(item_path)
    item.tween_to(global_position)
    
    
    
