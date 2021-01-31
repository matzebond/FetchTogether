tool
extends Node2D



onready var orientation_to_node = {
    G.Orientation.N : $N,
    G.Orientation.E : $E,
    G.Orientation.S : $S,
    G.Orientation.W : $W    
}

func addToMap(orientation, map:TileMap, nodeRoot:Node2D, pos:Vector2, id):
    var tileSize = map.cell_size
    
    var node = orientation_to_node[orientation]
    var tileMap:TileMap = node.get_node("TileMap")
    var spawnPositions = node.get_node("YSort/ItemSpawnPositions")
    var furniture = node.get_node("YSort/Furniture")
    var door = node.get_node("Door")
    
    #Add door
    node.remove_child(door)
    nodeRoot.add_child(door)
    door.position = pos * tileSize + door.position
    door.set_collision_mask_bit(id + 1, false)
    door.set_collision_layer_bit(id + 1, false)
    
    # Transfer tiles
    for cell in tileMap.get_used_cells():
        map.set_cellv(pos + cell, tileMap.get_cellv(cell))
    
    # Spawn Items 
    if ItemLoader.are_items_loaded():
        for spawnPt in spawnPositions.get_children():
            # TODO no duplicates
            var item = ItemLoader.get_random_item_scene().instance()
            
            # Set pos and add to scene
            item.position = pos * tileSize + spawnPt.position
            nodeRoot.add_child(item)
    else:
        print("Room: Could not spawn Items into room, there are none loaded")
        
    # Move furniture
    for f in furniture.get_children():
        furniture.remove_child(f)
        nodeRoot.add_child(f)
        f.position = pos * tileSize + f.position
