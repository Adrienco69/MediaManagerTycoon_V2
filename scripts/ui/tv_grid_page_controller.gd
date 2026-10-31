class_name TVGridPageController
extends RefCounted

const DYNAMIC_NODE_NAME: String = "GridDynamic"
const DAYS: Array[String] = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
const BLOCKS: Array[String] = ["00h–03h", "03h–06h", "06h–09h", "09h–12h", "12h–15h", "15h–18h", "18h–21h", "21h–00h"]


static func render(content_container: VBoxContainer, page_description: Label, channel: Dictionary) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Chaîne : %s — cliquez sur un bloc de 3 heures pour afficher ses créneaux de 30 minutes." % String(channel.get("name", ""))

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 10)
	content_container.add_child(dynamic)

	var detail_label: Label = Label.new()
	detail_label.text = "Sélectionnez un bloc horaire."
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var table: GridContainer = GridContainer.new()
	table.columns = 8
	table.add_theme_constant_override("h_separation", 4)
	table.add_theme_constant_override("v_separation", 4)
	dynamic.add_child(table)

	_add_header(table, "Horaire")
	for day: String in DAYS:
		_add_header(table, day)

	for block_index: int in range(BLOCKS.size()):
		_add_header(table, BLOCKS[block_index])
		for day_index: int in range(DAYS.size()):
			var button: Button = Button.new()
			button.text = "Vide"
			button.custom_minimum_size = Vector2(120, 46)
			var captured_day: int = day_index
			var captured_block: int = block_index
			button.pressed.connect(func() -> void:
				_show_block_detail(detail_label, captured_day, captured_block)
			)
			table.add_child(button)

	var separator: HSeparator = HSeparator.new()
	dynamic.add_child(separator)
	dynamic.add_child(detail_label)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()


static func _add_header(table: GridContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(120, 36)
	label.add_theme_font_size_override("font_size", 15)
	table.add_child(label)


static func _show_block_detail(detail_label: Label, day_index: int, block_index: int) -> void:
	var start_hour: int = block_index * 3
	var lines: PackedStringArray = PackedStringArray()
	for slot_index: int in range(6):
		var total_minutes: int = (start_hour * 60) + (slot_index * 30)
		var hour: int = int(total_minutes / 60) % 24
		var minute: int = total_minutes % 60
		lines.append("%02d:%02d — Vide" % [hour, minute])

	detail_label.text = "%s • %s\n%s" % [
		DAYS[day_index],
		BLOCKS[block_index],
		"\n".join(lines)
	]
