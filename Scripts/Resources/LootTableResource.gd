extends Resource
class_name LootTableResource

## LootTableResource
## Defines a weighted random drop table for gathering nodes and resource spawns.
## Attach to any gathering node via LootTableComponent.
##
## Create instances as .tres files under res://data/loot_tables/
## Naming convention: loot_forest_common.tres, loot_river_spring.tres


# ------------------------------------------------------------------ #
#  Inner types                                                         #
# ------------------------------------------------------------------ #

## A single entry in the loot table.
class LootEntry:
	## The item that can drop.
	var item: ItemResource
	## Relative weight. Higher = more likely relative to other entries.
	var weight: float = 1.0
	## Minimum quantity dropped when this entry is selected.
	var min_quantity: int = 1
	## Maximum quantity dropped when this entry is selected.
	var max_quantity: int = 1

	func _init(
		p_item: ItemResource,
		p_weight: float = 1.0,
		p_min: int = 1,
		p_max: int = 1
	) -> void:
		item = p_item
		weight = p_weight
		min_quantity = p_min
		max_quantity = p_max


# ------------------------------------------------------------------ #
#  Properties                                                          #
# ------------------------------------------------------------------ #

## Exported as an Array of Dictionaries for .tres authoring:
## [ { "item_id": "mushroom_chanterelle", "weight": 3.0, "min": 1, "max": 2 }, ... ]
## Resolved to LootEntry objects at runtime by the component.
@export var entries_raw: Array[Dictionary] = []

## How many separate rolls are made per gather interaction.
@export var rolls: int = 1

## If true, the same entry can be selected on multiple rolls.
## If false, each entry can only drop once per interaction.
@export var allow_duplicates: bool = true


# ------------------------------------------------------------------ #
#  Runtime API                                                         #
# ------------------------------------------------------------------ #

var _resolved_entries: Array = []  ## Array[LootEntry]
var _total_weight: float = 0.0


## Must be called once after resolution by LootTableComponent.
func set_resolved_entries(entries: Array) -> void:
	_resolved_entries = entries
	_total_weight = 0.0
	for entry in _resolved_entries:
		_total_weight += entry.weight


## Perform all rolls and return an Array of { "item": ItemResource, "quantity": int }.
## Returns an empty array if entries have not been resolved.
func roll() -> Array[Dictionary]:
	if _resolved_entries.is_empty():
		push_warning("LootTableResource: roll() called but entries are not resolved.")
		return []

	var results: Array[Dictionary] = []
	var available: Array = _resolved_entries.duplicate()

	for _i in range(rolls):
		if available.is_empty():
			break

		var entry = _pick_entry(available)
		if entry == null:
			continue

		var quantity: int = randi_range(entry.min_quantity, entry.max_quantity)
		results.append({ "item": entry.item, "quantity": quantity })

		if not allow_duplicates:
			available.erase(entry)

	return results


# ------------------------------------------------------------------ #
#  Internal                                                            #
# ------------------------------------------------------------------ #

func _pick_entry(pool: Array) -> LootEntry:
	var pool_weight: float = 0.0
	for entry in pool:
		pool_weight += entry.weight

	var roll_value: float = randf() * pool_weight
	var cumulative: float = 0.0

	for entry in pool:
		cumulative += entry.weight
		if roll_value <= cumulative:
			return entry

	return pool.back()
