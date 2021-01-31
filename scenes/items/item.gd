extends Node2D

onready var tween:Tween = $Tween

export(Array, G.ItemCategory) var item_categories = []
export var knockback_amplify = 1

func _ready():
    if has_node("AnimationPlayer"):
        $AnimationPlayer.play("anim")
    
    $animSprite.material = $animSprite.material.duplicate()
    $animSprite.playing = true

func tween_to(pos:Vector2, global=true):
    var prop = "global_position" if global else "position"
    tween.interpolate_property(self, prop, null, pos, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT)
    tween.start()

var active = false
func set_highlight(active:bool):
    if self.active != active:
        $ShaderAnimator.play("start" if active else "end")
        self.active = active

var disabled = false
func disable():
    $pickupArea.monitorable = false
    $pickupArea.monitoring = false
    disabled = true
    
