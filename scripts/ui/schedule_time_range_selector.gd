class_name ScheduleTimeRangeSelector
extends RefCounted

const DEFAULT_RANGE_ID: String = "21_00"

const RANGES: Array[Dictionary] = [
	{
		"id": "00_03",
		"label": "00h–03h",
		"start_slot": 0,
		"end_slot": 6
	},
	{
		"id": "03_06",
		"label": "03h–06h",
		"start_slot": 6,
		"end_slot": 12
	},
	{
		"id": "06_09",
		"label": "06h–09h",
		"start_slot": 12,
		"end_slot": 18
	},
	{
		"id": "09_12",
		"label": "09h–12h",
		"start_slot": 18,
		"end_slot": 24
	},
	{
		"id": "12_15",
		"label": "12h–15h",
		"start_slot": 24,
		"end_slot": 30
	},
	{
		"id": "15_18",
		"label": "15h–18h",
		"start_slot": 30,
		"end_slot": 36
	},
	{
		"id": "18_21",
		"label": "18h–21h",
		"start_slot": 36,
		"end_slot": 42
	},
	{
		"id": "21_00",
		"label": "21h–00h",
		"start_slot": 42,
		"end_slot": 48
	}
]


static func build(
	parent: HBoxContainer,
	selected_range_id: String,
	on_range_selected: Callable
) -> void:
	_clear(parent)
	parent.add_theme_constant_override("separation", 6)

	for range_data: Dictionary in RANGES:
		var range_id: String = String(range_data.get("id", ""))
		var button: Button = Button.new()
		button.text = String(range_data.get("label", ""))
		button.custom_minimum_size = Vector2(86, 38)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("time_range_id", range_id)
		parent.add_child(button)

		if on_range_selected.is_valid():
			var captured_range_id: String = range_id
			button.pressed.connect(func() -> void:
				on_range_selected.call(captured_range_id)
			)

	select(parent, selected_range_id)


static func select(parent: HBoxContainer, selected_range_id: String) -> void:
	for child: Node in parent.get_children():
		if not child is Button:
			continue
		var button: Button = child as Button
		button.disabled = String(button.get_meta("time_range_id", "")) == selected_range_id


static func get_range(range_id: String) -> Dictionary:
	for range_data: Dictionary in RANGES:
		if String(range_data.get("id", "")) == range_id:
			return range_data.duplicate(true)

	for range_data: Dictionary in RANGES:
		if String(range_data.get("id", "")) == DEFAULT_RANGE_ID:
			return range_data.duplicate(true)

	return {
		"id": DEFAULT_RANGE_ID,
		"label": "21h–00h",
		"start_slot": 42,
		"end_slot": 48
	}


static func _clear(parent: Control) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
