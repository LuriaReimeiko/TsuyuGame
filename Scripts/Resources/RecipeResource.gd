extends Resource
class_name RecipeResource

## RecipeResource
## Defines a cookable dish: what goes in, what comes out, how long it takes.
## The kitchen UI and InventoryManager read from this.
##
## Create instances as .tres files under res://data/recipes/
## Naming convention: recipe_tagliatelle_mushroom.tres


# ------------------------------------------------------------------ #
#  Inner types                                                         #
# ------------------------------------------------------------------ #

## One ingredient slot in the recipe.
class Ingredient:
	var item: ItemResource
	var quantity: int = 1

	func _init(p_item: ItemResource, p_quantity: int = 1) -> void:
		item = p_item
		quantity = p_quantity


# ------------------------------------------------------------------ #
#  Properties                                                          #
# ------------------------------------------------------------------ #

## Unique identifier. Example: "tagliatelle_mushroom"
@export var id: StringName = &""

@export var display_name: String = ""

@export var icon: Texture2D = null

## The ItemResource produced when this recipe is completed.
## Must have category = DISH.
@export var result_item: ItemResource = null

## How many result_item units are produced per cook.
@export var result_quantity: int = 1

## Ingredients required. Exported as a Dictionary for .tres compatibility:
## { "item_id": quantity } — resolved to ItemResource at runtime via RecipeDB.
## Do not access _ingredients_raw directly in gameplay code;
## use get_ingredients() after RecipeDB has resolved the references.
@export var ingredients_raw: Dictionary = {}

## Cook time in seconds at time_scale = 1.0.
@export var cook_time: float = 30.0

## Base sale price when served to a customer.
@export var base_price: int = 10

## Whether this recipe is available from the start or must be unlocked.
@export var unlocked_by_default: bool = true

## Flavour description shown in the recipe book.
@export_multiline var description: String = ""

## Resolved at runtime by RecipeDB. Do not set manually.
var _resolved_ingredients: Array = []  # Array[Ingredient]


# ------------------------------------------------------------------ #
#  Runtime API                                                         #
# ------------------------------------------------------------------ #

## Returns the resolved ingredient list.
## Only valid after RecipeDB.resolve_recipe() has been called on this resource.
func get_ingredients() -> Array:
	return _resolved_ingredients


## Returns true if [param inventory_dict] contains enough of each ingredient.
## inventory_dict format: { item_id: current_quantity }
func can_cook(inventory_dict: Dictionary) -> bool:
	for ingredient in _resolved_ingredients:
		var have: int = inventory_dict.get(ingredient.item.id, 0)
		if have < ingredient.quantity:
			return false
	return true


# ------------------------------------------------------------------ #
#  Validation                                                          #
# ------------------------------------------------------------------ #

func is_valid() -> bool:
	if id == &"":
		push_error("RecipeResource: id is empty on '%s'." % resource_path)
		return false
	if result_item == null:
		push_error("RecipeResource: result_item is null on '%s'." % id)
		return false
	if ingredients_raw.is_empty():
		push_warning("RecipeResource: no ingredients defined for '%s'." % id)
	if cook_time <= 0.0:
		push_warning("RecipeResource: cook_time is <= 0 for '%s'." % id)
	return true
