extends Node2D

var current_item = null

remotesync func receive_item(item_path):
    if !has_node(item_path): return
    
    var item = get_node(item_path)
    
    var pos = item.global_position
    item.get_parent().remove_child(item)
    $ItemRoot.add_child(item)
    item.global_position = pos
    
    item.tween_to(global_position + Vector2(0, 32))
    
    if current_item:
        pos = current_item.global_position
        $ItemRoot.remove_child(current_item)
        get_tree().get_nodes_in_group("ysort")[0].add_child(current_item)
        current_item.global_position = pos
        current_item.tween_to(global_position + position)
        
    current_item = item
    
    
    
