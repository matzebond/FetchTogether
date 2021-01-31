
extends Node2D


var time = 0



enum Phase {
    ChaseUp,
    ChaseDown    
}

var t = 0
export(Phase) var phase = Phase.ChaseDown

export var level = 0

export var active = false
func set_active(active):
    self.active = active
    if !active:
        phase = Phase.ChaseDown

func _ready():
    call_deferred("select_next_target")

var target_id = -1
var target = null
func select_next_target():
    var targets = get_tree().get_nodes_in_group("player")
    
    if targets.size() > 0:
        target_id = (target_id + 1) % (targets.size())
        target = targets[target_id]
    else:
        target = null
    
    

func _process(delta):
    time += delta
    
    
    var timeScale = 1 + 0.2 * level
    
    var posRandom = Vector2(0, -64*6)
    for i in range(1,5):
        posRandom += 140 * i * Vector2(sin(timeScale * time / (3 * i) + i), cos(timeScale * time / (2 * i)  + i))
    $AnimatedSprite.speed_scale = timeScale
    
    
    if phase == Phase.ChaseUp:
        t += 0.1 * delta * timeScale
        if t >= 1.3:
            phase = Phase.ChaseDown
            select_next_target()
    if phase == Phase.ChaseDown:
        t -= 0.1 * delta * timeScale
        if t <= -0.3 and active:
            phase = Phase.ChaseUp
    
    var t_cap = min(0.92 + 0.03 * level, 1)
    var fair_t = max(min(t, t_cap), 0)
    
    if target:
        var posTarget = target.position
        position = (1 - fair_t) * posRandom + fair_t * posTarget
    else:
        position = posRandom
        
func get_center():
    return $Center.global_position
