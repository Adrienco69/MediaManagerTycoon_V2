class_name ScheduleWeekSelector
extends RefCounted

const CalendarThemeScript = preload("res://scripts/calendar_theme.gd")
const MONTH_WEEKS: Array[int] = [7, 8, 7, 8, 7, 8, 7]
const POPUP_WIDTH: int = 320
const POPUP_HEIGHT: int = 560


static func build(on_week_changed: Callable) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label: Label = Label.new()
	label.text = "Semaine :"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var selector_button: Button = Button.new()
	selector_button.custom_minimum_size = Vector2(235, 38)
	selector_button.text = _get_week_text(1)
	_apply_month_style(selector_button, 0, false)
	row.add_child(selector_button)

	var popup: PopupPanel = PopupPanel.new()
	popup.name = "WeekPopup"
	row.add_child(popup)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	popup.add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(POPUP_WIDTH - 12, POPUP_HEIGHT - 12)
	margin.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)

	var week_buttons: Array[Button] = []
	for week_number: int in range(1, 53):
		var month_index: int = _get_month_index_for_week(week_number)
		var week_button: Button = Button.new()
		week_button.text = _get_week_text(week_number)
		week_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		week_button.custom_minimum_size = Vector2(285, 36)
		week_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_month_style(week_button, month_index, week_number == 1)
		list.add_child(week_button)
		week_buttons.append(week_button)

		var captured_week: int = week_number
		week_button.pressed.connect(func() -> void:
			_select_week(
				captured_week,
				selector_button,
				week_buttons,
				popup,
				on_week_changed
			)
		)

	selector_button.pressed.connect(func() -> void:
		var popup_position: Vector2 = selector_button.global_position + Vector2(0, selector_button.size.y + 4)
		popup.popup(Rect2i(
			Vector2i(int(popup_position.x), int(popup_position.y)),
			Vector2i(POPUP_WIDTH, POPUP_HEIGHT)
		))
	)

	return row


static func _select_week(
	week_number: int,
	selector_button: Button,
	week_buttons: Array[Button],
	popup: PopupPanel,
	on_week_changed: Callable
) -> void:
	var selected_month_index: int = _get_month_index_for_week(week_number)
	selector_button.text = _get_week_text(week_number)
	_apply_month_style(selector_button, selected_month_index, false)

	for index: int in range(week_buttons.size()):
		var item_week: int = index + 1
		var item_month_index: int = _get_month_index_for_week(item_week)
		_apply_month_style(week_buttons[index], item_month_index, item_week == week_number)

	popup.hide()
	on_week_changed.call(week_number)


static func _get_week_text(week_number: int) -> String:
	var month_index: int = _get_month_index_for_week(week_number)
	var palette: Dictionary = CalendarThemeScript.PALETTES[month_index]
	return "Semaine %d | %s" % [week_number, String(palette["name"])]


static func _get_month_index_for_week(week_number: int) -> int:
	var first_week: int = 1
	for month_index: int in range(MONTH_WEEKS.size()):
		var last_week: int = first_week + MONTH_WEEKS[month_index] - 1
		if week_number >= first_week and week_number <= last_week:
			return month_index
		first_week = last_week + 1
	return MONTH_WEEKS.size() - 1


static func _apply_month_style(button: Button, month_index: int, selected: bool) -> void:
	var palette: Dictionary = CalendarThemeScript.PALETTES[month_index]
	var accent: Color = palette["accent"]
	var normal_color: Color = accent.darkened(0.55 if not selected else 0.35)
	var hover_color: Color = accent.darkened(0.25)
	var pressed_color: Color = accent.darkened(0.15)

	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

	button.add_theme_stylebox_override("normal", _make_box(normal_color))
	button.add_theme_stylebox_override("hover", _make_box(hover_color))
	button.add_theme_stylebox_override("pressed", _make_box(pressed_color))
	button.add_theme_stylebox_override("focus", _make_box(hover_color))


static func _make_box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 5
	box.corner_radius_top_right = 5
	box.corner_radius_bottom_left = 5
	box.corner_radius_bottom_right = 5
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	return box
