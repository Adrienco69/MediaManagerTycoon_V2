class_name ProgramCatalogPanel
extends RefCounted


static func build(parent: Control, editable: bool) -> void:
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
		hint.text = "Les programmes créés apparaîtront ici et pourront être glissés vers la grille."
	else:
		hint.text = "Catalogue de la chaîne consultée."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	var empty_label: Label = Label.new()
	empty_label.text = "Aucun programme créé pour le moment."
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(empty_label)
