tool
extends Node2D

const MIN_MAIN_ROOM_SIZE = Vector2(17, 11) # (odd, odd)!
const ROOM_DST = 14 # even!
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
    var roomRoot = $Rooms
    
    var map:TileMap = $TileMap
    map.clear()
    
    var tileSize = map.cell_size
    var tileWall = map.tile_set.find_tile_by_name("wall")
    var tileFloor = map.tile_set.find_tile_by_name("floor")
    
    # Generate basic main room rectangle
    var posStart = Vector2(-floor(main_room_size.x / 2), -floor(main_room_size.y / 2))
    for y in range(main_room_size.y):
        
        for x in range(main_room_size.x):
            
            var tile = tileFloor
            if y == 0 or x == 0 or y == main_room_size.y-1 or x == main_room_size.x-1:
                tile = tileWall
            
            map.set_cell(posStart.x + x, posStart.y + y, tile)
    
    # Gather room info
    var protoRoom = Room.instance()
    var rooms = []
    if playerNum >= 1:
        rooms.append([Vector2(0, posStart.y-1), protoRoom.Orientation.S])
    if playerNum >= 2:
        rooms.append([Vector2(0, posStart.y+main_room_size.y), protoRoom.Orientation.N])
    
    
    var roomsOnEachSide = int(ceil((playerNum - 1) / 2))
    
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
    
    # Remove previous rooms
    for prevRoom in roomRoot.get_children():
        prevRoom.queue_free()
    

    # Spawn new rooms
    for roomInfo in rooms:
        var room = Room.instance()
        room.orientation = roomInfo[1]
        room.position = tileSize * roomInfo[0]
        roomRoot.add_child(room)
        
        match roomInfo[1]:
            room.Orientation.S:
                map.set_cellv(roomInfo[0] + Vector2(-1, 1), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(0, 1), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(1, 1), tileFloor)
            room.Orientation.N:
                map.set_cellv(roomInfo[0] + Vector2(-1, -1), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(0, -1), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(1, -1), tileFloor)
            room.Orientation.W:
                map.set_cellv(roomInfo[0] + Vector2(1, -1), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(1, 0), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(1, 1), tileFloor)
            room.Orientation.E:
                map.set_cellv(roomInfo[0] + Vector2(-1, -1), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(-1, 0), tileFloor)
                map.set_cellv(roomInfo[0] + Vector2(-1, 1), tileFloor)
        
    protoRoom.queue_free()
            
func _set_player_num_debug(v):
    player_num_debug = v;
    afterReady()
    
