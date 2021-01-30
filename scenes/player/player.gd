extends KinematicBody2D

const MOTION_SPEED = 90.0

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()

export var stunned = false

onready var front_root = $frontRoot

# Use sync because it will be called everywhere
sync func setup_bomb(bomb_name, pos, by_who):
    var bomb = preload("res://scenes/player/bomb.tscn").instance()
    bomb.set_name(bomb_name) # Ensure unique name for the bomb
    bomb.position = pos
    bomb.from_player = by_who
    # No need to set network master to bomb, will be owned by server by default
    get_node("../..").add_child(bomb)

var current_anim = ""
var prev_bombing = false
var bomb_index = 0
var current_item

func _process(delta):
    if is_network_master():
        if Input.is_action_just_released("interact") && !current_item:
            var item = get_closest_item()
            if item:
                rpc("pickup_item",item.get_path())

func _physics_process(_delta):
    var motion = Vector2()

    if is_network_master():
        $camera.current = true

        if Input.is_action_pressed("move_left"):
            motion += Vector2(-1, 0)
        if Input.is_action_pressed("move_right"):
            motion += Vector2(1, 0)
        if Input.is_action_pressed("move_up"):
            motion += Vector2(0, -1)
        if Input.is_action_pressed("move_down"):
            motion += Vector2(0, 1)

        var bombing = Input.is_action_pressed("set_bomb")

        if stunned:
            bombing = false
            motion = Vector2()

        if bombing and not prev_bombing:
            var bomb_name = get_name() + str(bomb_index)
            var bomb_pos = position
            rpc("setup_bomb", bomb_name, bomb_pos, get_tree().get_network_unique_id())

        prev_bombing = bombing

        rset("puppet_motion", motion)
        rset("puppet_pos", position)
    else:
        position = puppet_pos
        motion = puppet_motion

    var new_anim = "standing"
    if motion.y < 0:
        new_anim = "walk_up"
        front_root.position = Vector2(0, -70)
    elif motion.y > 0:
        new_anim = "walk_down"
        front_root.position = Vector2(0, 70)
    elif motion.x < 0:
        new_anim = "walk_left"
        front_root.position = Vector2(-70, 0)
    elif motion.x > 0:
        new_anim = "walk_right"
        front_root.position = Vector2(70, 0)
    if stunned:
        new_anim = "stunned"
        

    if new_anim != current_anim:
        current_anim = new_anim
        $spriteAnim.play(new_anim)

    move_and_slide(motion * MOTION_SPEED)
    if not is_network_master():
        puppet_pos = position # To avoid jitter

puppet func stun():
    stunned = true

master func exploded(_by_who):
    if stunned:
        return
    rpc("stun") # Stun puppets
    stun() # Stun master - could use sync to do both at once

func set_player_name(new_name):
    get_node("label").set_text(new_name)

func _ready():
    stunned = false
    puppet_pos = position

var items_in_range = []
func _on_ItemPickup_area_entered(area):
    if area in get_tree().get_nodes_in_group("item"):
        items_in_range.append(area.get_parent())
    print(items_in_range)

func _on_ItemPickup_area_exited(area):
    if area in get_tree().get_nodes_in_group("item"):
        items_in_range.erase(area.get_parent())
    print(items_in_range)
    
remotesync func pickup_item(item_path):
    var item = get_node(item_path)
    var parent = item.get_parent()
    
    # reset parent
    if parent.get_parent().get("current_item") == item:
        parent.get_parent().current_item = null

    current_item = item
    items_in_range.erase(item)
    parent.remove_child(item)
    front_root.add_child(item)
    item.position = Vector2(0, 0)

func get_closest_item():
    if items_in_range.size() == 0:
        return
    else:
        items_in_range.sort_custom(self, "sort_by_distance")
        return items_in_range[0];

func distanceTo(targetNode):
    var a = Vector2(targetNode.position - puppet_pos)
    return sqrt((a.x * a.x) + (a.y * a.y))
        
func sort_by_distance(a, b):
    return distanceTo(a) > distanceTo(b)
