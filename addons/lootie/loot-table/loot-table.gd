@tool
class_name LootTable extends Node

enum PROBABILITY { WEIGHT, ROLL_TIER }

## The available items that will be used on a roll
@export var available_items: Array[LootTableItem] = []
## The type of probability technique to apply on a loot, weight is the common case and generate random decimals
## while each time sum the weight of the next item. The roll tier uses a max roll number and define a number range
## for each tier
@export var probability_type := PROBABILITY.WEIGHT:
	set(value):
		probability_type = value
		notify_property_list_changed()

@export_group("Generation")
## When this is enabled items can be repeated for multiple rolls on this generation
@export var allow_duplicates := true

@export_group("Weight")
## The maximum items this weight generation can drop, more items requires more generation times so it's the way
## to adjust the probability.
@export var max_weight_items := 3
## A little help that is added to the total weight to allow drop more items increasing the chance.
@export var extra_weight_bias:= 0.25
@export_group("Roll")
@export var max_roll_items := 3
## Each time a random number between 0 and max roll will be generated, based on this result if the number
## fits on one of the rarity roll ranges, items of this rarity will be picked randomly
@export var max_roll := 100.0:
	set(value):
		max_roll = clampf(value, 1.0, max_current_rarity_roll())
		

## Duplicated items to not modify the original template of this loot table
@onready var mirrored_items: Array[LootTableItem] = []


func _validate_property(property: Dictionary):
	if property.name in ["max_roll", "max_roll_items"] and probability_type == PROBABILITY.WEIGHT:
		property.usage |= PROPERTY_USAGE_READ_ONLY
	
	elif property.name in ["max_weight_items", "extra_weight_bias"] and probability_type == PROBABILITY.ROLL_TIER:
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _init(items: Array[LootTableItem] = []):
	add_items(items)
	
	
func generate(times: int, type: PROBABILITY = probability_type) -> Array[LootTableItem]:
	mirrored_items.clear()
	mirrored_items = available_items.duplicate()
	
	var result: Array[LootTableItem] = []
	
	times = max(1, times)
	
	match type:
		PROBABILITY.WEIGHT:
			result = weight(times)
		PROBABILITY.ROLL_TIER:
			result = roll_tier(times)
	
	return result


func weight(times: int = 1) -> Array[LootTableItem]:
	var result: Array[LootTableItem] = []
	var total_weight := 0.0

	mirrored_items.shuffle()
	
	var max_picks = min(mirrored_items.size(), max_weight_items)
	
	for item: LootTableItem in mirrored_items:
		total_weight += item.weight
		item.accum_weight = total_weight
		
	total_weight += extra_weight_bias
	
	for i in range(times):
		if result.size() >= max_picks:
			break
			
		var roll := randf_range(0.0, total_weight)

		for item: LootTableItem in mirrored_items:
			if roll >= item.accum_weight:
				result.append(item)
					
				if not allow_duplicates:
					mirrored_items.erase(item)
					
				break
	
	return result.slice(0, max_picks)
				
	
func roll_tier(times: int = 1) -> Array[LootTableItem]:
	var result: Array[LootTableItem] = []
	
	for i in range(times):
		if result.size() >= max_roll_items:
			break
			
		var item_rarity_roll = randf_range(0.0, max_roll)
		var item := pick_random_item_by_roll(item_rarity_roll)
		
		if item is LootTableItem:
			result.append(item)
		
	if not allow_duplicates:
		var no_duplicates_result: Array[LootTableItem] = []
		
		for item: LootTableItem in result:
			if not no_duplicates_result.has(item):
				no_duplicates_result.append(item)
				
		return no_duplicates_result
	
	return result.slice(0, max_roll_items)


func max_current_rarity_roll() -> float:
	return available_items.map(func(item: LootTableItem): return item.rarity.max_roll).max()


func pick_random_item_by_roll(roll: float) -> LootTableItem:
	var items: Array[LootTableItem] = []
	
	var current_roll_items = mirrored_items.filter(
		func(item: LootTableItem):
			return _decimal_value_is_between(roll, item.rarity.min_roll, item.rarity.max_roll)
			)
	
	if current_roll_items.is_empty():
		return null
	
	current_roll_items.shuffle()
	
	return current_roll_items.pick_random()
	

func add_items(items: Array[LootTableItem] = []) -> void:
	available_items.append_array(items)


func add_item(item: LootTableItem) -> void:
	available_items.append(item)


func remove_items(items: Array[LootTableItem] = []) -> void:
	available_items = available_items.filter(func(item: LootTableItem): return not item in items)


func remove_item(item: LootTableItem) -> void:
	available_items.erase(item)


func remove_items_by_id(item_ids: Array[StringName] = []) -> void:
	available_items = available_items.filter(func(item: LootTableItem): return not item.id in item_ids)


func remove_item_by_id(item_id: StringName) -> void:
	available_items  = available_items.filter(func(item: LootTableItem): return not item.id == item_id)


func _decimal_value_is_between(number: float, min_value: float, max_value: float, inclusive: = true, precision: float = 0.00001) -> bool:
	if inclusive:
		min_value -= precision
		max_value += precision

	return number >= min(min_value, max_value) and number <= max(min_value, max_value)
