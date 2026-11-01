class_name MainContentScroll
extends RefCounted


static func setup(content_margin: MarginContainer, content_vbox: VBoxContainer) -> ScrollContainer:
	var existing: ScrollContainer = content_margin.get_node_or_null("MainContentScroll") as ScrollContainer
	if existing != null:
		return existing

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "MainContentScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	content_margin.remove_child(content_vbox)
	content_margin.add_child(scroll)
	scroll.add_child(content_vbox)

	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return scroll


static func scroll_to_top(scroll: ScrollContainer) -> void:
	scroll.scroll_vertical = 0
