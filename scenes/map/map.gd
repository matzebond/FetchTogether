tool
extends Node2D

const MIN_MAIN_ROOM_SIZE = Vector2(11, 11) # (odd, odd)!
const ROOM_DST = 14 # even!
const MAIN_ROOM_WIDTH_EXPAND_PER_SIDE_ROOMS = 2 # even!
const Room = preload("res://scenes/map/room.tscn")
export var player_num_debug = 8 setget _set_player_num_debug

func _ready():
    call_deferred("afterReady")

func afterReady():
    if !is_inside_tree(): return
    
    var playerNum = get_tree().get_nodes_in_group("player").size()
    
    if playerNum == 0:
        playerNum = player_num_debug
    
    
    var main_room_size = MIN_MAIN_ROOM_SIZE
    main_room_size += Vector2(0, ROOM_DST) * max(0, ceil((playerNum - 4) / 2.0))
    
    var roomsOnEachSide = int(ceil((playerNum - 1) / 2))
    
    main_room_size.x += MAIN_ROOM_WIDTH_EXPAND_PER_SIDE_ROOMS * roomsOnEachSide
    
    var map:TileMap = $TileMap
    map.clear()
    
    var tileSize = map.cell_size
    var tile = map.tile_set.find_tile_by_name("autotile_wall")
    
    # Generate basic main room rectangle
    var posStart = Vector2(-floor(main_room_size.x / 2), -floor(main_room_size.y / 2))
    for y in range(main_room_size.y):
        for x in range(main_room_size.x):            
            map.set_cell(posStart.x + x, posStart.y + y, tile)
    
    
    # Gather room info
    var protoRoom = Room.instance()
    var rooms = []
    if playerNum >= 1:
        rooms.append([Vector2(0, posStart.y-1), protoRoom.Orientation.S])
    if playerNum >= 2:
        rooms.append([Vector2(0, posStart.y+main_room_size.y), protoRoom.Orientation.N])
    
    var yStart = -(roomsOnEachSide - 1) * ROOM_DST
    yStart = -main_room_size.y/2 + ROOM_DST/2 - 1
    for i in range(2, playerNum):
        var x = ceil(main_room_size.x / 2) 
        var orientation = protoRoom.Orientation.E
        
        var y = floor((i - 2) / 2) * ROOM_DST
        
        if i % 2 == 1:
            x = -x
            orientation = protoRoom.Orientation.W
            
        rooms.append([Vector2(x, floor(yStart+y)), orientation])

    # Spawn new rooms
    for roomInfo in rooms:
        var room = Room.instance()
        room.orientation = roomInfo[1]
        add_child(room)
        room.addToMap(map, $ItemRoot, roomInfo[0])
        room.queue_free()
    
    map.update_bitmask_region()
    
    var i = 0
    for item in $ItemRoot.get_children():
        item.name = "item_" + str(i)
        i += 1
        
    
    protoRoom.queue_free()
            
func _set_player_num_debug(v):
    player_num_debug = v;
    afterReady()
    
