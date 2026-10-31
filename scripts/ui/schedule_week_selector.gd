class_name ScheduleWeekSelector
extends RefCounted

const CalendarThemeScript = preload("res://scripts/calendar_theme.gd")
const MONTH_WEEKS: Array[int] = [7, 8, 7, 8, 7, 8, 7]


static func build(on_week_changed: Callable) -> OptionButton:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label: Label = Label.new()
	label.text = "Semaine"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var selector: OptionButton = OptionButton.new()
	selector.custom_minimum_size = Vector2(220, 38)

	for week_number: int in range(1, 53):
		var month_index: int = _get_month_index_for_week(week_number)
		var palette: Dictionary = CalendarThemeScript.PALETTES[month_index]
		var month_name: String = String(palette["name"])
		var accent: Color = palette["accent"]
		selector.add_icon_item(
			_make_color_icon(accent),
			"Semaine %d — %s" % [week_number, month_name],
			week_number
		)

	selector.select(0)
	selector.item_selected.connect(func(index: int) -> void:
		on_week_changed.call(index + 1)
	)
	row.add_child(selector)
	selector.set_meta("container", row)
	return selector


static func get_container(selector: OptionButton) -> HBoxContainer:
	return selector.get_meta("container") as HBoxContainer


static func _get_month_index_for_week(week_number: int) -> int:
	var first_week: int = 1
	for month_index: int in range(MONTH_WEEKS.size()):
		var last_week: int = first_week + MONTH_WEEKS[month_index] - 1
		if week_number >= first_week and week_number <= last_week:
			return month_index
		first_week = last_week + 1
	return MONTH_WEEKS.size() - 1


static func _make_color_icon(color: Color) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([color, color])

	var texture: GradientTexture1D = GradientTexture1D.new()
	texture.width = 14
	texture.gradient = gradient
	return texture
