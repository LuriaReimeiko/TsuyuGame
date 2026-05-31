extends Node

## GameManager
## Owns the top-level game mode state machine and the master time scale.
## Does NOT load scenes — that is SceneManager's responsibility.
## Does NOT store save data — that is SaveManager's responsibility.
##
## Other systems read the current mode to decide their own behaviour,
## but they should not change the mode directly. Always call
## GameManager.request_mode_change() so the transition is validated
## and the signal fires exactly once.


# ------------------------------------------------------------------ #
#  Mode definition                                                     #
# ------------------------------------------------------------------ #

enum Mode {
	NONE,        ## Initial state before a save is loaded.
	MAIN_MENU,
	OVERWORLD,
	RESTAURANT,  ## Service is running.
	BUILD,       ## Restaurant build/edit mode (sub-state of RESTAURANT context).
	FARM,        ## Tending the plot outside the restaurant.
	MINIGAME,    ## An active minigame (fishing, foraging prompt, etc.).
	PAUSED,      ## Game is paused; previous mode is stored for resume.
}

# Human-readable names used for debug output only.
const MODE_NAMES: Dictionary = {
	Mode.NONE:       "None",
	Mode.MAIN_MENU:  "MainMenu",
	Mode.OVERWORLD:  "Overworld",
	Mode.RESTAURANT: "Restaurant",
	Mode.BUILD:      "Build",
	Mode.FARM:       "Farm",
	Mode.MINIGAME:   "Minigame",
	Mode.PAUSED:     "Paused",
}


# ------------------------------------------------------------------ #
#  Valid transitions table                                             #
# ------------------------------------------------------------------ #
# Explicit allowlist keeps accidental transitions from silently        #
# succeeding. Add entries here as new transitions become necessary.    #

const VALID_TRANSITIONS: Dictionary = {
	Mode.NONE:       [Mode.MAIN_MENU],
	Mode.MAIN_MENU:  [Mode.OVERWORLD],
	Mode.OVERWORLD:  [Mode.RESTAURANT, Mode.FARM, Mode.MAIN_MENU],
	Mode.RESTAURANT: [Mode.BUILD, Mode.OVERWORLD, Mode.PAUSED],
	Mode.BUILD:      [Mode.RESTAURANT, Mode.PAUSED],
	Mode.FARM:       [Mode.OVERWORLD, Mode.PAUSED],
	Mode.MINIGAME:   [Mode.OVERWORLD],
	Mode.PAUSED:     [Mode.RESTAURANT, Mode.BUILD, Mode.OVERWORLD, Mode.FARM],
}


# ------------------------------------------------------------------ #
#  State                                                               #
# ------------------------------------------------------------------ #

var current_mode: Mode = Mode.NONE

## Mode stored before entering PAUSED so it can be resumed.
var _mode_before_pause: Mode = Mode.NONE

## Master time scale applied to all in-game timers.
## 1.0 = normal speed. Does NOT affect Engine.time_scale (which would
## also slow down UI animations and input). Managed manually per timer.
var time_scale: float = 1.0:
	set(value):
		time_scale = clampf(value, 0.1, 5.0)
		EventBus.time_scale_changed.emit(time_scale)

var day_number: int = 1


# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #

func _ready() -> void:
	# Verify EventBus is available (autoload order matters in Project Settings).
	assert(EventBus != null, "GameManager: EventBus autoload not found. Check autoload order.")


# ------------------------------------------------------------------ #
#  Mode transitions                                                    #
# ------------------------------------------------------------------ #

## Request a transition to [param next_mode].
## Returns true if the transition was accepted, false if it was rejected.
func request_mode_change(next_mode: Mode) -> bool:
	if not _is_transition_valid(current_mode, next_mode):
		push_warning(
			"GameManager: invalid transition %s → %s" % [
				MODE_NAMES.get(current_mode, "?"),
				MODE_NAMES.get(next_mode, "?")
			]
		)
		return false

	var previous: Mode = current_mode

	if next_mode == Mode.PAUSED:
		_mode_before_pause = current_mode

	_set_mode(next_mode)
	EventBus.game_mode_changed.emit(previous, current_mode)
	return true


## Convenience wrapper: resume from PAUSED back to the previous mode.
func resume() -> bool:
	if current_mode != Mode.PAUSED:
		push_warning("GameManager: resume() called but mode is not PAUSED.")
		return false
	return request_mode_change(_mode_before_pause)


## Returns whether the game is currently in an active gameplay mode
## (i.e. a save is loaded and the player is in the world).
func is_in_game() -> bool:
	return current_mode not in [Mode.NONE, Mode.MAIN_MENU]


# ------------------------------------------------------------------ #
#  Day cycle                                                           #
# ------------------------------------------------------------------ #

func advance_day() -> void:
	EventBus.day_ended.emit(day_number)
	day_number += 1
	EventBus.day_started.emit(day_number)


# ------------------------------------------------------------------ #
#  Internal                                                            #
# ------------------------------------------------------------------ #

func _is_transition_valid(from: Mode, to: Mode) -> bool:
	var allowed: Array = VALID_TRANSITIONS.get(from, [])
	return to in allowed


func _set_mode(mode: Mode) -> void:
	current_mode = mode
