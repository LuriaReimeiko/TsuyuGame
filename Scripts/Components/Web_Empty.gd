extends Control

func _input(event: InputEvent) -> void:
	if event.pressed:
		var ok: bool = GameManager.request_mode_change(GameManager.Mode.MAIN_MENU)
		if not ok:
			push_error("WebEmpty: GameManager rejected transition to MAIN_MENU.")
			return
		SceneManager.go_to(SceneManager.SceneID.MAIN_MENU)
