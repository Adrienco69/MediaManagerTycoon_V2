class_name GameHeaderActions
extends RefCounted


static func build(
	game_title: Label,
	on_save: Callable,
	on_main_menu: Callable
) -> Dictionary:
	var existing_box: VBoxContainer = game_title.get_parent().get_node_or_null("TitleActions") as VBoxContainer
	if existing_box != null:
		return {
			"save_button": existing_box.get_node("Actions/SaveButton"),
			"menu_button": existing_box.get_node("Actions/MainMenuButton"),
			"status_label": existing_box.get_node("Actions/SaveStatusLabel")
		}

	var parent: HBoxContainer = game_title.get_parent() as HBoxContainer
	var original_index: int = game_title.get_index()

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.name = "TitleActions"
	title_box.add_theme_constant_override("separation", 5)
	parent.add_child(title_box)
	parent.move_child(title_box, original_index)
	game_title.reparent(title_box)
	title_box.move_child(game_title, 0)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "Actions"
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
