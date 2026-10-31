class_name ChannelTableBuilder
extends RefCounted

const COLUMN_WIDTHS: Array[float] = [110.0, 240.0, 210.0, 150.0, 220.0]


static func build(parent: VBoxContainer, channel: Dictionary, on_edit_guide: Callable) -> void:
	var table: GridContainer = GridContainer.new()
	table.columns = 5
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_text_cell(table, "N° MMTN", 0, true)
	_add_text_cell(table, "Nom", 1, true)
	_add_text_cell(table, "Thème", 2, true)
	_add_text_cell(table, "Guide TV", 3, true)
	_add_text_cell(table, "Lancement chaîne", 4, true)

	_add_text_cell(table, str(int(channel.get("mmtn_number", 2))), 0, false)
	_add_text_cell(table, String(channel.get("name", "")), 1, false)
	_add_text_cell(table, "%s 🔒" % String(channel.get("theme", "Généraliste")), 2, false)
	_add_button_cell(table, "Modifier", 3, on_edit_guide)
	_add_text_cell(table, String(channel.get("launch_date", "Lundi 1 Floréal 0001")), 4, false)


static func _add_text_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
	var panel: PanelContainer = _create_cell_panel(column)
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_header:
		label.add_theme_font_size_override("font_size", 17)
	panel.add_child(label)


static func _add_button_cell(table: GridContainer, text: String, column: int, on_pressed: Callable) -> void:
	var panel: PanelContainer = _create_cell_panel(column)
	table.add_child(panel)

	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 36)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(on_pressed)
	panel.add_child(button)


static func _create_cell_panel(column: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTHS[column], 48)

	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.025)
	box.border_color = Color(1, 1, 1, 0.20)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", box)
	return panel
