class_name EquipmentManager
extends Node

# IN-004: 7 equipment slots with equip/unequip + stat propagation.

const SLOTS: Array[String] = ["head", "chest", "legs", "hands", "feet", "main_hand", "off_hand"]

var equipped: Dictionary = {}  # slot -> item_id (matches an item in Inventory)

signal equipment_changed(slot: String, item_id: String)


func _ready() -> void:
	for s in SLOTS:
		equipped[s] = ""


func equip(item_id: String, slot: String, inventory: Inventory) -> bool:
	if not SLOTS.has(slot):
		return false
	# Find the item
	var item_dict: Dictionary = {}
	for item in inventory.items:
		if item["id"] == item_id:
			item_dict = item
			break
	if item_dict.is_empty():
		return false
	# Validate item slot
	var def: Dictionary = ItemDefs.get_item(item_dict["item_type"])
	var item_slot: String = def.get("slot", "none")
	if item_slot != slot:
		return false
	# Mutual-exclusion: torch in off_hand + shield in off_hand handled by slot match
	# But torch + shield both off_hand → can only have one at a time naturally
	equipped[slot] = item_id
	equipment_changed.emit(slot, item_id)
	return true


func unequip(slot: String) -> void:
	if not SLOTS.has(slot):
		return
	equipped[slot] = ""
	equipment_changed.emit(slot, "")


func get_equipped(slot: String) -> String:
	return equipped.get(slot, "")


func get_equipped_item_type(slot: String, inventory: Inventory) -> String:
	var item_id: String = get_equipped(slot)
	if item_id.is_empty():
		return ""
	for item in inventory.items:
		if item["id"] == item_id:
			return item["item_type"]
	return ""


func has_tool(tool_type: String, inventory: Inventory) -> bool:
	var equipped_type: String = get_equipped_item_type("main_hand", inventory)
	if equipped_type.is_empty():
		return false
	var def: Dictionary = ItemDefs.get_item(equipped_type)
	return def.get("tool_type", "") == tool_type
