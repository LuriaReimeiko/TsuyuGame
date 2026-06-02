extends Control

## MainMenu
## Handles the main menu UI: new game, continue, slot selection, quit.
## Reads slot info from SaveManager to populate the save slot display.
## Does not know about scenes or game state directly — it requests
## transitions via GameManager and SceneManager.


# ------------------------------------------------------------------ #
#  Node references                                                     #
# ------------------------------------------------------------------ #
# These match the node names you will create in MainMenu.tscn.
# Adjust paths if your scene tree differs.

@onready var btn_container: VBoxContainer = $Layout/ButtonContainer
@onready var btn_new_game: Button = $Layout/ButtonContainer/NewGame
@onready var btn_continue: Button = $Layout/ButtonContainer/Continue
@onready var btn_quit: Button = $Layout/ButtonContainer/Quit
@onready var slot_panel: Control = $Layout/SlotPanel
@onready var slot_container: VBoxContainer = $Layout/SlotPanel/Separator/SlotContainer
@onready var slot_label: Label = $Layout/SlotPanel/Separator/SlotLabel

## Preloaded slot entry scene — a small panel showing day, playtime, date.
## Create SlotEntry.tscn as a simple panel with labels; wire it below.
const SLOT_ENTRY_SCENE: PackedScene = preload("res://Scenes/Ui/SlotEntry.tscn")

## Whether we are picking a slot for a new game or continuing an old one.
var _picking_for_new_game: bool = false


# ------------------------------------------------------------------ #
#  Lifecycle                                                           #
# ------------------------------------------------------------------ #

func _ready() -> void:
	assert(
		GameManager.current_mode == GameManager.Mode.MAIN_MENU,
		"MainMenu: loaded while GameManager is not in MAIN_MENU mode."
	)

	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	slot_panel.visible = false
	_refresh_continue_button()


func _unhandled_input(event: InputEvent) -> void:
	# Escape: Return to default state
	if event.is_action_pressed("ui_cancel"):
		if slot_panel.visible:
			slot_panel.visible = false
			btn_container.visible = true


# ------------------------------------------------------------------ #
#  Button handlers                                                     #
# ------------------------------------------------------------------ #

func _on_new_game_pressed() -> void:
	_picking_for_new_game = true
	slot_label.text = "Choose a slot for your new game"
	_show_slot_panel()


func _on_continue_pressed() -> void:
	_picking_for_new_game = false
	slot_label.text = "Continue"
	_show_slot_panel()


func _on_quit_pressed() -> void:
	if OS.get_name() == "Web":
		var ok: bool = GameManager.request_mode_change(GameManager.Mode.WEB_EMPTY)
		if not ok:
			push_error("MainMenu: GameManager rejected transition to WEB_EMPTY.")
			return
		SceneManager.go_to(SceneManager.SceneID.WEB_EMPTY)
	else:
		get_tree().quit()


# ------------------------------------------------------------------ #
#  Slot panel                                                          #
# ------------------------------------------------------------------ #

func _show_slot_panel() -> void:
	# Clear previous entries.
	for child in slot_container.get_children():
		child.queue_free()

	var slot_infos: Array[Dictionary] = SaveManager.get_all_slot_info()

	for info in slot_infos:
		# Skip empty slots when continuing.
		if not _picking_for_new_game and not info["exists"]:
			continue

		var entry: Control = SLOT_ENTRY_SCENE.instantiate()
		slot_container.add_child(entry)
		entry.setup(info, _picking_for_new_game)
		entry.slot_selected.connect(_on_slot_selected)

	slot_panel.visible = true
	btn_container.visible = false


func _on_slot_selected(slot_index: int) -> void:
	slot_panel.visible = false
	btn_container.visible = true

	if _picking_for_new_game:
		SaveManager.new_game(slot_index)
	else:
		var success: bool = SaveManager.load_slot(slot_index)
		if not success:
			push_error("MainMenu: failed to load slot %d." % slot_index)
			return

	_start_game()


# ------------------------------------------------------------------ #
#  Transition to game                                                  #
# ------------------------------------------------------------------ #

func _start_game() -> void:
	var ok: bool = GameManager.request_mode_change(GameManager.Mode.OVERWORLD)
	if not ok:
		push_error("MainMenu: GameManager rejected transition to OVERWORLD.")
		return
	SceneManager.go_to(SceneManager.SceneID.OVERWORLD)


# ------------------------------------------------------------------ #
#  Helpers                                                             #
# ------------------------------------------------------------------ #

func _refresh_continue_button() -> void:
	## Disable "Continue" if no save slots exist yet.
	var any_exists: bool = false
	for info in SaveManager.get_all_slot_info():
		if info["exists"]:
			any_exists = true
			break
	btn_continue.disabled = not any_exists
