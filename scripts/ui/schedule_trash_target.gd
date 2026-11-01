class_name ScheduleTrashTarget
extends Button

var channel: Dictionary = {}
var refresh_callback: Callable = Callable()


func configure(new_channel: Dictionary, new_refresh_callback: Callable) -> void:
	channel = new_channel.duplicate(true)
	refresh_callback = new_refresh_callback
	text = "🗑 Supprimer une diffusion"
	tooltip_text = "Glissez une diffusion de la grille ici pour la supprimer."
	custom_minimum_size = Vector2(220, 42)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	return String((data as Dictionary).get("type", "")) == "scheduled_program"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	var drag_data: Dictionary = (data as Dictionary).duplicate(true)
	if String(drag_data.get("type", "")) != "scheduled_program":
		return

	var program_value: Variant = drag_data.get("program", {})
	var program_name: String = "cette diffusion"
	if program_value is Dictionary:
		program_name = String((program_value as Dictionary).get("name", program_name))

	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Supprimer la diffusion ?"
	dialog.dialog_text = "Voulez-vous supprimer %s de la grille ?\nLe programme restera dans votre bibliothèque." % program_name
	dialog.ok_button_text = "Supprimer"
	dialog.cancel_button_text = "Annuler"
	add_child(dialog)

	dialog.confirmed.connect(func() -> void:
		var removed: bool = GameState.remove_scheduled_program(
			channel,
			int(drag_data.get("source_week", 1)),
			int(drag_data.get("source_day", 0)),
			int(drag_data.get("source_slot", 0))
		)
		if removed and refresh_callback.is_valid():
			refresh_callback.call()
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	dialog.popup_centered(Vector2i(520, 220))
