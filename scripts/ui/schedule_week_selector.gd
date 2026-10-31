class_name ScheduleWeekSelector
extends RefCounted


static func build(on_week_changed: Callable) -> OptionButton:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label: Label = Label.new()
	label.text = "Semaine"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var selector: OptionButton = OptionButton.new()
	selector.custom_minimum_size = Vector2(140, 38)
	for week_number: int in range(1, 53):
		selector.add_item("Semaine %d" % week_number, week_number)
	selector.select(0)
	selector.item_selected.connect(func(index: int) -> void:
		on_week_changed.call(index + 1)
	)
	row.add_child(selector)
	selector.set_meta("container", row)
	return selector


static func get_container(selector: OptionButton) -> HBoxContainer:
	return selector.get_meta("container") as HBoxContainer
