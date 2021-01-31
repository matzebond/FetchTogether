extends Node

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
    MyFavorite    
}

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
