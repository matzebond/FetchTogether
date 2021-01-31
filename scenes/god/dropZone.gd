extends Node2D

signal item_changed()

var current_item = null setget _set_current_item
var category = null setget _set_category

remotesync func receive_item(item_path):
    if !has_node(item_path): return

    var item = get_node(item_path)

    var pos = item.global_position
    item.get_parent().remove_child(item)
    $ItemRoot.add_child(item)
    item.global_position = pos

    item.tween_to(global_position + Vector2(0, 32))

    if current_item:
        pos = current_item.global_position
        $ItemRoot.remove_child(current_item)
        get_tree().get_nodes_in_group("ysort")[0].add_child(current_item)
        current_item.global_position = pos
        current_item.tween_to(global_position + position)

    _set_current_item(item)

func has_item():
    return current_item != null

func _set_current_item(v):
    current_item = v
    emit_signal("item_changed")

func _set_category(v):
    category = v
    $Label.text = G.ItemCategory.keys()[v]
    $Label.rect_pivot_offset = $Label.rect_size / 2


func play_category_reveal_animation():
    $AnimationPlayer.play("reveal_category")

func play_score_animation():
    var won = false

    if current_item:
        if category in current_item.item_categories:
            won = true

    # In case reveal animation is still playing, reset
    if $AnimationPlayer.is_playing():
        $AnimationPlayer.reset()

    $AnimationPlayer.play("show_score_won" if won else "show_score_lost")
    if won:
        for ui in get_tree().get_nodes_in_group("ui"):
            ui.addPoint()


func clear_and_free():
    queue_free() # TODO animation

