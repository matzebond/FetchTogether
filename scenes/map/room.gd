tool
extends Node2D

enum Orientation {
    N, E, S, W
}

export(Orientation) var orientation = Orientation.E setget _set_orientation


func _ready():
    $TileMapOriginal.visible = false
    $TileMapRotated.visible = true
    
    _set_orientation(orientation)
    
    
func _set_orientation(v):
    orientation = v
    
    if !is_inside_tree(): return
    
    var mapOriginal:TileMap = $TileMapOriginal
    var mapRotated:TileMap = $TileMapRotated
    var mapItemSpawnPoints:TileMap = $TileMapItemSpawnPoints
    
    var itemRoot:Node2D = $Items
    
    var cellSize = mapOriginal.cell_size
    
    # Clear all previous data
    mapRotated.clear()
    for item in itemRoot.get_children():
        item.queue_free()
    
    # Rotate tilemap
    for cell in mapOriginal.get_used_cells():
        var cell_rotated = rotate_map_pos(cell, orientation)
        mapRotated.set_cellv(cell_rotated, mapOriginal.get_cellv(cell))
    
    # Rotate and create spawn points
    if ItemLoader.are_items_loaded():
        for cell in mapItemSpawnPoints.get_used_cells():
            var cell_rotated = rotate_map_pos(cell, orientation)
            
            # TODO no duplicates
            var item = ItemLoader.get_random_item_scene().instance()
            
            # Set pos and add to scene
            item.position = mapRotated.map_to_world(cell_rotated) + cellSize / 2.0
            itemRoot.add_child(item)
    else:
        print("Room: Could not spawn Items into room, there are none loaded")
    
    mapRotated.update_bitmask_region()

func addToMap(map:TileMap, itemRoot:Node2D, pos:Vector2):
    var mapRotated:TileMap = $TileMapRotated
    for cell in mapRotated.get_used_cells():
        map.set_cellv(pos + cell, mapRotated.get_cellv(cell))
    
    var tileSize = map.cell_size
    for item in $Items.get_children():
        #var itemPos = item.global_position
        $Items.remove_child(item)
        itemRoot.add_child(item)
        item.position += pos * tileSize
        #item.global_position = itemPos
        

func rotate_map_pos(map_pos:Vector2, orientation):
    match orientation:
        Orientation.N:
            return Vector2(map_pos.y, map_pos.x)
        Orientation.E:
            return map_pos
        Orientation.S:
            return Vector2(map_pos.y, -map_pos.x)
        Orientation.W:
            return Vector2(-map_pos.x, map_pos.y)

