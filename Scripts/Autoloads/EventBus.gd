extends Node

## EventBus
## Global signal relay. Emit here instead of coupling unrelated systems directly.
## Usage (emit):   EventBus.inventory_changed.emit()
## Usage (listen): EventBus.inventory_changed.connect(_on_inventory_changed)
##
## Convention: signals are past-tense facts, not commands.
##   Good:  order_completed, crop_harvested, scene_loaded
##   Bad:   do_save, request_scene_change


# ------------------------------------------------------------------ #
#  Save / Load                                                         #
# ------------------------------------------------------------------ #
signal save_requested()
signal load_requested(slot_index: int)
signal save_completed(success: bool)
signal load_completed(success: bool)


# ------------------------------------------------------------------ #
#  Game state                                                          #
# ------------------------------------------------------------------ #
signal game_mode_changed(previous: GameManager.Mode, next: GameManager.Mode)
signal time_scale_changed(new_scale: float)
signal day_ended(day_number: int)
signal day_started(day_number: int)


# ------------------------------------------------------------------ #
#  Scene                                                               #
# ------------------------------------------------------------------ #
signal scene_change_requested(scene_id: SceneManager.SceneID)
signal scene_loaded(scene_id: SceneManager.SceneID)
signal scene_unloaded(scene_id: SceneManager.SceneID)


# ------------------------------------------------------------------ #
#  Inventory                                                           #
# ------------------------------------------------------------------ #

## Emitted whenever any item quantity changes. Listeners rebuild their
## display rather than tracking individual add/remove calls.
signal inventory_changed()


# ------------------------------------------------------------------ #
#  Restaurant                                                          #
# ------------------------------------------------------------------ #
signal order_placed(recipe_id: StringName, customer_id: int)
signal order_completed(customer_id: int, satisfaction: float)
signal order_expired(customer_id: int)

signal customer_seated(customer_id: int, table_id: int)
signal customer_left(customer_id: int)
signal customer_left_angry(customer_id: int)


# ------------------------------------------------------------------ #
#  Grid / Build mode                                                   #
# ------------------------------------------------------------------ #
signal grid_changed()
signal unreachable_flagged(cell_positions: Array)
signal build_mode_entered()
signal build_mode_exited()


# ------------------------------------------------------------------ #
#  Gathering / Farm                                                    #
# ------------------------------------------------------------------ #
signal resource_gathered(item_id: StringName, quantity: int)
signal crop_planted(plot_id: int, item_id: StringName)
signal crop_ready(plot_id: int, item_id: StringName)
signal crop_harvested(plot_id: int, item_id: StringName)


# ------------------------------------------------------------------ #
#  Kitchen                                                             #
# ------------------------------------------------------------------ #
signal cooking_started(slot_index: int, recipe_id: StringName)
signal cooking_completed(slot_index: int, recipe_id: StringName)
