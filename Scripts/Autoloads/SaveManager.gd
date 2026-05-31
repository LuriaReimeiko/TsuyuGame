extends Node

## SaveManager
## Manages save slots, serialization, and deserialization.
## Is the ONLY autoload that holds persistent game data between sessions.
##
## Save file layout:
##   user://saves/slot_0.sav
##   user://saves/slot_1.sav
##   user://saves/slot_2.sav
##
## All scene-local managers (InventoryManager, GridManager, etc.)
## implement serialize() → Dictionary and deserialize(data: Dictionary).
## SaveManager calls them when saving/loading. It does not reach into
## their internals directly.
##
## VERSIONING: every save file contains a "version" key. When loading,
## _migrate() is called if the version is older than CURRENT_VERSION.
## Add migration steps there as the data format evolves — never remove
## old ones, only append.


# ------------------------------------------------------------------ #
#  Constants                                                           #
# ------------------------------------------------------------------ #

const CURRENT_VERSION: int = 1
const SAVE_DIR: String = "user://saves/"
const SLOT_COUNT: int = 5
const SLOT_NAME_TEMPLATE: String = "slot_%d.sav"


# ------------------------------------------------------------------ #
#  Active save state                                                   #
# ------------------------------------------------------------------ #

## The slot index that is currently loaded. -1 means no save is active.
var active_slot: int = -1

## The raw deserialized data for the active slot.
## Scene-local managers call SaveManager.get_section() to retrieve
## their portion and SaveManager.set_section() to write it back.
var _active_data: Dictionary = {}


# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #

func _ready() -> void:
	_ensure_save_directory()
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)


# ------------------------------------------------------------------ #
#  Slot metadata (used by the save select screen)                      #
# ------------------------------------------------------------------ #

## Returns an Array of Dictionaries, one per slot.
## Each dict contains: { "slot": int, "exists": bool, "day": int,
##                       "playtime_seconds": float, "timestamp": int }
func get_all_slot_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(SLOT_COUNT):
		result.append(_read_slot_info(i))
	return result


func slot_exists(slot_index: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot_index))


# ------------------------------------------------------------------ #
#  Load                                                                #
# ------------------------------------------------------------------ #

## Load [param slot_index] into memory. Populates _active_data.
## Returns true on success. Scene-local managers should call
## get_section() after this to restore their state.
func load_slot(slot_index: int) -> bool:
	assert(slot_index >= 0 and slot_index < SLOT_COUNT, "SaveManager: invalid slot index.")

	var path: String = _slot_path(slot_index)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: save file not found at %s." % path)
		EventBus.load_completed.emit(false)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: could not open %s. Error: %s" % [path, FileAccess.get_open_error()])
		EventBus.load_completed.emit(false)
		return false

	var raw: String = file.get_as_text()
	file.close()

	var data = JSON.parse_string(raw)
	if data == null or not data is Dictionary:
		push_error("SaveManager: failed to parse save file at %s." % path)
		EventBus.load_completed.emit(false)
		return false

	_active_data = _migrate(data)
	active_slot = slot_index

	EventBus.load_completed.emit(true)
	return true


## Returns the sub-dictionary for [param section_key], or a default
## empty dict if the section does not exist yet.
## Scene-local managers call this during their own _ready() or
## after load_slot() completes.
func get_section(section_key: String) -> Dictionary:
	return _active_data.get(section_key, {})


# ------------------------------------------------------------------ #
#  Save                                                                #
# ------------------------------------------------------------------ #

## Write the current _active_data to disk at the active slot.
## Call set_section() for each system before calling save().
func save() -> bool:
	if active_slot < 0:
		push_error("SaveManager: save() called with no active slot.")
		EventBus.save_completed.emit(false)
		return false

	_active_data["version"] = CURRENT_VERSION
	_active_data["timestamp"] = Time.get_unix_time_from_system()

	var json_string: String = JSON.stringify(_active_data, "\t")
	var path: String = _slot_path(active_slot)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not write to %s. Error: %s" % [path, FileAccess.get_open_error()])
		EventBus.save_completed.emit(false)
		return false

	file.store_string(json_string)
	file.close()

	EventBus.save_completed.emit(true)
	return true


## Write a section into the in-memory save data.
## Does NOT write to disk — call save() when ready to persist.
func set_section(section_key: String, data: Dictionary) -> void:
	_active_data[section_key] = data


# ------------------------------------------------------------------ #
#  New game                                                            #
# ------------------------------------------------------------------ #

## Initialise a fresh save at [param slot_index].
## Overwrites any existing data in that slot without confirmation —
## the calling UI is responsible for confirmation dialogs.
func new_game(slot_index: int) -> void:
	assert(slot_index >= 0 and slot_index < SLOT_COUNT)

	active_slot = slot_index
	_active_data = _default_save_data()


## Delete the save file at [param slot_index].
func delete_slot(slot_index: int) -> void:
	var path: String = _slot_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# ------------------------------------------------------------------ #
#  Migration                                                           #
# ------------------------------------------------------------------ #

## Called on every load. Applies incremental migrations until the
## data matches CURRENT_VERSION.
## RULE: never remove a migration step. Only append new ones.
func _migrate(data: Dictionary) -> Dictionary:
	var version: int = data.get("version", 0)

	# v0 → v1: initial version, nothing to migrate yet.
	# if version < 1:
	#     data = _migrate_v0_to_v1(data)

	if version < CURRENT_VERSION:
		push_warning(
			"SaveManager: migrated save from version %d to %d." % [version, CURRENT_VERSION]
		)

	data["version"] = CURRENT_VERSION
	return data


# ------------------------------------------------------------------ #
#  Defaults                                                            #
# ------------------------------------------------------------------ #

func _default_save_data() -> Dictionary:
	return {
		"version":           CURRENT_VERSION,
		"timestamp":         Time.get_unix_time_from_system(),
		"playtime_seconds":  0.0,
		"game_manager": {
			"day_number": 1,
		},
		"inventory":   {},
		"grid":        {},
		"farm":        {},
		"kitchen":     {},
	}


# ------------------------------------------------------------------ #
#  Signal handlers                                                     #
# ------------------------------------------------------------------ #

func _on_save_requested() -> void:
	save()


func _on_load_requested(slot_index: int) -> void:
	load_slot(slot_index)


# ------------------------------------------------------------------ #
#  Helpers                                                             #
# ------------------------------------------------------------------ #

func _slot_path(slot_index: int) -> String:
	return SAVE_DIR + SLOT_NAME_TEMPLATE % slot_index


func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)


func _read_slot_info(slot_index: int) -> Dictionary:
	var base: Dictionary = {
		"slot":             slot_index,
		"exists":           false,
		"day":              0,
		"playtime_seconds": 0.0,
		"timestamp":        0,
	}

	var path: String = _slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return base

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return base

	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data == null or not data is Dictionary:
		return base

	base["exists"]           = true
	base["day"]              = data.get("game_manager", {}).get("day_number", 1)
	base["playtime_seconds"] = data.get("playtime_seconds", 0.0)
	base["timestamp"]        = data.get("timestamp", 0)
	return base
