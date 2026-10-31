class_name TVGridPageController
extends RefCounted

const DYNAMIC_NODE_NAME: String = "GridDynamic"
const DAYS: Array[String] = [
	"Lundi",
	"Mardi",
	"Mercredi",
	"Jeudi",
	"Vendredi",
	"Samedi",
	"Dimanche"
]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	channel: Dictionary
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Chaîne : %s" % String(channel.get("name", ""))

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dynamic.add_theme_constant_override("separation", 10)
	content_container.add_child(dynamic)

	var day_buttons: Array[Button] = []
	var day_row: HBoxContainer = HBoxContainer.new()
	day_row.add_theme_constant_override("separation", 6)
	dynamic.add_child(day_row)

	var selected_day_label: Label = Label.new()
	selected_day_label.add_theme_font_size_override("font_size", 20)
	dynamic.add_child(selected_day_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dynamic.add_child(scroll)

	var schedule: VBoxContainer = VBoxContainer.new()
	schedule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule.add_theme_constant_override("separation", 4)
	scroll.add_child(schedule)

	for day_index: int in range(DAYS.size()):
		var day_button: Button = Button.new()
		day_button.text = DAYS[day_index]
		day_button.custom_minimum_size = Vector2(110, 38)
		day_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_row.add_child(day_button)
		day_buttons.append(day_button)

		var captured_day: int = day_index
		day_button.pressed.connect(func() -> void:
			_show_day(captured_day, day_buttons, selected_day_label, schedule, scroll)
		)

	_show_day(0, day_buttons, selected_day_label, schedule, scroll)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _show_day(
	day_index: int,
	day_buttons: Array[Button],
	selected_day_label: Label,
	schedule: VBoxContainer,
	scroll: ScrollContainer
) -> void:
	for index: int in range(day_buttons.size()):
		day_buttons[index].disabled = index == day_index

	selected_day_label.text = DAYS[day_index]
	_clear_schedule(schedule)

	for slot_index: int in range(48):
		_add_half_hour_row(schedule, slot_index)

	scroll.scroll_vertical = 0


static func _clear_schedule(schedule: VBoxContainer) -> void:
	for child: Node in schedule.get_children():
		schedule.remove_child(child)
		child.queue_free()


static func _add_half_hour_row(schedule: VBoxContainer, slot_index: int) -> void:
	var total_minutes: int = slot_index * 30
	var hour: int = int(total_minutes / 60)
	var minute: int = total_minutes % 60

	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 42)
	row.add_theme_constant_override("separation", 8)
	schedule.add_child(row)

	var time_label: Label = Label.new()
	time_label.text = "%02dh%02d" % [hour, minute]
	time_label.custom_minimum_size = Vector2(90, 0)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(time_label)

	var slot_button: Button = Button.new()
	slot_button.text = "Vide"
	slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_button.custom_minimum_size = Vector2(0, 38)
	row.add_child(slot_button)
