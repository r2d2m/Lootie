@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("LootieTable", "Node", preload("res://addons/lootie/loot-table/loot-table.gd"), preload("res://addons/lootie/loot-table/loot_table.svg"))


func _exit_tree():
	remove_custom_type("LootieTable")
