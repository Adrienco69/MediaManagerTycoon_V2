class_name ProgramCatalogPanel
extends RefCounted

const ProgramDetailPopupScript = preload("res://scripts/ui/program_detail_popup.gd")


static func build(parent: Control, editable: bool, programs: Array[Dictionary]) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.025)
	box.border_color = Color(1, 1, 1, 0.18)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 12.0
	box.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", box)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title: Label = Label.new()
	title.text = "Programmes"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	var hint: Label = Label.new()
	if editable:
		hint.text = "Catalogue du groupe. Cliquez sur un titre pour voir sa fiche. Le glisser-déposer sera branché ensuite."
	else:
		hint.text = "Catalogue non modifiable. Cliquez sur un titre pour voir sa fiche."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	if programs.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucun programme disponible."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(empty_label)
		return

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for program: Dictionary in programs:
		var button: Button = Button.new()
		button.text = "%s (%d min)" % [
			String(program.get("name", "")),
			int(program.get("duration_minutes", 0))
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 38)
		button.pressed.connect(func() -> void:
			ProgramDetailPopupScript.open(button, program)
		)
		list.add_child(button)
