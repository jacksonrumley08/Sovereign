class_name Inventory
extends Node

# IN-001/002: Weight-based inventory with slots and stackability.

@export var max_weight: float = 100.0
@export var max_slots: int = 40

var items: Array[Dictionary] = []
var current_weight: float = 0.0

signal item_added(item: Dictionary)
signal item_removed(item_id: String)
signal weight_changed(new_weight: float)
signal inventory_full()


func add_item(item_type: String, quantity: int = 1, quality: String = "normal") -> bool:
	var item_def: Dictionary = ItemDefs.get_item(item_type)
	if item_def.is_empty():
		return false
	var unit_weight: float = item_def.get("weight", 0.0)
	var total_weight: float = unit_weight * quantity
	if current_weight + total_weight > max_weight * 1.5:
		inventory_full.emit()
		return false
	# Stack if applicable
	if item_def.get("stackable", false):
		for existing in items:
			if existing["item_type"] == item_type and existing["quality"] == quality:
				existing["quantity"] += quantity
				existing["weight"] += total_weight
				current_weight += total_weight
				weight_changed.emit(current_weight)
				item_added.emit(existing)
				return true
	if items.size() >= max_slots:
		inventory_full.emit()
		return false
	var new_item: Dictionary = {
		"id": _generate_id(),
		"item_type": item_type,
		"quantity": quantity,
		"quality": quality,
		"durability": item_def.get("durability", -1),
		"max_durability": item_def.get("durability", -1),
		"weight": total_weight,
		"crafter_name": "",
		"custom_name": "",
		"spoil_at": -1.0,
	}
	if item_def.get("spoil_hours", 0) > 0:
		new_item["spoil_at"] = Time.get_unix_time_from_system() + item_def["spoil_hours"] * 3600
	items.append(new_item)
	current_weight += total_weight
	weight_changed.emit(current_weight)
	item_added.emit(new_item)
	return true


func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			var item_def: Dictionary = ItemDefs.get_item(items[i]["item_type"])
			var weight_per: float = item_def.get("weight", 0.0)
			if items[i]["quantity"] <= quantity:
				current_weight -= items[i]["weight"]
				items.remove_at(i)
			else:
				items[i]["quantity"] -= quantity
				items[i]["weight"] -= weight_per * quantity
				current_weight -= weight_per * quantity
			weight_changed.emit(current_weight)
			item_removed.emit(item_id)
			return true
	return false


func has_item(item_type: String, quantity: int = 1) -> bool:
	var count: int = 0
	for item in items:
		if item["item_type"] == item_type:
			count += item["quantity"]
			if count >= quantity:
				return true
	return false


func count_item(item_type: String) -> int:
	var count: int = 0
	for item in items:
		if item["item_type"] == item_type:
			count += item["quantity"]
	return count


func get_items_of_type(item_type: String) -> Array:
	var result: Array = []
	for item in items:
		if item["item_type"] == item_type:
			result.append(item)
	return result


func _process(_delta: float) -> void:
	# IN-006: Spoil check
	var now: float = Time.get_unix_time_from_system()
	var to_remove: Array[String] = []
	for item in items:
		if item.get("spoil_at", -1.0) > 0 and now >= item["spoil_at"]:
			to_remove.append(item["id"])
	for id in to_remove:
		remove_item(id, 99999)
		GameManager.log("info", "Item spoiled: %s" % id)


func _generate_id() -> String:
	return "%d-%d" % [Time.get_ticks_msec(), randi()]


# Debug helper for the overlay
func summary() -> String:
	if items.is_empty():
		return "(empty)"
	var lines: PackedStringArray = []
	for item in items:
		var name: String = ItemDefs.get_item(item["item_type"]).get("display_name", item["item_type"])
		if item["quantity"] > 1:
			lines.append("%s ×%d" % [name, item["quantity"]])
		else:
			lines.append(name)
	return ", ".join(lines)
