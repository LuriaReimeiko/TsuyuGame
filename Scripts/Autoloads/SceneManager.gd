extends Node

## SceneManager
## Owns all scene loading, unloading, and transitions.
## GameManager decides *what state* the game is in.
## SceneManager decides *what is on screen*.
##
## Scenes are identified by the SceneID enum so paths are never
## scattered across scripts as raw strings.


# ------------------------------------------------------------------ #
#  Scene registry                                                      #
# ------------------------------------------------------------------ #

enum SceneID {
	MAIN_MENU,
	OVERWORLD,
	RESTAURANT,
	GATHERING_FOREST,
	GATHERING_RIVER,
	MINIGAME_FISHING,
}

## Map each SceneID to its .tscn path.
## Update paths here as scenes are created — nowhere else.
const SCENE_PATHS: Dictionary = {
	SceneID.MAIN_MENU:         "res://scenes/ui/MainMenu.tscn",
	SceneID.OVERWORLD:         "res://scenes/world/Overworld.tscn",
	SceneID.RESTAURANT:        "res://scenes/restaurant/Restaurant.tscn",
	SceneID.GATHERING_FOREST:  "res://scenes/gathering/ForestZone.tscn",
	SceneID.GATHERING_RIVER:   "res://scenes/gathering/RiverZone.tscn",
	SceneID.MINIGAME_FISHING:  "res://scenes/gathering/FishingMinigame.tscn",
}


# ------------------------------------------------------------------ #
#  State                                                               #
# ------------------------------------------------------------------ #

var _current_scene_id: SceneID
var _is_transitioning: bool = false


# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #

func _ready() -> void:
	assert(EventBus != null, "SceneManager: EventBus autoload not found.")
	EventBus.scene_change_requested.connect(_on_scene_change_requested)


# ------------------------------------------------------------------ #
#  Public API                                                          #
# ------------------------------------------------------------------ #

## Load [param scene_id], replacing the current scene.
## Emits EventBus.scene_loaded on completion.
## Returns immediately; loading happens on the next frame via call_deferred.
func go_to(scene_id: SceneID) -> void:
	if _is_transitioning:
		push_warning("SceneManager: go_to() called while a transition is already in progress.")
		return

	if not SCENE_PATHS.has(scene_id):
		push_error("SceneManager: no path registered for SceneID %d." % scene_id)
		return

	_is_transitioning = true
	_load_scene.call_deferred(scene_id)


func get_current_scene_id() -> SceneID:
	return _current_scene_id


func is_transitioning() -> bool:
	return _is_transitioning


# ------------------------------------------------------------------ #
#  Internal                                                            #
# ------------------------------------------------------------------ #

func _load_scene(scene_id: SceneID) -> void:
	var path: String = SCENE_PATHS[scene_id]

	EventBus.scene_unloaded.emit(_current_scene_id)
	get_tree().change_scene_to_file(path)

	_current_scene_id = scene_id
	_is_transitioning = false

	EventBus.scene_loaded.emit(scene_id)


func _on_scene_change_requested(scene_id: SceneID) -> void:
	go_to(scene_id)
