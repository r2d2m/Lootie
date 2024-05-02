<div align="center">
    <img src="icon.png" alt="Logo" width="160" height="160">

<h3 align="center">Lootie</h3>

  <p align="center">
    Portable loot table for Godot Games
    <br />
    ·
    <a href="https://github.com/ninetailsrabbit/Lootie/issues/new?assignees=ninetailsrabbit&labels=%F0%9F%90%9B+bug&projects=&template=bug_report.md&title=">Report Bug</a>
    ·
    <a href="https://github.com/ninetailsrabbit/Lootie/issues/new?assignees=ninetailsrabbit&labels=%E2%AD%90+feature&projects=&template=feature_request.md&title=">Request Features</a>
  </p>
</div>

<br>
<br>

`Lootie` serves as a tool for game developers to define and manage the random generation of loot items within their games. It allows specifying a list of available items with their respective weights or rarity tiers, enabling the generation of loot with controlled probabilities. The class offers various methods for adding, removing, and manipulating the loot items, along with two primary generation methods: `weight-based` and `roll-tier based`

- [Getting started](#getting-started)
  - [Global](#global)
  - [Individual](#individual)
  - [LootTableItem](#loottableitem)
    - [Custom Resource Extension](#custom-resource-extension)
    - [Item Mapper Class](#item-mapper-class)
    - [Properties](#properties)
    - [Editor creation](#editor-creation)
    - [Rarity](#rarity)
- [Generate loot](#generate-loot)
  - [Generate() method](#generate-method)
  - [Weighted](#weighted)
  - [Roll tier](#roll-tier)

# Getting started

You can use it in two ways:

## Global

Add it as an autoload and have a fixed base of items from which to obtain the corresponding generations. This is useful for loots that are always available and whose percentages may change as the player progresses through the game.

It is recommended to create a script that extends from `LootTable` so that it is the singleton and can continue to add the original `LootTable` individually as a node.

```swift file=root_loot_table.gd
class_name RootLootTable extends LootTable
//...
```

![autoload-example](images/autoload-example.png)

## Individual

`LootTable` can be added as a node and set some items for this particular loot. This is a useful way to define loots based on enemies, chests, or levels where you want to only generate items of a particular type and rarity for that entity, for example.

![search-node](images/search-node.png)

![node-added](images/node-added.png)

## LootTableItem

`LootTableItem` resource serves as a placeholder for representing items that the `LootTable` plugin uses for loot generation. While these items may not directly correspond to the actual items in your game, they provide the necessary information for the plugin to identify and handle loot generation.

**There are two ways to use this items on your game:**

### Custom Resource Extension

- Create a new resource type that extends the base `LootTableItem` resource provided by the plugin.
- Add additional properties to your custom resource that align with your game's item data structure.
- Utilize this custom resource type when defining items in the LootTable plugin.

### Item Mapper Class

- Implement an intermediate class or function that acts as an item mapper.
- This mapper should receive a `LootTableItem` resource as input.
- Based on the `LootTableItem properties`, the mapper should translate or transform the data into an equivalent Item class or resource from your game's data model.
- When generating loot using the LootTable plugin, use the mapper to convert the generated `LootTableItem` instances into your game's Item objects

### Properties

The LootTableItem resource has several essential properties that must be defined for proper functionality:

- `id`: A unique identifier for the item. It should not be repeated among all items.
- `rarity`: A reference to a `LootItemRarity` resource that defines the item's rarity level.
- `weight`: A numerical value representing the weight of the item in probability calculations.

The `LootTableItem` offers a static helper method `from_dictionary()` that allows you to create new `LootTableItem` resources directly from dictionaries. This method requires the dictionary keys to match the property names of the LootTableItem resource _(e.g., id, rarity, weight)_. While the dictionary doesn't need to be complete, the method assigns default values for any missing properties. This provides a convenient way to create `LootTableItem` resources programmatically or from external data sources.

```swift
class_name LootTableItem extends Resource

/// This resource does not have to represent the in-game item of your game.
/// It is used to roll on the loot table and get the important information of the item to drop and that you could map to yours.

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
```

### Editor creation

In addition to the static helper method, you can also create `LootTableItem` resources directly within the Godot editor

![resource-creation](images/item-resource-creation.png)

![resource-creation-2](images/item-resource-creation2.png)

### Rarity

This resource represents the rarity of the item

```swift
class_name LootItemRarity extends Resource

enum ITEM_RARITY { COMMON, UNCOMMON, RARE, LEGENDARY, MYTHIC, ETERNAL, ABYSSAL, COSMIC, DIVINE} ## Expand here as to adjust it to your game requirements

## The grade of rarity for this item
@export var grade := ITEM_RARITY.COMMON
## The minimum value in range to be available on the roll pick
@export var min_roll: float
## The maximum value in range to be available on the roll pick
@export var max_roll: float
```

You can assign directly the rarity on the editor

![item-rarity-creation](images/item-rarity-creation.png)

# Generate loot

The cool thing of this plugin is that with a simple method you can generate loot in record time. There are two types of techniques this plugin provides for you.

**_The `LootTableItem` resources inside a `LootTable` are never deleted or altered. A copy is created each time a new generation is to be disposed of._**

## Generate() method

This method takes an integer `times` parameter and an optional type parameter _(defaulting to the `probability_type` property value)_ and returns an array of generated `LootTableItem` objects. It internally utilizes either the `weight()` or `roll_tier()` method based on the provided type.

`times` does not represent the amount of items to generate but the **number of times the generation will be applied** so more `times` means more probability to get the items from this loot table.

**Basic example**

```swift
extends Node2D

@onready var loot_table: LootTable = $LootieTable

func _on_death():
    var items := loot_table.generate(5)
    //... do stuff
```

You can use the `probability_type` you want on the generation function each time:

```swift
loot_table.generate(5, LootieTable.ROLL_TIER)
// Or
loot_table.generate(5, LootieTable.WEIGHT)

```

## Weighted

This method iterates through the available items, calculating their cumulative weights and randomly selecting items based on the accumulated weight values. It repeats this process for the specified `times parameter`, potentially returning up to `max_weight_items` items while considering the `allow_duplicates` flag.

## Roll tier

This method generates random numbers within the specified `max_roll` range and compares them to the defined rarity tiers of the available items. Based on the roll results, it randomly selects items corresponding to the matching rarity tiers, repeating for the specified times parameter and potentially returning up to `max_roll_items` while considering the `allow_duplicates` flag
