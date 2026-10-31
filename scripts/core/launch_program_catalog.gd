class_name LaunchProgramCatalog
extends RefCounted

const TELEFILMS: Array[String] = [
	"Un jour presque ordinaire",
	"Tout devait bien se passer",
	"Le monde d’après nous"
]


static func build(channel_name: String) -> Array[Dictionary]:
	var programs: Array[Dictionary] = []

	programs.append(_program("Notre monde en crises", "Shortcom", 30, 25, 25))
	programs.append(_program("Le futur pour un passée", "Shortcom", 30, 50, 50))
	programs.append(_program("La vie du lycée", "Série", 30, 21, 6, "Production en cours", 7))
	programs.append(_program("Une famille presque parfaite", "Série", 60, 21, 6, "Production en cours", 7))
	programs.append(_program("Combien j’ai de CC", "Jeux TV", 30, 15, 15))
	programs.append(_program("Le bon prix", "Jeux TV", 90, 5, 5))
	programs.append(_program("Tout le monde avec…", "Documentaire", 120, 5, 5))
	programs.append(_program("Dans les coulisses de %s" % channel_name, "Documentaire", 90, 5, 5))
	programs.append(_program("Ce soir, c’est nous !", "Divertissement", 150, 10, 10))
	programs.append(_program("Retour vers nos souvenirs", "Divertissement", 150, 10, 10))
	programs.append(_program("Ça nous concerne", "Magazine", 60, 35, 35))
	programs.append(_program("Mode d’emploi", "Magazine", 60, 35, 35))
	programs.append(_program("La vie des folles", "Télé-réalité", 60, 21, 21))
	programs.append(_program("Les Ailescapés de la réalité", "Télé-réalité", 30, 50, 50))
	programs.append(_program("@Talk", "Talk-show", 120, 0, 0))

	var telefilm_index: int = randi_range(0, TELEFILMS.size() - 1)
	programs.append(_program(TELEFILMS[telefilm_index], "Téléfilm", 150, 1, 1))
	return programs


static func _program(
	name: String,
	format_name: String,
	duration_minutes: int,
	episodes_total: int,
	episodes_available: int,
	status: String = "Disponible",
	current_episode: int = 0
) -> Dictionary:
	return {
		"id": name.to_lower().replace(" ", "_").replace("’", "").replace("'", ""),
		"name": name,
		"format": format_name,
		"duration_minutes": duration_minutes,
		"episodes_total": episodes_total,
		"episodes_available": episodes_available,
		"status": status,
		"current_episode": current_episode,
		"source": "launch",
		"owned_by_group": true
	}
