class_name ScheduleProgramPicker
extends RefCounted

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
	content.custom_minimum_size = Vector2(500, 0)
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
	hint.text = "Choisissez un programme à diffuser à cette heure."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var program_list: VBoxContainer = VBoxContainer.new()
	program_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	program_list.add_theme_constant_override("separation", 6)
	scroll.add_child(program_list)

	var available_count: int = 0
	for program: Dictionary in programs:
		var compatible: bool = GameState.can_schedule_program(
			channel,
			week_number,
			day_index,
			slot_index,
			program
		)

		var program_button: Button = Button.new()
		program_button.text = "%s (%d min)" % [
			String(program.get("name", "Programme")),
			int(program.get("duration_minutes", 0))
		]
		program_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		program_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		program_button.custom_minimum_size = Vector2(0, 40)
		program_button.disabled = not compatible
		program_list.add_child(program_button)

		if not compatible:
			program_button.tooltip_text = "Ce programme ne peut pas être placé à cette heure."
			continue

		available_count += 1
		var captured_program: Dictionary = program.duplicate(true)
		program_button.pressed.connect(func() -> void:
			var placed: bool = GameState.schedule_program(
				channel,
				week_number,
				day_index,
				slot_index,
				captured_program
			)
			if not placed:
				return
			popup.hide()
			if refresh_callback.is_valid():
				refresh_callback.call()
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
	popup.popup_centered(Vector2i(560, 520))


static func _add_empty_message(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


static func _get_time_text(slot_index: int) -> String:
	var total_minutes: int = slot_index * 30
	var hour: int = int(total_minutes / 60)
	var minute: int = total_minutes % 60
	return "%02dh%02d" % [hour, minute]


static func _get_day_name(day_index: int) -> String:
	if day_index < 0 or day_index >= DAYS.size():
		return "Jour"
	return DAYS[day_index]
