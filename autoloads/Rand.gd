tool
extends Node

var _rng:RandomNumberGenerator

func _ready():
    _rng = RandomNumberGenerator.new()
    _rng.seed = 0
    
func randf()->float:
    return _rng.randf()
func randi()->int:
    return _rng.randi()

remotesync func set_seed(seeed):
    _rng.seed = seeed
