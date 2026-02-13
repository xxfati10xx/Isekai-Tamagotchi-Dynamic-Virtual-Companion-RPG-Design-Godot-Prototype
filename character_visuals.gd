extends Node2D

@onready var body: Polygon2D = $Body
@onready var head: Polygon2D = $Head
@onready var eyes: Label = $Eyes
@onready var mouth: Label = $Mouth
@onready var hair: Label = $Hair

func update_appearance(stats: CharacterStats, update_scale: bool = true):
	if body:
		body.color = stats.outfit_color
	if head:
		head.color = stats.skin_color
	if eyes:
		eyes.add_theme_color_override("font_color", stats.eye_color)
	if hair:
		hair.add_theme_color_override("font_color", stats.hair_color)

	# Actualización de estilos (Placeholders con texto)
	match stats.eye_style:
		0: eyes.text = "◕ ◕"
		1: eyes.text = "ò ò"
		2: eyes.text = "X X"
		3: eyes.text = "^ ^"
		4: eyes.text = "o o"
		5: eyes.text = "> <"
		6: eyes.text = "U U"
		_: eyes.text = "◕ ◕"

	match stats.mouth_style:
		0: mouth.text = "◡"
		1: mouth.text = "ᗝ"
		2: mouth.text = "—"
		3: mouth.text = "w"
		4: mouth.text = "o"
		5: mouth.text = "v"
		_: mouth.text = "◡"

	match stats.hair_style:
		0: hair.text = "|||||"
		1: hair.text = "@@@@@"
		2: hair.text = "/\\/\\"
		3: hair.text = "~~~~~"
		4: hair.text = "#####"
		5: hair.text = "*****"
		_: hair.text = ""

	# El estilo de cuerpo afecta la escala general
	if update_scale:
		match stats.body_style:
			0: scale = Vector2(1, 1)
			1: scale = Vector2(0.8, 0.8)
			2: scale = Vector2(1.2, 1.2)
