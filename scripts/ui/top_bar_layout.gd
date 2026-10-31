class_name TopBarLayout
extends RefCounted


static func place_speed_under_date(
	speed_label: Label,
	week_label: Label,
	date_container: VBoxContainer
) -> void:
	week_label.visible = false

	if speed_label.get_parent() != date_container:
		speed_label.reparent(date_container)

	speed_label.custom_minimum_size = Vector2.ZERO
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_container.move_child(speed_label, 1)
