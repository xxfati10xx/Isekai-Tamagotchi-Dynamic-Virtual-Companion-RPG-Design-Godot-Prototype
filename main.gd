extends Control

# Enlaces a los nodos de la interfaz (Usando % para Nodos Únicos de Escena)
@onready var world_background: TextureRect = %WorldBackground
@onready var action_sphere: Button = %ActionSphere
@onready var sprite: Label = %Sprite
@onready var hp_bar: ProgressBar = %HPBar
@onready var mp_bar: ProgressBar = %MPBar
@onready var gem_label: Label = %GemLabel
@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var biome_badge: Label = %BiomeBadge
@onready var notification_panel: PanelContainer = %NotificationPanel
@onready var notification_text: Label = %NotificationText
@onready var option_1: Button = %Option1
@onready var option_2: Button = %Option2

# Estados del juego
var is_combat: bool = false
var normal_gradient: GradientTexture2D
var combat_gradient: GradientTexture2D

var stats: CharacterStats = CharacterStats.new()
var autonomy_timer: Timer

var weapon_level: int = 0
var skills: Array[String] = []

func _ready() -> void:
	# Configuración visual de los fondos degradados
	normal_gradient = GradientTexture2D.new()
	normal_gradient.gradient = Gradient.new()
	normal_gradient.gradient.colors = PackedColorArray([Color("4facfe"), Color("00f2fe")])
	normal_gradient.fill_from = Vector2(0.5, 0)
	normal_gradient.fill_to = Vector2(0.5, 1)

	combat_gradient = GradientTexture2D.new()
	combat_gradient.gradient = Gradient.new()
	combat_gradient.gradient.colors = PackedColorArray([Color("232526"), Color("414345")])
	combat_gradient.fill_from = Vector2(0.5, 0)
	combat_gradient.fill_to = Vector2(0.5, 1)

	# Estado inicial
	world_background.texture = normal_gradient
	action_sphere.pressed.connect(_on_action_button_pressed)
	option_1.pressed.connect(_on_option_1_pressed)
	option_2.pressed.connect(_on_option_2_pressed)
	
	_start_idle_animation()
	_update_stats_display()
	
	# Iniciamos el Ciclo de Autonomía (el personaje vive solo cada 5 seg)
	autonomy_timer = Timer.new()
	autonomy_timer.wait_time = 5.0
	autonomy_timer.autostart = true
	autonomy_timer.timeout.connect(_on_autonomy_tick)
	add_child(autonomy_timer)

# Alterna entre el modo paz y el modo combate
func _on_action_button_pressed() -> void:
	is_combat = !is_combat
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if is_combat:
		world_background.texture = combat_gradient
		tween.tween_property(action_sphere, "rotation_degrees", 45.0, 0.2)
		tween.tween_property(action_sphere, "scale", Vector2(1.2, 1.2), 0.2)
		status_label.text = "En combate"
		biome_badge.text = "📍 CAMPO DE BATALLA"
	else:
		world_background.texture = normal_gradient
		tween.tween_property(action_sphere, "rotation_degrees", 0.0, 0.2)
		tween.tween_property(action_sphere, "scale", Vector2(1.0, 1.0), 0.2)
		status_label.text = "Explorando..."
		biome_badge.text = "📍 DESFILADERO DE LAS SOMBRAS"

# Lógica que ocurre automáticamente en cada "tick" del reloj
func _on_autonomy_tick() -> void:
	if notification_panel.visible: return
	
	if is_combat:
		_check_death()
		if not is_instance_valid(self): return
		weapon_level += 1
		
	# Probabilidad de disparar un evento de decisión o una acción normal
	if randf() < 0.3:
		_trigger_decision_event()
	else:
		_simulate_action()
	
	_check_ascension()

# El personaje realiza una actividad por su cuenta
func _simulate_action() -> void:
	var actions = [
		{"msg": "Entrenando duro", "stats": [2, 0, -1, 1]},
		{"msg": "Leyendo libros antiguos", "stats": [-1, 3, 0, 0]},
		{"msg": "Ayudando a aldeanos", "stats": [0, 0, 4, -1]},
		{"msg": "Meditando", "stats": [0, 2, 2, 0]},
		{"msg": "Buscando tesoros", "stats": [1, 0, -1, 3]}
	]
	var action = actions[randi() % actions.size()]
	status_label.text = action["msg"]
	stats.update_stats(action["stats"][0], action["stats"][1], action["stats"][2], action["stats"][3])
	_update_stats_display()

# Dispara un evento donde el jugador DEBE elegir el destino
func _trigger_decision_event() -> void:
	var events = [
		{
			"text": "¡Un monstruo herido bloquea el camino! ¿Qué hacer?",
			"opt1": "Rematarlo (Valor+, Ambicion+)",
			"opt2": "Curarlo (Empatia++, Sabiduria+)",
			"res1": [5, 0, -5, 5], "res2": [-2, 3, 8, 0]
		}
	]
	var event = events[randi() % events.size()]
	notification_text.text = event["text"]
	option_1.text = event["opt1"]
	option_2.text = event["opt2"]
	
	notification_panel.set_meta("res1", event["res1"])
	notification_panel.set_meta("res2", event["res2"])
	notification_panel.show()

# Maneja la respuesta a la Opción 1 (o reinicio si el personaje murió/ascendió)
func _on_option_1_pressed() -> void:
	if notification_panel.has_meta("is_reset"):
		_reset_character(notification_panel.get_meta("new_legacy"))
		return
	var res = notification_panel.get_meta("res1")
	stats.update_stats(res[0], res[1], res[2], res[3])
	_update_stats_display()
	notification_panel.hide()

# Maneja la respuesta a la Opción 2
func _on_option_2_pressed() -> void:
	if notification_panel.has_meta("is_reset"):
		_reset_character(notification_panel.get_meta("new_legacy"))
		return
	var res = notification_panel.get_meta("res2")
	stats.update_stats(res[0], res[1], res[2], res[3])
	_update_stats_display()
	notification_panel.hide()

# Si todas las stats son altas, el personaje asciende a leyenda
func _check_ascension() -> void:
	if stats.valor >= 80 and stats.sabiduria >= 80 and stats.empatia >= 80 and stats.ambicion >= 80:
		var bonus = stats.legacy_bonus + 5.0
		notification_text.text = "¡LA ASCENSIÓN! Te has convertido en leyenda. Bono Legado: +%.1f" % bonus
		_show_reset_notification(bonus)

# Probabilidad de morir si estás en modo combate
func _check_death() -> void:
	if randf() < 0.01: # 1% de probabilidad por tick
		notification_text.text = "MUERTE PERMANENTE. Has caído en batalla. El ciclo se reinicia..."
		_show_reset_notification(stats.legacy_bonus)

# FUNCIÓN CORREGIDA: Muestra el panel de reinicio (ya sea por muerte o gloria)
func _show_reset_notification(new_legacy: float) -> void:
	option_1.text = "Resurgir / Nuevo Ciclo"
	option_2.text = "Aceptar Destino"
	notification_panel.set_meta("is_reset", true)
	notification_panel.set_meta("new_legacy", new_legacy)
	notification_panel.show()

# Reinicia los valores pero mantiene el bono de legado para el siguiente
func _reset_character(legacy_bonus: float) -> void:
	stats = CharacterStats.new(50, 50, 50, 50, 1, legacy_bonus)
	is_combat = false
	world_background.texture = normal_gradient
	action_sphere.rotation_degrees = 0
	action_sphere.scale = Vector2.ONE
	_update_stats_display()
	status_label.text = "Nuevo ciclo iniciado"
	notification_panel.remove_meta("is_reset")
	notification_panel.hide()

# Actualiza barras y textos de la interfaz
func _update_stats_display() -> void:
	hp_bar.value = stats.valor
	mp_bar.value = stats.sabiduria
	gem_label.text = "%d 💎" % stats.ambicion
	name_label.text = "KAELEN - NIV. %d" % stats.level
	
	# Evolución visual según la estadística dominante
	if stats.valor > 85: sprite.text = "ᕦ(ò_ó)ᕤ"
	elif stats.sabiduria > 85: sprite.text = "(∩｀-´)⊃━☆ﾟ.*･｡ﾟ"
	elif stats.empatia > 85: sprite.text = "⸜(｡˃ ᵕ ˂ )⸝♡"
	else: sprite.text = "(◕‿◕)"
	
	_update_background_aura()

# Cambia ligeramente el color del fondo según la personalidad del personaje
func _update_background_aura() -> void:
	var tint = Color.WHITE
	if stats.valor > stats.sabiduria: tint = Color(1, 0.85, 0.85)
	elif stats.sabiduria > stats.valor: tint = Color(0.85, 0.85, 1)
	world_background.self_modulate = tint

# Animación de respiración/flotado del sprite
func _start_idle_animation() -> void:
	await get_tree().process_frame
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var base_y = sprite.position.y
	tween.tween_property(sprite, "position:y", base_y - 10, 1.5)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.02, 1.02), 1.5)
	tween.tween_property(sprite, "position:y", base_y, 1.5)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.0, 1.0), 1.5)
