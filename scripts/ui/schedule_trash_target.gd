class_name ScheduleTrashTarget
extends Button

var channel: Dictionary = {}
var refresh_callback: Callable = Callable()


func configure(new_channel: Dictionary, new_refresh_callback: Callable) -> void:
	channel = new_channel.duplicate(true)
	refresh_callback = new_refresh_callback
	text = "🗑 Supprimer une diffusion"
	tooltip_text = "Glissez cette poubelle sur une diffusion de la grille pour la supprimer."
	custom_minimum_size = Vector2(220, 42)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview: Label = Label.new()
	preview.text = "🗑 Supprimer"
	preview.add_theme_font_size_override("font_size", 16)
	set_drag_preview(preview)

	return {
		"type": "schedule_trash"
	}
