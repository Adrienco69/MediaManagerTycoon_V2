class_name DraggableProgramButton
extends Button

var program_data: Dictionary = {}


func setup(program: Dictionary) -> void:
	program_data = program.duplicate(true)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if program_data.is_empty():
		return null

	var preview: Label = Label.new()
	preview.text = "%s (%d min)" % [
		String(program_data.get("name", "Programme")),
		int(program_data.get("duration_minutes", 0))
	]
	preview.add_theme_font_size_override("font_size", 16)
	set_drag_preview(preview)

	return {
		"type": "program",
		"program": program_data.duplicate(true)
	}
