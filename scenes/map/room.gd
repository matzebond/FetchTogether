tool
extends Node2D

enum Orientation {
    N, E, S, W
}

export(Orientation) var orientation = Orientation.E setget _set_orientation

func _ready():
    $TileMapOriginal.visible = false
    $TileMapRotated.visible = true
    
    # Delete original map only in game!!!
    if !Engine.editor_hint:
        $TileMapOriginal.queue_free()
    
    _set_orientation(orientation)
        

func _set_orientation(v):
    orientation = v
    
    if !is_inside_tree(): return
    
    var mapOriginal:TileMap = $TileMapOriginal
    var mapRotated:TileMap = $TileMapRotated
    
    mapRotated.clear();
    
    for cell in mapOriginal.get_used_cells():
        var cell_rotated
        match orientation:
            Orientation.N:
                cell_rotated = Vector2(cell.y, cell.x)
            Orientation.E:
                cell_rotated = cell
            Orientation.S:
                cell_rotated = Vector2(cell.y, -cell.x)
            Orientation.W:
                cell_rotated = Vector2(-cell.x, cell.y)
        
        mapRotated.set_cellv(cell_rotated, mapOriginal.get_cellv(cell))
