extends KinematicBody2D

onready var front_root = $YSort/frontRoot
onready var sprite_anim = $YSort/spriteAnim
onready var camera = $camera
onready var world = get_node("/root/World")
onready var tween:Tween = $Tween

puppet var puppet_pos = Vector2()
puppet var puppet_vel = Vector2()

var vel = Vector2()

const STOP_ACCEL = 1400.0
const ACCEL = 3300.0
const MAX_VEL = 400.0

const PLAYER_COLLISION_FORCE = 1000

var current_anim = ""
var current_item

var spawn_pos

var enable_walk = G.IS_DEBUG

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
                if item and !item.disabled:
                    rpc("pickup_item",item.get_path())
            else:
                var item = current_item
                rpc("drop_item", item.get_path(), front_root.global_position)
                
                var drop_zone = get_closest_in(drop_zones_in_range)
                if drop_zone:
                    drop_zone.rpc("receive_item", item.get_path())
    
func _physics_process(delta):

    if is_network_master():
        camera.current = true
        
        # Apply stop force
        if vel.x > 0:   vel.x = max(0, vel.x - STOP_ACCEL*delta)
        if vel.x < 0:   vel.x = min(0, vel.x + STOP_ACCEL*delta)
        if vel.y > 0:   vel.y = max(0, vel.y - STOP_ACCEL*delta)
        if vel.y < 0:   vel.y = min(0, vel.y + STOP_ACCEL*delta)

        # Apply acceleration onto velocity (if not max)
        var dVel = delta * ACCEL
        if enable_walk:
            if Input.is_action_pressed("move_left"):
                var dVelToMax = max(0, MAX_VEL + vel.x)
                vel.x -= min(dVel, dVelToMax)
            if Input.is_action_pressed("move_right"):
                var dVelToMax = max(0, MAX_VEL - vel.x)
                vel.x += min(dVel, dVelToMax)
            if Input.is_action_pressed("move_up"):
                var dVelToMax = max(0, MAX_VEL + vel.y)
                vel.y -= min(dVel, dVelToMax)
            if Input.is_action_pressed("move_down"):
                var dVelToMax = max(0, MAX_VEL - vel.y)
                vel.y += min(dVel, dVelToMax)
    else:
        position = puppet_pos
        vel = puppet_vel

    var new_anim = null
    var front_root_pos = front_root.position
    if abs(vel.y) > abs(vel.x):
        if vel.y < 0:
            new_anim = "walk_up"
            front_root_pos = Vector2(0, -88)
        elif vel.y > 0:
            new_anim = "walk_down"
            front_root_pos = Vector2(0,52)
    else:
        if vel.x < 0:
            new_anim = "walk_side"
            front_root_pos = Vector2(-70, -18)
            sprite_anim.flip_h = false
        if vel.x > 0:
            new_anim = "walk_side"
            front_root_pos = Vector2(70, -18)
            sprite_anim.flip_h = true
    
    # Animate front root
    if front_root_pos != front_root.position:
        tween.interpolate_property(front_root, "position", null, front_root_pos, 0.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
        tween.start()

    # Switch animation
    if new_anim and new_anim != current_anim:
        current_anim = new_anim
        sprite_anim.play(new_anim)
    
    # Scale animation speed
    var is_walking = vel != Vector2.ZERO
    sprite_anim.speed_scale = 1 if is_walking else 0
    if !is_walking: sprite_anim.frame = 0

    vel = move_and_slide(vel)
    
    if is_network_master():
        rset("puppet_vel", vel)
        rset("puppet_pos", position)
    else:
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
    if area.get_parent() in get_tree().get_nodes_in_group("item"):
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
    # works for both player and dropZone!
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



func _on_playerDetector_body_entered(body):
    if body in get_tree().get_nodes_in_group("player") or body in get_tree().get_nodes_in_group("god"):
        if is_network_master():
            var n = (get_center() - body.get_center()).normalized()
            vel += n * PLAYER_COLLISION_FORCE
    
    
func get_center()->Vector2:
    return sprite_anim.global_position




func teleport_to_spawn_pos():
    enable_walk = false
    vel = Vector2.ZERO
    
    # Make GHOST
    collision_layer = 0; collision_mask = 0
    $playerDetector.collision_layer = 0; $playerDetector.collision_mask = 0
    
    $TeleportationAnimationPlayer.play("teleport_start")
    
func _on_AnimationPlayer_animation_finished(anim_name):
    if anim_name == "teleport_start":
        $TeleportationTween.interpolate_property(self, "position", null, spawn_pos, 1.8, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
        $TeleportationTween.start()
    if anim_name == "teleport_end":
        enable_walk = true
        
        # undo ghost
        collision_layer = 1; collision_mask = 1
        $playerDetector.collision_layer = 1; $playerDetector.collision_mask = 1
        
func _on_TeleportationTween_tween_all_completed():
    $TeleportationAnimationPlayer.play("teleport_end")
