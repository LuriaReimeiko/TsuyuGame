extends Node

## Root
## The persistent root scene. Set this as the Main Scene in Project Settings.
## It never changes — scenes are loaded as children of SceneContainer.
##
## Scene tree layout:
##   Root                       (this script)
##   ├── SceneContainer         (Node — child scenes load here)
##   └── TransitionLayer        (CanvasLayer, layer=10 — always on top)
##       └── TransitionOverlay  (ColorRect, full-screen, handles fade)
##
## This node exists only to:
##   1. Hold the SceneContainer where SceneManager swaps scenes in/out.
##   2. Hold the TransitionLayer so it persists above all scenes.
##   3. Kick off the first scene transition on _ready().


@onready var scene_container: Node = $SceneContainer
@onready var transition_overlay: ColorRect = $TransitionLayer/TransitionOverlay


func _ready() -> void:
	# Give SceneManager a reference to the container node so it knows
	# where to place loaded scenes.
	SceneManager.set_scene_container(scene_container)
	SceneManager.set_transition_overlay(transition_overlay)

	# Start at the main menu.
	GameManager.request_mode_change(GameManager.Mode.MAIN_MENU)
	SceneManager.go_to(SceneManager.SceneID.MAIN_MENU)
