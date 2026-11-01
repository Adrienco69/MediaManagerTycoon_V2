class_name SaveGameManager
extends RefCounted

const SAVE_PATH: String = "user://media_manager_tycoon_v2_save.json"
const SAVE_VERSION: int = 1


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func save_game(data: Dictionary) -> bool:
	var payload: Dictionary = data.duplicate(true)
	payload["save_version"] = SAVE_VERSION

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


static func load_game() -> Dictionary:
	if not has_save():
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary:
		return {}

	var data: Dictionary = parsed
	if int(data.get("save_version", 0)) <= 0:
		return {}
	return data


static func delete_save() -> bool:
	if not has_save():
		return true

	var absolute_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	return DirAccess.remove_absolute(absolute_path) == OK
