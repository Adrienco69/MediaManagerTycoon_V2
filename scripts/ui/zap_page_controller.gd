class_name ZapPageController
extends RefCounted

const MMTNRegistryScript = preload("res://scripts/core/mmtn_registry.gd")
const DYNAMIC_NODE_NAME: String = "ZapDynamic"
const COLUMN_WIDTHS: Array[float] = [100.0, 220.0, 240.0, 180.0, 220.0, 220.0]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	channels: Array[Dictionary],
	on_open_channel: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Historique des chaînes MMTN. Cliquez sur le nom d'une chaîne pour consulter son guide TV."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 10)
	content_container.add_child(dynamic)

	if channels.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucune chaîne n'a encore été lancée."
		dynamic.add_child(empty_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 6
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	dynamic.add_child(table)

	_add_cell(table, "N° MMTN", 0, true)
	_add_cell(table, "Chaîne", 1, true)
	_add_cell(table, "Groupe", 2, true)
	_add_cell(table, "Thème", 3, true)
	_add_cell(table, "Lancement", 4, true)
	_add_cell(table, "Statut", 5, true)

	for channel: Dictionary in channels:
		var selected_channel: Dictionary = channel.duplicate(true)
		_add_cell(table, str(int(channel.get("mmtn_number", 0))), 0, false)
		_add_channel_button(table, String(channel.get("name", "")), 1, func() -> void:
			on_open_channel.call(selected_channel)
		)
		_add_cell(table, String(channel.get("group", "")), 2, false)
		_add_cell(table, String(channel.get("theme", "Généraliste")), 3, false)
		_add_cell(table, String(channel.get("launch_date", "")), 4, false)
		_add_cell(table, MMTNRegistryScript.get_status_text(channel), 5, false)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _add_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
	var panel: PanelContainer = _create_panel(column)
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)


static func _add_channel_button(
	table: GridContainer,
	text: String,
	column: int,
	on_pressed: Callable
) -> void:
	var panel: PanelContainer = _create_panel(column)
	table.add_child(panel)

	var button: Button = Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_pressed)
	panel.add_child(button)


static func _create_panel(column: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTHS[column], 46)

	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.025)
	box.border_color = Color(1, 1, 1, 0.20)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", box)
	return panel
