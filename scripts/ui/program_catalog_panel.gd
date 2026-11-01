class_name ProgramCatalogPanel
extends RefCounted

const DraggableProgramButtonScript = preload("res://scripts/ui/draggable_program_button.gd")
const ScheduleWeekUsageScript = preload("res://scripts/ui/schedule_week_usage.gd")


static func build(
	parent: Control,
	editable: bool,
	programs: Array[Dictionary],
	on_program_selected: Callable = Callable(),
	channel: Dictionary = {},
	week_number: int = 1
) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.025)
	box.border_color = Color(1, 1, 1, 0.18)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 12.0
	box.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", box)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title: Label = Label.new()
	title.text = "Programmes"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	var hint: Label = Label.new()
	if editable:
		hint.text = "Cliquez sur une case horaire pour choisir un programme, ou glissez un titre sur la grille. Orange = déjà programmé dans cette semaine."
	else:
		hint.text = "Catalogue non modifiable. Cliquez sur un titre pour voir sa fiche."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	if programs.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucun programme disponible."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(empty_label)
		return

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

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

	for program: Dictionary in sorted_programs:
		var button: Button
		if editable:
			var draggable_button: DraggableProgramButton = DraggableProgramButtonScript.new()
			draggable_button.setup(program)
			button = draggable_button
		else:
			button = Button.new()

		button.text = "%s | %s | %d min" % [
			_get_format_name(program),
			String(program.get("name", "Programme")),
			int(program.get("duration_minutes", 0))
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 38)
		button.disabled = not on_program_selected.is_valid() and not editable

		if editable and not channel.is_empty():
			var already_scheduled: bool = ScheduleWeekUsageScript.is_program_scheduled(
				channel,
				week_number,
				program
			)
			ScheduleWeekUsageScript.apply_highlight(button, already_scheduled)

		if on_program_selected.is_valid():
			var captured_program: Dictionary = program.duplicate(true)
			button.pressed.connect(func() -> void:
				on_program_selected.call(captured_program)
			)

		list.add_child(button)


static func _get_format_name(program: Dictionary) -> String:
	var format_name: String = String(program.get("format", "Programme")).strip_edges()
	if format_name.is_empty():
		return "Programme"
	return format_name
