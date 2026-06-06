extends Node

## SceneManager
## Loads and unloads scenes into a persistent SceneContainer node.
## Plays a fade transition between every scene change.
## GameManager decides what mode the game is in.
## SceneManager decides what is on screen.
##
## Flow for go_to(id):
##   1. Fade out (overlay becomes opaque)
##   2. Remove current scene from container
##   3. Load and add next scene to container
##   4. Notify GameManager (caller's responsibility via mode change)
##   5. Fade in (overlay becomes transparent)


# ------------------------------------------------------------------ #
#  Scene registry                                                      #
# ------------------------------------------------------------------ #

enum SceneID {
	MAIN_MENU,
	WEB_EMPTY,
	OVERWORLD,
	RESTAURANT,
	RESTAURANT_EDITOR,
	GATHERING_FOREST,
	GATHERING_RIVER,
	MINIGAME_FISHING,
}

const SCENE_PATHS: Dictionary = {
	SceneID.MAIN_MENU:        "res://Scenes/Ui/MainMenu.tscn",
	SceneID.WEB_EMPTY:        "res://Scenes/Ui/WebEmpty.tscn",
	SceneID.OVERWORLD:        "res://Scenes/World/Overworld.tscn",
	SceneID.RESTAURANT:       "res://Scenes/Restaurant/Restaurant.tscn",
	SceneID.RESTAURANT_EDITOR:"res://Scenes/Restaurant/RestaurantEditor.tscn",
	SceneID.GATHERING_FOREST: "res://Scenes/Gathering/ForestZone.tscn",
	SceneID.GATHERING_RIVER:  "res://Scenes/Gathering/RiverZone.tscn",
	SceneID.MINIGAME_FISHING: "res://Scenes/Gathering/FishingMinigame.tscn",
}


# ------------------------------------------------------------------ #
#  Transition config                                                   #
# ------------------------------------------------------------------ #

const FADE_DURATION: float = 0.35  ## Seconds for fade-out or fade-in.


# ------------------------------------------------------------------ #
#  State                                                               #
# ------------------------------------------------------------------ #

var _scene_container: Node = null
var _transition_overlay: ColorRect = null
var _current_scene: Node = null
var _current_scene_id: SceneID
var _is_transitioning: bool = false


# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #

func _ready() -> void:
	assert(EventBus != null, "SceneManager: EventBus not found.")
	EventBus.scene_change_requested.connect(_on_scene_change_requested)


# ------------------------------------------------------------------ #
#  Setup (called by Root before first go_to)                          #
# ------------------------------------------------------------------ #

func set_scene_container(container: Node) -> void:
	_scene_container = container


func set_transition_overlay(overlay: ColorRect) -> void:
	_transition_overlay = overlay
	# Start fully transparent — no overlay visible at launch.
	_transition_overlay.modulate.a = 0.0
	_transition_overlay.visible = true


# ------------------------------------------------------------------ #
#  Public API                                                          #
# ------------------------------------------------------------------ #

func go_to(scene_id: SceneID) -> void:
	if _is_transitioning:
		push_warning("SceneManager: go_to() called during an active transition. Ignored.")
		return
	if _scene_container == null:
		push_error("SceneManager: scene container not set. Call set_scene_container() from Root.")
		return
	if not SCENE_PATHS.has(scene_id):
		push_error("SceneManager: no path registered for SceneID %d." % scene_id)
		return

	_is_transitioning = true
	_transition_sequence.call_deferred(scene_id)


func get_current_scene_id() -> SceneID:
	return _current_scene_id


func is_transitioning() -> bool:
	return _is_transitioning


# ------------------------------------------------------------------ #
#  Transition sequence                                                 #
# ------------------------------------------------------------------ #

func _transition_sequence(scene_id: SceneID) -> void:
	# 1. Fade out.
	await _fade(1.0)

	# 2. Remove the current scene if one exists.
	if _current_scene != null:
		EventBus.scene_unloaded.emit(_current_scene_id)
		_current_scene.queue_free()
		_current_scene = null
		# Wait one frame so queue_free completes before loading the next scene.
		await get_tree().process_frame

	# 3. Load and add the next scene.
	var path: String = SCENE_PATHS[scene_id]
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("SceneManager: failed to load scene at '%s'." % path)
		_is_transitioning = false
		await _fade(0.0)
		return

	_current_scene = packed.instantiate()
	_scene_container.add_child(_current_scene)
	_current_scene_id = scene_id

	# 4. Emit loaded signal before fading in so the scene can
	#    finish its own _ready() while the screen is still black.
	EventBus.scene_loaded.emit(scene_id)

	# 5. Fade in.
	await _fade(0.0)

	_is_transitioning = false


# ------------------------------------------------------------------ #
#  Fade helper                                                         #
# ------------------------------------------------------------------ #

## Animate the overlay alpha to [param target_alpha] over FADE_DURATION.
## await this call to block until the tween completes.
func _fade(target_alpha: float) -> void:
	if _transition_overlay == null:
		return

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(
		_transition_overlay,
		"modulate:a",
		target_alpha,
		FADE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN if target_alpha > 0.0 else Tween.EASE_OUT
	)
	await tween.finished


# ------------------------------------------------------------------ #
#  Signal handler                                                      #
# ------------------------------------------------------------------ #

func _on_scene_change_requested(scene_id: SceneID) -> void:
	go_to(scene_id)
