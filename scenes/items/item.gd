extends Node2D

func _ready():
    if has_node("AnimationPlayer"):
        $AnimationPlayer.play("animation")
    
    $animSprite.material = $animSprite.material.duplicate()

var active = false
func set_highlight(active:bool):
    if self.active != active:
        $ShaderAnimator.play("start" if active else "end")
        self.active = active
