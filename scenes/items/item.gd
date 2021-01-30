extends Node2D

func _ready():
    if has_node("AnimationPlayer"):
        $AnimationPlayer.play("animation")
