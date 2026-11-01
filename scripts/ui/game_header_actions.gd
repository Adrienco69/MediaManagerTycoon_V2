class_name GameHeaderActions
extends RefCounted


static func build(
	game_title: Label,
	on_save: Callable,
	on_main_menu: Callable
) -> Dictionary:
	var parent: HBoxContainer = game_title.get_parent() as HBoxContainer
	var visual_anchor: Control = game_title
	var logo: TextureRect = parent.get_node_or_null("GameLogo") as TextureRect
	if logo != null:
		visual_anchor = logo
		game_title.visible = false

	var existing_box: VBoxContainer = parent.get_node_or_null("TitleActions") as VBoxContainer
	if existing_box != null:
		return {
			"save_button": existing_box.get_node("Actions/SaveButton"),
			"menu_button": existing_box.get_node("Actions/MainMenuButton"),
			"status_label": existing_box.get_node("Actions/SaveStatusLabel")
		}

	var original_index: int = visual_anchor.get_index()

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.name = "TitleActions"
	title_box.add_theme_constant_override("separation", 5)
	parent.add_child(title_box)
	parent.move_child(title_box, original_index)
	visual_anchor.reparent(title_box)
	title_box.move_child(visual_anchor, 0)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 6)
	title_box.add_child(actions)

	var save_button: Button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "Sauvegarder"
	save_button.custom_minimum_size = Vector2(105, 30)
	save_button.pressed.connect(on_save)
	actions.add_child(save_button)

	var menu_button: Button = Button.new()
	menu_button.name = "MainMenuButton"
	menu_button.text = "Menu principal"
	menu_button.custom_minimum_size = Vector2(115, 30)
	menu_button.pressed.connect(on_main_menu)
	actions.add_child(menu_button)

	var status_label: Label = Label.new()
	status_label.name = "SaveStatusLabel"
	status_label.text = ""
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actions.add_child(status_label)

	return {
		"save_button": save_button,
		"menu_button": menu_button,
		"status_label": status_label
	}
