class_name MG1LaunchCatalog
extends RefCounted

const PROGRAM_COUNT: int = 16

const PROGRAM_POOL: Array[Dictionary] = [
	{"name": "Quartier Central", "format": "Série", "duration": 60, "episodes": 48},
	{"name": "Dernier étage", "format": "Série", "duration": 30, "episodes": 36},
	{"name": "Ligne de vie", "format": "Série", "duration": 60, "episodes": 28},
	{"name": "Entre deux mondes", "format": "Série", "duration": 30, "episodes": 42},
	{"name": "Dossiers sensibles", "format": "Série", "duration": 60, "episodes": 32},
	{"name": "Face au hasard", "format": "Série", "duration": 30, "episodes": 26},
	{"name": "Le Cercle des champions", "format": "Jeux TV", "duration": 60, "episodes": 40},
	{"name": "Question de seconde", "format": "Jeux TV", "duration": 30, "episodes": 60},
	{"name": "Le Grand Défi", "format": "Jeux TV", "duration": 90, "episodes": 18},
	{"name": "À vous de jouer", "format": "Jeux TV", "duration": 60, "episodes": 35},
	{"name": "Terres inconnues", "format": "Documentaire", "duration": 60, "episodes": 20},
	{"name": "Mémoires du monde", "format": "Documentaire", "duration": 90, "episodes": 14},
	{"name": "Au cœur du réel", "format": "Documentaire", "duration": 60, "episodes": 24},
	{"name": "Horizons", "format": "Documentaire", "duration": 120, "episodes": 10},
	{"name": "Grand angle", "format": "Magazine", "duration": 60, "episodes": 45},
	{"name": "Le point du jour", "format": "Magazine", "duration": 30, "episodes": 70},
	{"name": "Tout s'explique", "format": "Magazine", "duration": 60, "episodes": 36},
	{"name": "On en parle", "format": "Talk-show", "duration": 120, "episodes": 30},
	{"name": "Place au public", "format": "Talk-show", "duration": 90, "episodes": 24},
	{"name": "La Grande Soirée", "format": "Divertissement", "duration": 150, "episodes": 12},
	{"name": "Tous en scène", "format": "Divertissement", "duration": 120, "episodes": 15},
	{"name": "Défis en famille", "format": "Divertissement", "duration": 90, "episodes": 20},
	{"name": "Villa sous tension", "format": "Télé-réalité", "duration": 60, "episodes": 30},
	{"name": "Une semaine avec eux", "format": "Télé-réalité", "duration": 30, "episodes": 45},
	{"name": "Le pacte", "format": "Téléfilm", "duration": 120, "episodes": 1},
	{"name": "Un été ailleurs", "format": "Téléfilm", "duration": 150, "episodes": 1},
	{"name": "La dernière promesse", "format": "Téléfilm", "duration": 90, "episodes": 1},
	{"name": "Retour à demain", "format": "Téléfilm", "duration": 120, "episodes": 1}
]


static func build(excluded_programs: Array[Dictionary], reserved_series_telefilm: Dictionary) -> Array[Dictionary]:
	var excluded_names: Dictionary = {}
	for program: Dictionary in excluded_programs:
		excluded_names[String(program.get("name", "")).to_lower()] = true

	var available_pool: Array[Dictionary] = []
	for template: Dictionary in PROGRAM_POOL:
		var program_name: String = String(template.get("name", ""))
		if excluded_names.has(program_name.to_lower()):
			continue
		available_pool.append(template.duplicate(true))

	available_pool.shuffle()
	var programs: Array[Dictionary] = []
	var amount: int = mini(PROGRAM_COUNT, available_pool.size())
	for index: int in range(amount):
		var template: Dictionary = available_pool[index]
		programs.append(_program(
			String(template.get("name", "")),
			String(template.get("format", "Programme")),
			int(template.get("duration", 30)),
			int(template.get("episodes", 1))
		))

	if not reserved_series_telefilm.is_empty():
		var reserved_name: String = String(reserved_series_telefilm.get("name", ""))
		var reserved_episodes: int = int(reserved_series_telefilm.get("episodes", 0))
		if not reserved_name.is_empty() and reserved_episodes > 0:
			programs.append(_program(reserved_name, "Série-téléfilm", 90, reserved_episodes))

	return programs


static func _program(name: String, format_name: String, duration_minutes: int, episodes: int) -> Dictionary:
	return {
		"id": name.to_lower().replace(" ", "_").replace("’", "").replace("'", ""),
		"name": name,
		"format": format_name,
		"duration_minutes": duration_minutes,
		"episodes_total": episodes,
		"episodes_available": episodes,
		"status": "Disponible",
		"source": "mg1_launch",
		"owned_by_group": false
	}
