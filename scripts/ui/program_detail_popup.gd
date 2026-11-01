class_name ProgramDetailPopup
extends RefCounted

const ProgramDetailControllerScript = preload("res://scripts/ui/library_program_detail_controller.gd")


static func open(anchor: Control, program: Dictionary) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return

	var popup: PopupPanel = PopupPanel.new()
	popup.name = "ProgramDetailPopup"
	anchor.get_tree().root.add_child(popup)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	popup.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.custom_minimum_size = Vector2(920, 620)
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = String(program.get("name", "Programme"))
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)

	var description: Label = Label.new()
	root.add_child(description)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	var close_popup: Callable = func() -> void:
		popup.hide()

	ProgramDetailControllerScript.render(
		content,
		description,
		program.duplicate(true),
		close_popup,
		"Fermer"
	)

	popup.popup_hide.connect(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)
	popup.popup_centered(Vector2i(980, 700))
