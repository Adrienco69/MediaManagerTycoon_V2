class_name CalendarTheme
extends RefCounted

# Identité visuelle des 7 mois de Media Manager Tycoon.
# Les couleurs sont interpolées au fil des jours afin d'éviter un changement brutal
# lors du passage d'un mois au suivant.
const PALETTES := [
	{
		"name": "Floréal",
		"background": Color("#142019"),
		"surface": Color("#223126"),
		"surface_alt": Color("#2d4233"),
		"accent": Color("#78bd72"),
		"accent_soft": Color("#acd69d"),
		"text": Color("#f2f7f2"),
		"muted": Color("#b7c7b9")
	},
	{
		"name": "Clôture",
		"background": Color("#211c12"),
		"surface": Color("#352c1b"),
		"surface_alt": Color("#493b23"),
		"accent": Color("#d6a84f"),
		"accent_soft": Color("#efd08a"),
		"text": Color("#fff8e8"),
		"muted": Color("#d3c7a9")
	},
	{
		"name": "Crépuscule",
		"background": Color("#211826"),
		"surface": Color("#34233b"),
		"surface_alt": Color("#47304e"),
		"accent": Color("#b276c7"),
		"accent_soft": Color("#d9a6e5"),
		"text": Color("#fbf2ff"),
		"muted": Color("#cdb9d3")
	},
	{
		"name": "Zénith",
		"background": Color("#13202a"),
		"surface": Color("#203746"),
		"surface_alt": Color("#2b4c5f"),
		"accent": Color("#55b9d7"),
		"accent_soft": Color("#91d9ea"),
		"text": Color("#eefaff"),
		"muted": Color("#b3ccd5")
	},
	{
		"name": "Origine",
		"background": Color("#221713"),
		"surface": Color("#37241d"),
		"surface_alt": Color("#4b3025"),
		"accent": Color("#ca7959"),
		"accent_soft": Color("#e9aa8c"),
		"text": Color("#fff4ef"),
		"muted": Color("#d6beb3")
	},
	{
		"name": "Essor",
		"background": Color("#102120"),
		"surface": Color("#193735"),
		"surface_alt": Color("#234b48"),
		"accent": Color("#4fb9aa"),
		"accent_soft": Color("#8bd9cd"),
		"text": Color("#effbf9"),
		"muted": Color("#b0d0cb")
	},
	{
		"name": "Brumal",
		"background": Color("#171b2c"),
		"surface": Color("#252b43"),
		"surface_alt": Color("#333b59"),
		"accent": Color("#7e91d5"),
		"accent_soft": Color("#aebcea"),
		"text": Color("#f3f5ff"),
		"muted": Color("#bec4db")
	}
]


static func get_palette(month_index: int, day_of_month: int, weeks_in_month: int) -> Dictionary:
	var safe_index: int = posmod(month_index, PALETTES.size())
	var next_index: int = (safe_index + 1) % PALETTES.size()
	var current: Dictionary = PALETTES[safe_index]
	var next: Dictionary = PALETTES[next_index]
	var total_days: int = maxi(weeks_in_month * 7, 1)
	var raw_progress: float = clampf(
		float(day_of_month - 1) / float(maxi(total_days - 1, 1)),
		0.0,
		1.0
	)
	# Smoothstep : la transition reste douce au début et à la fin du mois.
	var progress: float = raw_progress * raw_progress * (3.0 - (2.0 * raw_progress))

	var current_background: Color = current["background"]
	var current_surface: Color = current["surface"]
	var current_surface_alt: Color = current["surface_alt"]
	var current_accent: Color = current["accent"]
	var current_accent_soft: Color = current["accent_soft"]
	var current_text: Color = current["text"]
	var current_muted: Color = current["muted"]

	var next_background: Color = next["background"]
	var next_surface: Color = next["surface"]
	var next_surface_alt: Color = next["surface_alt"]
	var next_accent: Color = next["accent"]
	var next_accent_soft: Color = next["accent_soft"]
	var next_text: Color = next["text"]
	var next_muted: Color = next["muted"]

	return {
		"name": current["name"],
		"background": current_background.lerp(next_background, progress),
		"surface": current_surface.lerp(next_surface, progress),
		"surface_alt": current_surface_alt.lerp(next_surface_alt, progress),
		"accent": current_accent.lerp(next_accent, progress),
		"accent_soft": current_accent_soft.lerp(next_accent_soft, progress),
		"text": current_text.lerp(next_text, progress),
		"muted": current_muted.lerp(next_muted, progress)
	}
