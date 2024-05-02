class_name LootItemRarity extends Resource

enum ITEM_RARITY { COMMON, UNCOMMON, RARE, LEGENDARY, MYTHIC, ETERNAL, ABYSSAL, COSMIC, DIVINE} ## Expand here as to adjust it to your game requirements

## The grade of rarity for this item
@export var grade := ITEM_RARITY.COMMON
## The minimum value in range to be available on the roll pick
@export var min_roll: float
## The maximum value in range to be available on the roll pick
@export var max_roll: float
