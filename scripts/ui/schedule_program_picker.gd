class_name ScheduleProgramPicker
extends RefCounted

const ScheduleWeekUsageScript = preload("res://scripts/ui/schedule_week_usage.gd")
const ScheduleEpisodeHelperScript = preload("res://scripts/ui/schedule_episode_helper.gd")
const ScheduleEpisodePickerScript = preload("res://scripts/ui/schedule_episode_picker.gd")

const DAYS: Array[String] = [
	"Lundi",
	"Mardi",
	"Mercredi",
	"Jeudi",
	"Vendredi",
	"Samedi",
	"Dimanche"
]


static func open(
	anchor: Control,
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	programs: Array[Dictionary],
	refresh_callback: Callable
) -> void:
	if anchor == null:
		return

	var existing: Node = anchor.get_node_or_null("ScheduleProgramPicker")
	if existing != null:
		existing.queue_free()

	var popup: PopupPanel = PopupPanel.new()
	popup.name = "ScheduleProgramPicker"
	anchor.add_child(popup)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(640, 0)
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title: Label = Label.new()
	title.text = "Programmer %s" % _get_time_text(slot_index)
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var context_label: Label = Label.new()
	context_label.text = "%s | Semaine %d" % [
		_get_day_name(day_index),
		week_number
	]
	content.add_child(context_label)

	var hint: Label = Label.new()
	hint.text = "Choisissez un programme à diffuser à cette heure. Orange = déjà programmé dans cette semaine."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	var sorted_programs: Array[Dictionary] = []
	for program: Dictionary in programs:
		sorted_programs.append(program)
	sorted_programs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var type_a: String = _get_format_name(a).to_lower()
		var type_b: String = _get_format_name(b).to_lower()
		if type_a == type_b:
			return String(a.get("name", "Programme")).to_lower() < String(b.get("name", "Programme")).to_lower()
		return type_a < type_b
	)

	var filter_scroll: ScrollContainer = ScrollContainer.new()
	filter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	filter_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(filter_scroll)

	var filter_row: HBoxContainer = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	filter_scroll.add_child(filter_row)

	var filter_group: ButtonGroup = ButtonGroup.new()
	filter_group.allow_unpress = false
	var filter_buttons: Array[Button] = []
	var filter_values: Array[String] = []

	var all_button: Button = Button.new()
	all_button.text = "Tous"
	all_button.toggle_mode = true
	all_button.button_group = filter_group
	all_button.button_pressed = true
	filter_row.add_child(all_button)
	filter_buttons.append(all_button)
	filter_values.append("")

	var format_names: Array[String] = []
	for program: Dictionary in sorted_programs:
		var format_name: String = _get_format_name(program)
		if not format_names.has(format_name):
			format_names.append(format_name)
	format_names.sort_custom(func(a: String, b: String) -> bool:
		return a.to_lower() < b.to_lower()
	)

	for format_name: String in format_names:
		var filter_button: Button = Button.new()
		filter_button.text = format_name
		filter_button.toggle_mode = true
		filter_button.button_group = filter_group
		filter_row.add_child(filter_button)
		filter_buttons.append(filter_button)
		filter_values.append(format_name)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var program_list: VBoxContainer = VBoxContainer.new()
	program_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	program_list.add_theme_constant_override("separation", 6)
	scroll.add_child(program_list)

	var program_entries: Array[Dictionary] = []
	var available_count: int = 0
	for program: Dictionary in sorted_programs:
		var compatible: bool = GameState.can_schedule_program(
			channel,
			week_number,
			day_index,
			slot_index,
			program
		)
		var already_scheduled: bool = ScheduleWeekUsageScript.is_program_scheduled(
			channel,
			week_number,
			program
		)

		var program_button: Button = Button.new()
		var format_name: String = _get_format_name(program)
		program_button.text = "%s | %s | %d min" % [
			format_name,
			String(program.get("name", "Programme")),
			int(program.get("duration_minutes", 0))
		]
		program_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		program_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		program_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		program_button.custom_minimum_size = Vector2(0, 40)
		ScheduleWeekUsageScript.apply_highlight(program_button, already_scheduled)
		program_button.disabled = not compatible
		program_list.add_child(program_button)
		program_entries.append({"button": program_button, "format": format_name})

		if not compatible:
			program_button.tooltip_text = "Ce programme ne peut pas être placé à cette heure."
			continue

		available_count += 1
		var captured_program: Dictionary = program.duplicate(true)
		program_button.pressed.connect(func() -> void:
			if ScheduleEpisodeHelperScript.requires_episode_choice(captured_program):
				popup.hide()
				ScheduleEpisodePickerScript.open(
					anchor,
					channel,
					week_number,
					day_index,
					slot_index,
					captured_program,
					refresh_callback
				)
				return

			var placed: bool = GameState.schedule_program(
				channel,
				week_number,
				day_index,
				slot_index,
				captured_program,
				{}
			)
			if not placed:
				return
			popup.hide()
			if refresh_callback.is_valid():
				refresh_callback.call()
		)

	for filter_index: int in range(filter_buttons.size()):
		var filter_button: Button = filter_buttons[filter_index]
		var filter_value: String = filter_values[filter_index]
		filter_button.pressed.connect(func() -> void:
			for entry: Dictionary in program_entries:
				var entry_button: Button = entry.get("button") as Button
				if entry_button == null:
					continue
				entry_button.visible = filter_value.is_empty() or String(entry.get("format", "")) == filter_value
		)

	if programs.is_empty():
		_add_empty_message(program_list, "Aucun programme disponible.")
	elif available_count == 0:
		_add_empty_message(
			program_list,
			"Aucun programme ne peut être placé sur ce créneau."
		)

	var cancel_button: Button = Button.new()
	cancel_button.text = "Annuler"
	cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel_button.pressed.connect(popup.hide)
	content.add_child(cancel_button)

	popup.popup_hide.connect(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)
	popup.popup_centered(Vector2i(700, 560))


static func _add_empty_message(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


static func _get_format_name(program: Dictionary) -> String:
	var format_name: String = String(program.get("format", "Programme")).strip_edges()
	if format_name.is_empty():
		return "Programme"
	return format_name


static func _get_time_text(slot_index: int) -> String:
	var total_minutes: int = slot_index * 30
	var hour: int = int(total_minutes / 60)
	var minute: int = total_minutes % 60
	return "%02dh%02d" % [hour, minute]


static func _get_day_name(day_index: int) -> String:
	if day_index < 0 or day_index >= DAYS.size():
		return "Jour"
	return DAYS[day_index]
