class_name ZapPageController
extends RefCounted

const DYNAMIC_NODE_NAME: String = "ZapDynamic"
const COLUMN_WIDTHS: Array[float] = [85.0, 285.0, 205.0, 155.0, 200.0, 175.0]


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	channels: Array[Dictionary],
	on_open_channel: Callable,
	on_open_archive: Callable = Callable()
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Historique des chaînes MMTN. Utilisez le bouton Guide TV à côté d'une chaîne pour consulter sa grille."

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 10)
	content_container.add_child(dynamic)

	var active_channels: Array[Dictionary] = _filter_channels(channels, false)
	var closed_channels: Array[Dictionary] = _filter_channels(channels, true)

	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	dynamic.add_child(tabs)

	var active_button: Button = Button.new()
	active_button.text = "Chaînes actives (%d)" % active_channels.size()
	tabs.add_child(active_button)

	var closed_button: Button = Button.new()
	closed_button.text = "Chaînes fermées (%d)" % closed_channels.size()
	tabs.add_child(closed_button)

	var table_holder: VBoxContainer = VBoxContainer.new()
	table_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dynamic.add_child(table_holder)

	var show_list: Callable = func(show_closed: bool) -> void:
		active_button.disabled = not show_closed
		closed_button.disabled = show_closed
		_clear_holder(table_holder)
		var selected: Array[Dictionary] = closed_channels if show_closed else active_channels
		_build_table(table_holder, selected, show_closed, on_open_channel, on_open_archive)

	active_button.pressed.connect(func() -> void: show_list.call(false))
	closed_button.pressed.connect(func() -> void: show_list.call(true))
	show_list.call(false)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _filter_channels(channels: Array[Dictionary], closed: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for channel: Dictionary in channels:
		var is_closed: bool = (
			not bool(channel.get("is_open", true))
			or not String(channel.get("closed_date", "")).is_empty()
		)
		if is_closed == closed:
			result.append(channel.duplicate(true))
	return result


static func _build_table(
	parent: VBoxContainer,
	channels: Array[Dictionary],
	show_closed: bool,
	on_open_channel: Callable,
	on_open_archive: Callable
) -> void:
	if channels.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucune chaîne fermée." if show_closed else "Aucune chaîne active."
		parent.add_child(empty_label)
		return

	var table: GridContainer = GridContainer.new()
	table.columns = 6
	table.add_theme_constant_override("h_separation", 0)
	table.add_theme_constant_override("v_separation", 0)
	parent.add_child(table)

	_add_cell(table, "N° MMTN", 0, true)
	_add_cell(table, "Chaîne", 1, true)
	_add_cell(table, "Groupe", 2, true)
	_add_cell(table, "Thème", 3, true)
	_add_cell(table, "Lancement", 4, true)
	_add_cell(table, "Fermeture" if show_closed else "État", 5, true)

	for channel: Dictionary in channels:
		var selected_channel: Dictionary = channel.duplicate(true)
		_add_cell(table, str(int(channel.get("mmtn_number", 0))), 0, false)
		var open_action: Callable = on_open_archive if show_closed else on_open_channel
		_add_channel_cell(
			table,
			String(channel.get("name", "")),
			1,
			open_action.bind(selected_channel),
			"Archives" if show_closed else "Guide TV"
		)
		_add_cell(table, String(channel.get("group", "")), 2, false)
		_add_cell(table, String(channel.get("theme", "Généraliste")), 3, false)
		_add_cell(table, String(channel.get("launch_date", "")), 4, false)
		if show_closed:
			_add_cell(table, "Fermée le %s" % String(channel.get("closed_date", "")), 5, false)
		else:
			_add_cell(table, "Ouverte", 5, false)


static func _clear_holder(holder: VBoxContainer) -> void:
	for child: Node in holder.get_children():
		holder.remove_child(child)
		child.queue_free()


static func _add_cell(table: GridContainer, text: String, column: int, is_header: bool) -> void:
	var panel: PanelContainer = _create_panel(column)
	table.add_child(panel)

	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)


static func _add_channel_cell(
	table: GridContainer,
	channel_name: String,
	column: int,
	on_open_guide: Callable,
	button_label: String = "Guide TV"
) -> void:
	var panel: PanelContainer = _create_panel(column)
	table.add_child(panel)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = channel_name
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	var guide_button: Button = Button.new()
	guide_button.text = button_label
	guide_button.flat = false
	guide_button.focus_mode = Control.FOCUS_ALL
	guide_button.custom_minimum_size = Vector2(105, 34)
	guide_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	guide_button.disabled = not on_open_guide.is_valid()
	if on_open_guide.is_valid():
		guide_button.pressed.connect(on_open_guide)
	row.add_child(guide_button)


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
