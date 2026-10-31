class_name NavigationButtonState
extends RefCounted


static func apply(buttons: Array[Button], active_button: Button) -> void:
	for button: Button in buttons:
		button.disabled = button == active_button
