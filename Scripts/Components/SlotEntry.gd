extends PanelContainer

## SlotEntry
## A single save slot row in the slot selection panel.
## Populated by MainMenu via setup(). Emits slot_selected when clicked.


signal slot_selected(slot_index: int)


@onready var lbl_slot: Label = $Margin/Row/Slot
@onready var lbl_info: Label = $Margin/Row/Info
@onready var lbl_date: Label = $Margin/Row/Date
@onready var btn_select: Button = $Margin/Row/Select

var _slot_index: int = -1


func setup(info: Dictionary, is_new_game: bool) -> void:
	_slot_index = info["slot"]
	lbl_slot.text = "Slot %d" % (_slot_index + 1)

	if not info["exists"]:
		lbl_info.text = "Empty"
		lbl_date.text = ""
		btn_select.text = "New Game"
	else:
		lbl_info.text = "Day %d  —  %s" % [
			info["day"],
			_format_playtime(info["playtime_seconds"])
		]
		lbl_date.text = _format_timestamp(info["timestamp"])
		btn_select.text = "New Game" if is_new_game else "Load"

	btn_select.pressed.connect(_on_select_pressed)


func _on_select_pressed() -> void:
	slot_selected.emit(_slot_index)


# ------------------------------------------------------------------ #
#  Formatting helpers                                                  #
# ------------------------------------------------------------------ #

func _format_playtime(seconds: float) -> String:
	var h: int = floor(seconds / 3600.)
	var m: int = floor(fmod(seconds, 3600.) / 60.)
	return "%dh %02dm" % [h, m]


func _format_timestamp(unix_time: int) -> String:
	if unix_time == 0:
		return ""
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]
