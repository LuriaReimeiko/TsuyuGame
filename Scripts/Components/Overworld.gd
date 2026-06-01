extends Node2D

## Overworld
## The base game scene. Loaded after a save slot is selected.
## Currently a placeholder that demonstrates:
##   - Correct mode assertion on load
##   - Save/load integration (restoring and persisting state)
##   - EventBus subscriptions
##   - How to trigger a save
##   - How to return to the main menu
##
## Replace the placeholder content here as actual gameplay is built.


# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #

func _ready() -> void:
	assert(
		GameManager.current_mode == GameManager.Mode.OVERWORLD,
		"Overworld: loaded while GameManager is not in OVERWORLD mode."
	)
	assert(
		SaveManager.active_slot >= 0,
		"Overworld: loaded with no active save slot. A slot must be selected first."
	)

	_restore_from_save()
	_connect_signals()

	print("Overworld ready. Day: %d, Slot: %d" % [
		GameManager.day_number,
		SaveManager.active_slot
	])


func _exit_tree() -> void:
	# Persist state when this scene is removed.
	# Each system calls SaveManager.set_section() with its own data.
	_write_to_save()


# ------------------------------------------------------------------ #
#  Save integration                                                    #
# ------------------------------------------------------------------ #

func _restore_from_save() -> void:
	var gm_data: Dictionary = SaveManager.get_section("game_manager")
	if gm_data.has("day_number"):
		GameManager.day_number = gm_data["day_number"]

	# Scene-local managers would restore themselves here, e.g.:
	# InventoryManager.deserialize(SaveManager.get_section("inventory"))
	# FarmManager.deserialize(SaveManager.get_section("farm"))


func _write_to_save() -> void:
	SaveManager.set_section("game_manager", {
		"day_number": GameManager.day_number,
	})

	# Scene-local managers serialize themselves here, e.g.:
	# SaveManager.set_section("inventory", InventoryManager.serialize())
	# SaveManager.set_section("farm", FarmManager.serialize())


# ------------------------------------------------------------------ #
#  Signal connections                                                  #
# ------------------------------------------------------------------ #

func _connect_signals() -> void:
	EventBus.day_ended.connect(_on_day_ended)
	EventBus.day_started.connect(_on_day_started)


# ------------------------------------------------------------------ #
#  Input — temporary dev shortcuts, remove before release             #
# ------------------------------------------------------------------ #

func _unhandled_input(event: InputEvent) -> void:
	#if not OS.is_debug_build():
		#return

	# F5: manual save
	if event.is_action_pressed("ui_focus_next"):
		EventBus.save_requested.emit()
		print("Manual save triggered.")

	# Escape: return to main menu
	if event.is_action_pressed("ui_cancel"):
		_return_to_main_menu()


# ------------------------------------------------------------------ #
#  Day cycle (stub)                                                    #
# ------------------------------------------------------------------ #

func _on_day_ended(day_number: int) -> void:
	print("Day %d ended." % day_number)
	_write_to_save()
	EventBus.save_requested.emit()


func _on_day_started(day_number: int) -> void:
	print("Day %d started." % day_number)


# ------------------------------------------------------------------ #
#  Navigation                                                          #
# ------------------------------------------------------------------ #

func _return_to_main_menu() -> void:
	_write_to_save()
	EventBus.save_requested.emit()

	var ok: bool = GameManager.request_mode_change(GameManager.Mode.MAIN_MENU)
	if not ok:
		push_error("Overworld: GameManager rejected transition to MAIN_MENU.")
		return

	SceneManager.go_to(SceneManager.SceneID.MAIN_MENU)
