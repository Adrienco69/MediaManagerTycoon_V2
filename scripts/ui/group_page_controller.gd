class_name GroupPageController
extends RefCounted

const ChannelTableBuilderScript = preload("res://scripts/ui/channel_table_builder.gd")
const DYNAMIC_NODE_NAME: String = "GroupDynamic"


static func render(
	content_container: VBoxContainer,
	page_description: Label,
	player_name: String,
	company_name: String,
	first_channel: Dictionary,
	on_create_channel: Callable,
	on_edit_guide: Callable
) -> void:
	clear(content_container)
	page_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page_description.text = "Dirigeant : %s\nCapital de départ : 1 200 CC" % player_name

	var dynamic: VBoxContainer = VBoxContainer.new()
	dynamic.name = DYNAMIC_NODE_NAME
	dynamic.add_theme_constant_override("separation", 12)
	content_container.add_child(dynamic)

	if first_channel.is_empty():
		_build_creation_form(dynamic, company_name, on_create_channel)
	else:
		_build_channel_summary(dynamic, first_channel, on_edit_guide)


static func clear(content_container: VBoxContainer) -> void:
	var existing: Node = content_container.get_node_or_null(DYNAMIC_NODE_NAME)
	if existing == null:
		return

	content_container.remove_child(existing)
	existing.queue_free()


static func _build_creation_form(
	parent: VBoxContainer,
	company_name: String,
	on_create_channel: Callable
) -> void:
	var title: Label = Label.new()
	title.text = "Créer votre première chaîne"
	title.add_theme_font_size_override("font_size", 22)
	parent.add_child(title)

	var choice_label: Label = Label.new()
	choice_label.text = "Nom de la chaîne"
	parent.add_child(choice_label)

	var choice_group: ButtonGroup = ButtonGroup.new()

	var use_group_name: CheckBox = CheckBox.new()
	use_group_name.text = "Reprendre le nom du groupe : %s" % company_name
	use_group_name.button_group = choice_group
	use_group_name.button_pressed = true
	parent.add_child(use_group_name)

	var use_custom_name: CheckBox = CheckBox.new()
	use_custom_name.text = "Choisir un autre nom"
	use_custom_name.button_group = choice_group
	parent.add_child(use_custom_name)

	var name_input: LineEdit = LineEdit.new()
	name_input.placeholder_text = "Nom de votre chaîne"
	name_input.max_length = 50
	name_input.custom_minimum_size = Vector2(0, 44)
	name_input.text = company_name
	name_input.editable = false
	parent.add_child(name_input)

	var update_name_mode: Callable = func() -> void:
		var reuse_group_name: bool = use_group_name.button_pressed
		name_input.editable = not reuse_group_name
		if reuse_group_name:
			name_input.text = company_name
		else:
			name_input.text = ""
			name_input.grab_focus()

	use_group_name.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			update_name_mode.call()
	)
	use_custom_name.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			update_name_mode.call()
	)

	var theme_label: Label = Label.new()
	theme_label.text = "Thème : Généraliste 🔒"
	parent.add_child(theme_label)

	var error_label: Label = Label.new()
	error_label.text = ""
	parent.add_child(error_label)

	var create_button: Button = Button.new()
	create_button.text = "Créer la chaîne"
	create_button.custom_minimum_size = Vector2(180, 44)
	parent.add_child(create_button)

	var submit: Callable = func() -> void:
		var channel_name: String = company_name if use_group_name.button_pressed else name_input.text.strip_edges()
		if channel_name.is_empty():
			error_label.text = "Renseigne le nom de la chaîne."
			return
		error_label.text = ""
		on_create_channel.call(channel_name)

	create_button.pressed.connect(submit)
	name_input.text_submitted.connect(func(_text: String) -> void: submit.call())


static func _build_channel_summary(
	parent: VBoxContainer,
	channel: Dictionary,
	on_edit_guide: Callable
) -> void:
	var title: Label = Label.new()
	title.text = "Votre chaîne"
	title.add_theme_font_size_override("font_size", 22)
	parent.add_child(title)

	ChannelTableBuilderScript.build(parent, channel, on_edit_guide)
