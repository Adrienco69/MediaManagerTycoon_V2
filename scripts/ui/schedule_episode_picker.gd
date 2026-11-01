class_name ScheduleEpisodePicker
extends RefCounted

const ScheduleEpisodeHelperScript = preload("res://scripts/ui/schedule_episode_helper.gd")


static func open(
	anchor: Control,
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary,
	refresh_callback: Callable
) -> void:
	if anchor == null:
		return

	var existing: Node = anchor.get_node_or_null("ScheduleEpisodePicker")
	if existing != null:
		existing.queue_free()

	var episode_count: int = ScheduleEpisodeHelperScript.get_episode_count(program)
	if episode_count <= 0:
		_place_without_episode(channel, week_number, day_index, slot_index, program, refresh_callback)
		return

	var popup: PopupPanel = PopupPanel.new()
	popup.name = "ScheduleEpisodePicker"
	anchor.add_child(popup)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(540, 0)
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title: Label = Label.new()
	title.text = "Choisir l'épisode | %s" % String(program.get("name", "Programme"))
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Choisissez exactement l'épisode à diffuser sur ce créneau."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var episode_list: VBoxContainer = VBoxContainer.new()
	episode_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	episode_list.add_theme_constant_override("separation", 6)
	scroll.add_child(episode_list)

	for global_episode: int in range(1, episode_count + 1):
		var episode_data: Dictionary = ScheduleEpisodeHelperScript.get_episode_data(program, global_episode)
		if episode_data.is_empty():
			continue

		var episode_button: Button = Button.new()
		episode_button.text = String(episode_data.get("label", "Épisode %d" % global_episode))
		episode_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		episode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		episode_button.custom_minimum_size = Vector2(0, 40)
		episode_list.add_child(episode_button)

		var captured_episode: Dictionary = episode_data.duplicate(true)
		episode_button.pressed.connect(func() -> void:
			var placed: bool = GameState.schedule_program(
				channel,
				week_number,
				day_index,
				slot_index,
				program,
				captured_episode
			)
			if not placed:
				return
			popup.hide()
			if refresh_callback.is_valid():
				refresh_callback.call()
		)

	var cancel_button: Button = Button.new()
	cancel_button.text = "Annuler"
	cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel_button.pressed.connect(popup.hide)
	content.add_child(cancel_button)

	popup.popup_hide.connect(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)
	popup.popup_centered(Vector2i(600, 560))


static func _place_without_episode(
	channel: Dictionary,
	week_number: int,
	day_index: int,
	slot_index: int,
	program: Dictionary,
	refresh_callback: Callable
) -> void:
	var placed: bool = GameState.schedule_program(
		channel,
		week_number,
		day_index,
		slot_index,
		program,
		{}
	)
	if placed and refresh_callback.is_valid():
		refresh_callback.call()
