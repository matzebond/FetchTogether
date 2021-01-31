extends KinematicBody2D

onready var front_root = $YSort/frontRoot
onready var sprite_anim = $YSort/spriteAnim
onready var camera = $camera
onready var world = get_node("/root/World")
onready var tween:Tween = $Tween

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
                rpc("drop_item", item.get_path(), front_root.global_position)
                
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
    var front_root_pos = front_root.position
    if motion.y < 0:
        new_anim = "walk_up"
        front_root_pos = Vector2(0, -88)
    elif motion.y > 0:
        new_anim = "walk_down"
        front_root_pos = Vector2(0,52)
    elif motion.x < 0:
        new_anim = "walk_side"
        front_root_pos = Vector2(-70, -18)
        sprite_anim.flip_h = false
    elif motion.x > 0:
        new_anim = "walk_side"
        front_root_pos = Vector2(70, -18)
        sprite_anim.flip_h = true
        
    if front_root_pos != front_root.position:
        tween.interpolate_property(front_root, "position", null, front_root_pos, 0.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
        tween.start()

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
    if area.get_parent() in get_tree().get_nodes_in_group("item"):
        items_in_range.append(area.get_parent())
        update_item_highlights()
    if area in get_tree().get_nodes_in_group("drop_zone"):
        drop_zones_in_range.append(area.get_parent())

func _on_ItemPickup_area_exited(area):
    if area in get_tree().get_nodes_in_group("item"):
        items_in_range.erase(area.get_parent())
        update_item_highlights()
    if area in get_tree().get_nodes_in_group("drop_zone"):
        drop_zones_in_range.erase(area.get_parent())

var cur_highlighted_item = null
func update_item_highlights():
    if current_item:
        if cur_highlighted_item != current_item:
            cur_highlighted_item.set_highlight(false)
        current_item.set_highlight(true)
        return
    
    var closest = get_closest_in(items_in_range)
    
    if cur_highlighted_item and cur_highlighted_item != closest:
        cur_highlighted_item.set_highlight(false)
    
    if closest and cur_highlighted_item != closest:
        closest.set_highlight(true)
    
    cur_highlighted_item = closest

remotesync func pickup_item(item_path):
    if !has_node(item_path): return
    
    var item = get_node(item_path)
    if not item:
        print("Pickup: %s does not exist. Item is null" % str(item_path))
    var parent = item.get_parent()
    
    # reset parent
    if parent.get_parent().get("current_item") == item:
        parent.get_parent().current_item = null

    current_item = item
    items_in_range.erase(item)
    
    var pos = item.global_position
    parent.remove_child(item)
    front_root.add_child(item)
    item.global_position = pos
    item.tween_to(Vector2(0, 0), false)
    
remotesync func drop_item(item_path, new_position):
    if !has_node(item_path): return
    
    var item = get_node(item_path)
    if not item:
        print("Drop: %s does not exist. Item is null" % str(item_path))
    front_root.remove_child(item)
    get_parent().add_child(item)
    current_item = null
    item.global_position = new_position
    

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
