extends Control

# Enlaces a los nodos de la interfaz (Usando % para Nodos Únicos de Escena)
@onready var world_background: TextureRect = %WorldBackground
@onready var action_sphere: Button = %ActionSphere
@onready var character_visuals: Node2D = %CharacterVisuals
@onready var hp_bar: ProgressBar = %HPBar
@onready var mp_bar: ProgressBar = %MPBar
@onready var gem_label: Label = %GemLabel
@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var biome_badge: PanelContainer = %BiomeBadge
@onready var biome_label: Label = %BiomeLabel
@onready var nav_estilo: Button = %NavEstilo
@onready var notification_panel: PanelContainer = %NotificationPanel
@onready var notification_text: Label = %NotificationText
@onready var option_1: Button = %Option1
@onready var option_2: Button = %Option2
@onready var customization_panel: PanelContainer = %CustomizationPanel
@onready var name_input: LineEdit = %NameInput
@onready var skin_color: ColorPickerButton = %SkinColor
@onready var hair_style_btn: OptionButton = %HairStyle
@onready var eye_style_btn: OptionButton = %EyeStyle
@onready var mouth_style_btn: OptionButton = %MouthStyle
@onready var body_style_btn: OptionButton = %BodyStyle
@onready var confirm_button: Button = %ConfirmButton

# Estados del juego
var is_combat: bool = false
var normal_gradient: GradientTexture2D
var combat_gradient: GradientTexture2D

var stats: CharacterStats = CharacterStats.new()
var autonomy_timer: Timer
var idle_tween: Tween

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
	confirm_button.pressed.connect(_on_confirm_customization)
	nav_estilo.pressed.connect(func(): customization_panel.show(); autonomy_timer.paused = true)

	# Inicializar opciones de personalización
	hair_style_btn.add_item("Lacio", 0)
	hair_style_btn.add_item("Rizado", 1)
	hair_style_btn.add_item("Picos", 2)

	eye_style_btn.add_item("Normal", 0)
	eye_style_btn.add_item("Enojado", 1)
	eye_style_btn.add_item("Muerto", 2)

	mouth_style_btn.add_item("Feliz", 0)
	mouth_style_btn.add_item("Asombrado", 1)
	mouth_style_btn.add_item("Serio", 2)

	body_style_btn.add_item("Normal", 0)
	body_style_btn.add_item("Pequeño", 1)
	body_style_btn.add_item("Grande", 2)
	
	_start_idle_animation()
	_update_stats_display()
	
	# Iniciamos el Ciclo de Autonomía (el personaje vive solo cada 5 seg)
	autonomy_timer = Timer.new()
	autonomy_timer.wait_time = 5.0
	autonomy_timer.autostart = true
	autonomy_timer.timeout.connect(_on_autonomy_tick)
	add_child(autonomy_timer)
	autonomy_timer.paused = true

func _on_confirm_customization() -> void:
	if name_input.text != "":
		stats.character_name = name_input.text

	stats.skin_color = skin_color.color
	stats.hair_style = hair_style_btn.get_selected_id()
	stats.eye_style = eye_style_btn.get_selected_id()
	stats.mouth_style = mouth_style_btn.get_selected_id()
	stats.body_style = body_style_btn.get_selected_id()

	customization_panel.hide()
	autonomy_timer.paused = false
	if character_visuals:
		character_visuals.update_appearance(stats, true)
	_update_stats_display()
	_start_idle_animation() # Reiniciar animación con nueva escala

# Alterna entre el modo paz y el modo combate
func _on_action_button_pressed() -> void:
	is_combat = !is_combat
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if is_combat:
		world_background.texture = combat_gradient
		tween.tween_property(action_sphere, "rotation_degrees", 45.0, 0.2)
		tween.tween_property(action_sphere, "scale", Vector2(1.2, 1.2), 0.2)
		status_label.text = "En combate"
		biome_label.text = "📍 CAMPO DE BATALLA"
	else:
		world_background.texture = normal_gradient
		tween.tween_property(action_sphere, "rotation_degrees", 0.0, 0.2)
		tween.tween_property(action_sphere, "scale", Vector2(1.0, 1.0), 0.2)
		status_label.text = "Explorando..."
		biome_label.text = "📍 DESFILADERO DE LAS SOMBRAS"

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
	stats = CharacterStats.new("Kaelen", 50, 50, 50, 50, 1, legacy_bonus)
	is_combat = false
	world_background.texture = normal_gradient
	action_sphere.rotation_degrees = 0
	action_sphere.scale = Vector2.ONE
	if character_visuals:
		character_visuals.update_appearance(stats, true)
	_update_stats_display()
	status_label.text = "Nuevo ciclo iniciado"
	notification_panel.remove_meta("is_reset")
	notification_panel.hide()
	customization_panel.show()
	autonomy_timer.paused = true

# Actualiza barras y textos de la interfaz
func _update_stats_display() -> void:
	hp_bar.value = stats.valor
	mp_bar.value = stats.sabiduria
	gem_label.text = "%.0f 💎" % stats.ambicion
	name_label.text = "%s - NIV. %d" % [stats.character_name, stats.level]
	
	if character_visuals:
		character_visuals.update_appearance(stats, false)
	
	_update_background_aura()

# Cambia ligeramente el color del fondo según la personalidad del personaje
func _update_background_aura() -> void:
	var tint = Color.WHITE
	if stats.valor > stats.sabiduria: tint = Color(1, 0.85, 0.85)
	elif stats.sabiduria > stats.valor: tint = Color(0.85, 0.85, 1)
	world_background.self_modulate = tint

# Animación de respiración/flotado del personaje
func _start_idle_animation() -> void:
	if idle_tween: idle_tween.kill()
	await get_tree().process_frame
	idle_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var base_y = character_visuals.position.y
	var base_scale = character_visuals.scale
	idle_tween.tween_property(character_visuals, "position:y", base_y - 10, 1.5)
	idle_tween.parallel().tween_property(character_visuals, "scale", base_scale * 1.02, 1.5)
	idle_tween.tween_property(character_visuals, "position:y", base_y, 1.5)
	idle_tween.parallel().tween_property(character_visuals, "scale", base_scale, 1.5)
