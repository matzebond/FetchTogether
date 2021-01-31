tool
extends StaticBody2D

export var flip_h = false setget _set_flip_h
export var flip_v = false setget _set_flip_v

func _ready():
    _set_flip_h(flip_h)
    _set_flip_v(flip_v)

func _set_flip_v(v):
    flip_v = v
    if is_inside_tree():
        $Sprite.flip_v = v
    
func _set_flip_h(v):
    flip_h = v
    if is_inside_tree():
        $Sprite.flip_h = v
