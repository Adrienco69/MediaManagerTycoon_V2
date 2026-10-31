class_name StartScreenGradient
extends Control

const MONTH_COLORS: Array[Color] = [
	Color("#1f4327"), # Floréal
	Color("#5a4318"), # Clôture
	Color("#43234e"), # Crépuscule
	Color("#1e475c"), # Zénith
	Color("#542d1e"), # Origine
	Color("#174b45"), # Essor
	Color("#2d355e")  # Brumal
]

const BAND_HALF_WIDTH: float = 0.18
const BAND_ALPHA: float = 0.78


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_month_layers()


func _build_month_layers() -> void:
	for month_index: int in range(MONTH_COLORS.size()):
		var layer: TextureRect = _create_month_layer(month_index)
		add_child(layer)
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _create_month_layer(month_index: int) -> TextureRect:
	var month_color: Color = MONTH_COLORS[month_index]
	var center: float = float(month_index + 1) / float(MONTH_COLORS.size() + 1)
	var left: float = maxf(center - BAND_HALF_WIDTH, 0.001)
	var right: float = minf(center + BAND_HALF_WIDTH, 0.999)

	var transparent: Color = Color(month_color.r, month_color.g, month_color.b, 0.0)
	var peak: Color = Color(month_color.r, month_color.g, month_color.b, BAND_ALPHA)

	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, left, center, right, 1.0])
	gradient.colors = PackedColorArray([transparent, transparent, peak, transparent, transparent])

	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 1366
	texture.height = 768

	# Un mois sur deux est horizontal, l'autre vertical.
	if month_index % 2 == 0:
		texture.fill_from = Vector2(0.0, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
	else:
		texture.fill_from = Vector2(0.5, 0.0)
		texture.fill_to = Vector2(0.5, 1.0)

	var layer: TextureRect = TextureRect.new()
	layer.name = "MonthLayer%d" % (month_index + 1)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	return layer
