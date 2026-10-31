class_name TVDayScheduleBuilder
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


static func build(
	parent: VBoxContainer,
	week_number: int,
	editable: bool
) -> void:
	var day_buttons: Array[Button] = []
	var day_row: HBoxContainer = HBoxContainer.new()
	day_row.add_theme_constant_override("separation", 6)
	parent.add_child(day_row)

	var selected_day_label: Label = Label.new()
	selected_day_label.add_theme_font_size_override("font_size", 20)
	parent.add_child(selected_day_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)

	var schedule: VBoxContainer = VBoxContainer.new()
	schedule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule.add_theme_constant_override("separation", 4)
	scroll.add_child(schedule)

	for day_index: int in range(DAYS.size()):
		var button: Button = Button.new()
		button.text = DAYS[day_index]
		button.custom_minimum_size = Vector2(110, 38)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_row.add_child(button)
		day_buttons.append(button)

		var captured_day: int = day_index
		button.pressed.connect(func() -> void:
			_show_day(captured_day, week_number, editable, day_buttons, selected_day_label, schedule, scroll)
		)

	_show_day(0, week_number, editable, day_buttons, selected_day_label, schedule, scroll)


static func _show_day(
	day_index: int,
	week_number: int,
	editable: bool,
	day_buttons: Array[Button],
	selected_day_label: Label,
	schedule: VBoxContainer,
	scroll: ScrollContainer
) -> void:
	for index: int in range(day_buttons.size()):
		day_buttons[index].disabled = index == day_index

	selected_day_label.text = "%s | Semaine %d" % [DAYS[day_index], week_number]
	_clear(schedule)

	for slot_index: int in range(48):
		_add_slot(schedule, slot_index, editable)

	scroll.scroll_vertical = 0


static func _add_slot(parent: VBoxContainer, slot_index: int, editable: bool) -> void:
	var total_minutes: int = slot_index * 30
	var hour: int = int(total_minutes / 60)
	var minute: int = total_minutes % 60

	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 42)
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var time_label: Label = Label.new()
	time_label.text = "%02dh%02d" % [hour, minute]
	time_label.custom_minimum_size = Vector2(90, 0)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(time_label)

	if editable:
		var slot_button: Button = Button.new()
		slot_button.text = "Vide"
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.custom_minimum_size = Vector2(0, 38)
		row.add_child(slot_button)
	else:
		var slot_label: Label = Label.new()
		slot_label.text = "Vide"
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(slot_label)


static func _clear(parent: VBoxContainer) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
