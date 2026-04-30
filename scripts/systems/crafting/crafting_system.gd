class_name CraftingSystem
extends Node

# CR-007/008: Crafting lifecycle on a per-character basis.

signal craft_started(recipe_id: String, duration: float)
signal craft_completed(recipe_id: String, output_item: String, quantity: int, quality: String)
signal craft_failed(recipe_id: String, reason: String)

var active_recipe_id: String = ""
var active_recipe: Dictionary = {}
var craft_timer: float = 0.0


func attempt_craft(recipe_id: String, inventory: Inventory, station_type: String, skills: SkillSystem) -> bool:
	var recipe: Dictionary = RecipeDefs.get_recipe(recipe_id)
	if recipe.is_empty():
		craft_failed.emit(recipe_id, "Unknown recipe")
		return false
	# Station check
	if recipe["station"] != "inventory" and recipe["station"] != station_type:
		craft_failed.emit(recipe_id, "Need %s station" % recipe["station"])
		return false
	# Skill check
	var skill_lv: int = skills.get_level(recipe["skill"]) if skills else 0
	if skill_lv < recipe["skill_req"]:
		craft_failed.emit(recipe_id, "Need %s %d" % [recipe["skill"], recipe["skill_req"]])
		return false
	# Material check
	for mat in recipe["materials"]:
		if not inventory.has_item(mat["item_type"], mat["quantity"]):
			craft_failed.emit(recipe_id, "Missing %s ×%d" % [mat["item_type"], mat["quantity"]])
			return false
	# Already crafting?
	if not active_recipe_id.is_empty():
		craft_failed.emit(recipe_id, "Already crafting")
		return false
	# Consume materials
	for mat in recipe["materials"]:
		var need: int = mat["quantity"]
		var stacks: Array = inventory.get_items_of_type(mat["item_type"])
		for s in stacks:
			if need <= 0:
				break
			var take: int = min(s["quantity"], need)
			inventory.remove_item(s["id"], take)
			need -= take
	# Start craft timer
	active_recipe_id = recipe_id
	active_recipe = recipe
	craft_timer = recipe["craft_time"]
	craft_started.emit(recipe_id, craft_timer)
	return true


func _process(delta: float) -> void:
	if active_recipe_id.is_empty():
		return
	craft_timer -= delta
	if craft_timer <= 0:
		_complete()


func _complete() -> void:
	var rid: String = active_recipe_id
	var recipe: Dictionary = active_recipe
	active_recipe_id = ""
	active_recipe = {}
	# Failure & quality skipped for first cut (always succeed, normal quality).
	var quality: String = "normal"
	craft_completed.emit(rid, recipe["output"], recipe.get("output_quantity", 1), quality)


func is_crafting() -> bool:
	return not active_recipe_id.is_empty()


func progress() -> float:
	if active_recipe.is_empty():
		return 0.0
	var total: float = active_recipe.get("craft_time", 1.0)
	return 1.0 - (craft_timer / total)
