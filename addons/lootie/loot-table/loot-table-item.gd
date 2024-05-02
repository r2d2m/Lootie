class_name LootTableItem extends Resource

### This resource does not have to represent the in-game item of your game. 
### It is used to roll on the loot table and get the important information of the item to drop and that you could map to yours.

@export_group("Information")
@export var id: StringName
@export_file var file
@export var name : String
@export var abbreviation : String
@export_multiline var description : String

@export_group("Stats")
@export var type: String
@export var rarity: LootItemRarity
@export var weight := 1.0 ## This is the important parameter as more weight more chances to appear in a roll.
@export var value := 1.0
@export var usable := false
@export var equippable := false

@export_group("Visuals")
@export var icon : Texture2D
@export var image : Texture2D

var accum_weight := 0.0


static func from_dictionary(data: Dictionary = {}) -> LootTableItem:
	var item = LootTableItem.new()
	var valid_properties = item.get_property_list().map(func(property: Dictionary): return property.name)
	
	for property: String in data.keys():
		if valid_properties.has(property):
			item[property] = data[property]
			
	return item
	
