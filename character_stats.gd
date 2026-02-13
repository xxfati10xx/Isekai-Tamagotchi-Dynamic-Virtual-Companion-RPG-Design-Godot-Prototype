extends Resource
class_name CharacterStats

# Atributos principales (Las cuatro Dimensiones del Alma)
@export var character_name: String = "Kaelen"
@export var valor: float = 50.0
@export var sabiduria: float = 50.0
@export var empatia: float = 50.0
@export var ambicion: float = 50.0

# Atributos visuales
@export var skin_color: Color = Color("ffe0bd")
@export var hair_color: Color = Color("4b2c20")
@export var eye_color: Color = Color("000000")
@export var outfit_color: Color = Color("3a6ea5")
@export var hair_style: int = 0
@export var face_style: int = 0
@export var eye_style: int = 0
@export var mouth_style: int = 0
@export var body_style: int = 0

# Progreso del personaje y bono permanente de legado
@export var level: int = 1
@export var legacy_bonus: float = 0.0

# Inicialización de las estadísticas al crear un nuevo personaje
func _init(_character_name: String = "Kaelen", _valor: float = 50.0, _sabiduria: float = 50.0, _empatia: float = 50.0, _ambicion: float = 50.0, _level: int = 1, _legacy_bonus: float = 0.0, _skin_color: Color = Color("ffe0bd"), _hair_style: int = 0, _face_style: int = 0, _eye_style: int = 0, _mouth_style: int = 0, _body_style: int = 0, _hair_color: Color = Color("4b2c20"), _eye_color: Color = Color("000000"), _outfit_color: Color = Color("3a6ea5")):
	character_name = _character_name
	valor = _valor
	sabiduria = _sabiduria
	empatia = _empatia
	ambicion = _ambicion
	level = _level
	legacy_bonus = _legacy_bonus
	skin_color = _skin_color
	hair_style = _hair_style
	face_style = _face_style
	eye_style = _eye_style
	mouth_style = _mouth_style
	body_style = _body_style
	hair_color = _hair_color
	eye_color = _eye_color
	outfit_color = _outfit_color

# Actualiza las estadísticas aplicando el bono de legado acumulado a las ganancias
func update_stats(delta_valor: float, delta_sabiduria: float, delta_empatia: float, delta_ambicion: float):
	# Si el cambio es positivo, le sumamos el bono de legado acumulado
	var v = delta_valor + (legacy_bonus if delta_valor > 0 else 0.0)
	var s = delta_sabiduria + (legacy_bonus if delta_sabiduria > 0 else 0.0)
	var e = delta_empatia + (legacy_bonus if delta_empatia > 0 else 0.0)
	var a = delta_ambicion + (legacy_bonus if delta_ambicion > 0 else 0.0)
	
	# Mantenemos los valores siempre entre 0 y 100
	valor = clamp(valor + v, 0, 100)
	sabiduria = clamp(sabiduria + s, 0, 100)
	empatia = clamp(empatia + e, 0, 100)
	ambicion = clamp(ambicion + a, 0, 100)
