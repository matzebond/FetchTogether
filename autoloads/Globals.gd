extends Node

# When true:
#       Initially allow walking
const IS_DEBUG = false

enum Orientation {
    N, E, S, W
}

enum ItemCategory {
    Soft,
    Food,
    Dangerous,
    Colorful,
    Heavy,
    KidsLoveIt,
    Shiny,
    Fun,
    MyFavorite,
    Sport
}

const CATEGORY_TO_FILE = {
ItemCategory.Soft : preload("res://assets/audio/soft.WAV"),
ItemCategory.Food : preload("res://assets/audio/yummy.WAV"),
ItemCategory.Dangerous : preload("res://assets/audio/dangerous.WAV"),
ItemCategory.Colorful : preload("res://assets/audio/Colorful.WAV"),
ItemCategory.Heavy : preload("res://assets/audio/heavy.WAV"),
ItemCategory.KidsLoveIt : preload("res://assets/audio/kidsLoveIt.WAV"),
ItemCategory.Shiny : preload("res://assets/audio/shiny.WAV"),
ItemCategory.Fun : preload("res://assets/audio/fun.WAV"),
ItemCategory.MyFavorite : preload("res://assets/audio/myFavorite.WAV")
}
#var path = G.CATEGORY_TO_FILE[category]

const ItemCategoryProbabilities = [
    ItemCategory.Soft, ItemCategory.Soft, ItemCategory.Soft,
    ItemCategory.Food, ItemCategory.Food, ItemCategory.Food,
    ItemCategory.Dangerous, ItemCategory.Dangerous, ItemCategory.Dangerous,
    ItemCategory.Colorful, ItemCategory.Colorful, ItemCategory.Colorful,
    ItemCategory.Heavy, ItemCategory.Heavy, ItemCategory.Heavy,
    ItemCategory.KidsLoveIt, ItemCategory.KidsLoveIt, ItemCategory.KidsLoveIt,
    ItemCategory.Shiny, ItemCategory.Shiny, ItemCategory.Shiny,
    ItemCategory.Fun, ItemCategory.Fun, ItemCategory.Fun,
    ItemCategory.MyFavorite
]

func get_random_item_category():
    return ItemCategoryProbabilities[Rand.randi() % ItemCategoryProbabilities.size()]

func get_item_category_num():
    return ItemCategory.size()
