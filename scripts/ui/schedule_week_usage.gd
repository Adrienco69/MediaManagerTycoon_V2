class_name ScheduleWeekUsage
extends RefCounted


static func is_program_scheduled(
	channel: Dictionary,
	week_number: int,
	program: Dictionary
) -> bool:
	var program_id: String = String(program.get("id", ""))
	var program_name: String = String(program.get("name", ""))
	if program_id.is_empty() and program_name.is_empty():
		return false

	for day_index: int in range(7):
		var day_slots: Array[Dictionary] = GameState.get_player_day_schedule(
			channel,
			week_number,
			day_index
		)
		for slot_entry: Dictionary in day_slots:
			if slot_entry.is_empty():
				continue
			if String(slot_entry.get("kind", "")) != "start":
				continue

			var scheduled_id: String = String(slot_entry.get("program_id", ""))
			var scheduled_name: String = String(slot_entry.get("program_name", ""))
			if not program_id.is_empty() and scheduled_id == program_id:
				return true
			if program_id.is_empty() and scheduled_name == program_name:
				return true

	return false


static func apply_highlight(button: Button, highlighted: bool) -> void:
	if not highlighted:
		return

	button.tooltip_text = "Déjà programmé au moins une fois dans cette semaine."
	button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.86, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_box(Color(0.78, 0.36, 0.08, 0.55)))
	button.add_theme_stylebox_override("hover", _make_box(Color(0.88, 0.45, 0.10, 0.72)))
	button.add_theme_stylebox_override("pressed", _make_box(Color(0.68, 0.29, 0.05, 0.78)))


static func _make_box(background_color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = background_color
	box.border_color = Color(1.0, 0.58, 0.18, 0.95)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	return box
