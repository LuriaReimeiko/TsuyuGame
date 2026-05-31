extends Resource
class_name ItemResource

## ItemResource
##
## Create instances as .tres files under res://data/items/
## Naming convention: item_mushroom_chanterelle.tres
##                    item_fish_trout.tres
##                    item_herb_thyme.tres

# ------------------------------------------------------------------ #
#  Enums                                                               #
# ------------------------------------------------------------------ #

enum Category {
	FORAGED,    ## Found in the wild: mushrooms, berries, herbs.
	FISH,       ## Caught in rivers or lakes.
	CROP,       ## Grown in the farm plot.
	PURCHASED,  ## Bought from the village shop (flour, butter, eggs…).
	DISH,       ## A cooked recipe output.
	MISC,       ## Anything that doesn't fit above.
}


# ------------------------------------------------------------------ #
#  Properties                                                          #
# ------------------------------------------------------------------ #

## Unique identifier used throughout code. Never changes after creation.
## Snake_case, no spaces. Example: "mushroom_chanterelle"
@export var id: StringName = &""

@export var display_name: String = ""

## Shown in inventory, recipe book, and shop UI.
@export var icon: Texture2D = null

@export var category: Category = Category.MISC

## Whether multiple units can stack in one inventory slot.
@export var stackable: bool = true

## Maximum units per stack. Ignored if stackable is false.
@export var max_stack: int = 99

## Base sell value in coins. 0 means the item cannot be sold directly.
@export var base_value: int = 0

## Flavour text shown in the inventory tooltip. Optional.
@export_multiline var description: String = ""


# ------------------------------------------------------------------ #
#  Validation                                                          #
# ------------------------------------------------------------------ #

## Called in the editor and at runtime to catch misconfigured items.
func is_valid() -> bool:
	if id == &"":
		push_error("ItemResource: id is empty on resource '%s'." % resource_path)
		return false
	if display_name == "":
		push_warning("ItemResource: display_name is empty for id '%s'." % id)
	return true
