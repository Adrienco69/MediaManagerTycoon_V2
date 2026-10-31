class_name TopBarLayout
extends RefCounted


static func place_speed_controls_under_date(
	speed_label: Label,
	week_label: Label,
	date_container: VBoxContainer,
	credits_label: Label,
	pause_button: Button,
	hour_button: Button,
	day_button: Button,
	week_button: Button
) -> void:
	var old_controls: Control = speed_label.get_parent() as Control

	week_label.visible = false
	speed_label.visible = false

	if credits_label.get_parent() != date_container:
		credits_label.reparent(date_container)
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_label.custom_minimum_size = Vector2.ZERO
	date_container.move_child(credits_label, 1)

	var button_row: HBoxContainer = date_container.get_node_or_null("SpeedButtons") as HBoxContainer
	if button_row == null:
		button_row = HBoxContainer.new()
		button_row.name = "SpeedButtons"
		button_row.alignment = BoxContainer.ALIGNMENT_CENTER
		button_row.add_theme_constant_override("separation", 6)
		date_container.add_child(button_row)

	var buttons: Array[Button] = [
		pause_button,
		hour_button,
		day_button,
		week_button
	]

	for button: Button in buttons:
		if button.get_parent() != button_row:
			button.reparent(button_row)
		button.custom_minimum_size = Vector2(64, 34)

	date_container.move_child(button_row, 2)
	date_container.add_theme_constant_override("separation", 5)

	if old_controls != null:
		old_controls.visible = false
