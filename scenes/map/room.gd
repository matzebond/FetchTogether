tool
extends Node2D

enum Orientation {
    N, E, S, W
}

export(Orientation) var orientation = Orientation.E setget _set_orientation

const ITEM_SCENE_PATH = "res://scenes/items/"
const ITEM_MAIN_SCENE = "item.tscn"
var item_scenes = []

func _ready():
    $TileMapOriginal.visible = false
    $TileMapRotated.visible = true
    
    # Delete original map only in game!!!
    if !Engine.editor_hint:
        $TileMapOriginal.queue_free()
    
    # Preload items
    item_scenes = []
    var dir = Directory.new()
    if dir.open(ITEM_SCENE_PATH) == OK:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if !dir.current_is_dir() and file_name != ITEM_MAIN_SCENE:
                item_scenes.append(load(ITEM_SCENE_PATH + file_name))
            file_name = dir.get_next()
    else:
        printerr("Room: Could not iterate " + ITEM_SCENE_PATH)

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
    if item_scenes.size() > 0:
        for cell in mapItemSpawnPoints.get_used_cells():
            var cell_rotated = rotate_map_pos(cell, orientation)
            
            # TODO no duplicates
            var item_id = Rand.randi() % item_scenes.size()
            var item = item_scenes[item_id].instance()
            
            # Set pos and add to scene
            item.position = mapRotated.map_to_world(cell_rotated) + cellSize / 2.0
            itemRoot.add_child(item)
    else:
        print("Room: Could not spawn Items into room, there are none loaded")


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

