class_name LibraryProgramStatus
extends RefCounted


static func get_text(program: Dictionary) -> String:
	var status: String = String(program.get("status", "Disponible"))
	if status == "Production en cours":
		return "Disponible | Production en cours"

	# Le renouvellement est une action disponible depuis la fiche du programme,
	# indépendamment du nombre d'épisodes déjà possédés.
	return "Disponible | Renouvellement"
