class_name ScheduleSlotButton
extends Button

const ScheduleProgramPickerScript = preload("res://scripts/ui/schedule_program_picker.gd")
const ScheduleEpisodeHelperScript = preload("res://scripts/ui/schedule_episode_helper.gd")
const ScheduleEpisodePickerScript = preload("res://scripts/ui/schedule_episode_picker.gd")

var channel: Dictionary = {}
var week_number: int = 1
var day_index: int = 0
var slot_index: int = 0
var refresh_callback: Callable = Callable()


func configure(
	new_channel: Dictionary,
	new_week_number: int,
	new_day_index: int,
	new_slot_index: int,
	new_refresh_callback: Callable
) -> void:
	channel = new_channel.duplicate(true)
	week_number = new_week_number
	day_index = new_day_index
	slot_index = new_slot_index
	refresh_callback = new_refresh_callback

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	tooltip_text = "Cliquez pour programmer ce créneau, ou glissez-déposez un programme."


func _on_pressed() -> void:
	var day_slots: Array[Dictionary] = GameState.get_player_day_schedule(
		channel,
		week_number,
		day_index
	)
	if slot_index < 0 or slot_index >= day_slots.size():
		return

	var slot_entry: Dictionary = day_slots[slot_index]
	if slot_entry.is_empty():
		ScheduleProgramPickerScript.open(
			self,
			channel,
			week_number,
			day_index,
			slot_index,
			GameState.get_group_programs(),
			refresh_callback
		)
		return

	if String(slot_entry.get("kind", "")) != "start":
		return
	if int(slot_entry.get("episode_global", 0)) > 0:
		return

	var program: Dictionary = _get_program_for_slot(slot_entry)
	if program.is_empty() or not ScheduleEpisodeHelperScript.requires_episode_choice(program):
		return

	ScheduleEpisodePickerScript.open(
		self,
		channel,
		week_number,
		day_index,
		slot_index,
		program,
		refresh_callback
	)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false

	var drag_data: Dictionary = data as Dictionary
	if String(drag_data.get("type", "")) != "program":
		return false

	var program_value: Variant = drag_data.get("program", {})
	if not program_value is Dictionary:
		return false

	return GameState.can_schedule_program(
		channel,
		week_number,
		day_index,
		slot_index,
		program_value as Dictionary
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return

	var drag_data: Dictionary = data as Dictionary
	var program_value: Variant = drag_data.get("program", {})
	if not program_value is Dictionary:
		return

	var program: Dictionary = (program_value as Dictionary).duplicate(true)
	if ScheduleEpisodeHelperScript.requires_episode_choice(program):
		ScheduleEpisodePickerScript.open(
			self,
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			refresh_callback
		)
		return

	var placed: bool = GameState.schedule_program(
		channel,
		week_number,
		day_index,
		slot_index,
		program,
		{}
	)
	if placed and refresh_callback.is_valid():
		refresh_callback.call()


func _get_program_for_slot(slot_entry: Dictionary) -> Dictionary:
	var program_id: String = String(slot_entry.get("program_id", ""))
	if not program_id.is_empty():
		var program_by_id: Dictionary = GameState.get_program(program_id)
		if not program_by_id.is_empty():
			return program_by_id

	var program_name: String = String(slot_entry.get("program_name", ""))
	for program: Dictionary in GameState.get_group_programs():
		if String(program.get("name", "")) == program_name:
			return program.duplicate(true)
	return {}
