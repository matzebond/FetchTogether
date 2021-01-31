extends CanvasLayer

const TIME = 30.0

var score_value = 0

onready var timer = $timer 
onready var time_left = $VContainer/HContainerTime/timeLeft
onready var score_label = $VContainer/HContainerScore/score

func _ready():
    time_left.text = str(TIME)

func _process(delta):
    score_label.text = str(score_value)
    if !timer.is_stopped():
        time_left.text = str(round(timer.time_left))
        
func addPoint():
    score_value += 1
    
func resetTime():
    timer.start(TIME)
