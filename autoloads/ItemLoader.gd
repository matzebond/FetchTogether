tool
extends Node

const ITEM_SCENE_PATH = "res://scenes/items/"
const ITEM_MAIN_SCENE = "item.tscn"
var item_scenes = []

func _ready():
    
    
    # Gather item paths
    var item_paths = []
    var dir = Directory.new()
    if dir.open(ITEM_SCENE_PATH) == OK:
        dir.list_dir_begin()
        var file_name:String = dir.get_next()
        while file_name != "":
            if !dir.current_is_dir() and file_name != ITEM_MAIN_SCENE and file_name.ends_with(".tscn"):
                item_paths.append(file_name)
            file_name = dir.get_next()
    else:
        printerr("Room: Could not iterate " + ITEM_SCENE_PATH)
        
    # SORT and load item scenes
    item_paths.sort()
    item_scenes = []
    for path in item_paths:
        item_scenes.append(load(ITEM_SCENE_PATH + path))
        

func are_items_loaded():
    return item_scenes.size() > 0
    
func get_random_item_scene():
    var item_id = Rand.randi() % item_scenes.size()
    return item_scenes[item_id]
    
