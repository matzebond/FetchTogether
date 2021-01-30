extends KinematicBody2D

onready var front_root = $frontRoot
onready var sprite_anim = $spriteAnim
onready var camera = $camera
onready var world = get_node("/root/World")

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()

const MOTION_SPEED = 220.0

var current_anim = ""
var current_item

func _ready():
    puppet_pos = position
    
    var id = self.get_index() + 1
    var frames = load("res://assets/char/player" + str(id) +".tres")
    sprite_anim.set_sprite_frames(frames)

func _process(delta):
    if is_network_master():
        if Input.is_action_just_released("interact"):
            if !current_item:
                var item = get_closest_in(items_in_range)
                if item:
                    rpc("pickup_item",item.get_path())
            else:
                var item = current_item
                rpc("drop_item")
                
                var drop_zone = get_closest_in(drop_zones_in_range)
                if drop_zone:
                    drop_zone.rpc("receive_item", item.get_path())

func _physics_process(_delta):
    var motion = Vector2()

    if is_network_master():
        camera.current = true

        if Input.is_action_pressed("move_left"):
            motion += Vector2(-1, 0)
        if Input.is_action_pressed("move_right"):
            motion += Vector2(1, 0)
        if Input.is_action_pressed("move_up"):
            motion += Vector2(0, -1)
        if Input.is_action_pressed("move_down"):
            motion += Vector2(0, 1)

        rset("puppet_motion", motion)
        rset("puppet_pos", position)
    else:
        position = puppet_pos
        motion = puppet_motion

    var new_anim = null
    if motion.y < 0:
        new_anim = "walk_up"
        front_root.position = Vector2(0, -70)
    elif motion.y > 0:
        new_anim = "walk_down"
        front_root.position = Vector2(0, 70)
    elif motion.x < 0:
        new_anim = "walk_side"
        front_root.position = Vector2(-70, 0)
        sprite_anim.flip_h = false
    elif motion.x > 0:
        new_anim = "walk_side"
        front_root.position = Vector2(70, 0)
        sprite_anim.flip_h = true

    if new_anim and new_anim != current_anim:
        current_anim = new_anim
        sprite_anim.play(new_anim)
    
    var is_walking = motion != Vector2.ZERO
    sprite_anim.speed_scale = 1 if is_walking else 0
    if !is_walking:
        sprite_anim.frame = 0

    move_and_slide(motion * MOTION_SPEED)
    if not is_network_master():
        puppet_pos = position # To avoid jitter

func set_player_name(new_name):
    get_node("label").set_text(new_name)

var items_in_range = []
var drop_zones_in_range = []
func _on_ItemPickup_area_entered(area):
    if area in get_tree().get_nodes_in_group("item"):
        items_in_range.append(area.get_parent())
    if area in get_tree().get_nodes_in_group("drop_zone"):
        drop_zones_in_range.append(area.get_parent())

func _on_ItemPickup_area_exited(area):
    if area in get_tree().get_nodes_in_group("item"):
        items_in_range.erase(area.get_parent())
    if area in get_tree().get_nodes_in_group("drop_zone"):
        drop_zones_in_range.erase(area.get_parent())
    
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
    
remotesync func drop_item():
    var item = current_item
    front_root.remove_child(item)
    world.add_child(item)
    current_item = null
    item.position = position + front_root.position
    

func get_closest_in(arr:Array):
    if arr.size() == 0:
        return
    else:
        arr.sort_custom(self, "sort_by_distance")
        return arr[0];

func distanceTo(targetNode):
    var a = Vector2(targetNode.position - position)
    return sqrt((a.x * a.x) + (a.y * a.y))
        
func sort_by_distance(a, b):
    return distanceTo(a) < distanceTo(b)
