class_name ZapChannelArchive
extends RefCounted

const DYNAMIC_NODE_NAME: String = "ZapArchiveDynamic"


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	channel: Dictionary,
	on_back: Callable
) -> void:
	clear(content_container)
	page_description.visible = true
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Archives de la chaîne fermée — consultation uniquement."

	var root: VBoxContainer = VBoxContainer.new()
	root.name = DYNAMIC_NODE_NAME
	root.add_theme_constant_override("separation", 12)
	content_container.add_child(root)

	var back_button: Button = Button.new()
	back_button.text = "← Retour au Zapping"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(on_back)
	root.add_child(back_button)

	var name_label: Label = Label.new()
	name_label.text = "%s | N° MMTN %d" % [
		String(channel.get("name", "Chaîne")),
		int(channel.get("mmtn_number", 0))
	]
	name_label.add_theme_font_size_override("font_size", 23)
	root.add_child(name_label)

	var dates: Label = Label.new()
	dates.text = "Groupe : %s | Lancement : %s | Fermeture : %s" % [
		String(channel.get("group", "Inconnu")),
		String(channel.get("launch_date", "Date inconnue")),
		String(channel.get("closed_date", "Date inconnue"))
	]
	dates.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(dates)

	var header: Label = Label.new()
	header.text = "Anciens programmes"
	header.add_theme_font_size_override("font_size", 19)
	root.add_child(header)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 7)
	scroll.add_child(list)

	var snapshot_value: Variant = channel.get("archived_programs", channel.get("programs", []))
	var archive: Array = snapshot_value as Array if snapshot_value is Array else []
	if archive.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Aucun ancien programme archivé pour cette chaîne."
		list.add_child(empty_label)
	else:
		for item: Variant in archive:
			if not item is Dictionary:
				continue
			var program: Dictionary = item as Dictionary
			var program_name: String = String(program.get("name", "Programme"))
			var format_name: String = String(program.get("format", "Format inconnu"))
			var duration: int = int(program.get("duration_minutes", 0))
			var line: Label = Label.new()
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.text = "%s | %s" % [format_name, program_name]
			if duration > 0:
				line.text += " | %d min" % duration
			list.add_child(line)

	var note: Label = Label.new()
	note.text = "Catalogue conservé à la fermeture. Les diffusions passées détaillées ne sont pas encore archivées."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing != null:
		content_container.remove_child(existing)
		existing.queue_free()
