class_name TopBarLayout
extends RefCounted


static func place_speed_controls_under_date(
	speed_label: Label,
	week_label: Label,
	date_container: VBoxContainer,
	credits_label: Label,
	date_label: Label,
	time_label: Label,
	pause_button: Button,
	hour_button: Button,
	day_button: Button,
	week_button: Button
) -> void:
	var old_controls: Control = speed_label.get_parent() as Control

	week_label.visible = false
	speed_label.visible = false

	var info_row: HBoxContainer = date_container.get_node_or_null("InfoRow") as HBoxContainer
	if info_row == null:
		info_row = HBoxContainer.new()
		info_row.name = "InfoRow"
		info_row.alignment = BoxContainer.ALIGNMENT_CENTER
		info_row.add_theme_constant_override("separation", 18)
		date_container.add_child(info_row)

	var status_labels: Array[Label] = [
		credits_label,
		date_label,
		time_label
	]

	for label: Label in status_labels:
		if label.get_parent() != info_row:
			label.reparent(info_row)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2.ZERO

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

	var on_air_label: Label = date_container.get_node_or_null("OnAirLabel") as Label
	if on_air_label == null:
		on_air_label = Label.new()
		on_air_label.name = "OnAirLabel"
		on_air_label.text = "Actuellement : Aucun programme"
		on_air_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		on_air_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		on_air_label.add_theme_color_override("font_color", Color.WHITE)
		date_container.add_child(on_air_label)

	date_container.move_child(info_row, 0)
	date_container.move_child(button_row, 1)
	date_container.move_child(on_air_label, 2)
	date_container.add_theme_constant_override("separation", 6)
	date_container.custom_minimum_size = Vector2(400, 0)

	if old_controls != null:
		old_controls.visible = false
