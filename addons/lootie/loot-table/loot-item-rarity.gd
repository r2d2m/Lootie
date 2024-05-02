class_name LootItemRarity extends Resource


## The grade of rarity for this item
@export var grade := LootTable.ITEM_RARITY.COMMON
## The minimum value in range to be available on the roll pick
@export var min_roll: float
## The maximum value in range to be available on the roll pick
@export var max_roll: float
