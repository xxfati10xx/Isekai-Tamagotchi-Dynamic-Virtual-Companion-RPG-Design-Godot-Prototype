extends Resource
class_name CharacterStats

# Atributos principales (Las cuatro Dimensiones del Alma)
@export var valor: float = 50.0
@export var sabiduria: float = 50.0
@export var empatia: float = 50.0
@export var ambicion: float = 50.0

# Progreso del personaje y bono permanente de legado
@export var level: int = 1
@export var legacy_bonus: float = 0.0

# Inicialización de las estadísticas al crear un nuevo personaje
func _init(_valor: float = 50.0, _sabiduria: float = 50.0, _empatia: float = 50.0, _ambicion: float = 50.0, _level: int = 1, _legacy_bonus: float = 0.0):
	valor = _valor
	sabiduria = _sabiduria
	empatia = _empatia
	ambicion = _ambicion
	level = _level
	legacy_bonus = _legacy_bonus

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
