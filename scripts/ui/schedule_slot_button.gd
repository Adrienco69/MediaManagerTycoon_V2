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

	tooltip_text = "Cliquez pour programmer ce créneau, glissez-déposez un programme, ou déposez la poubelle sur une diffusion."


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


func _get_drag_data(_at_position: Vector2) -> Variant:
	var source_data: Dictionary = _get_source_drag_data()
	if source_data.is_empty():
		return null

	var preview: Label = Label.new()
	var program: Dictionary = source_data.get("program", {})
	preview.text = "Déplacer : %s" % String(program.get("name", "Programme"))
	preview.add_theme_font_size_override("font_size", 16)
	set_drag_preview(preview)
	return source_data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false

	var drag_data: Dictionary = data as Dictionary
	var drag_type: String = String(drag_data.get("type", ""))

	if drag_type == "schedule_trash":
		return not _get_source_drag_data().is_empty()

	if drag_type != "program" and drag_type != "scheduled_program":
		return false

	var program_value: Variant = drag_data.get("program", {})
	if not program_value is Dictionary:
		return false

	return GameState.can_fit_schedule_program(
		channel,
		week_number,
		day_index,
		slot_index,
		program_value as Dictionary
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return

	var drag_data: Dictionary = (data as Dictionary).duplicate(true)
	var drag_type: String = String(drag_data.get("type", ""))

	if drag_type == "schedule_trash":
		_open_delete_confirmation()
		return

	var program_value: Variant = drag_data.get("program", {})
	if not program_value is Dictionary:
		return

	if drag_type == "scheduled_program":
		if (
			int(drag_data.get("source_week", -1)) == week_number
			and int(drag_data.get("source_day", -1)) == day_index
			and int(drag_data.get("source_slot", -1)) == slot_index
		):
			return

	var program: Dictionary = (program_value as Dictionary).duplicate(true)
	var ignored_start: int = -1
	if (
		drag_type == "scheduled_program"
		and int(drag_data.get("source_week", -1)) == week_number
		and int(drag_data.get("source_day", -1)) == day_index
	):
		ignored_start = int(drag_data.get("source_slot", -1))

	var conflicts: Array[Dictionary] = GameState.get_schedule_conflicts(
		channel,
		week_number,
		day_index,
		slot_index,
		program,
		ignored_start
	)

	if conflicts.is_empty():
		_perform_drop(drag_data, false)
		return

	_open_replace_confirmation(drag_data, conflicts)


func _perform_drop(drag_data: Dictionary, replace_conflicts: bool) -> void:
	var program_value: Variant = drag_data.get("program", {})
	if not program_value is Dictionary:
		return
	var program: Dictionary = (program_value as Dictionary).duplicate(true)
	var drag_type: String = String(drag_data.get("type", ""))

	if drag_type == "scheduled_program":
		var moved: bool = GameState.move_scheduled_program(
			channel,
			int(drag_data.get("source_week", week_number)),
			int(drag_data.get("source_day", day_index)),
			int(drag_data.get("source_slot", slot_index)),
			week_number,
			day_index,
			slot_index,
			replace_conflicts
		)
		if moved and refresh_callback.is_valid():
			refresh_callback.call()
		return

	if ScheduleEpisodeHelperScript.requires_episode_choice(program):
		ScheduleEpisodePickerScript.open(
			self,
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			refresh_callback,
			replace_conflicts
		)
		return

	var placed: bool = false
	if replace_conflicts:
		placed = GameState.replace_scheduled_program(
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			{}
		)
	else:
		placed = GameState.schedule_program(
			channel,
			week_number,
			day_index,
			slot_index,
			program,
			{}
		)
	if placed and refresh_callback.is_valid():
		refresh_callback.call()


func _open_replace_confirmation(
	drag_data: Dictionary,
	conflicts: Array[Dictionary]
) -> void:
	var program_value: Variant = drag_data.get("program", {})
	if not program_value is Dictionary:
		return
	var new_name: String = String((program_value as Dictionary).get("name", "Programme"))
	var conflict_names: Array[String] = []
	for conflict: Dictionary in conflicts:
		var name: String = String(conflict.get("program_name", "Programme"))
		if not conflict_names.has(name):
			conflict_names.append(name)
	var old_name: String = ", ".join(conflict_names)

	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Remplacer la diffusion ?"
	dialog.dialog_text = "Voulez-vous remplacer %s par %s ?" % [old_name, new_name]
	dialog.ok_button_text = "Remplacer"
	dialog.cancel_button_text = "Annuler"
	add_child(dialog)

	dialog.confirmed.connect(func() -> void:
		_perform_drop(drag_data, true)
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.popup_centered(Vector2i(520, 210))


func _open_delete_confirmation() -> void:
	var source_data: Dictionary = _get_source_drag_data()
	if source_data.is_empty():
		return

	var program_value: Variant = source_data.get("program", {})
	var program_name: String = "cette diffusion"
	if program_value is Dictionary:
		program_name = String((program_value as Dictionary).get("name", program_name))

	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Supprimer la diffusion ?"
	dialog.dialog_text = "Voulez-vous supprimer %s de la grille ?\nLe programme restera dans votre bibliothèque." % program_name
	dialog.ok_button_text = "Supprimer"
	dialog.cancel_button_text = "Annuler"
	add_child(dialog)

	dialog.confirmed.connect(func() -> void:
		var removed: bool = GameState.remove_scheduled_program(
			channel,
			week_number,
			day_index,
			int(source_data.get("source_slot", slot_index))
		)
		if removed and refresh_callback.is_valid():
			refresh_callback.call()
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.popup_centered(Vector2i(520, 220))


func _get_source_drag_data() -> Dictionary:
	var day_slots: Array[Dictionary] = GameState.get_player_day_schedule(
		channel,
		week_number,
		day_index
	)
	if slot_index < 0 or slot_index >= day_slots.size():
		return {}

	var entry: Dictionary = day_slots[slot_index]
	if entry.is_empty():
		return {}
	var source_start: int = int(entry.get("start_slot", slot_index))
	if source_start < 0 or source_start >= day_slots.size():
		return {}
	var start_entry: Dictionary = day_slots[source_start]
	if start_entry.is_empty():
		return {}

	var program: Dictionary = _get_program_for_slot(start_entry)
	if program.is_empty():
		program = {
			"id": String(start_entry.get("program_id", "")),
			"name": String(start_entry.get("program_name", "Programme")),
			"duration_minutes": int(start_entry.get("duration_minutes", 30))
		}

	return {
		"type": "scheduled_program",
		"program": program.duplicate(true),
		"episode_data": {
			"episode_global": int(start_entry.get("episode_global", 0)),
			"season_number": int(start_entry.get("season_number", 0)),
			"episode_number": int(start_entry.get("episode_number", 0))
		},
		"source_week": week_number,
		"source_day": day_index,
		"source_slot": source_start
	}


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
